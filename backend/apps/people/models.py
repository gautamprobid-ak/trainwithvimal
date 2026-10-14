"""Coaches and clients.

Screens: Admin · Trainers / Trainer profile, Admin · Clients / Client profile (header, overview, notes,
history), Admin · Approvals, Trainer · My clients / Client profile / My profile (Me), Client · Welcome
(onboarding answers), Health & injuries, More (profile, reminders, units, privacy).
Other apps hang client data off ClientProfile (FK `client`).
"""
from django.conf import settings
from django.db import models
from django.utils import timezone

from apps.core.models import TimeStampedModel

WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


# ─────────────────────────────────────────────────────────────── trainers


def default_permissions():
    """Access and permissions screen — key: on/off. Same as the design's 'Assigned clients' level."""
    return {
        "clients.view_assigned": True,
        "clients.view_all": False,
        "clients.approve_signups": False,
        "clients.pause_resume": False,
        "training.edit_programs": True,
        "training.use_templates": True,
        "training.edit_templates": False,
        "training.custom_exercises": True,
        "nutrition.meal_plans": True,
        "nutrition.add_foods": True,
        "nutrition.supplements": True,
        "nutrition.see_food_logs": True,
        "checkins.review_daily": True,
        "checkins.review_weekly": True,
        "checkins.edit_forms": False,
        "checkins.photos": True,
        "schedule.own_calendar": True,
        "schedule.book_sessions": True,
    }


def default_client_view():
    """'What clients see' toggles on the trainer's public card."""
    return {"name": True, "spec": True, "exp": True, "about": True, "lang": True, "certs": True, "soc": True, "mob": False, "mail": False}


def default_trainer_notifications():
    """Trainer · Me · Account notification toggles."""
    return {"ci": True, "miss": True, "new": True, "sess": True, "sum": False, "news": True}


class TrainerProfile(TimeStampedModel):
    class Access(models.TextChoices):
        ASSIGNED = "assigned", "Assigned clients"
        ALL = "all", "All clients"
        CUSTOM = "custom", "Custom"

    class Gender(models.TextChoices):
        MALE = "male", "Male"
        FEMALE = "female", "Female"
        OTHER = "other", "Other"

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="trainer_profile")
    title = models.CharField(max_length=60, blank=True, help_text="e.g. Head coach")
    focus = models.CharField(max_length=160, blank=True, help_text="e.g. Strength, fat loss")
    bio = models.TextField(blank=True)
    capacity = models.PositiveIntegerField(default=30, help_text="Max clients")
    access = models.CharField(max_length=10, choices=Access.choices, default=Access.ASSIGNED)
    custom_clients = models.ManyToManyField("people.ClientProfile", blank=True, related_name="+", help_text="When access is custom")
    is_owner = models.BooleanField(default=False)
    active = models.BooleanField(default=True)
    started_on = models.DateField(null=True, blank=True)

    # Profile details (Trainer profile · Overview, Trainer · Me)
    gender = models.CharField(max_length=8, choices=Gender.choices, blank=True)
    short_bio = models.CharField(max_length=200, blank=True, help_text="One-line bio shown to clients")
    specialities = models.JSONField(default=list, blank=True, help_text='e.g. ["Strength", "Fat loss", "Powerlifting"]')
    experience_since = models.PositiveSmallIntegerField(null=True, blank=True, help_text="Year they started coaching")
    trains_mode = models.CharField(max_length=60, blank=True, help_text="e.g. Gym and online")
    languages = models.JSONField(default=list, blank=True)
    best_with = models.CharField(max_length=160, blank=True)
    socials = models.JSONField(default=list, blank=True, help_text='[{"kind": "instagram", "handle": "@aman.lifts", "followers": "12.4k"}]')
    rating = models.DecimalField(max_digits=2, decimal_places=1, null=True, blank=True, help_text="Client rating 0–5")
    adherence = models.PositiveSmallIntegerField(null=True, blank=True, help_text="Avg client adherence %, recalculated nightly")
    avg_reply_hours = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True, help_text="Avg check-in reply time")
    permissions = models.JSONField(default=default_permissions, blank=True)
    client_view = models.JSONField(default=default_client_view, blank=True, help_text="What clients see on the trainer card")
    notification_prefs = models.JSONField(default=default_trainer_notifications, blank=True)
    deactivated_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("user__full_name",)

    def __str__(self):
        return self.user.full_name

    @property
    def client_count(self):
        return self.clients.exclude(status__in=[ClientProfile.Status.ARCHIVED, ClientProfile.Status.REJECTED]).count()

    @property
    def experience_years(self):
        return (timezone.localdate().year - self.experience_since) if self.experience_since else None

    @property
    def is_full(self):
        return self.client_count >= self.capacity


