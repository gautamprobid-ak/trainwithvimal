"""Session reminders: 'Session reminders · 30 minutes before each session' (trainer) and
'Workout reminders · 1 hour before your session' (client)."""
import datetime as dt

from celery import shared_task
from django.utils import timezone


@shared_task(name="apps.scheduling.tasks.send_session_reminders")
def send_session_reminders():
    from apps.core.services.notify import notify
    from apps.engage.models import NotificationSettings

    from .models import CalendarEvent

    now = timezone.now()
    events = CalendarEvent.objects.select_related("client__user", "trainer__user").filter(
        status=CalendarEvent.Status.BOOKED, reminder_sent_at__isnull=True, start__gt=now, start__lte=now + dt.timedelta(hours=1))
    sent = 0
    for ev in events:
        when = timezone.localtime(ev.start).strftime("%-I:%M %p").lower()
        place = ev.location or ("Call" if ev.where == "call" else "")
        if ev.client_id and NotificationSettings.for_user(ev.client.user).wants("workout"):
            notify(ev.client.user, f"Session today at {when}", f"With {ev.trainer.user.first_name_display} · {place} · {ev.minutes} min",
                   kind="session", link="/c/train")
            sent += 1
        if NotificationSettings.for_user(ev.trainer.user).wants("sess"):
            notify(ev.trainer.user, f"{ev.get_kind_display()} at {when}", ev.client.user.full_name if ev.client_id else ev.title,
                   kind="session", link="/t/calendar")
            sent += 1
        ev.reminder_sent_at = now
        ev.save(update_fields=["reminder_sent_at"])
    return sent
