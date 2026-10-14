"""Engage: notifications, activity log, automations, message templates, team alerts and workspace settings.

Screens: Admin · Automations / New automation / Automation builder, Emails & alerts, Settings,
Activity log; Client · Home notifications sheet, More › Notifications / My activity / reminder settings;
Trainer · dashboard notices + tasks, Me › Account notification toggles.
"""
import datetime as dt

from django.conf import settings
from django.db import models
from django.utils import timezone

from apps.core.models import OrderedModel, TimeStampedModel


class Channel(models.TextChoices):
    EMAIL = "email", "Email"
    PUSH = "push", "Push"
    WHATSAPP = "whatsapp", "WhatsApp"
    IN_APP = "inApp", "In-app"
    SMS = "sms", "SMS"


# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------


class Notification(TimeStampedModel):
    """One in-app notification (bell sheet / More › Notifications). Created by core.services.notify."""

    class Tone(models.TextChoices):
        BLUE = "blue", "Blue"
        GREEN = "green", "Green"
        AMBER = "amber", "Amber"
        PURPLE = "purple", "Purple"
        GRAY = "gray", "Gray"
        RED = "red", "Red"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications")
    title = models.CharField(max_length=160)
    body = models.TextField(blank=True)
    kind = models.CharField(max_length=30, default="info", db_index=True,
                            help_text="info, checkin, session, plan, pb, water, meal, reminder, birthday, client, automation …")
    link = models.CharField(max_length=255, blank=True, help_text="App route the notification opens, e.g. /c/more/checkins")
    read_at = models.DateTimeField(null=True, blank=True, db_index=True)
    icon = models.CharField(max_length=20, blank=True, help_text="Design icon key: form, cal, star, dumb, water, food, bell, user …")
    tone = models.CharField(max_length=10, choices=Tone.choices, default=Tone.BLUE)
    action_label = models.CharField(max_length=40, blank=True, help_text="e.g. Open check-ins")
    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+",
                              help_text="Who caused it (avatar on trainer notices)")
    client = models.ForeignKey("people.ClientProfile", on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ("-created_at", "-id")
        indexes = [models.Index(fields=["user", "read_at"])]

    def __str__(self):
        return f"{self.user_id}: {self.title}"

    @property
    def is_read(self):
        return self.read_at is not None


def default_client_prefs():
    return {"workout": True, "meals": True, "water": True, "supps": True, "habits": False,
            "checkin": True, "coach": True, "progress": True}


def default_trainer_prefs():
    return {"ci": True, "miss": True, "new": True, "sess": True, "sum": False, "news": True}


class NotificationSettings(TimeStampedModel):
    """Per-user reminder toggles + personal quiet hours (Client More › Notification settings,
    Trainer Me › Account)."""

    CLIENT_KEYS = [
        ("workout", "Workout reminders", "1 hour before your session or planned workout"),
        ("meals", "Meal reminders", "At each meal time in your plan"),
        ("water", "Water reminders", "Every 2 hours when you are behind"),
        ("supps", "Supplement reminders", "Whey and D3 in the morning, magnesium at night"),
        ("habits", "Habit reminders", "Steps and sleep nudges in the evening"),
        ("checkin", "Check-in reminders", "Sunday 6:00 pm, again on Monday if not sent"),
        ("coach", "Coach updates", "Aman replies or changes your plan"),
        ("progress", "Progress and personal bests", "New bests, streaks and milestones"),
    ]
    TRAINER_KEYS = [
        ("ci", "New check-in", "When a client sends a check-in"),
        ("miss", "Missed workouts", "When a client misses 2 in a row"),
        ("new", "New client", "When the admin gives you a client"),
        ("sess", "Session reminders", "30 minutes before each session"),
        ("sum", "Daily summary", "Email at 8:00 am with your day"),
        ("news", "Gym news", "Notices from Vimal"),
    ]

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notification_settings")
    prefs = models.JSONField(default=dict, blank=True, help_text="{key: on/off}; keys depend on the role")
    quiet_hours_enabled = models.BooleanField(default=True)
    quiet_from = models.TimeField(default=dt.time(22, 0))
    quiet_to = models.TimeField(default=dt.time(7, 0))

    class Meta:
        verbose_name_plural = "notification settings"

    def __str__(self):
        return f"Notification settings · {self.user_id}"

    @classmethod
    def defaults_for(cls, user):
        return default_trainer_prefs() if getattr(user, "role", "") in {"admin", "trainer"} else default_client_prefs()

    @classmethod
    def keys_for(cls, user):
        return cls.TRAINER_KEYS if getattr(user, "role", "") in {"admin", "trainer"} else cls.CLIENT_KEYS

    @classmethod
    def for_user(cls, user):
        obj, _ = cls.objects.get_or_create(user=user, defaults={"prefs": cls.defaults_for(user)})
        return obj

    def wants(self, key):
        return bool({**self.defaults_for(self.user), **(self.prefs or {})}.get(key, True))


# ---------------------------------------------------------------------------
# Activity log
# ---------------------------------------------------------------------------


class ActivityLog(TimeStampedModel):
    """One row of Admin › Activity log, Client More › My activity, Trainer Me › My activity."""

    class Category(models.TextChoices):
        CHECKIN = "checkin", "Check-in"
        PLAN = "plan", "Plan"
        WORKOUT = "workout", "Workout"
        MEAL = "meal", "Meal"
        BODY = "body", "Body"
        CLIENT = "client", "Client"
        CONTENT = "content", "Content"
        SYSTEM = "system", "System"
        HABITS = "habits", "Habits"
        ACCOUNT = "account", "Account"
        GENERAL = "general", "General"

    class ActorRole(models.TextChoices):
        ADMIN = "admin", "Admin"
        TRAINER = "trainer", "Trainer"
        CLIENT = "client", "Client"
        SYSTEM = "system", "Automation"

    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="activity")
    verb = models.CharField(max_length=255, help_text="What happened, after the actor's name: 'changed Kabir Mehta’s program'")
    target = models.CharField(max_length=160, blank=True, help_text="The item changed, e.g. a program or meal name")
    client = models.ForeignKey("people.ClientProfile", on_delete=models.SET_NULL, null=True, blank=True, related_name="activity")
    category = models.CharField(max_length=10, choices=Category.choices, default=Category.GENERAL, db_index=True)
    meta = models.JSONField(default=dict, blank=True, help_text="Extra detail: icon, tone, rows [[label, value]], link, link_label")

    actor_name = models.CharField(max_length=120, blank=True, help_text="Shown name; 'Automation' for system rows")
    actor_role = models.CharField(max_length=10, choices=ActorRole.choices, blank=True, db_index=True)
    note = models.CharField(max_length=255, blank=True, help_text="Grey line under the row")
    old_value = models.CharField(max_length=120, blank=True, help_text="Change: old → new")
    new_value = models.CharField(max_length=120, blank=True)
    source = models.CharField(max_length=60, blank=True, help_text="'Admin · Web', 'Client · Android app', 'Automation · Push and WhatsApp'")
    occurred_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        ordering = ("-occurred_at", "-id")
        indexes = [models.Index(fields=["category", "occurred_at"]), models.Index(fields=["actor", "occurred_at"])]

    def __str__(self):
        return f"{self.display_actor} {self.verb}"

    @property
    def display_actor(self):
        if self.actor_name:
            return self.actor_name
        return self.actor.full_name if self.actor else "Automation"

    def save(self, *args, **kwargs):
        if not self.actor_name and self.actor_id:
            self.actor_name = self.actor.full_name
        if not self.actor_role:
            self.actor_role = getattr(self.actor, "role", "") if self.actor_id else self.ActorRole.SYSTEM
        super().save(*args, **kwargs)


