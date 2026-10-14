"""Coaches and clients.

Screens: Admin · Trainers / Trainer profile, Admin · Clients / Client profile,
Trainer · My clients / Client profile / My profile, Client · About / More.
Other apps hang client data off ClientProfile (FK `client`).
"""
from django.conf import settings
from django.db import models

from apps.core.models import TimeStampedModel


class TrainerProfile(TimeStampedModel):
    class Access(models.TextChoices):
        ASSIGNED = "assigned", "Assigned clients"
        ALL = "all", "All clients"
        CUSTOM = "custom", "Custom"

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

    class Meta:
        ordering = ("user__full_name",)

    def __str__(self):
        return self.user.full_name

    @property
    def client_count(self):
        return self.clients.exclude(status=ClientProfile.Status.ARCHIVED).count()


class ClientProfile(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACTIVE = "active", "Active"
        AT_RISK = "at_risk", "At risk"
        PAUSED = "paused", "Paused"
        ARCHIVED = "archived", "Archived"

    class Goal(models.TextChoices):
        FAT_LOSS = "fat_loss", "Fat loss"
        MUSCLE_GAIN = "muscle_gain", "Muscle gain"
        STRENGTH = "strength", "Strength"
        RECOMP = "recomp", "Recomp"
        GENERAL = "general", "General fitness"

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="client_profile")
    trainer = models.ForeignKey(TrainerProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name="clients")
    invite_link = models.ForeignKey("accounts.InviteLink", on_delete=models.SET_NULL, null=True, blank=True, related_name="clients")
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING, db_index=True)
    goal = models.CharField(max_length=12, choices=Goal.choices, default=Goal.GENERAL)
    plan = models.CharField(max_length=60, blank=True, help_text="Membership plan, e.g. Quarterly plan")
    plan_ends_on = models.DateField(null=True, blank=True)
    joined_on = models.DateField(null=True, blank=True)
    paused_until = models.DateField(null=True, blank=True)
    adherence = models.PositiveSmallIntegerField(null=True, blank=True, help_text="0–100, recalculated nightly")

    class Meta:
        ordering = ("user__full_name",)

    def __str__(self):
        return self.user.full_name
