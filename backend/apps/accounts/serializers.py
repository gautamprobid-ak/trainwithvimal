from django.contrib.auth import authenticate, password_validation
from django.db import transaction
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from .models import DeviceToken, InviteLink, User


def tokens_for(user):
    refresh = RefreshToken.for_user(user)
    refresh["role"] = user.role
    return {"refresh": str(refresh), "access": str(refresh.access_token)}


class UserSerializer(serializers.ModelSerializer):
    initials = serializers.CharField(read_only=True)
    client_profile_id = serializers.SerializerMethodField()
    trainer_profile_id = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            "id", "email", "full_name", "initials", "role", "phone", "country_code", "avatar", "avatar_url",
            "avatar_color", "email_verified", "onboarded", "push_enabled", "camera_allowed", "photos_allowed",
            "whatsapp_enabled", "email_updates", "units", "language", "last_active_at", "date_joined",
            "client_profile_id", "trainer_profile_id",
        )
        read_only_fields = ("id", "email", "role", "email_verified", "last_active_at", "date_joined")

    def get_client_profile_id(self, obj):
        cp = getattr(obj, "client_profile", None)
        return cp.id if cp else None

    def get_trainer_profile_id(self, obj):
        tp = getattr(obj, "trainer_profile", None)
        return tp.id if tp else None


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        user = authenticate(self.context.get("request"), email=attrs["email"].lower(), password=attrs["password"])
        if user is None:
            raise serializers.ValidationError({"detail": "Email or password is wrong"})
        if not user.is_active:
            raise serializers.ValidationError({"detail": "This account is turned off. Ask your coach."})
        attrs["user"] = user
        return attrs


class InvitePublicSerializer(serializers.ModelSerializer):
    """What the join screen needs before sign-up."""

    state = serializers.CharField(read_only=True)
    trainer_name = serializers.CharField(source="trainer.user.full_name", default=None, read_only=True)
    trainer_first_name = serializers.SerializerMethodField()

    class Meta:
        model = InviteLink
        fields = ("code", "state", "trainer_name", "trainer_first_name", "expires_at", "max_uses", "plan", "requires_approval")

    def get_trainer_first_name(self, obj):
        return obj.trainer.user.first_name_display if obj.trainer else "your coach"


class InviteLinkSerializer(serializers.ModelSerializer):
    state = serializers.CharField(read_only=True)
    trainer_name = serializers.CharField(source="trainer.user.full_name", default=None, read_only=True)
    url = serializers.SerializerMethodField()

    class Meta:
        model = InviteLink
        fields = (
            "id", "code", "label", "trainer", "trainer_name", "valid_days", "expires_at", "max_uses", "plan",
            "requires_approval", "status", "state", "joined_count", "pending_count", "url", "created_at",
        )
        read_only_fields = ("expires_at", "joined_count", "pending_count", "created_at")

    def get_url(self, obj):
        return f"trainwithvimal.app/join/{obj.code}"

    def create(self, data):
        if data.get("valid_days"):
            data["expires_at"] = timezone.now() + timezone.timedelta(days=data["valid_days"])
        data["created_by"] = self.context["request"].user
        return super().create(data)


class RegisterSerializer(serializers.Serializer):
    """Sign up from an invite link (Client · Join from a link)."""

    code = serializers.CharField()
    full_name = serializers.CharField(max_length=120)
    email = serializers.EmailField()
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    password = serializers.CharField(write_only=True)

    def validate_email(self, v):
        v = v.lower()
        if User.objects.filter(email=v).exists():
            raise serializers.ValidationError("This email already has an account")
        return v

    def validate_password(self, v):
        password_validation.validate_password(v)
        return v

    def validate(self, attrs):
        invite = InviteLink.objects.select_related("trainer__user").filter(code__iexact=attrs["code"]).first()
        if invite is None:
            raise serializers.ValidationError({"code": "This invite link doesn’t exist"})
        msgs = {"expired": "This invite has expired", "off": "This invite was turned off", "full": "This invite is full"}
        if invite.state != "on":
            raise serializers.ValidationError({"code": msgs[invite.state]})
        attrs["invite"] = invite
        return attrs

    @transaction.atomic
    def create(self, data):
        from apps.people.models import ClientProfile

        invite = data["invite"]
        user = User.objects.create_user(
            email=data["email"], password=data["password"], full_name=data["full_name"], phone=data.get("phone", ""), role=User.Role.CLIENT
        )
        ClientProfile.objects.create(
            user=user,
            trainer=invite.trainer,
            invite_link=invite,
            plan=invite.plan,
            status=ClientProfile.Status.PENDING if invite.requires_approval else ClientProfile.Status.ACTIVE,
        )
        if invite.requires_approval:
            invite.pending_count += 1
        else:
            invite.joined_count += 1
        invite.save(update_fields=["pending_count", "joined_count"])
        return user


class EmailSerializer(serializers.Serializer):
    email = serializers.EmailField()


class TokenSerializer(serializers.Serializer):
    token = serializers.CharField()


class ResetPasswordSerializer(TokenSerializer):
    password = serializers.CharField(write_only=True)

    def validate_password(self, v):
        password_validation.validate_password(v)
        return v


class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True)

    def validate_current_password(self, v):
        if not self.context["request"].user.check_password(v):
            raise serializers.ValidationError("Current password is wrong")
        return v

    def validate_new_password(self, v):
        password_validation.validate_password(v, self.context["request"].user)
        return v


class DeviceTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = ("id", "token", "platform", "active", "last_seen_at")
        read_only_fields = ("active", "last_seen_at")