# ---------------------------------------------------------------------------
# Message templates + team alerts (Emails & alerts)
# ---------------------------------------------------------------------------

TEMPLATE_VARIABLES = ["first_name", "coach_name", "gym_name", "package_name", "date"]
SAMPLE_VARIABLES = {"first_name": "Sana", "coach_name": "Meera", "gym_name": "Train With Vimal",
                    "package_name": "Quarterly Transformation", "date": "7 Oct"}
CHANNEL_LIMITS = {"email": (50, 2000), "push": (50, 120), "whatsapp": (0, 1000), "inApp": (50, 2000), "sms": (0, 160)}


class MessageTemplate(TimeStampedModel):
    """A client message ('Check-in reminder') with one text per channel."""

    class Group(models.TextChoices):
        ACCESS = "access", "Access"
        COACHING = "coaching", "Coaching"
        PACKAGES = "packages", "Packages"
        TEAM = "team", "Team"

    key = models.SlugField(max_length=60, unique=True, help_text="Stable id: invite, welcome, checkin-reminder …")
    name = models.CharField(max_length=80)
    group = models.CharField(max_length=10, choices=Group.choices, default=Group.COACHING, db_index=True)
    when_sent = models.CharField(max_length=160, blank=True, help_text="'When a check-in is due or was missed'")
    event_key = models.CharField(max_length=40, blank=True, db_index=True,
                                 help_text="App event that sends it directly (client_invited, client_approved, password_reset …)")
    system_note = models.CharField(max_length=160, blank=True, help_text="'Sent by the app when …' for system templates")
    is_custom = models.BooleanField(default=False, help_text="Made with New template (can be deleted)")
    enabled = models.BooleanField(default=True)
    position = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ("group", "position", "id")

    def __str__(self):
        return self.name

    def text_for(self, channel):
        return self.texts.filter(channel=channel, enabled=True).first()


