from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken

from apps.core.permissions import IsStaff, role_of
from apps.core.services.activity import log_activity

from .emails import send_link
from .models import DeviceToken, InviteLink, OneTimeLink, User
from .serializers import (
    ChangePasswordSerializer, DeviceTokenSerializer, EmailSerializer, InviteLinkSerializer, InvitePublicSerializer,
    LoginSerializer, RegisterSerializer, ResetPasswordSerializer, TokenSerializer, UserSerializer, tokens_for,
)


def _session_payload(user, request):
    return {**tokens_for(user), "user": UserSerializer(user, context={"request": request}).data}


class PublicView(APIView):
    permission_classes = [AllowAny]
    throttle_scope = "auth"


class LoginView(PublicView):
    @extend_schema(request=LoginSerializer)
    def post(self, request):
        s = LoginSerializer(data=request.data, context={"request": request})
        s.is_valid(raise_exception=True)
        user = s.validated_data["user"]
        User.objects.filter(pk=user.pk).update(last_active_at=timezone.now())
        return Response(_session_payload(user, request))


class LogoutView(APIView):
    def post(self, request):
        try:
            RefreshToken(request.data.get("refresh", "")).blacklist()
        except TokenError:
            pass
        token = request.data.get("device_token")
        if token:
            DeviceToken.objects.filter(user=request.user, token=token).update(active=False)
        return Response(status=status.HTTP_204_NO_CONTENT)


class InviteLookupView(PublicView):
    """GET /auth/invites/<code>/ — the join screen checks the link first."""

    def get(self, request, code):
        invite = InviteLink.objects.select_related("trainer__user").filter(code__iexact=code).first()
        if invite is None:
            return Response({"detail": "This invite link doesn’t exist"}, status=404)
        return Response(InvitePublicSerializer(invite).data)


class RegisterView(PublicView):
    @extend_schema(request=RegisterSerializer)
    def post(self, request):
        s = RegisterSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        user = s.save()
        send_link(user, OneTimeLink.Purpose.VERIFY_EMAIL)
        log_activity(user, "joined from invite", s.validated_data["invite"].code, client=user.client_profile, category="clients")
        return Response(_session_payload(user, request), status=201)


class SendVerifyEmailView(APIView):
    def post(self, request):
        if request.user.email_verified:
            return Response({"detail": "Email already verified"})
        send_link(request.user, OneTimeLink.Purpose.VERIFY_EMAIL)
        return Response({"detail": f"A new link went to {request.user.email}"})


def _use_link(token, purpose):
    link = OneTimeLink.objects.select_related("user").filter(token=token, purpose=purpose).first()
    if link is None or not link.is_valid:
        return None
    link.used_at = timezone.now()
    link.save(update_fields=["used_at"])
    return link.user


class ConfirmEmailView(PublicView):
    @extend_schema(request=TokenSerializer)
    def post(self, request):
        s = TokenSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        user = _use_link(s.validated_data["token"], OneTimeLink.Purpose.VERIFY_EMAIL)
        if user is None:
            return Response({"detail": "This link has expired. Send the email again."}, status=400)
        user.email_verified, user.email_verified_at = True, timezone.now()
        user.save(update_fields=["email_verified", "email_verified_at"])
        return Response(_session_payload(user, request))


class ForgotPasswordView(PublicView):
    """Always answers the same, so the screen never reveals who has an account."""

    @extend_schema(request=EmailSerializer)
    def post(self, request):
        s = EmailSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        user = User.objects.filter(email=s.validated_data["email"].lower(), is_active=True).first()
        if user:
            send_link(user, OneTimeLink.Purpose.RESET_PASSWORD)
        return Response({"detail": "If this email has an account, a reset link is on its way"})


class ResetPasswordView(PublicView):
    @extend_schema(request=ResetPasswordSerializer)
    def post(self, request):
        s = ResetPasswordSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        user = _use_link(s.validated_data["token"], OneTimeLink.Purpose.RESET_PASSWORD)
        if user is None:
            return Response({"detail": "This link has expired. Ask for a new one."}, status=400)
        user.set_password(s.validated_data["password"])
        user.save(update_fields=["password"])
        return Response(_session_payload(user, request))


class LoginLinkView(PublicView):
    @extend_schema(request=EmailSerializer)
    def post(self, request):
        s = EmailSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        user = User.objects.filter(email=s.validated_data["email"].lower(), is_active=True).first()
        if user:
            send_link(user, OneTimeLink.Purpose.LOGIN)
        return Response({"detail": "If this email has an account, a log-in link is on its way"})


class LoginLinkConfirmView(PublicView):
    @extend_schema(request=TokenSerializer)
    def post(self, request):
        s = TokenSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        user = _use_link(s.validated_data["token"], OneTimeLink.Purpose.LOGIN)
        if user is None:
            return Response({"detail": "This log-in link has expired"}, status=400)
        if not user.email_verified:
            user.email_verified, user.email_verified_at = True, timezone.now()
            user.save(update_fields=["email_verified", "email_verified_at"])
        return Response(_session_payload(user, request))


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user


class CompleteOnboardingView(APIView):
    def post(self, request):
        request.user.onboarded = True
        request.user.save(update_fields=["onboarded"])
        return Response(UserSerializer(request.user, context={"request": request}).data)


class ChangePasswordView(APIView):
    @extend_schema(request=ChangePasswordSerializer)
    def post(self, request):
        s = ChangePasswordSerializer(data=request.data, context={"request": request})
        s.is_valid(raise_exception=True)
        request.user.set_password(s.validated_data["new_password"])
        request.user.save(update_fields=["password"])
        return Response({"detail": "Password changed"})


class DeviceTokenViewSet(viewsets.ModelViewSet):
    """Register this phone for push notifications (POST after the Permissions screen)."""

    serializer_class = DeviceTokenSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return DeviceToken.objects.filter(user=self.request.user)

    def create(self, request, *args, **kwargs):
        s = self.get_serializer(data=request.data)
        s.is_valid(raise_exception=True)
        obj, _ = DeviceToken.objects.update_or_create(
            token=s.validated_data["token"],
            defaults={"user": request.user, "platform": s.validated_data["platform"], "active": True},
        )
        return Response(self.get_serializer(obj).data, status=201)


class InviteLinkViewSet(viewsets.ModelViewSet):
    """Admin · Clients → Invite links. Trainers only see / make their own links."""

    serializer_class = InviteLinkSerializer
    permission_classes = [IsStaff]
    search_fields = ("code", "label")
    filterset_fields = ("status", "trainer")

    def get_queryset(self):
        qs = InviteLink.objects.select_related("trainer__user")
        if role_of(self.request.user) == "trainer":
            qs = qs.filter(trainer__user=self.request.user)
        return qs

    @action(detail=True, methods=["post"])
    def turn_off(self, request, pk=None):
        link = self.get_object()
        link.status = InviteLink.Status.OFF
        link.save(update_fields=["status"])
        return Response(self.get_serializer(link).data)

    @action(detail=True, methods=["post"])
    def turn_on(self, request, pk=None):
        link = self.get_object()
        link.status = InviteLink.Status.ON
        link.save(update_fields=["status"])
        return Response(self.get_serializer(link).data)
