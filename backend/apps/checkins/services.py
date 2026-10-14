"""Business logic shared by the API, the seed and the Celery tasks."""
import logging
from datetime import timedelta
from decimal import Decimal, InvalidOperation

from django.db import transaction
from django.utils import timezone

from .models import (
    MEASUREMENT_METRICS,
    Answer,
    BodyMeasurement,
    BodyWeight,
    CheckinPhoto,
    CheckinSubmission,
    Form,
    FormKind,
    Metric,
    ProgressPhotoSet,
    Question,
    QuestionType,
)

log = logging.getLogger(__name__)


def safe_notify(user, title, body="", kind="checkin", link=""):
    """notify() but never breaks the request (e.g. engage app not migrated yet)."""
    if user is None:
        return None
    try:
        from apps.core.services.notify import notify

        return notify(user, title, body, kind=kind, link=link)
    except Exception:  # pragma: no cover - defensive
        log.exception("notify failed for %s", user)
        return None


def safe_log_activity(actor, verb, target="", client=None, category="checkin"):
    try:
        from apps.core.services.activity import log_activity

        return log_activity(actor, verb, target=target, client=client, category=category)
    except Exception:  # pragma: no cover
        log.exception("log_activity failed")
        return None


def to_decimal(v):
    if v is None or v == "":
        return None
    try:
        return Decimal(str(v))
    except (InvalidOperation, ValueError):
        return None


# ---------------------------------------------------------------- forms
@transaction.atomic
def duplicate_form(form, user=None, name=None, client=None):
    """Copy a form with its questions. Copies start as drafts (design: “Saved as a draft”).

    With `client`, makes that client's edited copy (parent = the master).
    """
    copy = Form.objects.get(pk=form.pk)
    copy.pk = None
    copy.id = None
    copy.name = name or (form.name if client else f"{form.name} (copy)")
    copy.is_published = bool(client) and form.is_published
    copy.published_at = None
    copy.is_archived = False
    copy.archived_at = None
    copy.is_template = False
    copy.created_by = user
    copy.updated_by = user
    copy.client = client
    copy.parent = form if client else None
    copy.save()
    for q in form.questions.all():
        src = q.pk
        q.pk = None
        q.id = None
        q.form = copy
        q.source_question_id = src if client else None
        q.save()
    return copy


def form_stats(form, now=None):
    """Form builder “Answers so far”: sent this month · answered · answer rate."""
    now = now or timezone.localtime()
    start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    forms = [form.pk] + list(form.copies.values_list("pk", flat=True))
    qs = CheckinSubmission.objects.filter(form_id__in=forms, due_at__gte=start, due_at__lte=now)
    sent = qs.count()
    answered = qs.filter(status__in=[CheckinSubmission.Status.SUBMITTED, CheckinSubmission.Status.REVIEWED]).count()
    rate = round(answered * 100 / sent) if sent else 0
    return {"sent_this_month": sent, "answered": answered, "answer_rate": rate}


# ---------------------------------------------------------------- answers
def display_text(question, value):
    """Human text for an answer, e.g. scale 4 → “4 / 5 · Good”."""
    if value is None or value == "" or value == []:
        return ""
    t = question.type if question else None
    if t == QuestionType.SCALE:
        try:
            n = int(value)
        except (TypeError, ValueError):
            return str(value)
        labels = question.scale_labels or []
        idx = n - question.scale_min
        lab = labels[idx] if 0 <= idx < len(labels) else ""
        return f"{n} / {question.scale_max}" + (f" · {lab}" if lab else "")
    if t == QuestionType.YES_NO:
        if isinstance(value, bool):
            return "Yes" if value else "No"
        return str(value)
    if t in (QuestionType.MULTI_CHOICE,) and isinstance(value, list):
        return ", ".join(str(v) for v in value)
    if t in (QuestionType.NUMBER, QuestionType.MEASUREMENT):
        unit = f" {question.unit}" if question.unit else ""
        return f"{value}{unit}"
    if t == QuestionType.PHOTO:
        if isinstance(value, list):
            n = len(value)
            return "No photos this week" if n == 0 else f"{n} photo{'s' if n != 1 else ''}"
        return str(value)
    if isinstance(value, list):
        return ", ".join(str(v) for v in value)
    return str(value)


def numeric_value(question, value):
    if question and question.type in (QuestionType.NUMBER, QuestionType.SCALE, QuestionType.MEASUREMENT):
        return to_decimal(value)
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return to_decimal(value)
    return None


@transaction.atomic
def save_answers(submission, answers):
    """Replace a submission's answers.

    answers: list of {question: id, value, text?} or {label, value, text?, metric?}.
    """
    submission.answers.all().delete()
    qmap = {q.id: q for q in submission.form.questions.all()}
    for pos, a in enumerate(answers or []):
        q = qmap.get(a.get("question")) if a.get("question") else None
        value = a.get("value")
        Answer.objects.create(
            submission=submission,
            question=q,
            position=pos,
            label=a.get("label") or (q.text if q else ""),
            metric=a.get("metric") or (q.metric if q else ""),
            value=value,
            number=numeric_value(q, value),
            text=a.get("text") or display_text(q, value),
            previous_text=a.get("previous_text", ""),
            trend=a.get("trend", ""),
        )


def missing_required(submission):
    answered = {
        a.question_id
        for a in submission.answers.all()
        if a.question_id and a.value not in (None, "", [])
    }
    return [q for q in submission.form.questions.all() if q.required and q.id not in answered]


