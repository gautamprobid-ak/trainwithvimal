"""Background jobs for engage (Celery beat: see CELERY_BEAT_SCHEDULE in settings)."""
from celery import shared_task


@shared_task(name="apps.engage.tasks.run_due_automations")
def run_due_automations():
    """Evaluate enabled automations' triggers and run every step that is due."""
    from .engine import run_due

    return run_due()