class TemplateText(TimeStampedModel):
    """Subject/title + body of a template on one channel; `enabled` is the channel toggle."""

    template = models.ForeignKey(MessageTemplate, on_delete=models.CASCADE, related_name="texts")
    channel = models.CharField(max_length=10, choices=Channel.choices)
    subject = models.CharField(max_length=120, blank=True, help_text="Email subject / push title (none for WhatsApp)")
    body = models.TextField()
    enabled = models.BooleanField(default=True)
    default_subject = models.CharField(max_length=120, blank=True, help_text="For 'Reset to default'")
    default_body = models.TextField(blank=True)

    class Meta:
        ordering = ("template", "channel")
        constraints = [models.UniqueConstraint(fields=["template", "channel"], name="uniq_template_channel")]

    def __str__(self):
        return f"{self.template.name} · {self.get_channel_display()}"


class AlertRule(OrderedModel, TimeStampedModel):
    """Team alerts: event → channels; goes to the admin and the assigned trainer."""

    class Recipients(models.TextChoices):
        ADMIN_AND_TRAINER = "admin_trainer", "Admin and assigned trainer"
        ADMIN = "admin", "Admin only"
        TRAINER = "trainer", "Assigned trainer only"

    key = models.SlugField(max_length=40, unique=True, help_text="Event key: new-client, checkin, plan-updated, missed-workout")
    name = models.CharField(max_length=80)
    description = models.CharField(max_length=160, blank=True)
    channels = models.JSONField(default=list, blank=True, help_text="List of channels: email, push, whatsapp, inApp")
    recipients = models.CharField(max_length=15, choices=Recipients.choices, default=Recipients.ADMIN_AND_TRAINER)
    enabled = models.BooleanField(default=True)

    class Meta(OrderedModel.Meta):
        pass

    def __str__(self):
        return self.name


# ---------------------------------------------------------------------------
# Automations
# ---------------------------------------------------------------------------


class Trigger(models.TextChoices):
    CLIENT_APPROVED = "clientApproved", "New client approved"
    PLAN_STARTS = "planStarts", "Plan starts"
    PLAN_ENDS = "planEnds", "Plan ends"
    RENEWAL_DUE = "renewalDue", "Package ending"
    BIRTHDAY = "birthday", "Client birthday"
    WEEKLY = "weeklyCheckInDay", "Every week"
    DAILY = "daily", "Every day"
    ON_DATE = "onDate", "On a date"
    CHECKIN_MISSED = "checkInMissed", "Missed check-in"
    WORKOUTS_MISSED = "workoutsMissed", "Missed workouts"
    INACTIVE = "inactive", "No app activity"
    FORM_SUBMITTED = "formSubmitted", "Form sent in"
    STREAK = "streak", "Workout streak"
    GOAL_REACHED = "goalReached", "Goal weight reached"
    WEIGHT_STUCK = "weightStuck", "Weight not changing"


