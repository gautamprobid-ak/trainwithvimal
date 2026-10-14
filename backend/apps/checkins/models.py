"""Forms, check-ins and body progress.

Screens: Admin · Forms & check-ins / Form builder, Trainer · Check-ins,
Client · Check-ins / Progress, the Check-ins, Logs, Progress and Forms tabs of
the client profile (admin + trainer).

- Form + Question: master forms built in the form builder. A client copy
  ("Weekly check-in · edited for Riya") is a Form with `parent` = master and
  `client` = that client.
- CheckinSchedule: when a form (or a measurement / photo reminder) goes to a client.
- CheckinSubmission + Answer + CheckinReply + CheckinPhoto: one filled (or due /
  missed) check-in, its answers, the coach's reply and its photos.
- BodyWeight / BodyMeasurement / ProgressPhotoSet / BodyGoal: the progress screen.
"""
from django.conf import settings
from django.db import models

from apps.core.models import OrderedModel, TimeStampedModel


# ---------------------------------------------------------------- choices
class FormKind(models.TextChoices):
    ONBOARDING = "onboarding", "Onboarding questionnaire"
    WEEKLY = "weekly", "Weekly check-in"
    DAILY = "daily", "Daily check-in"
    PROGRESS = "progress", "Monthly progress"
    SURVEY = "survey", "Survey / feedback"
    WAIVER = "waiver", "Waiver / consent"
    CUSTOM = "custom", "Custom"


class QuestionType(models.TextChoices):
    SHORT_TEXT = "short_text", "Short answer"
    LONG_TEXT = "long_text", "Long answer"
    NUMBER = "number", "Number"
    SINGLE_CHOICE = "single_choice", "Single choice"
    MULTI_CHOICE = "multi_choice", "Multiple choice"
    DROPDOWN = "dropdown", "Dropdown"
    SCALE = "scale", "Scale"
    YES_NO = "yes_no", "Yes / No"
    PHOTO = "photo", "Photo upload"
    MEASUREMENT = "measurement", "Body measurement"


CHOICE_TYPES = {QuestionType.SINGLE_CHOICE, QuestionType.MULTI_CHOICE, QuestionType.DROPDOWN}


class Metric(models.TextChoices):
    """What a question feeds into (weight chart, measurements, trainer trend rows)."""

    NONE = "", "—"
    WEIGHT = "weight", "Body weight (kg)"
    WAIST = "waist", "Waist (cm)"
    HIPS = "hips", "Hips (cm)"
    CHEST = "chest", "Chest (cm)"
    ARM = "arm", "Arm (cm)"
    THIGH = "thigh", "Thigh (cm)"
    NECK = "neck", "Neck (cm)"
    BODY_FAT = "body_fat", "Body fat (%)"
    SLEEP = "sleep", "Sleep (h)"
    ENERGY = "energy", "Energy"
    MOOD = "mood", "Mood"
    HUNGER = "hunger", "Hunger"
    SORENESS = "soreness", "Soreness"
    STRESS = "stress", "Stress"
    STEPS = "steps", "Steps"
    WATER = "water", "Water (L)"
    WEEK = "week", "How the week went"
    DIET = "diet", "Diet / meal plan adherence"
    PAIN = "pain", "Pain / injury"
    PHOTOS = "photos", "Progress photos"
    NOTE = "note", "Note for the coach"


MEASUREMENT_METRICS = {
    Metric.WAIST: "waist_cm",
    Metric.HIPS: "hips_cm",
    Metric.CHEST: "chest_cm",
    Metric.ARM: "arm_cm",
    Metric.THIGH: "thigh_cm",
    Metric.NECK: "neck_cm",
    Metric.BODY_FAT: "body_fat_pct",
}


class Frequency(models.TextChoices):
    ONCE = "once", "Once"
    DAILY = "daily", "Every day"
    WEEKLY = "weekly", "Every week"
    BIWEEKLY = "biweekly", "Every 2 weeks"
    MONTHLY = "monthly", "Every month"


class Pose(models.TextChoices):
    FRONT = "front", "Front"
    SIDE = "side", "Side"
    BACK = "back", "Back"
    FLEX = "flex", "Flex"
    OTHER = "other", "Other"


def default_channels():
    return ["push"]