class TrainerDocument(TimeStampedModel):
    """Trainer profile · Documents: certificates, ID proof, contract."""

    class Kind(models.TextChoices):
        CERT = "cert", "Certificate"
        ID = "id", "ID proof"
        CONTRACT = "file", "Contract"

    class Status(models.TextChoices):
        VERIFIED = "verified", "Verified"
        NOT_CHECKED = "not_checked", "Not checked"
        SIGNED = "signed", "Signed"
        REJECTED = "rejected", "Rejected"

    trainer = models.ForeignKey(TrainerProfile, on_delete=models.CASCADE, related_name="documents")
    name = models.CharField(max_length=160)
    issuer = models.CharField(max_length=160, blank=True)
    kind = models.CharField(max_length=5, choices=Kind.choices, default=Kind.CERT)
    issued_on = models.DateField(null=True, blank=True)
    valid_till = models.DateField(null=True, blank=True, help_text="Empty = no end date")
    status = models.CharField(max_length=12, choices=Status.choices, default=Status.NOT_CHECKED)
    clients_see = models.BooleanField(default=False, help_text="Shown on the trainer card to clients")
    file = models.FileField(upload_to="trainer-docs/", blank=True)
    file_url = models.URLField(blank=True, help_text="Firebase Storage URL when used")
    file_name = models.CharField(max_length=160, blank=True)
    file_type = models.CharField(max_length=10, blank=True, help_text="PDF, JPG …")
    size_bytes = models.PositiveIntegerField(null=True, blank=True)
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    uploaded_at = models.DateTimeField(default=timezone.now)
    verified_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("trainer", "id")

    def __str__(self):
        return f"{self.name} ({self.trainer})"

    @property
    def expires_in_days(self):
        if not self.valid_till:
            return None
        return (self.valid_till - timezone.localdate()).days

    @property
    def expiring(self):
        d = self.expires_in_days
        return d is not None and 0 <= d <= 60


class TrainerAvailability(TimeStampedModel):
    """Working hours per weekday (Calendar · My working hours, Trainer profile)."""

    trainer = models.ForeignKey(TrainerProfile, on_delete=models.CASCADE, related_name="availability")
    weekday = models.PositiveSmallIntegerField(help_text="0 = Monday … 6 = Sunday")
    is_working = models.BooleanField(default=True)
    start_minute = models.PositiveSmallIntegerField(default=420, help_text="Minutes after midnight, 420 = 7:00 am")
    end_minute = models.PositiveSmallIntegerField(default=1260)

    class Meta:
        ordering = ("trainer", "weekday")
        constraints = [models.UniqueConstraint(fields=("trainer", "weekday"), name="uniq_trainer_weekday")]

    def __str__(self):
        return f"{self.trainer} {WEEKDAYS[self.weekday]}"