TRIGGER_INFO = {
    # key: (group, description, note, number setting (label, unit, min, max, step) or None)
    "clientApproved": ("Client", "As soon as they are approved.", "Runs once for each client.", None),
    "planStarts": ("Client", "A program or meal plan starts.", "Runs on the start date of the plan, at 9 am.", None),
    "planEnds": ("Client", "Before a plan ends.", "", ("Days before the end", "days", 0, 14, 1)),
    "renewalDue": ("Client", "Before a package ends.", "", ("Days before the end", "days", 1, 30, 1)),
    "birthday": ("Client", "On the client’s birthday.", "", None),
    "weeklyCheckInDay": ("Schedule", "Same day and time each week.", "", None),
    "daily": ("Schedule", "Same time every day.", "", None),
    "onDate": ("Schedule", "Once, on a date you pick.", "", None),
    "checkInMissed": ("Activity", "A check-in is late.", "Counts from the time the check-in was due.", ("Not sent within", "hours", 6, 72, 6)),
    "workoutsMissed": ("Activity", "Workouts missed in a row.", "", ("Missed in a row", "workouts", 1, 10, 1)),
    "inactive": ("Activity", "The app is not opened.", "Opening the app, logging a meal or a workout all count as activity.", ("No activity for", "days", 2, 30, 1)),
    "formSubmitted": ("Activity", "A client sends a form.", "", None),
    "streak": ("Activity", "Workouts done days in a row.", "Starts once per streak, on the day it is reached.", ("Days in a row", "days", 3, 60, 1)),
    "goalReached": ("Progress", "Weight reaches the goal.", "Uses the goal weight in each client’s profile.", None),
    "weightStuck": ("Progress", "Weight stays the same.", "", ("Same weight for", "weeks", 1, 8, 1)),
}

# Default settings block per trigger (builder): n = number, time = "HH:MM", weekday 1–7, date, plan any/prog/meal, form key.
TRIGGER_DEFAULTS = {
    "clientApproved": {}, "planStarts": {"plan": "any"}, "planEnds": {"n": 3, "time": "09:00"},
    "renewalDue": {"n": 7, "time": "09:00"}, "birthday": {"time": "08:00"}, "weeklyCheckInDay": {"weekday": 7, "time": "09:00"},
    "daily": {"time": "07:00"}, "onDate": {"date": "2026-10-15", "time": "10:00"}, "checkInMissed": {"n": 24},
    "workoutsMissed": {"n": 3}, "inactive": {"n": 5}, "formSubmitted": {"form": "f-parq"}, "streak": {"n": 7},
    "goalReached": {}, "weightStuck": {"n": 3},
}


class Automation(TimeStampedModel):
    class Status(models.TextChoices):
        ON = "on", "On"
        OFF = "off", "Off"
        DRAFT = "draft", "Draft"

    key = models.SlugField(max_length=60, unique=True, help_text="Stable id, e.g. a-onboarding")
    name = models.CharField(max_length=120)
    trigger = models.CharField(max_length=20, choices=Trigger.choices, blank=True, help_text="Empty while a new draft has none")
    trigger_value = models.IntegerField(default=0, help_text="Weekday 1–7 for weekly; hours / days / workouts / weeks for the others")
    trigger_config = models.JSONField(default=dict, blank=True,
                                      help_text="Trigger settings block: {n, time 'HH:MM', weekday, date, plan, form}")
    conditions = models.JSONField(default=list, blank=True, help_text="Extra audience filters: [{field, op, value}]")
    status = models.CharField(max_length=5, choices=Status.choices, default=Status.DRAFT, db_index=True)
    package = models.CharField(max_length=80, blank=True, help_text="Audience: clients on this package ('' = any package)")
    trainer = models.ForeignKey("people.TrainerProfile", on_delete=models.SET_NULL, null=True, blank=True, related_name="automations",
                                help_text="Audience: clients of this trainer (empty = any trainer)")
    stop_on_reply = models.BooleanField(default=True, help_text="Skip remaining steps once the client sends the form or replies")
    edited_at = models.DateTimeField(default=timezone.now, help_text="'Changed 20 Sep' in the list")
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    last_evaluated_at = models.DateTimeField(null=True, blank=True)

    # Counters shown on cards and the builder's "Last 30 days" box (kept by the engine; seeded from the design).
    running_count = models.PositiveIntegerField(default=0, help_text="Clients waiting for their next step")
    finished_count = models.PositiveIntegerField(default=0)
    started_30d = models.PositiveIntegerField(default=0)
    finished_30d = models.PositiveIntegerField(default=0)
    stopped_30d = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ("created_at", "id")

    def __str__(self):
        return self.name

    def problems(self):
        """Why it cannot be turned on (builder 'Not ready to turn on')."""
        steps = list(self.steps.all())
        out = []
        if not self.trigger:
            out.append("Pick what starts it")
        if not steps:
            out.append("Add at least one step")
        if steps and steps[-1].kind == AutomationStep.Kind.WAIT:
            out.append("Add a step that does something after the wait")
        for i, s in enumerate(steps, 1):
            if s.kind in (AutomationStep.Kind.MESSAGE, AutomationStep.Kind.FORM) and not s.channels:
                out.append(f"Step {i}: pick at least one channel")
        return out