# ---------------------------------------------------------------- forms
class Form(TimeStampedModel):
    class Audience(models.TextChoices):
        ALL = "all", "All clients"
        ASSIGNED = "assigned", "Assigned clients"

    name = models.CharField(max_length=120)
    kind = models.CharField(max_length=12, choices=FormKind.choices, default=FormKind.CUSTOM, db_index=True)
    description = models.CharField(max_length=255, blank=True)
    is_published = models.BooleanField(default=False, db_index=True)
    published_at = models.DateTimeField(null=True, blank=True)
    is_archived = models.BooleanField(default=False, db_index=True)
    archived_at = models.DateTimeField(null=True, blank=True)
    is_template = models.BooleanField(default=False, help_text="Starter questions for “Create form · Template”")
    audience = models.CharField(max_length=10, choices=Audience.choices, default=Audience.ASSIGNED)

    # Default schedule (copied to CheckinSchedule when the form is assigned)
    frequency = models.CharField(max_length=10, choices=Frequency.choices, default=Frequency.ONCE)
    weekday = models.PositiveSmallIntegerField(null=True, blank=True, help_text="0 = Monday … 6 = Sunday")
    day_of_month = models.PositiveSmallIntegerField(null=True, blank=True)
    send_time = models.TimeField(null=True, blank=True)
    channels = models.JSONField(default=default_channels, blank=True, help_text='e.g. ["push", "whatsapp", "email"]')

    # Client copy of a master form ("edited for Riya")
    parent = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="copies")
    client = models.ForeignKey(
        "people.ClientProfile", on_delete=models.CASCADE, null=True, blank=True, related_name="custom_forms",
        help_text="Set when this is one client's edited copy of a master form",
    )
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    updated_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ("-updated_at",)
        indexes = [models.Index(fields=["kind", "is_archived"])]

    def __str__(self):
        return f"{self.name} · {self.client}" if self.client_id else self.name

    @property
    def status(self):
        if self.is_archived:
            return "archived"
        return "published" if self.is_published else "draft"


class Question(OrderedModel, TimeStampedModel):
    form = models.ForeignKey(Form, on_delete=models.CASCADE, related_name="questions")
    text = models.CharField(max_length=255)
    help_text = models.CharField(max_length=255, blank=True, help_text="Grey hint under the question")
    type = models.CharField(max_length=14, choices=QuestionType.choices, default=QuestionType.SHORT_TEXT)
    required = models.BooleanField(default=False)
    options = models.JSONField(default=list, blank=True, help_text="Choices for single / multi / dropdown")
    allow_other = models.BooleanField(default=False, help_text="Adds an “Other” option the client can type into")
    scale_min = models.PositiveSmallIntegerField(default=1)
    scale_max = models.PositiveSmallIntegerField(default=5)
    scale_labels = models.JSONField(default=list, blank=True, help_text='One label per step, e.g. ["Very hard", …, "Great"]')
    unit = models.CharField(max_length=10, blank=True, help_text="kg, cm, h, L …")
    metric = models.CharField(max_length=10, choices=Metric.choices, blank=True, default="")
    poses = models.JSONField(default=list, blank=True, help_text='Photo questions: ["front", "side", "back"]')
    source_question = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="+",
                                        help_text="Master question this client-copy question came from")
    change_note = models.CharField(max_length=120, blank=True, help_text="Client copy: “Added for Riya”, “Was: required”")
    added_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+",
                                 help_text="Shown to the client as “Added for you by Aman”")

    class Meta(OrderedModel.Meta):
        ordering = ("form", "position", "id")

    def __str__(self):
        return self.text


class CheckinSchedule(TimeStampedModel):
    """A form (or a measurement / photo reminder) sent to one client on a schedule."""

    class Purpose(models.TextChoices):
        FORM = "form", "Form"
        MEASUREMENTS = "measurements", "Measurements"
        PHOTOS = "photos", "Progress photos"

    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="checkin_schedules")
    form = models.ForeignKey(Form, on_delete=models.CASCADE, null=True, blank=True, related_name="schedules")
    purpose = models.CharField(max_length=12, choices=Purpose.choices, default=Purpose.FORM)
    label = models.CharField(max_length=80, blank=True, help_text="e.g. Weekly check-in, Measurements")
    frequency = models.CharField(max_length=10, choices=Frequency.choices, default=Frequency.WEEKLY)
    weekday = models.PositiveSmallIntegerField(null=True, blank=True, help_text="0 = Monday … 6 = Sunday")
    day_of_month = models.PositiveSmallIntegerField(null=True, blank=True)
    send_time = models.TimeField(null=True, blank=True)
    channels = models.JSONField(default=default_channels, blank=True)
    starts_on = models.DateField(null=True, blank=True)
    ends_on = models.DateField(null=True, blank=True)
    next_due_at = models.DateTimeField(null=True, blank=True, db_index=True)
    active = models.BooleanField(default=True)
    assigned_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ("client", "purpose", "id")

    def __str__(self):
        return f"{self.label or self.form} → {self.client}"