class AccessRequest(TimeStampedModel):
    """Trainer · Me · My access → 'Ask for more access'."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        GRANTED = "granted", "Granted"
        DECLINED = "declined", "Declined"

    trainer = models.ForeignKey(TrainerProfile, on_delete=models.CASCADE, related_name="access_requests")
    items = models.JSONField(default=list, help_text='Asked keys: "all", "tpl", "forms", "pause"')
    note = models.TextField(blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING, db_index=True)
    decided_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    decided_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.trainer} asks {', '.join(self.items)}"


# ─────────────────────────────────────────────────────────────── clients


def default_reminders():
    """Client · More · Reminders toggles."""
    return {"workout": True, "meals": True, "water": True, "supps": True, "habits": False, "checkin": True, "coach": True, "progress": True}


class ClientProfile(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACTIVE = "active", "Active"
        AT_RISK = "at_risk", "At risk"
        PAUSED = "paused", "Paused"
        ARCHIVED = "archived", "Archived"
        REJECTED = "rejected", "Rejected"

    class Goal(models.TextChoices):
        FAT_LOSS = "fat_loss", "Fat loss"
        MUSCLE_GAIN = "muscle_gain", "Muscle gain"
        STRENGTH = "strength", "Strength"
        RECOMP = "recomp", "Recomp"
        GENERAL = "general", "General fitness"
        EVENT = "event", "Event prep"

    class Gender(models.TextChoices):
        FEMALE = "female", "Female"
        MALE = "male", "Male"
        OTHER = "other", "Other"

    class Experience(models.TextChoices):
        BEGINNER = "beginner", "0–6 months"
        INTERMEDIATE = "intermediate", "6 months – 2 years"
        ADVANCED = "advanced", "2+ years"

    class Place(models.TextChoices):
        GYM = "gym", "Gym"
        HOME = "home", "Home"
        BOTH = "both", "Gym and home"

    class Activity(models.TextChoices):
        DESK = "desk", "Mostly sitting"
        ON_FEET = "on_feet", "On my feet"
        VERY_ACTIVE = "very_active", "Very active"

    class Diet(models.TextChoices):
        VEG = "veg", "Vegetarian"
        EGG = "egg", "Eggetarian"
        NON_VEG = "non_veg", "Non-veg"
        VEGAN = "vegan", "Vegan"
        JAIN = "jain", "Jain"

    class Device(models.TextChoices):
        WEB = "web", "Web"
        ANDROID = "android", "Android app"
        IOS = "ios", "iPhone app"
        STAFF = "staff", "Added by staff"

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="client_profile")
    trainer = models.ForeignKey(TrainerProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name="clients")
    invite_link = models.ForeignKey("accounts.InviteLink", on_delete=models.SET_NULL, null=True, blank=True, related_name="clients")
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING, db_index=True)
    goal = models.CharField(max_length=12, choices=Goal.choices, default=Goal.GENERAL, db_index=True)
    plan = models.CharField(max_length=60, blank=True, help_text="Membership plan, e.g. Quarterly plan")
    plan_ends_on = models.DateField(null=True, blank=True)
    joined_on = models.DateField(null=True, blank=True)
    paused_until = models.DateField(null=True, blank=True)
    adherence = models.PositiveSmallIntegerField(null=True, blank=True, help_text="0–100, recalculated nightly")

    # Personal (Edit profile · Personal / Contact, Client · More · Profile)
    gender = models.CharField(max_length=8, choices=Gender.choices, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    city = models.CharField(max_length=80, blank=True)
    source = models.CharField(max_length=80, blank=True, help_text="Came from, e.g. Instagram ad")
    signup_device = models.CharField(max_length=8, choices=Device.choices, blank=True)
    emergency_name = models.CharField(max_length=120, blank=True)
    emergency_relation = models.CharField(max_length=40, blank=True)
    emergency_phone = models.CharField(max_length=20, blank=True)

    # Goal and body (onboarding step 1–2)
    goal_detail = models.CharField(max_length=200, blank=True, help_text="Her own words, e.g. 68 kg before her wedding")
    height_cm = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    start_weight_kg = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    current_weight_kg = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True, help_text="Latest weigh-in")
    target_weight_kg = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    target_date = models.DateField(null=True, blank=True)
    experience = models.CharField(max_length=12, choices=Experience.choices, blank=True)
    train_place = models.CharField(max_length=5, choices=Place.choices, blank=True)
    equipment = models.CharField(max_length=200, blank=True, help_text="What she has, e.g. Full gym / dumbbells at home")

    # Training days (onboarding step 3)
    training_days = models.JSONField(default=list, blank=True, help_text="Weekday numbers, 0 = Monday")
    session_minutes = models.PositiveSmallIntegerField(null=True, blank=True, help_text="30 / 45 / 60 / 75")
    preferred_time = models.TimeField(null=True, blank=True, help_text="Preferred training time")
    wake_time = models.TimeField(null=True, blank=True)

    # Health (onboarding step 4) — injuries/conditions live in HealthIssue
    daily_activity = models.CharField(max_length=12, choices=Activity.choices, blank=True)
    doctor_cleared = models.BooleanField(default=False, help_text="Doctor's OK to exercise")
    health_notes = models.TextField(blank=True, help_text="Free text: 'Tell Aman more'")

    # Food (onboarding step 5)
    diet = models.CharField(max_length=8, choices=Diet.choices, blank=True)
    meals_per_day = models.PositiveSmallIntegerField(null=True, blank=True)
    avoid_foods = models.JSONField(default=list, blank=True, help_text='e.g. ["Eggs", "Mushrooms"]')
    allergies = models.CharField(max_length=200, blank=True)
    cooks_at_home = models.BooleanField(default=True, help_text="Home-cooked meals in the plan")
    food_notes = models.CharField(max_length=200, blank=True, help_text="e.g. no eggs, no onion or garlic")

    # Onboarding progress
    onboarding_steps = models.JSONField(default=list, blank=True, help_text="Done step indexes 0–4 (goal, about, days, health, food)")
    onboarding_answers = models.JSONField(default=dict, blank=True, help_text="Raw answers as sent by the app")
    onboarded_at = models.DateTimeField(null=True, blank=True)
    setup_reminder = models.CharField(max_length=20, blank=True, help_text="Finish later reminder: tonight / tomorrow / 3days / off")

    # Coaching state
    next_checkin_on = models.DateField(null=True, blank=True)
    plans_start_on = models.DateField(null=True, blank=True, help_text="Her day 1 for workout and meal plans")
    approved_at = models.DateTimeField(null=True, blank=True)
    approved_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    paused_at = models.DateTimeField(null=True, blank=True)
    pause_reason = models.CharField(max_length=200, blank=True)
    archived_at = models.DateTimeField(null=True, blank=True)
    last_edited_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    # Client · More (reminders, units, privacy)
    reminders = models.JSONField(default=default_reminders, blank=True)
    quiet_hours_on = models.BooleanField(default=True)
    quiet_from = models.PositiveSmallIntegerField(default=1320, help_text="Minutes after midnight (10:00 pm)")
    quiet_to = models.PositiveSmallIntegerField(default=420, help_text="Minutes after midnight (7:00 am)")
    weight_unit = models.CharField(max_length=2, choices=[("kg", "kg"), ("lb", "lb")], default="kg")
    length_unit = models.CharField(max_length=2, choices=[("cm", "cm"), ("in", "in")], default="cm")
    water_unit = models.CharField(max_length=2, choices=[("L", "litres"), ("oz", "fl oz")], default="L")
    week_start = models.CharField(max_length=6, choices=[("monday", "Monday"), ("sunday", "Sunday")], default="monday")
    theme = models.CharField(max_length=6, choices=[("light", "Light"), ("dark", "Dark"), ("system", "Like my phone")], default="light")
    share_photos = models.BooleanField(default=True, help_text="Share progress photos with the coach")
    improve_app = models.BooleanField(default=True, help_text="Send anonymous usage data")
    delete_requested_at = models.DateTimeField(null=True, blank=True, help_text="Account deletion asked; cancel by logging in within 14 days")

    class Meta:
        ordering = ("user__full_name",)
        indexes = [models.Index(fields=("trainer", "status"))]

    def __str__(self):
        return self.user.full_name

    @property
    def age(self):
        if not self.date_of_birth:
            return None
        t = timezone.localdate()
        b = self.date_of_birth
        return t.year - b.year - ((t.month, t.day) < (b.month, b.day))

    @property
    def onboarding_progress(self):
        """0–100, the Onboarding bar in the client lists."""
        return round(len(set(self.onboarding_steps)) * 100 / 5)

    @property
    def onboarding_label(self):
        n = len(set(self.onboarding_steps))
        return "Done" if n >= 5 else "Not started" if n == 0 else f"{self.onboarding_progress}%"

    @property
    def weight_change_kg(self):
        if self.start_weight_kg is None or self.current_weight_kg is None:
            return None
        return self.current_weight_kg - self.start_weight_kg

    @property
    def to_goal_kg(self):
        if self.target_weight_kg is None or self.current_weight_kg is None:
            return None
        return abs(self.current_weight_kg - self.target_weight_kg)


class HealthIssue(TimeStampedModel):
    """Injuries and health conditions (Health & injuries step, Edit profile · Health, History · Health over time)."""

    class Kind(models.TextChoices):
        INJURY = "injury", "Injury"
        CONDITION = "condition", "Condition"
        FOOD = "food", "Food / allergy"

    class Severity(models.TextChoices):
        MILD = "mild", "Mild"
        MODERATE = "moderate", "Moderate"
        SEVERE = "severe", "Severe"

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        IMPROVING = "improving", "Getting better"
        CLEARED = "cleared", "Cleared"

    client = models.ForeignKey(ClientProfile, on_delete=models.CASCADE, related_name="health_issues")
    kind = models.CharField(max_length=10, choices=Kind.choices, default=Kind.INJURY)
    area = models.CharField(max_length=40, help_text="Knee, Lower back … / Diabetes, Thyroid, High BP …")
    title = models.CharField(max_length=160, help_text="e.g. Right knee pain on deep squats")
    severity = models.CharField(max_length=8, choices=Severity.choices, default=Severity.MILD)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.ACTIVE, db_index=True)
    since = models.DateField(null=True, blank=True)
    until = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True, help_text="What the coach does about it, e.g. box squats instead")
    needs_doctor_note = models.BooleanField(default=False)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ("client", "-since", "id")

    def __str__(self):
        return f"{self.client}: {self.title}"


class ClientNote(TimeStampedModel):
    """Client profile · Notes (staff only). A flag shows in Needs attention."""

    client = models.ForeignKey(ClientProfile, on_delete=models.CASCADE, related_name="notes")
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="client_notes")
    text = models.TextField()
    is_flag = models.BooleanField(default=False, help_text="Shows in Needs attention")
    pinned = models.BooleanField(default=False)

    class Meta:
        ordering = ("-pinned", "-created_at")

    def __str__(self):
        return self.text[:60]


class TrainerChange(TimeStampedModel):
    """Change trainer drawer + client History."""

    client = models.ForeignKey(ClientProfile, on_delete=models.CASCADE, related_name="trainer_changes")
    from_trainer = models.ForeignKey(TrainerProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    to_trainer = models.ForeignKey(TrainerProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    changed_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    reason = models.CharField(max_length=200, blank=True)
    note_for_trainer = models.TextField(blank=True)
    move_open_checkins = models.BooleanField(default=True)
    notify_client = models.BooleanField(default=True)
    notify_old_trainer = models.BooleanField(default=False)

    class Meta:
        ordering = ("-created_at",)

    def __str__(self):
        return f"{self.client}: {self.from_trainer} → {self.to_trainer}"


class ApprovalRequest(TimeStampedModel):
    """Admin · Approvals: new sign-ups (Waiting / History) and trainer-change asks."""

    class Kind(models.TextChoices):
        SIGNUP = "signup", "New sign-up"
        TRAINER_CHANGE = "trainer_change", "Trainer change"
        PLAN_CHANGE = "plan_change", "Plan change"

    class Status(models.TextChoices):
        WAITING = "waiting", "Waiting"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    class RejectReason(models.TextChoices):
        FIT = "fit", "Not a fit for our coaching"
        DUP = "dup", "Already has an account"
        WRONG = "wrong", "Wrong or fake details"
        FULL = "full", "No trainer free right now"
        OTHER = "other", "Something else"

    kind = models.CharField(max_length=16, choices=Kind.choices, default=Kind.SIGNUP, db_index=True)
    client = models.ForeignKey(ClientProfile, on_delete=models.CASCADE, related_name="approvals")
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.WAITING, db_index=True)
    invite_link = models.ForeignKey("accounts.InviteLink", on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    invited_by = models.ForeignKey(TrainerProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    plan = models.CharField(max_length=60, blank=True)
    device = models.CharField(max_length=8, choices=ClientProfile.Device.choices, blank=True)
    requested_at = models.DateTimeField(default=timezone.now, db_index=True, help_text="Signed up / asked at")
    good_fit = models.ForeignKey(TrainerProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name="+", help_text="Suggested trainer")
    requested_trainer = models.ForeignKey(TrainerProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name="+", help_text="Trainer change: wanted trainer")
    reason = models.CharField(max_length=200, blank=True, help_text="Why she asked (trainer/plan change)")
    # decision
    assigned_trainer = models.ForeignKey(TrainerProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    decided_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    decided_at = models.DateTimeField(null=True, blank=True)
    reject_reason = models.CharField(max_length=6, choices=RejectReason.choices, blank=True)
    decision_note = models.CharField(max_length=300, blank=True, help_text="Shown in History, e.g. 'Not a fit: needs a physio first'")
    message = models.TextField(blank=True, help_text="Message sent with the decision")
    tell_client = models.BooleanField(default=True, help_text="Tell her on WhatsApp and email / by email")
    ask_finish_setup = models.BooleanField(default=False)
    moved_back = models.BooleanField(default=False, help_text="Moved back from History to Waiting")

    class Meta:
        ordering = ("requested_at",)  # oldest first

    def __str__(self):
        return f"{self.get_kind_display()} · {self.client} · {self.status}"

    @property
    def hours_waiting(self):
        end = self.decided_at or timezone.now()
        return round((end - self.requested_at).total_seconds() / 3600, 1)

    @property
    def wait_level(self):
        h = self.hours_waiting
        return "late" if h > 48 else "old" if h > 24 else "normal"


class InfoRequest(TimeStampedModel):
    """Approvals · Ask for info."""

    class Item(models.TextChoices):
        SETUP = "setup", "Finish profile setup"
        PARQ = "parq", "Fill the health form again"
        DOC = "doc", "Send a doctor note"
        PHOTO = "photo", "Add a profile photo"
        PHONE = "phone", "Check her phone number"

    approval = models.ForeignKey(ApprovalRequest, on_delete=models.CASCADE, related_name="info_requests")
    items = models.JSONField(default=list)
    channels = models.JSONField(default=list, help_text='["whatsapp", "email", "app"]')
    message = models.TextField(blank=True)
    sent_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    resolved_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Info asked from {self.approval.client}"


class ClientNudge(TimeStampedModel):
    """'Remind' on at-risk / needs-you lists (skip clients reminded in the last 24 h)."""

    client = models.ForeignKey(ClientProfile, on_delete=models.CASCADE, related_name="nudges")
    sent_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    reason = models.CharField(max_length=160, blank=True)
    channels = models.JSONField(default=list, blank=True)

    class Meta:
        ordering = ("-created_at",)


class DashboardDismissal(TimeStampedModel):
    """Dashboard 'Needs action' row × — hidden for this user."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="dashboard_dismissals")
    key = models.CharField(max_length=80)

    class Meta:
        constraints = [models.UniqueConstraint(fields=("user", "key"), name="uniq_dismissal")]

