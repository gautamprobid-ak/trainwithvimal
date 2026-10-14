"""Training: exercise library, programs (master + per-client copies), assignments,
workout sessions with set logs, swaps and personal records.

Screens: Exercise library / detail / new exercise, Programs, Program builder,
Client profile > Plans (workout) and Logs (workouts), Client Home (today's workout),
Train (week strip, blocks, exercise guide, past workouts), Workout logger
(sets, rest timer, warm-ups, swaps, finish summary), Progress (lifts, PRs, history).
"""
import datetime as dt
import re
from decimal import Decimal

from django.conf import settings
from django.db import models
from django.utils import timezone
from django.utils.text import slugify

from apps.core.models import OrderedModel, TimeStampedModel

WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


class MuscleGroup(models.TextChoices):
    """Library filter groups (and the wider list used by "Primary muscle" on New exercise)."""

    CHEST = "Chest"
    BACK = "Back"
    LEGS = "Legs"
    SHOULDERS = "Shoulders"
    ARMS = "Arms"
    CORE = "Core"
    CARDIO = "Cardio"
    GLUTES = "Glutes"
    HAMSTRINGS = "Hamstrings"


class Equipment(models.TextChoices):
    BARBELL = "Barbell"
    DUMBBELL = "Dumbbell"
    CABLE = "Cable"
    MACHINE = "Machine"
    BODYWEIGHT = "Bodyweight"
    KETTLEBELL = "Kettlebell"
    BAND = "Band"
    OTHER = "Other"


class Level(models.TextChoices):
    BEGINNER = "Beginner"
    INTERMEDIATE = "Intermediate"
    ADVANCED = "Advanced"


class LogType(models.TextChoices):
    """How the client logs the exercise (New exercise > Client logs)."""

    WEIGHT_REPS = "weight_reps", "kg × reps"
    TIME = "time", "Seconds"
    CARDIO = "cardio", "Minutes · km"


class VideoSource(models.TextChoices):
    NONE = "none", "No video"
    LIBRARY = "library", "From content library"
    YOUTUBE = "youtube", "YouTube link"
    UPLOAD = "upload", "Uploaded file"


# ===================================================================== exercises