# ---------------------------------------------------------------- submissions
class CheckinSubmission(TimeStampedModel):
    class Status(models.TextChoices):
        DUE = "due", "Due"
        DRAFT = "draft", "Draft"
        SUBMITTED = "submitted", "Sent · to review"
        REVIEWED = "reviewed", "Reviewed"
        OVERDUE = "overdue", "Overdue"
        MISSED = "missed", "Missed"

    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="checkins")
    form = models.ForeignKey(Form, on_delete=models.PROTECT, related_name="submissions")
    schedule = models.ForeignKey(CheckinSchedule, on_delete=models.SET_NULL, null=True, blank=True, related_name="submissions")
    kind = models.CharField(max_length=12, choices=FormKind.choices, db_index=True, help_text="Copied from the form")
    title = models.CharField(max_length=80, blank=True, help_text="e.g. Week 6")
    period_number = models.PositiveIntegerField(null=True, blank=True, help_text="Week number of the program")
    plan_label = models.CharField(max_length=120, blank=True, help_text="e.g. Fat Loss Phase 1 · week 6")
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.DUE, db_index=True)
    due_at = models.DateTimeField(null=True, blank=True, db_index=True)
    submitted_at = models.DateTimeField(null=True, blank=True, db_index=True)
    reminder_sent_at = models.DateTimeField(null=True, blank=True)
    reviewed_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="reviewed_checkins")
    reviewed_at = models.DateTimeField(null=True, blank=True)

    # Snapshot shown on the cards (KPIs) — filled from answers and other logs at submit time
    weight_kg = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    weight_change_kg = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
    weight_change_label = models.CharField(max_length=20, blank=True, help_text="Change / In 2 weeks")
    workouts_done = models.PositiveSmallIntegerField(null=True, blank=True)
    workouts_planned = models.PositiveSmallIntegerField(null=True, blank=True)
    workout_label = models.CharField(max_length=40, blank=True, help_text="Daily: e.g. Rest day")
    meals_on_plan_pct = models.PositiveSmallIntegerField(null=True, blank=True)
    sleep_hours = models.DecimalField(max_digits=3, decimal_places=1, null=True, blank=True)
    steps = models.PositiveIntegerField(null=True, blank=True)
    water_ml = models.PositiveIntegerField(null=True, blank=True)
    note = models.TextField(blank=True, help_text="The client's note for the coach")
    summary = models.CharField(max_length=160, blank=True, help_text="One-line queue summary, e.g. “Weight 74.2 kg · bench up 2.5 kg”")
    signature_name = models.CharField(max_length=120, blank=True, help_text="Waivers: typed name as signature")
    signed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("-due_at", "-submitted_at", "-id")
        indexes = [models.Index(fields=["client", "kind", "status"]), models.Index(fields=["status", "submitted_at"])]

    def __str__(self):
        return f"{self.client} · {self.title or self.form.name} · {self.status}"

    def save(self, *args, **kwargs):
        if not self.kind and self.form_id:
            self.kind = self.form.kind
        super().save(*args, **kwargs)

    @property
    def photo_count(self):
        return self.photos.count()


class Answer(OrderedModel):
    submission = models.ForeignKey(CheckinSubmission, on_delete=models.CASCADE, related_name="answers")
    question = models.ForeignKey(Question, on_delete=models.SET_NULL, null=True, blank=True, related_name="answers")
    label = models.CharField(max_length=255, help_text="Question text when answered (or a metric name like Energy)")
    metric = models.CharField(max_length=10, choices=Metric.choices, blank=True, default="")
    value = models.JSONField(null=True, blank=True, help_text="Raw value: number, text, list of options, true/false")
    number = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, help_text="Numeric value for charts")
    text = models.CharField(max_length=500, blank=True, help_text="Display text, e.g. “4 / 5 · Good”")
    previous_text = models.CharField(max_length=60, blank=True, help_text="Last time's value for the trainer view")
    trend = models.CharField(max_length=4, blank=True, choices=[("up", "Better"), ("down", "Worse"), ("same", "Same")])

    class Meta(OrderedModel.Meta):
        ordering = ("submission", "position", "id")

    def __str__(self):
        return f"{self.label}: {self.text}"


class CheckinReply(TimeStampedModel):
    submission = models.ForeignKey(CheckinSubmission, on_delete=models.CASCADE, related_name="replies")
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="checkin_replies")
    text = models.TextField(blank=True)
    voice_note = models.FileField(upload_to="checkins/voice/", blank=True)
    voice_note_url = models.URLField(blank=True, help_text="Firebase Storage URL when used")
    voice_seconds = models.PositiveSmallIntegerField(null=True, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("sent_at", "id")

    def __str__(self):
        return f"Reply by {self.author} · {self.text[:40]}"


class QuickReply(OrderedModel, TimeStampedModel):
    """Canned replies under the reply box (“Great week, keep going!”). owner = None → for everyone."""

    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True, related_name="quick_replies")
    text = models.CharField(max_length=200)

    class Meta(OrderedModel.Meta):
        pass

    def __str__(self):
        return self.text


