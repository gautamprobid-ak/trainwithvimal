"""Firebase integration: push notifications (FCM) and optional file storage.

Configure with FIREBASE_CREDENTIALS (service-account JSON path) and, for
storage, FIREBASE_STORAGE_BUCKET. Without credentials, pushes are logged so
local development works without a Firebase project.
"""
import logging
from functools import lru_cache

from django.conf import settings

log = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def _app():
    if not settings.FIREBASE_CREDENTIALS:
        return None
    import firebase_admin
    from firebase_admin import credentials

    options = {"storageBucket": settings.FIREBASE_STORAGE_BUCKET} if settings.FIREBASE_STORAGE_BUCKET else None
    return firebase_admin.initialize_app(credentials.Certificate(settings.FIREBASE_CREDENTIALS), options)


def send_push(tokens, title, body, data=None):
    """Send one notification to many device tokens. Returns the number delivered.

    Tokens that FCM reports as unregistered are deactivated.
    """
    tokens = [t for t in tokens if t]
    if not tokens:
        return 0
    app = _app()
    if app is None:
        log.info("[push:dev] %s — %s → %d device(s) %s", title, body, len(tokens), data or {})
        return len(tokens)

    from firebase_admin import messaging

    message = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in (data or {}).items()},
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(payload=messaging.APNSPayload(aps=messaging.Aps(sound="default"))),
    )
    resp = messaging.send_each_for_multicast(message, app=app)
    dead = [tokens[i] for i, r in enumerate(resp.responses) if not r.success and _is_unregistered(r.exception)]
    if dead:
        from apps.accounts.models import DeviceToken

        DeviceToken.objects.filter(token__in=dead).update(active=False)
    return resp.success_count


def _is_unregistered(exc):
    return exc is not None and exc.__class__.__name__ in {"UnregisteredError", "SenderIdMismatchError"}


def upload_file(fileobj, path, content_type=None):
    """Upload to Firebase Storage and return a public URL, or None when storage is not configured."""
    app = _app()
    if app is None or not settings.FIREBASE_STORAGE_BUCKET:
        return None
    from firebase_admin import storage

    blob = storage.bucket(app=app).blob(path)
    blob.upload_from_file(fileobj, content_type=content_type)
    blob.make_public()
    return blob.public_url