class Exercise(TimeStampedModel):
    class Category(models.TextChoices):
        STRENGTH = "strength", "Strength"
        CARDIO = "cardio", "Cardio"
        MOBILITY = "mobility", "Mobility"

    class CoverSource(models.TextChoices):
        FRAME = "frame", "Frame from the video"
        UPLOAD = "upload", "Uploaded image"

    name = models.CharField(max_length=120)
    slug = models.SlugField(max_length=140, unique=True)
    muscle_group = models.CharField(max_length=12, choices=MuscleGroup.choices, db_index=True,
                                    help_text="Decides where the exercise shows in the library filter")
    primary_muscle = models.CharField(max_length=40, help_text="Main muscle on the Muscles tab, e.g. Chest, Quads, Glutes")
    primary_muscle_note = models.CharField(max_length=120, blank=True, help_text="e.g. Pectorals / Push the body up the incline")
    equipment = models.CharField(max_length=12, choices=Equipment.choices, db_index=True)
    level = models.CharField(max_length=12, choices=Level.choices, default=Level.BEGINNER, db_index=True)
    category = models.CharField(max_length=10, choices=Category.choices, default=Category.STRENGTH)
    log_type = models.CharField(max_length=12, choices=LogType.choices, default=LogType.WEIGHT_REPS)
    bodyweight_default = models.BooleanField(default=False, help_text="Sets start as BW (bodyweight) in the logger")

    # default prescription, copied when the exercise is added to a program day
    default_sets = models.PositiveSmallIntegerField(default=3)
    default_reps = models.CharField(max_length=20, default="8–12", help_text="Reps, '45 s' (time) or '20 min' (cardio)")
    default_rest_s = models.PositiveIntegerField(default=90)
    default_rpe = models.PositiveSmallIntegerField(default=0, help_text="0 = not set")
    default_tempo = models.CharField(max_length=12, blank=True)

    how_to = models.JSONField(default=list, blank=True, help_text="Ordered steps (How to tab)")
    cues = models.JSONField(default=list, blank=True, help_text="Form cues / tips")
    common_mistakes = models.JSONField(default=list, blank=True)

    video_source = models.CharField(max_length=10, choices=VideoSource.choices, default=VideoSource.NONE)
    video_title = models.CharField(max_length=160, blank=True, help_text="e.g. Bench press · setup")
    video_url = models.URLField(blank=True)
    video_duration_s = models.PositiveIntegerField(null=True, blank=True)
    video_channel = models.CharField(max_length=80, blank=True, help_text="YouTube channel name")
    content_item_id = models.PositiveIntegerField(null=True, blank=True, help_text="content app item id when from the library")
    cover_source = models.CharField(max_length=8, choices=CoverSource.choices, default=CoverSource.FRAME)
    cover_frame_s = models.PositiveIntegerField(null=True, blank=True, help_text="Video second used as cover")
    cover_image = models.ImageField(upload_to="exercises/", blank=True)
    image_url = models.URLField(blank=True)
    tone = models.PositiveSmallIntegerField(default=1, help_text="Thumbnail gradient t1…t4")

    is_custom = models.BooleanField(default=False, db_index=True, help_text="Made by the team (Source: Custom)")
    show_in_library = models.BooleanField(default=True, help_text="False for exercises used only inside client plans")
    duplicated_from = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="copies")
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    archived = models.BooleanField(default=False, db_index=True)

    class Meta:
        ordering = ("name",)

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if not self.slug:
            base = slugify(self.name)[:120] or "exercise"
            slug, n = base, 2
            while Exercise.objects.filter(slug=slug).exclude(pk=self.pk).exists():
                slug, n = f"{base}-{n}", n + 1
            self.slug = slug
        super().save(*args, **kwargs)

    @property
    def source(self):
        return "Custom" if self.is_custom else "Built-in"

    @property
    def works_label(self):
        also = [m.muscle for m in self.muscles.all()]
        return self.primary_muscle + (" · also " + ", ".join(also) if also else "")


class ExerciseMuscle(OrderedModel):
    """"Also works" rows on the Muscles tab."""

    class Intensity(models.TextChoices):
        STRONG = "strong", "Strong"
        LIGHT = "light", "Light"

    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE, related_name="muscles")
    muscle = models.CharField(max_length=40)
    intensity = models.CharField(max_length=6, choices=Intensity.choices, default=Intensity.LIGHT)
    note = models.CharField(max_length=120, blank=True, help_text="e.g. Straighten the arms at the top")

    class Meta(OrderedModel.Meta):
        unique_together = ("exercise", "muscle")

    def __str__(self):
        return f"{self.exercise} · {self.muscle}"


# ===================================================================== programs


