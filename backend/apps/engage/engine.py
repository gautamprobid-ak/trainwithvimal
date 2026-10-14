"""Automation engine: pluggable trigger evaluation + step execution.

Triggers are small functions registered with @trigger("key"). Each gets the automation, the
audience queryset of ClientProfiles and `now`, and yields (client, trigger_key) pairs. The
trigger_key makes a run unique, so a client never enters the same automation twice for the same
event (e.g. the date of a weekly send). Other apps can register their own triggers
(missed check-in, missed workouts, streaks …) by importing `trigger` from here.
"""
import datetime as dt
import logging
import re

from django.conf import settings
from django.core.mail import send_mail
from django.db import IntegrityError, transaction
from django.utils import timezone

from .models import (
    SAMPLE_VARIABLES, Automation, AutomationRun, AutomationStep, MessageLog, MessageTemplate, TrainerTask,
    WorkspaceSettings,
)

log = logging.getLogger(__name__)
TRIGGERS = {}
VAR_RE = re.compile(r"\{\{(\w+)\}\}")


def trigger(key):
    def deco(fn):
        TRIGGERS[key] = fn
        return fn
    return deco


# ------------------------------------------------------------------ helpers

def fill_vars(text, values):
    return VAR_RE.sub(lambda m: str(values.get(m.group(1), m.group(0))), text or "")


def variables_for(client, ws=None):
    ws = ws or WorkspaceSettings.load()
    if client is None:
        return dict(SAMPLE_VARIABLES, gym_name=ws.business_name)
    coach = client.trainer.user.full_name.split()[0] if client.trainer_id else ""
    ends = client.plan_ends_on
    return {"first_name": client.user.first_name_display, "coach_name": coach, "gym_name": ws.business_name,
            "package_name": client.plan, "date": f"{ends.day} {ends:%b}" if ends else ""}


def _time_of(cfg, default="09:00"):
    try:
        h, m = (cfg.get("time") or default).split(":")
        return dt.time(int(h), int(m))
    except (ValueError, AttributeError):
        return dt.time(9, 0)


def _past_time(now, cfg, default="09:00"):
    return timezone.localtime(now).time() >= _time_of(cfg, default)


def audience(automation):
    from apps.people.models import ClientProfile

    qs = ClientProfile.objects.select_related("user", "trainer__user").filter(status__in=["active", "at_risk"])
    if automation.package:
        qs = qs.filter(plan__iexact=automation.package)
    if automation.trainer_id:
        qs = qs.filter(trainer_id=automation.trainer_id)
    for c in automation.conditions or []:
        field, value = c.get("field"), c.get("value")
        if field in {"goal", "status", "plan"}:
            qs = qs.filter(**{field: value})
    return qs


# ------------------------------------------------------------------ triggers

@trigger("clientApproved")
def _approved(a, clients, now):
    since = (now - dt.timedelta(days=2)).date()
    for c in clients.filter(joined_on__gte=since):
        yield c, "approved"


@trigger("weeklyCheckInDay")
def _weekly(a, clients, now):
    local = timezone.localtime(now)
    weekday = a.trigger_config.get("weekday") or a.trigger_value or 7
    if local.isoweekday() == int(weekday) and _past_time(now, a.trigger_config):
        for c in clients:
            yield c, local.date().isoformat()


@trigger("daily")
def _daily(a, clients, now):
    if _past_time(now, a.trigger_config, "07:00"):
        for c in clients:
            yield c, timezone.localtime(now).date().isoformat()


@trigger("onDate")
def _on_date(a, clients, now):
    if a.trigger_config.get("date") == timezone.localtime(now).date().isoformat() and _past_time(now, a.trigger_config):
        for c in clients:
            yield c, "once"


def _days_before_end(a, clients, now):
    n = a.trigger_config.get("n", a.trigger_value)
    target = timezone.localtime(now).date() + dt.timedelta(days=int(n or 0))
    if _past_time(now, a.trigger_config):
        for c in clients.filter(plan_ends_on=target):
            yield c, f"ends-{target.isoformat()}"


