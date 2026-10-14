from django.conf import settings
from django.core.mail import send_mail

from .models import OneTimeLink

_COPY = {
    OneTimeLink.Purpose.VERIFY_EMAIL: ("Verify your email", "verify-email", "Tap the link to verify your email and finish setting up your account"),
    OneTimeLink.Purpose.RESET_PASSWORD: ("Set a new password", "reset-password", "Tap the link to set a new password. It works for 1 hour"),
    OneTimeLink.Purpose.LOGIN: ("Your log-in link", "login-link", "Tap the link to log in. It works for 30 minutes"),
}


def send_link(user, purpose):
    """Create a one-time link and email it. Older unused links of the same purpose stop working."""
    OneTimeLink.objects.filter(user=user, purpose=purpose, used_at__isnull=True).delete()
    link = OneTimeLink.objects.create(user=user, purpose=purpose)
    subject, route, line = _COPY[purpose]
    url = f"{settings.APP_LINK_BASE}/{route}?token={link.token}"
    send_mail(
        f"Train With Vimal · {subject}",
        f"Hi {user.first_name_display},\n\n{line}:\n{url}\n\nIf you didn’t ask for this, you can ignore this email.\n\n— Train With Vimal",
        settings.DEFAULT_FROM_EMAIL,
        [user.email],
    )
    return link