class Program(TimeStampedModel):
    """A master plan, or (client set) a copy made for one client ("Edited for Riya")."""

    class Goal(models.TextChoices):
        FAT_LOSS = "fat_loss", "Fat loss"
        MUSCLE_GAIN = "muscle_gain", "Muscle gain"
        STRENGTH = "strength", "Strength"
        GENERAL = "general", "General fitness"
        MOBILITY = "mobility", "Mobility and strength"
        REHAB = "rehab", "Rehab friendly"
        RECOMP = "recomp", "Recomp"

    class Location(models.TextChoices):
        GYM = "gym", "Gym"
        HOME = "home", "Home"
        ANY = "any", "Gym or home"

    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        ACTIVE = "active", "Active"
        ARCHIVED = "archived", "Archived"

    name = models.CharField(max_length=120)
    short_name = models.CharField(max_length=60, blank=True, help_text='Used in "On Hypertrophy PPL"')
    goal = models.CharField(max_length=12, choices=Goal.choices, default=Goal.GENERAL)
    goal_label = models.CharField(max_length=80, blank=True, help_text='Card subtitle, e.g. "Fat loss · gym"')
    description = models.TextField(blank=True)
    level = models.CharField(max_length=12, choices=Level.choices, default=Level.BEGINNER)
    location = models.CharField(max_length=4, choices=Location.choices, default=Location.GYM)
    weeks = models.PositiveSmallIntegerField(default=8)
    status = models.CharField(max_length=8, choices=Status.choices, default=Status.ACTIVE, db_index=True)
    tags = models.JSONField(default=list, blank=True)
    tone = models.PositiveSmallIntegerField(default=1, help_text="Icon tone t1…t4")
    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, null=True, blank=True, related_name="custom_programs",
                               help_text="Set for a client's own copy; empty = master plan in the library")
    based_on = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="copies",
                                 help_text="Master this copy came from")
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    edited_at = models.DateTimeField(default=timezone.now, help_text='"Edited 2 Oct"')
    edited_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ("status", "-edited_at")
        indexes = [models.Index(fields=["client", "status"])]

    def __str__(self):
        return self.name + (f" · {self.client}" if self.client_id else "")

    @property
    def is_master(self):
        return self.client_id is None

    def week_pattern(self, number=1):
        """Training (True) / rest (False) per weekday, Monday first."""
        week = self.program_weeks.filter(number=number).first() or self.program_weeks.first()
        out = [False] * 7
        if week:
            for d in week.days.all():
                out[d.day_index] = not d.is_rest
        return out

    @property
    def days_per_week(self):
        return sum(self.week_pattern())


class ProgramWeek(TimeStampedModel):
    program = models.ForeignKey(Program, on_delete=models.CASCADE, related_name="program_weeks")
    number = models.PositiveSmallIntegerField(help_text="1-based week number")
    note = models.CharField(max_length=200, blank=True)

    class Meta:
        ordering = ("program", "number")
        unique_together = ("program", "number")

    def __str__(self):
        return f"{self.program} · W{self.number}"


class ProgramDay(TimeStampedModel):
    """One day of a program week. A non-rest day is the workout itself."""

    class Kind(models.TextChoices):
        STRENGTH = "strength", "Strength"
        CARDIO = "cardio", "Cardio"
        MOBILITY = "mobility", "Mobility"
        REST = "rest", "Rest"

    week = models.ForeignKey(ProgramWeek, on_delete=models.CASCADE, related_name="days")
    day_index = models.PositiveSmallIntegerField(help_text="0 = Monday … 6 = Sunday")
    title = models.CharField(max_length=80)
    kind = models.CharField(max_length=10, choices=Kind.choices, default=Kind.STRENGTH)
    is_rest = models.BooleanField(default=False)
    note = models.TextField(blank=True, help_text="Coach note for this day / rest day instructions")
    estimated_minutes = models.PositiveSmallIntegerField(null=True, blank=True, help_text="Override of the computed ≈ minutes")
    equipment_note = models.CharField(max_length=120, blank=True, help_text="e.g. Treadmill, kettlebell, mat")
    changed_for_client = models.BooleanField(default=False, help_text="Client copy differs from master here")

    class Meta:
        ordering = ("week__program", "week__number", "day_index")
        unique_together = ("week", "day_index")

    def __str__(self):
        return f"{self.week} · {WEEKDAYS[self.day_index][:3]} {self.title}"

    @property
    def program(self):
        return self.week.program

    def computed_minutes(self):
        if self.estimated_minutes:
            return self.estimated_minutes
        total = 0
        for e in self.exercises.all():
            work = (e.duration_min or 0) * 60 if e.duration_min else 40
            total += e.sets * (work + e.rest_s)
        return max(5, round(total / 300) * 5) if total else 0

    @property
    def total_sets(self):
        return sum(e.sets for e in self.exercises.all())


def parse_reps(text):
    """'6–8' → (6, 8); '10/side' → (10, 10); 'AMRAP' → (None, None)."""
    nums = [int(x) for x in re.findall(r"\d+", text or "")]
    if not nums or re.search(r"\b(s|min)\b", text or ""):
        return None, None
    return nums[0], (nums[1] if len(nums) > 1 else nums[0])