trigger("renewalDue")(_days_before_end)
trigger("planEnds")(_days_before_end)


@trigger("birthday")
def _birthday(a, clients, now):
    today = timezone.localtime(now).date()
    if not _past_time(now, a.trigger_config):
        return
    for c in clients:
        dob = getattr(c, "date_of_birth", None) or getattr(c.user, "date_of_birth", None)
        if dob and (dob.month, dob.day) == (today.month, today.day):
            yield c, str(today.year)


@trigger("inactive")
def _inactive(a, clients, now):
    n = int(a.trigger_config.get("n", a.trigger_value) or 5)
    cutoff = now - dt.timedelta(days=n)
    for c in clients.filter(user__last_active_at__lt=cutoff):
        yield c, f"inactive-{c.user.last_active_at:%Y%m%d}"


# ------------------------------------------------------------------ steps

def _deliver(template, channel, client, run, ws):
    """Send one channel of a template to the client. Returns the MessageLog row."""
    from apps.core.services.notify import notify

    text = template.texts.filter(channel=channel, enabled=True).first() if template else None
    if template and not text:
        return None
    values = variables_for(client, ws)
    subject = fill_vars(text.subject if text else "", values)
    body = fill_vars(text.body if text else "", values)
    user = client.user
    status = MessageLog.Status.SENT
    if channel in ("push", "inApp"):
        notify(user, subject or template.name, body, kind="automation", push=channel == "push")
        status = MessageLog.Status.DELIVERED
    elif channel == "email":
        if user.email_updates:
            send_mail(subject, body, settings.DEFAULT_FROM_EMAIL, [user.email], fail_silently=True)
        else:
            status = MessageLog.Status.FAILED
    else:  # whatsapp / sms: queued for the provider integration
        status = MessageLog.Status.QUEUED if user.whatsapp_enabled else MessageLog.Status.FAILED
    return MessageLog.objects.create(automation=run.automation if run else None, run=run, template=template, user=user,
                                     client=client, channel=channel, subject=subject, body=body, status=status)


def _send_form(step, client, run):
    from apps.core.services.notify import notify

    for ch in step.channels:
        if ch in ("push", "inApp"):
            notify(client.user, "A form from your coach", "Please fill it in when you can.", kind="form",
                   link=f"/c/more/checkins?form={step.form_key}", push=ch == "push")
        MessageLog.objects.create(automation=run.automation, run=run, user=client.user, client=client, channel=ch,
                                  subject="Form", body=step.form_key, status=MessageLog.Status.SENT)


def _assign(step, client, run):
    from apps.accounts.models import User
    from apps.core.services.notify import notify

    if step.task_for == "owner" or not client.trainer_id:
        assignee = User.objects.filter(role="admin").order_by("id").first()
    else:
        assignee = client.trainer.user
    if not assignee:
        return None
    task = TrainerTask.objects.create(automation=run.automation, run=run, client=client, assignee=assignee, title=step.task_text)
    notify(assignee, step.task_text, client.user.full_name, kind="task", push=False)
    return task


def client_responded(run):
    """Hook for 'Stop when the client responds'. Apps may monkey-patch / extend; default: never."""
    return False


