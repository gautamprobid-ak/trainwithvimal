from django.apps import AppConfig


class PeopleConfig(AppConfig):
    name = "apps.people"
    label = "people"

    def ready(self):
        from . import signals  # noqa: F401