class WorkoutExercise(OrderedModel):
    """An exercise on a program day with its prescription (program builder row)."""

    day = models.ForeignKey(ProgramDay, on_delete=models.CASCADE, related_name="exercises")
    exercise = models.ForeignKey(Exercise, on_delete=models.PROTECT, related_name="placements")
    block = models.CharField(max_length=40, blank=True, help_text='Client app block, e.g. "Cardio", "Conditioning", "Core"')
    sets = models.PositiveSmallIntegerField(default=3)
    reps = models.CharField(max_length=20, default="8–12", help_text="As written: 6–8, 10/side, AMRAP, 45 s, 30 min")
    rep_min = models.PositiveSmallIntegerField(null=True, blank=True)
    rep_max = models.PositiveSmallIntegerField(null=True, blank=True)
    per_side = models.BooleanField(default=False, help_text="Reps / time are each side or each leg")
    hold_s = models.PositiveIntegerField(null=True, blank=True, help_text="Time sets: seconds per set")
    rest_s = models.PositiveIntegerField(default=90)
    rpe = models.PositiveSmallIntegerField(default=0, help_text="0 = not set")
    tempo = models.CharField(max_length=12, blank=True)
    superset_group = models.CharField(max_length=2, blank=True, help_text="Superset letter, '' = none")
    note = models.TextField(blank=True)
    target_weight_kg = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    load_note = models.CharField(max_length=40, blank=True, help_text="Load when not kg: Body, Band, 10% · 5 km/h")
    duration_min = models.PositiveSmallIntegerField(null=True, blank=True, help_text="Cardio minutes")
    incline_pct = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
    speed_kmh = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
    distance_km = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, help_text="Cardio target distance")
    target_note = models.CharField(max_length=160, blank=True, help_text='Extra target line, e.g. "you can still talk"')

    # "Edit for this program": per-program copy of the library exercise
    override_name = models.CharField(max_length=120, blank=True)
    override_video_source = models.CharField(max_length=10, choices=[("lib", "Same as library"), ("cl", "Another content library video"), ("yt", "YouTube link")], blank=True)
    override_video_url = models.URLField(blank=True)
    override_video_title = models.CharField(max_length=160, blank=True)
    override_steps = models.JSONField(default=list, blank=True)
    override_cues = models.JSONField(default=list, blank=True)

    # client copies
    changed_for_client = models.BooleanField(default=False)
    replaced_exercise = models.ForeignKey(Exercise, on_delete=models.SET_NULL, null=True, blank=True, related_name="+",
                                          help_text="Swapped in the plan: what it was before")
    change_note = models.CharField(max_length=160, blank=True, help_text='e.g. "Was: Back squat (knee pain)"')

    class Meta(OrderedModel.Meta):
        ordering = ("day", "position", "id")

    def __str__(self):
        return f"{self.day} · {self.shown_name}"

    def save(self, *args, **kwargs):
        lo, hi = parse_reps(self.reps)
        if self.rep_min is None and lo is not None:
            self.rep_min, self.rep_max = lo, hi
        super().save(*args, **kwargs)

    @property
    def is_customized(self):
        return bool(self.override_name or self.override_video_source or self.override_steps or self.override_cues)

    @property
    def shown_name(self):
        return self.override_name or self.exercise.name

    @property
    def summary(self):
        """"4 × 6–8 · 42.5 kg" style line."""
        if self.exercise.log_type == LogType.CARDIO:
            parts = [self.reps]
            if self.incline_pct is not None:
                parts.append(f"incline {self.incline_pct.normalize():f}%")
            if self.speed_kmh is not None:
                parts.append(f"{self.speed_kmh.normalize():f} km/h")
            return " · ".join(parts)
        line = f"{self.sets} × {self.reps}" + (" each side" if self.per_side and "each" not in self.reps and "/" not in self.reps else "")
        if self.target_weight_kg is not None:
            line += f" · {self.target_weight_kg.normalize():f} kg"
        return line


# ===================================================================== assignments