def advance(run, now=None, ws=None):
    """Run steps until a wait or the end. Returns the number of steps executed."""
    now = now or timezone.now()
    ws = ws or WorkspaceSettings.load()
    a = run.automation
    steps = list(a.steps.select_related("template").all())
    done = 0
    while run.current_step < len(steps):
        step = steps[run.current_step]
        if a.stop_on_reply and run.current_step > 0 and client_responded(run):
            run.status, run.finished_at = AutomationRun.Status.STOPPED, now
            run.status_text = f"Stopped at step {run.current_step + 1}"
            break
        if step.kind == AutomationStep.Kind.WAIT:
            run.current_step += 1
            run.next_step_at = now + step.wait_delta
            run.status_text = f"Waiting · step {run.current_step} of {len(steps)}"
            run.save()
            return done
        if step.kind in (AutomationStep.Kind.MESSAGE, AutomationStep.Kind.FORM) and not run.is_test and ws.in_quiet_hours(now) \
                and any(c in ("push", "whatsapp") for c in step.channels):
            run.next_step_at = ws.quiet_hours_end(now)
            run.status_text = f"Waiting for quiet hours to end · step {run.current_step + 1} of {len(steps)}"
            run.save()
            return done
        if step.kind == AutomationStep.Kind.MESSAGE:
            for ch in step.channels:
                _deliver(step.template, ch, run.client, run, ws)
            run.status_text = f"Sent “{step.template.name if step.template else 'message'}” · step {run.current_step + 1}"
        elif step.kind == AutomationStep.Kind.FORM:
            _send_form(step, run.client, run)
            run.status_text = f"Sent the form · step {run.current_step + 1}"
        elif step.kind == AutomationStep.Kind.ASSIGN:
            _assign(step, run.client, run)
            run.status_text = f"Trainer task made · step {run.current_step + 1}"
        run.current_step += 1
        done += 1
    else:
        run.status, run.finished_at = AutomationRun.Status.FINISHED, now
        run.status_text = "Finished"
        Automation.objects.filter(pk=a.pk).update(finished_count=a.finished_count + 1)
    run.next_step_at = None
    run.save()
    return done


def start_run(automation, client, trigger_key, now=None, is_test=False):
    now = now or timezone.now()
    try:
        with transaction.atomic():
            run = AutomationRun.objects.create(automation=automation, client=client, trigger_key=trigger_key,
                                               next_step_at=now, started_at=now, is_test=is_test)
    except IntegrityError:
        return None
    return run


def evaluate(automation, now=None):
    """Start runs for every client the trigger matches. Returns the number started."""
    now = now or timezone.now()
    fn = TRIGGERS.get(automation.trigger)
    started = 0
    if fn:
        for client, key in fn(automation, audience(automation), now):
            if start_run(automation, client, key, now):
                started += 1
    if started:
        Automation.objects.filter(pk=automation.pk).update(running_count=automation.running_count + started)
    automation.last_evaluated_at = now
    automation.save(update_fields=["last_evaluated_at"])
    return started


def refresh_counters(automation):
    since = timezone.now() - dt.timedelta(days=30)
    runs = automation.runs.filter(is_test=False)
    Automation.objects.filter(pk=automation.pk).update(
        running_count=runs.filter(status=AutomationRun.Status.RUNNING).count(),
        started_30d=runs.filter(started_at__gte=since).count(),
        finished_30d=runs.filter(started_at__gte=since, status=AutomationRun.Status.FINISHED).count(),
        stopped_30d=runs.filter(started_at__gte=since, status=AutomationRun.Status.STOPPED).count(),
    )


def run_due(now=None):
    """Evaluate every 'on' automation, then advance every run whose next step is due."""
    now = now or timezone.now()
    ws = WorkspaceSettings.load()
    started = advanced = 0
    for a in Automation.objects.filter(status=Automation.Status.ON).exclude(trigger=""):
        started += evaluate(a, now)
    due = AutomationRun.objects.select_related("automation", "client__user", "client__trainer__user").filter(
        status=AutomationRun.Status.RUNNING, next_step_at__lte=now, automation__status=Automation.Status.ON)
    touched = set()
    for run in due:
        touched.add(run.automation_id)
        advanced += advance(run, now, ws)
    for a in Automation.objects.filter(pk__in=touched):
        refresh_counters(a)
    return {"started": started, "steps": advanced}


def send_event_template(event_key, client, extra=None):
    """Send a system template (invite, welcome, feedback …) on all its enabled channels."""
    tpl = MessageTemplate.objects.filter(event_key=event_key, enabled=True).first()
    if not tpl:
        return []
    return [m for t in tpl.texts.filter(enabled=True) if (m := _deliver(tpl, t.channel, client, None, None))]