class AutomationStep(OrderedModel):
    class Kind(models.TextChoices):
        WAIT = "wait", "Wait"
        MESSAGE = "message", "Send message"
        FORM = "form", "Send form"
        ASSIGN = "assign", "Assign task"

    class WaitUnit(models.TextChoices):
        HOURS = "hours", "Hours"
        DAYS = "days", "Days"

    class TaskFor(models.TextChoices):
        TRAINER = "trainer", "Assigned trainer"
        OWNER = "owner", "Owner"

    automation = models.ForeignKey(Automation, on_delete=models.CASCADE, related_name="steps")
    kind = models.CharField(max_length=8, choices=Kind.choices)
    wait_amount = models.PositiveIntegerField(default=0)
    wait_unit = models.CharField(max_length=5, choices=WaitUnit.choices, blank=True)
    template = models.ForeignKey(MessageTemplate, on_delete=models.PROTECT, null=True, blank=True, related_name="automation_steps")
    form_key = models.CharField(max_length=60, blank=True, help_text="Form id from Forms & check-ins (f-onboarding, f-weekly …)")
    channels = models.JSONField(default=list, blank=True, help_text="email, push, whatsapp, inApp")
    task_text = models.CharField(max_length=200, blank=True)
    task_for = models.CharField(max_length=7, choices=TaskFor.choices, blank=True)

    class Meta(OrderedModel.Meta):
        pass

    def __str__(self):
        return f"{self.automation.name} · step {self.position + 1} · {self.kind}"

    @property
    def wait_delta(self):
        return dt.timedelta(hours=self.wait_amount) if self.wait_unit == "hours" else dt.timedelta(days=self.wait_amount)


class AutomationStarter(OrderedModel, TimeStampedModel):
    """Ready-made recipe in 'New automation'. Steps are stored as JSON in the same shape as the API."""

    key = models.SlugField(max_length=60, unique=True)
    name = models.CharField(max_length=120)
    trigger = models.CharField(max_length=20, choices=Trigger.choices)
    trigger_value = models.IntegerField(default=0)
    trigger_config = models.JSONField(default=dict, blank=True)
    steps = models.JSONField(default=list, help_text="[{kind, wait_amount, wait_unit, template, form_key, channels, task_text, task_for}]")
    note = models.CharField(max_length=200, blank=True)

    class Meta(OrderedModel.Meta):
        pass

    def __str__(self):
        return self.name


class AutomationRun(TimeStampedModel):
    """One client going through one automation (builder 'Last 30 days' log)."""

    class Status(models.TextChoices):
        RUNNING = "running", "Waiting"
        FINISHED = "finished", "Finished"
        STOPPED = "stopped", "Stopped early"
        FAILED = "failed", "Failed"

    automation = models.ForeignKey(Automation, on_delete=models.CASCADE, related_name="runs")
    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="automation_runs")
    trigger_key = models.CharField(max_length=60, blank=True, help_text="Dedupe key, e.g. the date a weekly trigger fired")
    status = models.CharField(max_length=8, choices=Status.choices, default=Status.RUNNING, db_index=True)
    current_step = models.PositiveIntegerField(default=0, help_text="Index of the next step to run")
    next_step_at = models.DateTimeField(null=True, blank=True, db_index=True)
    status_text = models.CharField(max_length=120, blank=True, help_text="'Waiting · step 2 of 5', 'Sent the form · stopped at step 1'")
    started_at = models.DateTimeField(default=timezone.now, db_index=True)
    finished_at = models.DateTimeField(null=True, blank=True)
    is_test = models.BooleanField(default=False)

    class Meta:
        ordering = ("-started_at", "-id")
        constraints = [models.UniqueConstraint(fields=["automation", "client", "trigger_key"], name="uniq_run_per_trigger")]

    def __str__(self):
        return f"{self.automation.name} · {self.client}"