# ---------------------------------------------------------------- body progress
class ProgressPhotoSet(TimeStampedModel):
    class Source(models.TextChoices):
        ONBOARDING = "onboarding", "Start photos"
        CHECKIN = "checkin", "Check-in"
        MANUAL = "manual", "Added by the client"
        COACH = "coach", "Added by the coach"

    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="photo_sets")
    date = models.DateField(db_index=True)
    weight_kg = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    label = models.CharField(max_length=80, blank=True, help_text="e.g. Week 4 check-in")
    source = models.CharField(max_length=10, choices=Source.choices, default=Source.MANUAL)
    submission = models.OneToOneField(CheckinSubmission, on_delete=models.SET_NULL, null=True, blank=True, related_name="photo_set")
    cover_tone = models.CharField(max_length=4, blank=True, help_text="Placeholder tint t1–t4 until a real photo exists")

    class Meta:
        ordering = ("client", "date")
        constraints = [models.UniqueConstraint(fields=["client", "date"], name="uniq_photoset_client_date")]

    def __str__(self):
        return f"{self.client} · {self.date} · {self.label}"


class CheckinPhoto(TimeStampedModel):
    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="progress_photos")
    submission = models.ForeignKey(CheckinSubmission, on_delete=models.SET_NULL, null=True, blank=True, related_name="photos")
    photo_set = models.ForeignKey(ProgressPhotoSet, on_delete=models.CASCADE, null=True, blank=True, related_name="photos")
    pose = models.CharField(max_length=6, choices=Pose.choices, default=Pose.FRONT)
    image = models.ImageField(upload_to="checkins/photos/%Y/%m/", blank=True)
    image_url = models.URLField(blank=True, help_text="Firebase Storage URL when used")
    file_name = models.CharField(max_length=120, blank=True, help_text="Original file name, e.g. IMG_2041.jpg")
    taken_on = models.DateField(null=True, blank=True)
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ("client", "taken_on", "pose")

    def __str__(self):
        return f"{self.client} · {self.pose} · {self.taken_on}"

    @property
    def url(self):
        if self.image:
            try:
                return self.image.url
            except ValueError:
                return ""
        return self.image_url


class BodyWeight(TimeStampedModel):
    class Source(models.TextChoices):
        MANUAL = "manual", "Logged by the client"
        DAILY = "daily", "Daily check-in"
        WEEKLY = "weekly", "Weekly check-in"
        ONBOARDING = "onboarding", "Onboarding"
        COACH = "coach", "Logged by the coach"
        DEVICE = "device", "Health app / scale"

    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="weights")
    date = models.DateField(db_index=True)
    weight_kg = models.DecimalField(max_digits=5, decimal_places=1)
    source = models.CharField(max_length=10, choices=Source.choices, default=Source.MANUAL)
    submission = models.ForeignKey(CheckinSubmission, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    logged_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    note = models.CharField(max_length=200, blank=True)

    class Meta:
        ordering = ("client", "date")
        constraints = [models.UniqueConstraint(fields=["client", "date"], name="uniq_weight_client_date")]

    def __str__(self):
        return f"{self.client} · {self.date} · {self.weight_kg} kg"


class BodyMeasurement(TimeStampedModel):
    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="measurements")
    date = models.DateField(db_index=True)
    waist_cm = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    hips_cm = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    chest_cm = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    arm_cm = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    thigh_cm = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    neck_cm = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    body_fat_pct = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
    submission = models.ForeignKey(CheckinSubmission, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    measured_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    note = models.CharField(max_length=200, blank=True)

    FIELDS = ("waist_cm", "hips_cm", "chest_cm", "arm_cm", "thigh_cm", "neck_cm", "body_fat_pct")

    class Meta:
        ordering = ("client", "date")
        constraints = [models.UniqueConstraint(fields=["client", "date"], name="uniq_measure_client_date")]

    def __str__(self):
        return f"{self.client} · {self.date}"


class BodyGoal(TimeStampedModel):
    """Start → now → goal card on the progress screen."""

    client = models.OneToOneField("people.ClientProfile", on_delete=models.CASCADE, related_name="body_goal")
    start_date = models.DateField(null=True, blank=True)
    start_weight_kg = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    goal_weight_kg = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    goal_date = models.DateField(null=True, blank=True, help_text="Target date, e.g. Feb 2027")
    goal_label = models.CharField(max_length=60, blank=True, help_text="e.g. Feb 2027")
    height_cm = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)

    def __str__(self):
        return f"{self.client}: {self.start_weight_kg} → {self.goal_weight_kg} kg"