class ProgramAssignment(TimeStampedModel):
    """A client following a program (master or their own copy). Plan history = past rows."""

    class Status(models.TextChoices):
        UPCOMING = "upcoming", "Up next"
        ACTIVE = "active", "Current"
        COMPLETED = "completed", "Completed"
        REPLACED = "replaced", "Replaced"
        ENDED = "ended", "Ended early"

    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="program_assignments")
    program = models.ForeignKey(Program, on_delete=models.PROTECT, related_name="assignments")
    master = models.ForeignKey(Program, on_delete=models.SET_NULL, null=True, blank=True, related_name="master_assignments",
                               help_text="Master plan when program is a client copy")
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.ACTIVE, db_index=True)
    assigned_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    ended_on = models.DateField(null=True, blank=True)
    end_reason = models.CharField(max_length=200, blank=True)
    replaced_by = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    note = models.CharField(max_length=200, blank=True)

    class Meta:
        ordering = ("client", "-start_date")
        indexes = [models.Index(fields=["client", "status"])]

    def __str__(self):
        return f"{self.client} → {self.program} ({self.status})"

    @property
    def is_custom(self):
        return self.program.client_id is not None

    def week_start(self):
        return self.start_date - dt.timedelta(days=self.start_date.weekday())

    def week_number(self, on=None):
        on = on or timezone.localdate()
        n = (on - self.week_start()).days // 7 + 1
        return max(1, min(n, self.program.weeks))

    @property
    def current_week(self):
        return self.week_number()

    def day_for(self, date):
        """ProgramDay planned for a calendar date (or None)."""
        if date < self.week_start() or (self.end_date and date > self.end_date):
            return None
        n = self.week_number(date)
        week = self.program.program_weeks.filter(number=n).first() or self.program.program_weeks.order_by("-number").first()
        if not week:
            return None
        return week.days.filter(day_index=date.weekday()).first()


# ===================================================================== sessions