def _previous_weight(client, before_date):
    return BodyWeight.objects.filter(client=client, date__lt=before_date).order_by("-date").first()


@transaction.atomic
def apply_progress(submission, user=None, photos=None):
    """After submit: weight / measurements / photos go to the progress tables, KPIs get filled."""
    day = timezone.localtime(submission.submitted_at or timezone.now()).date()
    client = submission.client
    measures = {}
    for a in submission.answers.select_related("question"):
        metric = a.metric
        if metric == Metric.WEIGHT and a.number is not None:
            prev = _previous_weight(client, day)
            source = {FormKind.DAILY: BodyWeight.Source.DAILY, FormKind.WEEKLY: BodyWeight.Source.WEEKLY,
                      FormKind.ONBOARDING: BodyWeight.Source.ONBOARDING}.get(submission.kind, BodyWeight.Source.MANUAL)
            BodyWeight.objects.update_or_create(
                client=client, date=day,
                defaults={"weight_kg": a.number, "source": source, "submission": submission, "logged_by": user},
            )
            submission.weight_kg = a.number
            if prev:
                submission.weight_change_kg = a.number - prev.weight_kg
                submission.weight_change_label = submission.weight_change_label or "Change"
        elif metric in MEASUREMENT_METRICS and a.number is not None:
            measures[MEASUREMENT_METRICS[metric]] = a.number
        elif metric == Metric.SLEEP and a.number is not None:
            submission.sleep_hours = a.number
        elif metric == Metric.STEPS and a.number is not None:
            submission.steps = int(a.number)
        elif metric == Metric.NOTE and a.text:
            submission.note = a.text
    if measures:
        BodyMeasurement.objects.update_or_create(
            client=client, date=day, defaults={**measures, "submission": submission, "measured_by": user}
        )
    if photos:
        photo_set, _ = ProgressPhotoSet.objects.update_or_create(
            client=client, date=day,
            defaults={"weight_kg": submission.weight_kg, "label": f"{submission.title or submission.form.name}",
                      "source": ProgressPhotoSet.Source.CHECKIN, "submission": submission},
        )
        for pose, f in photos:
            CheckinPhoto.objects.filter(photo_set=photo_set, pose=pose).delete()
            CheckinPhoto.objects.create(
                client=client, submission=submission, photo_set=photo_set, pose=pose, image=f,
                file_name=getattr(f, "name", "")[:120], taken_on=day, uploaded_by=user,
            )
    submission.save()


def submit(submission, user, answers=None, photos=None):
    if answers is not None:
        save_answers(submission, answers)
    missing = missing_required(submission)
    if missing:
        return [q.text for q in missing]
    submission.status = CheckinSubmission.Status.SUBMITTED
    submission.submitted_at = timezone.now()
    if submission.form.kind == FormKind.WAIVER and not submission.signed_at:
        submission.signed_at = submission.submitted_at
    submission.save()
    apply_progress(submission, user=user, photos=photos)
    trainer = getattr(submission.client, "trainer", None)
    who = submission.client.user.full_name
    if trainer is not None:
        safe_notify(trainer.user, f"{who} sent the {submission.title or submission.form.name.lower()} check-in",
                    submission.summary or "", kind="checkin", link=f"/checkins/{submission.id}")
    safe_log_activity(user, f" sent the {submission.title or submission.form.name} check-in", target=submission.form.name,
                      client=submission.client)
    return []


def review(submission, user, reply_text="", voice_note=None, voice_note_url=""):
    from .models import CheckinReply

    now = timezone.now()
    reply = None
    if reply_text or voice_note or voice_note_url:
        reply = CheckinReply.objects.create(
            submission=submission, author=user, text=reply_text or "", voice_note=voice_note or "",
            voice_note_url=voice_note_url or "", sent_at=now,
        )
    submission.status = CheckinSubmission.Status.REVIEWED
    submission.reviewed_by = user
    submission.reviewed_at = now
    submission.save(update_fields=["status", "reviewed_by", "reviewed_at", "updated_at"])
    first = user.full_name.split(" ")[0] if getattr(user, "full_name", "") else "Your coach"
    if reply:
        safe_notify(submission.client.user, f"{first} replied to your check-in", reply.text[:140] or "Voice note",
                    kind="checkin", link=f"/checkins/{submission.id}")
        safe_log_activity(user, f" replied to {submission.client.user.full_name}’s check-in", target=reply.text[:120],
                          client=submission.client)
    else:
        safe_log_activity(user, f" reviewed {submission.client.user.full_name}’s check-in", client=submission.client)
    return reply


# ---------------------------------------------------------------- schedules
def next_due(schedule, after):
    """Next due datetime (aware, local tz) strictly after `after` for a schedule."""
    from datetime import datetime, time

    tz = timezone.get_current_timezone()
    t = schedule.send_time or time(9, 0)
    local = timezone.localtime(after)
    d = local.date()
    freq = schedule.frequency
    for i in range(0, 62):
        day = d + timedelta(days=i)
        ok = False
        if freq == "daily":
            ok = True
        elif freq in ("weekly", "biweekly"):
            ok = schedule.weekday is None or day.weekday() == schedule.weekday
            if ok and freq == "biweekly" and schedule.starts_on:
                ok = ((day - schedule.starts_on).days // 7) % 2 == 0
        elif freq == "monthly":
            ok = day.day == (schedule.day_of_month or 1)
        elif freq == "once":
            ok = True
        if ok:
            dt = timezone.make_aware(datetime.combine(day, t), tz)
            if dt > after:
                return dt
    return None
