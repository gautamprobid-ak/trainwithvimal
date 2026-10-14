"""Activity log helper (Admin · Activity log screen)."""


def log_activity(actor, verb, target="", client=None, category="general", meta=None):
    from apps.engage.models import ActivityLog

    return ActivityLog.objects.create(
        actor=actor if actor and actor.is_authenticated else None,
        verb=verb,
        target=target,
        client=client,
        category=category,
        meta=meta or {},
    )