class WorkoutSession(TimeStampedModel):
    class Status(models.TextChoices):
        PLANNED = "planned", "Planned"
        IN_PROGRESS = "in_progress", "In progress"
        COMPLETED = "completed", "Done"
        SKIPPED = "skipped", "Skipped"
        MISSED = "missed", "Missed"
        DISCARDED = "discarded", "Discarded"

    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="workout_sessions")
    assignment = models.ForeignKey(ProgramAssignment, on_delete=models.SET_NULL, null=True, blank=True, related_name="sessions")
    program_day = models.ForeignKey(ProgramDay, on_delete=models.SET_NULL, null=True, blank=True, related_name="sessions")
    title = models.CharField(max_length=80, help_text="Workout name at the time, e.g. Upper A")
    kind = models.CharField(max_length=10, choices=ProgramDay.Kind.choices, default=ProgramDay.Kind.STRENGTH)
    week_number = models.PositiveSmallIntegerField(null=True, blank=True)
    scheduled_date = models.DateField(db_index=True)
    status = models.CharField(max_length=12, choices=Status.choices, default=Status.PLANNED, db_index=True)
    started_at = models.DateTimeField(null=True, blank=True)
    finished_at = models.DateTimeField(null=True, blank=True)
    paused_at = models.DateTimeField(null=True, blank=True, help_text="Set while the workout timer is paused")
    paused_s = models.PositiveIntegerField(default=0, help_text="Paused time, not counted")
    time_adjust_s = models.IntegerField(default=0, help_text="±1 min fixes from the timer sheet")
    duration_s = models.PositiveIntegerField(null=True, blank=True, help_text="Workout time when finished")
    rest_s = models.PositiveIntegerField(default=0, help_text="Time spent in the rest timer (Where the time went)")
    last_activity_at = models.DateTimeField(null=True, blank=True, help_text="Last ticked set / Keep going")
    effort = models.PositiveSmallIntegerField(null=True, blank=True, help_text="How hard was it? 1–10")
    feeling = models.CharField(max_length=20, blank=True, help_text="Optional mood label")
    note = models.TextField(blank=True, help_text="Note for the coach")
    sent_to_coach_at = models.DateTimeField(null=True, blank=True)
    skip_reason = models.CharField(max_length=200, blank=True, help_text="Missed / skipped reason, e.g. Work ran late")
    coach_seen_at = models.DateTimeField(null=True, blank=True)
    # summary (kept on the row so history lists need no joins; recalculated on finish)
    exercises_done = models.PositiveSmallIntegerField(default=0)
    exercises_total = models.PositiveSmallIntegerField(default=0)
    sets_done = models.PositiveSmallIntegerField(default=0)
    sets_total = models.PositiveSmallIntegerField(default=0)
    volume_kg = models.DecimalField(max_digits=9, decimal_places=1, default=Decimal("0"))

    class Meta:
        ordering = ("-scheduled_date", "-started_at")
        indexes = [models.Index(fields=["client", "scheduled_date"]), models.Index(fields=["client", "status"])]

    def __str__(self):
        return f"{self.client} · {self.title} · {self.scheduled_date}"

    @property
    def elapsed_s(self):
        if self.duration_s is not None:
            return self.duration_s
        if not self.started_at:
            return 0
        end = self.finished_at or self.paused_at or timezone.now()
        return max(0, int((end - self.started_at).total_seconds()) - self.paused_s + self.time_adjust_s)

    @property
    def minutes(self):
        return round(self.elapsed_s / 60) if self.elapsed_s else 0

    @property
    def has_pr(self):
        return SetLog.objects.filter(entry__session=self, is_pr=True).exists()

    def recalc(self, save=True):
        entries = list(self.entries.prefetch_related("sets", "exercise"))
        self.exercises_total = len(entries)
        self.exercises_done = sum(1 for e in entries if e.sets.filter(done=True).exists())
        sets = [s for e in entries for s in e.sets.all()]
        self.sets_total = len(sets)
        self.sets_done = sum(1 for s in sets if s.done)
        bw = self.client_bodyweight()
        vol = Decimal("0")
        for s in sets:
            if s.done and not s.is_warmup and s.reps:
                kg = s.load_kg(bw)
                if kg:
                    vol += kg * s.reps
        self.volume_kg = vol.quantize(Decimal("0.1"))
        if save:
            self.save(update_fields=["exercises_total", "exercises_done", "sets_total", "sets_done", "volume_kg", "updated_at"])

    def client_bodyweight(self):
        """Last weigh-in (checkins app when present), used for BW sets."""
        try:
            from django.apps import apps

            WeighIn = apps.get_model("checkins", "WeighIn")
            w = WeighIn.objects.filter(client=self.client).order_by("-date").first()
            for f in ("weight_kg", "kg", "weight"):
                if w is not None and hasattr(w, f):
                    return Decimal(str(getattr(w, f)))
        except Exception:  # noqa: BLE001 — optional dependency
            pass
        return None


