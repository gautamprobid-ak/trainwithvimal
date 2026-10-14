"""Role-based access used by every app.

Roles (accounts.User.role): admin (owner / head coach), trainer, client.
- Admins see everything.
- Trainers see their own clients (or all clients when their access is "all").
- Clients see only their own data.
"""
from rest_framework.permissions import SAFE_METHODS, BasePermission


def role_of(user):
    return getattr(user, "role", None) if user and user.is_authenticated else None


class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        return role_of(request.user) == "admin"


class IsTrainer(BasePermission):
    def has_permission(self, request, view):
        return role_of(request.user) == "trainer"


class IsClient(BasePermission):
    def has_permission(self, request, view):
        return role_of(request.user) == "client"


class IsStaff(BasePermission):
    """Admin or trainer — the coaching team."""

    def has_permission(self, request, view):
        return role_of(request.user) in {"admin", "trainer"}


class StaffWriteOrReadOnly(BasePermission):
    """Anyone signed in can read (e.g. the exercise library); only the team can write."""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.method in SAFE_METHODS or role_of(request.user) in {"admin", "trainer"}


def visible_client_ids(user):
    """ClientProfile ids this user may see, or None for "all"."""
    from apps.people.models import ClientProfile

    role = role_of(user)
    if role == "admin":
        return None
    if role == "trainer":
        tp = getattr(user, "trainer_profile", None)
        if tp is not None and tp.access == "all":
            return None
        return list(ClientProfile.objects.filter(trainer__user=user).values_list("id", flat=True))
    if role == "client":
        cp = getattr(user, "client_profile", None)
        return [cp.id] if cp else []
    return []


class ClientScopedQuerysetMixin:
    """For viewsets whose model has a `client` FK to people.ClientProfile.

    Filters the queryset to what the user may see and supports ?client=<id>.
    For clients, `perform_create` attaches their own profile automatically.
    """

    client_field = "client"

    def scope_queryset(self, qs):
        ids = visible_client_ids(self.request.user)
        if ids is not None:
            qs = qs.filter(**{f"{self.client_field}__in": ids})
        client = self.request.query_params.get("client")
        if client:
            qs = qs.filter(**{self.client_field: client})
        return qs

    def get_queryset(self):
        return self.scope_queryset(super().get_queryset())

    def perform_create(self, serializer):
        user = self.request.user
        if role_of(user) == "client":
            serializer.save(**{self.client_field: user.client_profile})
        else:
            serializer.save()
