"""One place to notify a user: stored in-app notification + push to their devices."""
from apps.core.services.firebase import send_push


def notify(user, title, body="", kind="info", link="", data=None, push=True):
    from apps.engage.models import Notification

    n = Notification.objects.create(user=user, title=title, body=body, kind=kind, link=link)
    if push and getattr(user, "push_enabled", True):
        tokens = list(user.devices.filter(active=True).values_list("token", flat=True))
        send_push(tokens, title, body, {"link": link, "kind": kind, "notification_id": n.id, **(data or {})})
    return n