class MessageLog(TimeStampedModel):
    """Every message the app sent (stats: 'Messages this month 214 · 96% delivered · 61% opened')."""

    class Status(models.TextChoices):
        QUEUED = "queued", "Queued"
        SENT = "sent", "Sent"
        DELIVERED = "delivered", "Delivered"
        OPENED = "opened", "Opened"
        FAILED = "failed", "Failed"

    automation = models.ForeignKey(Automation, on_delete=models.SET_NULL, null=True, blank=True, related_name="messages")
    run = models.ForeignKey(AutomationRun, on_delete=models.SET_NULL, null=True, blank=True, related_name="messages")
    template = models.ForeignKey(MessageTemplate, on_delete=models.SET_NULL, null=True, blank=True, related_name="messages")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    client = models.ForeignKey("people.ClientProfile", on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    channel = models.CharField(max_length=10, choices=Channel.choices)
    subject = models.CharField(max_length=160, blank=True)
    body = models.TextField(blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.QUEUED, db_index=True)
    sent_at = models.DateTimeField(default=timezone.now, db_index=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    opened_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("-sent_at", "-id")

    def __str__(self):
        return f"{self.channel} → {self.user_id} ({self.status})"


class TrainerTask(TimeStampedModel):
    """To-do made by an 'Assign task' step (Trainer dashboard › Tasks; 'Tasks for trainers 9 · 4 still open')."""

    automation = models.ForeignKey(Automation, on_delete=models.SET_NULL, null=True, blank=True, related_name="tasks")
    run = models.ForeignKey(AutomationRun, on_delete=models.SET_NULL, null=True, blank=True, related_name="tasks")
    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, null=True, blank=True, related_name="trainer_tasks")
    assignee = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="tasks")
    title = models.CharField(max_length=200)
    due_at = models.DateTimeField(null=True, blank=True)
    done_at = models.DateTimeField(null=True, blank=True, db_index=True)

    class Meta:
        ordering = ("done_at", "-created_at")

    def __str__(self):
        return self.title


# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------


class WorkspaceSettings(TimeStampedModel):
    """Singleton (pk=1): Settings › General / Branding, Emails & alerts › Sender + Team alerts side cards."""

    class Units(models.TextChoices):
        METRIC = "metric", "Metric · kg, cm"
        IMPERIAL = "imperial", "Imperial · lb, in"

    class WeekStart(models.TextChoices):
        MONDAY = "monday", "Monday"
        SUNDAY = "sunday", "Sunday"

    class Theme(models.TextChoices):
        LIGHT = "light", "Light"
        DARK = "dark", "Dark"
        SYSTEM = "system", "Match phone"

    class Digest(models.TextChoices):
        OFF = "off", "Off"
        DAILY = "daily", "Daily"
        WEEKLY = "weekly", "Weekly"

    # General · Gym profile
    business_name = models.CharField(max_length=120, default="Train With Vimal")
    contact_email = models.EmailField(default="hello@trainwithvimal.com")
    phone = models.CharField(max_length=30, blank=True, help_text="Phone / WhatsApp")
    address = models.CharField(max_length=255, blank=True)
    website = models.CharField(max_length=160, blank=True, help_text="Website / Instagram")
    general_saved_at = models.DateTimeField(null=True, blank=True, help_text="'Last saved 2 Oct'")
    # General · Regional & defaults
    units = models.CharField(max_length=8, choices=Units.choices, default=Units.METRIC)
    week_start = models.CharField(max_length=6, choices=WeekStart.choices, default=WeekStart.MONDAY)
    timezone = models.CharField(max_length=40, default="Asia/Kolkata")
    language = models.CharField(max_length=10, default="en")
    currency = models.CharField(max_length=3, default="INR")
    default_checkin_day = models.PositiveSmallIntegerField(default=7, help_text="1 = Monday … 7 = Sunday")
    default_checkin_time = models.TimeField(default=dt.time(18, 0))
    # Branding
    logo = models.ImageField(upload_to="branding/", blank=True)
    logo_url = models.URLField(blank=True)
    brand_color = models.CharField(max_length=7, default="#2563EB")
    brand_swatches = models.JSONField(default=list, blank=True)
    theme = models.CharField(max_length=6, choices=Theme.choices, default=Theme.LIGHT)
    branding_applied_at = models.DateTimeField(null=True, blank=True)
    # Emails & alerts · Sender
    sender_name = models.CharField(max_length=120, default="Train With Vimal")
    reply_to_email = models.EmailField(default="hello@trainwithvimal.com")
    whatsapp_number = models.CharField(max_length=30, blank=True)
    # Emails & alerts · Team alerts side cards
    quiet_hours_enabled = models.BooleanField(default=True, help_text="No push or WhatsApp at night. Emails wait in a queue.")
    quiet_from = models.TimeField(default=dt.time(22, 0))
    quiet_to = models.TimeField(default=dt.time(7, 0))
    digest = models.CharField(max_length=6, choices=Digest.choices, default=Digest.DAILY)
    digest_time = models.TimeField(default=dt.time(8, 0))
    # Integrations · Health data the client app may read
    health_data = models.JSONField(default=dict, blank=True, help_text="{steps, sleep, hr, wo}: on/off")

    class Meta:
        verbose_name = verbose_name_plural = "workspace settings"

    def __str__(self):
        return self.business_name

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj

    def in_quiet_hours(self, when=None):
        if not self.quiet_hours_enabled:
            return False
        t = timezone.localtime(when or timezone.now()).time()
        a, b = self.quiet_from, self.quiet_to
        return (a <= t or t < b) if a > b else (a <= t < b)

    def quiet_hours_end(self, when=None):
        now = timezone.localtime(when or timezone.now())
        end = now.replace(hour=self.quiet_to.hour, minute=self.quiet_to.minute, second=0, microsecond=0)
        return end if end > now else end + dt.timedelta(days=1)