class SessionExercise(OrderedModel):
    """An exercise as done in a session: from the plan, swapped, or added by the client."""

    session = models.ForeignKey(WorkoutSession, on_delete=models.CASCADE, related_name="entries")
    workout_exercise = models.ForeignKey(WorkoutExercise, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    exercise = models.ForeignKey(Exercise, on_delete=models.PROTECT, related_name="session_entries")
    name = models.CharField(max_length=120, help_text="Name as shown in the log, e.g. Band pull-up")
    swapped_from = models.ForeignKey(Exercise, on_delete=models.SET_NULL, null=True, blank=True, related_name="+",
                                     help_text="Planned exercise the client swapped out")
    swap_reason = models.CharField(max_length=160, blank=True)
    added_by_client = models.BooleanField(default=False)
    note = models.CharField(max_length=200, blank=True)

    class Meta(OrderedModel.Meta):
        ordering = ("session", "position", "id")

    def __str__(self):
        return f"{self.session} · {self.name}"


class SetLog(TimeStampedModel):
    entry = models.ForeignKey(SessionExercise, on_delete=models.CASCADE, related_name="sets")
    set_no = models.PositiveSmallIntegerField(help_text="1-based order in the exercise (warm-ups included)")
    is_warmup = models.BooleanField(default=False, help_text="Warm-up sets do not count towards volume")
    reps = models.PositiveSmallIntegerField(null=True, blank=True)
    weight_kg = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True,
                                    help_text="Load in kg; for BW sets the added (+) or assisted (−) kg")
    is_bodyweight = models.BooleanField(default=False, help_text="BW, BW+5, BW−10")
    assistance = models.CharField(max_length=30, blank=True, help_text="e.g. Band")
    per_side = models.BooleanField(default=False, help_text="Reps/time each side")
    duration_s = models.PositiveIntegerField(null=True, blank=True, help_text="Time sets and cardio")
    distance_km = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    rpe = models.DecimalField(max_digits=3, decimal_places=1, null=True, blank=True)
    target_reps = models.PositiveSmallIntegerField(null=True, blank=True)
    target_weight_kg = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    target_duration_s = models.PositiveIntegerField(null=True, blank=True)
    done = models.BooleanField(default=False)
    skipped = models.BooleanField(default=False)
    done_at = models.DateTimeField(null=True, blank=True)
    done_at_s = models.PositiveIntegerField(null=True, blank=True, help_text="Workout time when ticked (for Where the time went)")
    is_pr = models.BooleanField(default=False, help_text='"New best" badge')

    class Meta:
        ordering = ("entry", "set_no")
        unique_together = ("entry", "set_no")

    def __str__(self):
        return f"{self.entry} · set {self.set_no}"

    def load_kg(self, bodyweight=None):
        if self.is_bodyweight:
            if bodyweight is None:
                return None
            return bodyweight + (self.weight_kg or 0)
        return self.weight_kg

    @property
    def display(self):
        lt = self.entry.exercise.log_type
        each = " each" if self.per_side else ""
        if lt == LogType.CARDIO:
            mins = round((self.duration_s or 0) / 60)
            return f"{mins} min" + (f" · {self.distance_km.normalize():f} km" if self.distance_km is not None else "")
        if lt == LogType.TIME:
            return f"{self.duration_s or 0} s{each}"
        if self.assistance:
            load = self.assistance
        elif self.is_bodyweight:
            w = self.weight_kg or 0
            load = "BW" + (f"+{w.normalize():f}" if w > 0 else f"−{(-w).normalize():f}" if w < 0 else "")
        else:
            load = f"{(self.weight_kg or 0).normalize():f} kg"
        return f"{load} × {self.reps or 0}{each}"


class PersonalRecord(TimeStampedModel):
    """A new best for a client on an exercise. Lift progress = the PR history."""

    class Kind(models.TextChoices):
        WEIGHT = "weight", "Heaviest weight"
        REPS = "reps", "Most reps"
        TIME = "time", "Longest hold"
        DISTANCE = "distance", "Longest distance"

    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="personal_records")
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE, related_name="records")
    kind = models.CharField(max_length=8, choices=Kind.choices, default=Kind.WEIGHT)
    weight_kg = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    reps = models.PositiveSmallIntegerField(null=True, blank=True)
    duration_s = models.PositiveIntegerField(null=True, blank=True)
    distance_km = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    achieved_on = models.DateField(db_index=True)
    session = models.ForeignKey(WorkoutSession, on_delete=models.SET_NULL, null=True, blank=True, related_name="records")
    set_log = models.ForeignKey(SetLog, on_delete=models.SET_NULL, null=True, blank=True, related_name="records")
    note = models.CharField(max_length=200, blank=True, help_text="Coach caption on the lift card")

    class Meta:
        ordering = ("client", "exercise", "-achieved_on")
        indexes = [models.Index(fields=["client", "exercise", "kind"])]

    def __str__(self):
        return f"{self.client} · {self.exercise} · {self.label}"

    @property
    def value(self):
        return {"weight": self.weight_kg, "reps": self.reps, "time": self.duration_s, "distance": self.distance_km}[self.kind]

    @property
    def label(self):
        if self.kind == self.Kind.TIME:
            return f"{self.duration_s} s"
        if self.kind == self.Kind.DISTANCE:
            return f"{self.distance_km} km"
        w = f"{self.weight_kg.normalize():f} kg" if self.weight_kg is not None else "BW"
        return w + (f" × {self.reps}" if self.reps else "")
