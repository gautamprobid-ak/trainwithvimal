"""Scheduling: sessions on the admin / trainer calendars and trainer working hours."""
import datetime as dt

from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


class CalendarEvent(TimeStampedModel):
    class Kind(models.TextChoices):
        SESSION = "session", "1:1 session"  # k-ss, 60 min
        CALL = "call", "Quick call"  # k-qc, 15 min
        REVIEW = "review", "Program review"  # k-rv, 30 min
        SCAN = "scan", "Body scan"  # k-bs, 20 min (parked in the design)

    class Status(models.TextChoices):
        BOOKED = "booked", "Booked"
        DONE = "done", "Done"
        MISSED = "missed", "Missed"
        CANCELLED = "cancelled", "Cancelled"

    class Where(models.TextChoices):
        IN_PERSON = "person", "In person"
        CALL = "call", "Call"

    DEFAULT_MINUTES = {"session": 60, "call": 15, "review": 30, "scan": 20}
    CSS = {"session": "k-ss", "call": "k-qc", "review": "k-rv", "scan": "k-bs"}

    ref = models.CharField(max_length=40, blank=True, db_index=True, help_text="External / seed id (s1 … s20)")
    kind = models.CharField(max_length=8, choices=Kind.choices, default=Kind.SESSION, db_index=True)
    title = models.CharField(max_length=120, blank=True, help_text="What the session is, e.g. 'Push A' or 'Form check'")
    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, null=True, blank=True, related_name="events")
    trainer = models.ForeignKey("people.TrainerProfile", on_delete=models.CASCADE, related_name="events")
    start = models.DateTimeField(db_index=True)
    end = models.DateTimeField()
    where = models.CharField(max_length=6, choices=Where.choices, default=Where.IN_PERSON)
    location = models.CharField(max_length=120, blank=True, help_text="'Andheri gym floor', 'Yoga room'")
    online_link = models.URLField(blank=True, help_text="Call link, e.g. https://meet.google.com/abc-defg-hij")
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.BOOKED, db_index=True)
    notes = models.TextField(blank=True)
    booked_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    notify_client = models.BooleanField(default=True, help_text="'Tell the client'")
    recurrence_rule = models.CharField(max_length=200, blank=True, help_text="RFC 5545 RRULE, e.g. FREQ=WEEKLY;BYDAY=MO,WE")
    completed_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancel_reason = models.CharField(max_length=200, blank=True)
    reminder_sent_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("start", "id")
        indexes = [models.Index(fields=["trainer", "start"]), models.Index(fields=["client", "start"])]

    def __str__(self):
        return f"{self.get_kind_display()} · {self.client or '—'} · {self.start:%d %b %H:%M}"

    @property
    def minutes(self):
        return int((self.end - self.start).total_seconds() // 60)

    @property
    def css(self):
        return self.CSS.get(self.kind, "")

    def clashes(self, qs=None):
        qs = qs if qs is not None else CalendarEvent.objects.all()
        qs = qs.filter(trainer_id=self.trainer_id, start__lt=self.end, end__gt=self.start).exclude(status=self.Status.CANCELLED)
        if self.pk:
            qs = qs.exclude(pk=self.pk)
        return qs


class Availability(TimeStampedModel):
    """Trainer working hours per weekday ('My working hours' / Availability drawer)."""

    class Weekday(models.IntegerChoices):
        MON = 0, "Monday"
        TUE = 1, "Tuesday"
        WED = 2, "Wednesday"
        THU = 3, "Thursday"
        FRI = 4, "Friday"
        SAT = 5, "Saturday"
        SUN = 6, "Sunday"

    trainer = models.ForeignKey("people.TrainerProfile", on_delete=models.CASCADE, related_name="availability")
    weekday = models.PositiveSmallIntegerField(choices=Weekday.choices)
    is_working = models.BooleanField(default=True, help_text="False = day off")
    start_time = models.TimeField(default=dt.time(7, 0))
    end_time = models.TimeField(default=dt.time(21, 0))

    # Design default for trainers without their own hours: Mon–Fri 7 am – 9 pm, Sat 8 am – 2 pm, Sun off.
    DEFAULT = [(True, dt.time(7), dt.time(21))] * 5 + [(True, dt.time(8), dt.time(14)), (False, None, None)]

    class Meta:
        ordering = ("trainer", "weekday")
        constraints = [models.UniqueConstraint(fields=["trainer", "weekday"], name="uniq_trainer_weekday")]
        verbose_name_plural = "availability"

    def __str__(self):
        return f"{self.trainer} · {self.get_weekday_display()}"

    @classmethod
    def for_day(cls, trainer_id, weekday):
        """(working, start, end) for a trainer on a weekday, falling back to the default week."""
        row = cls.objects.filter(trainer_id=trainer_id, weekday=weekday).first()
        if row:
            return row.is_working, row.start_time, row.end_time
        return cls.DEFAULT[weekday]