class RolePermission(OrderedModel, TimeStampedModel):
    """Settings › Roles & access matrix. Admin always has everything (locked)."""

    key = models.SlugField(max_length=40, unique=True)
    name = models.CharField(max_length=80)
    trainer = models.BooleanField(default=False)
    client = models.BooleanField(default=False)
    default_trainer = models.BooleanField(default=False)
    default_client = models.BooleanField(default=False)

    class Meta(OrderedModel.Meta):
        pass

    def __str__(self):
        return self.name


class Integration(OrderedModel, TimeStampedModel):
    class Status(models.TextChoices):
        ON = "on", "Connected"
        DNS = "dns", "Checking DNS"
        OFF = "off", "Not connected"

    key = models.SlugField(max_length=20, unique=True, help_text="whatsapp, email, health")
    name = models.CharField(max_length=80)
    short = models.CharField(max_length=4)
    description = models.CharField(max_length=200, blank=True)
    status = models.CharField(max_length=3, choices=Status.choices, default=Status.OFF)
    account = models.CharField(max_length=120, blank=True, help_text="Business number / sending domain / linked count")
    from_address = models.CharField(max_length=120, blank=True, help_text="Email: address emails come from once verified")
    linked_count = models.PositiveIntegerField(default=0, help_text="Health: clients linked")
    uses = models.JSONField(default=list, blank=True, help_text="'Used in' chips: [{label, target}]")
    setup_steps = models.JSONField(default=list, blank=True, help_text="[{title, help}]")
    bg = models.CharField(max_length=7, blank=True)
    fg = models.CharField(max_length=7, blank=True)
    connected_at = models.DateTimeField(null=True, blank=True)

    class Meta(OrderedModel.Meta):
        pass

    def __str__(self):
        return self.name


class DnsRecord(OrderedModel):
    integration = models.ForeignKey(Integration, on_delete=models.CASCADE, related_name="dns_records")
    record = models.CharField(max_length=10, help_text="SPF, DKIM, DMARC")
    record_type = models.CharField(max_length=6, default="TXT")
    host = models.CharField(max_length=80)
    value = models.CharField(max_length=255, blank=True)
    verified = models.BooleanField(default=False)
    checked_at = models.DateTimeField(null=True, blank=True)

    class Meta(OrderedModel.Meta):
        pass

    def __str__(self):
        return f"{self.record} {self.host}"
