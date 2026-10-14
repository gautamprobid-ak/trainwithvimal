"""Users, sign-in links and devices.

Screens: Client · Welcome / Log in / Join from a link / Verify email /
Forgot & set new password / Permissions; Admin · Clients (invite links).
"""
import secrets
from datetime import timedelta

from django.contrib.auth.base_user import BaseUserManager
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone

from apps.core.models import TimeStampedModel


class UserManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, email, password, **extra):
        if not email:
            raise ValueError("Email is required")
        user = self.model(email=self.normalize_email(email).lower(), **extra)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, **extra):
        extra.setdefault("is_staff", False)
        extra.setdefault("is_superuser", False)
        return self._create_user(email, password, **extra)

    def create_superuser(self, email, password=None, **extra):
        extra.update(is_staff=True, is_superuser=True, role=User.Role.ADMIN)
        return self._create_user(email, password, **extra)


class User(AbstractUser):
    """Everyone who signs in. Email is the login."""

    class Role(models.TextChoices):
        ADMIN = "admin", "Admin"
        TRAINER = "trainer", "Trainer"
        CLIENT = "client", "Client"

    class AvatarColor(models.TextChoices):
        C1 = "c1"
        C2 = "c2"
        C3 = "c3"
        C4 = "c4"
        C5 = "c5"
        C6 = "c6"

    username = None
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=120)
    role = models.CharField(max_length=10, choices=Role.choices, default=Role.CLIENT, db_index=True)
    phone = models.CharField(max_length=20, blank=True)
    country_code = models.CharField(max_length=6, default="+91")
    avatar = models.ImageField(upload_to="avatars/", blank=True)
    avatar_url = models.URLField(blank=True, help_text="Firebase Storage URL when used")
    avatar_color = models.CharField(max_length=2, choices=AvatarColor.choices, default=AvatarColor.C1)
    email_verified = models.BooleanField(default=False)
    email_verified_at = models.DateTimeField(null=True, blank=True)
    onboarded = models.BooleanField(default=False, help_text="Finished welcome / setup steps")
    last_active_at = models.DateTimeField(null=True, blank=True)

    # Permissions screen (notifications, camera, photos) + notification prefs (Client · More)
    push_enabled = models.BooleanField(default=True)
    camera_allowed = models.BooleanField(default=False)
    photos_allowed = models.BooleanField(default=False)
    whatsapp_enabled = models.BooleanField(default=True)
    email_updates = models.BooleanField(default=True)
    units = models.CharField(max_length=10, choices=[("metric", "kg, cm"), ("imperial", "lb, in")], default="metric")
    language = models.CharField(max_length=10, default="en")

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["full_name"]

    objects = UserManager()

    class Meta:
        ordering = ("full_name",)

    def __str__(self):
        return f"{self.full_name} <{self.email}>"

    @property
    def initials(self):
        parts = self.full_name.split()
        if not parts:
            return "?"
        return (parts[0][0] + parts[-1][0]).upper() if len(parts) > 1 else parts[0][0].upper()

    @property
    def first_name_display(self):
        return self.full_name.split()[0] if self.full_name else ""


def _token():
    return secrets.token_urlsafe(32)


class OneTimeLink(TimeStampedModel):
    """Email links: verify email, reset password, magic log-in link."""

    class Purpose(models.TextChoices):
        VERIFY_EMAIL = "verify", "Verify email"
        RESET_PASSWORD = "reset", "Reset password"
        LOGIN = "login", "Log-in link"

    LIFETIME = {Purpose.VERIFY_EMAIL: timedelta(days=2), Purpose.RESET_PASSWORD: timedelta(hours=1), Purpose.LOGIN: timedelta(minutes=30)}

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="links")
    purpose = models.CharField(max_length=10, choices=Purpose.choices)
    token = models.CharField(max_length=64, unique=True, default=_token)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
    sent_to = models.EmailField()

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + self.LIFETIME[self.purpose]
        if not self.sent_to:
            self.sent_to = self.user.email
        super().save(*args, **kwargs)

    @property
    def is_valid(self):
        return self.used_at is None and self.expires_at > timezone.now()


class InviteLink(TimeStampedModel):
    """Join links coaches share ("trainwithvimal.app/join/AMAN-4821").

    A link can expire, be turned off, or be full — the join screen shows each case.
    """

    class Status(models.TextChoices):
        ON = "on", "On"
        OFF = "off", "Off"
        ENDED = "end", "Ended"

    code = models.CharField(max_length=32, unique=True)
    label = models.CharField(max_length=80, blank=True)
    trainer = models.ForeignKey("people.TrainerProfile", on_delete=models.SET_NULL, null=True, blank=True, related_name="invite_links")
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="+")
    valid_days = models.PositiveIntegerField(null=True, blank=True, help_text="Empty = never expires")
    expires_at = models.DateTimeField(null=True, blank=True)
    max_uses = models.PositiveIntegerField(null=True, blank=True, help_text="Empty = no limit")
    plan = models.CharField(max_length=60, blank=True, help_text="e.g. Quarterly plan")
    requires_approval = models.BooleanField(default=True, help_text="New clients go to Approvals first")
    status = models.CharField(max_length=4, choices=Status.choices, default=Status.ON)
    joined_count = models.PositiveIntegerField(default=0)
    pending_count = models.PositiveIntegerField(default=0)

    def __str__(self):
        return self.code

    @property
    def state(self):
        """on / off / expired / full — what the join screen shows."""
        if self.status != self.Status.ON:
            return "off" if self.status == self.Status.OFF else "expired"
        if self.expires_at and self.expires_at <= timezone.now():
            return "expired"
        if self.max_uses and self.joined_count + self.pending_count >= self.max_uses:
            return "full"
        return "on"


class DeviceToken(TimeStampedModel):
    """FCM token of a phone / browser, for push notifications."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="devices")
    token = models.CharField(max_length=512, unique=True)
    platform = models.CharField(max_length=10, choices=[("android", "Android"), ("ios", "iOS"), ("web", "Web")])
    active = models.BooleanField(default=True)
    last_seen_at = models.DateTimeField(auto_now=True)
