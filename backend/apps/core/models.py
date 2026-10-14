from django.db import models


class TimeStampedModel(models.Model):
    """created_at / updated_at on every table."""

    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
        ordering = ("-created_at",)


class OrderedModel(models.Model):
    """Rows the user can drag to reorder (exercises in a workout, questions in a form ...)."""

    position = models.PositiveIntegerField(default=0, db_index=True)

    class Meta:
        abstract = True
        ordering = ("position", "id")
