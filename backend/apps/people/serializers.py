from django.contrib.auth import get_user_model
from django.db import transaction
from django.utils import timezone
from rest_framework import serializers

from .models import (
    AccessRequest,
    ApprovalRequest,
    ClientNote,
    ClientNudge,
    ClientProfile,
    HealthIssue,
    InfoRequest,
    TrainerAvailability,
    TrainerChange,
    TrainerDocument,
    TrainerProfile,
)

User = get_user_model()


def person(user):
    if user is None:
        return None
    return {"id": user.id, "name": user.full_name, "initials": user.initials, "avatar_color": user.avatar_color}


# ─────────────────────────────────────────────── trainers


class TrainerMiniSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="user.full_name", read_only=True)
    initials = serializers.CharField(source="user.initials", read_only=True)
    avatar_color = serializers.CharField(source="user.avatar_color", read_only=True)
    client_count = serializers.IntegerField(read_only=True)
    is_full = serializers.BooleanField(read_only=True)

    class Meta:
        model = TrainerProfile
        fields = ("id", "name", "initials", "avatar_color", "focus", "rating", "client_count", "capacity", "is_full", "active")


class TrainerDocumentSerializer(serializers.ModelSerializer):
    expires_in_days = serializers.IntegerField(read_only=True)
    expiring = serializers.BooleanField(read_only=True)
    uploaded_by_name = serializers.CharField(source="uploaded_by.full_name", read_only=True, default="")

    class Meta:
        model = TrainerDocument
        fields = (
            "id", "trainer", "name", "issuer", "kind", "issued_on", "valid_till", "status", "clients_see", "file", "file_url",
            "file_name", "file_type", "size_bytes", "uploaded_by", "uploaded_by_name", "uploaded_at", "verified_by", "verified_at",
            "expires_in_days", "expiring",
        )
        read_only_fields = ("uploaded_by", "uploaded_at", "verified_by", "verified_at")


class TrainerAvailabilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = TrainerAvailability
        fields = ("id", "trainer", "weekday", "is_working", "start_minute", "end_minute")


class TrainerSerializer(serializers.ModelSerializer):
    """List + detail. Writes create/update the linked user too (Add trainer / Edit details)."""

    full_name = serializers.CharField(source="user.full_name")
    email = serializers.EmailField(source="user.email")
    phone = serializers.CharField(source="user.phone", required=False, allow_blank=True)
    initials = serializers.CharField(source="user.initials", read_only=True)
    avatar_color = serializers.CharField(source="user.avatar_color", required=False)
    last_active_at = serializers.DateTimeField(source="user.last_active_at", read_only=True)
    client_count = serializers.IntegerField(read_only=True)
    is_full = serializers.BooleanField(read_only=True)
    experience_years = serializers.IntegerField(read_only=True)
    pending_checkins = serializers.SerializerMethodField()
    send_invite = serializers.BooleanField(write_only=True, required=False, default=True)

    class Meta:
        model = TrainerProfile
        fields = (
            "id", "user", "full_name", "email", "phone", "initials", "avatar_color", "last_active_at", "title", "focus", "bio",
            "short_bio", "gender", "specialities", "experience_since", "experience_years", "trains_mode", "languages", "best_with",
            "socials", "rating", "adherence", "avg_reply_hours", "capacity", "client_count", "is_full", "access", "permissions",
            "client_view", "notification_prefs", "is_owner", "active", "started_on", "deactivated_at", "pending_checkins",
            "send_invite", "created_at",
        )
        read_only_fields = ("user", "is_owner", "deactivated_at", "adherence", "avg_reply_hours", "rating")

    def get_pending_checkins(self, obj):
        return self.context.get("pending_checkins", {}).get(obj.id)

    def validate_email(self, v):
        v = v.lower()
        qs = User.objects.filter(email=v)
        if self.instance:
            qs = qs.exclude(pk=self.instance.user_id)
        if qs.exists():
            raise serializers.ValidationError("This email already has an account")
        return v

    @transaction.atomic
    def create(self, data):
        u = data.pop("user")
        send_invite = data.pop("send_invite", True)
        user = User.objects.create_user(email=u["email"], password=None, full_name=u["full_name"], phone=u.get("phone", ""),
                                        avatar_color=u.get("avatar_color", "c1"), role=User.Role.TRAINER)
        if not data.get("started_on"):
            data["started_on"] = timezone.localdate()
        tp = TrainerProfile.objects.create(user=user, **data)
        if send_invite:
            try:
                from apps.accounts.emails import send_link
                from apps.accounts.models import OneTimeLink

                send_link(user, OneTimeLink.Purpose.RESET_PASSWORD)
            except Exception:
                pass
        return tp

    @transaction.atomic
    def update(self, inst, data):
        u = data.pop("user", {})
        data.pop("send_invite", None)
        for k, v in u.items():
            setattr(inst.user, k, v)
        if u:
            inst.user.save()
        return super().update(inst, data)


class TrainerDetailSerializer(TrainerSerializer):
    documents = TrainerDocumentSerializer(many=True, read_only=True)
    availability = TrainerAvailabilitySerializer(many=True, read_only=True)

    class Meta(TrainerSerializer.Meta):
        fields = TrainerSerializer.Meta.fields + ("documents", "availability")


class TrainerSelfSerializer(serializers.ModelSerializer):
    """Trainer · Me — what a trainer may edit about themself."""

    full_name = serializers.CharField(source="user.full_name", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)
    phone = serializers.CharField(source="user.phone", required=False, allow_blank=True)
    client_count = serializers.IntegerField(read_only=True)
    experience_years = serializers.IntegerField(read_only=True)
    documents = TrainerDocumentSerializer(many=True, read_only=True)
    availability = TrainerAvailabilitySerializer(many=True, read_only=True)

    class Meta:
        model = TrainerProfile
        fields = (
            "id", "full_name", "email", "phone", "title", "focus", "bio", "short_bio", "gender", "specialities", "experience_since",
            "experience_years", "trains_mode", "languages", "best_with", "socials", "rating", "adherence", "avg_reply_hours",
            "capacity", "client_count", "access", "permissions", "client_view", "notification_prefs", "started_on",
            "documents", "availability",
        )
        read_only_fields = ("title", "rating", "adherence", "avg_reply_hours", "capacity", "access", "permissions", "started_on")

    def update(self, inst, data):
        u = data.pop("user", {})
        if "phone" in u:
            inst.user.phone = u["phone"]
            inst.user.save(update_fields=["phone"])
        cv = data.get("client_view")
        if cv is not None:
            cv["name"] = True  # always visible
        return super().update(inst, data)


class AccessRequestSerializer(serializers.ModelSerializer):
    trainer_name = serializers.CharField(source="trainer.user.full_name", read_only=True)

    class Meta:
        model = AccessRequest
        fields = ("id", "trainer", "trainer_name", "items", "note", "status", "decided_by", "decided_at", "created_at")
        read_only_fields = ("trainer", "status", "decided_by", "decided_at")


# ─────────────────────────────────────────────── clients


class HealthIssueSerializer(serializers.ModelSerializer):
    class Meta:
        model = HealthIssue
        fields = ("id", "client", "kind", "area", "title", "severity", "status", "since", "until", "notes", "needs_doctor_note", "created_at")
        read_only_fields = ("client",)


class ClientListSerializer(serializers.ModelSerializer):
    user_id = serializers.IntegerField(source="user.id", read_only=True)
    name = serializers.CharField(source="user.full_name", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)
    phone = serializers.SerializerMethodField()
    initials = serializers.CharField(source="user.initials", read_only=True)
    avatar_color = serializers.CharField(source="user.avatar_color", read_only=True)
    last_active_at = serializers.DateTimeField(source="user.last_active_at", read_only=True)
    trainer = TrainerMiniSerializer(read_only=True)
    goal_label = serializers.CharField(source="get_goal_display", read_only=True)
    status_label = serializers.CharField(source="get_status_display", read_only=True)
    onboarding_progress = serializers.IntegerField(read_only=True)
    onboarding_label = serializers.CharField(read_only=True)

    class Meta:
        model = ClientProfile
        fields = (
            "id", "user_id", "name", "email", "phone", "initials", "avatar_color", "trainer", "goal", "goal_label", "status",
            "status_label", "onboarding_progress", "onboarding_label", "joined_on", "next_checkin_on", "last_active_at",
            "adherence", "plan", "plan_ends_on", "paused_until",
        )

    def get_phone(self, obj):
        return f"{obj.user.country_code} {obj.user.phone}".strip() if obj.user.phone else ""


CLIENT_EDITABLE = (
    "gender", "date_of_birth", "city", "source", "emergency_name", "emergency_relation", "emergency_phone", "goal", "goal_detail",
    "height_cm", "start_weight_kg", "current_weight_kg", "target_weight_kg", "target_date", "experience", "train_place",
    "equipment", "training_days", "session_minutes", "preferred_time", "wake_time", "daily_activity", "doctor_cleared",
    "health_notes", "diet", "meals_per_day", "avoid_foods", "allergies", "cooks_at_home", "food_notes", "onboarding_steps",
    "onboarding_answers", "setup_reminder",
)
CLIENT_PREFS = (
    "reminders", "quiet_hours_on", "quiet_from", "quiet_to", "weight_unit", "length_unit", "water_unit", "week_start", "theme",
    "share_photos", "improve_app",
)
STAFF_ONLY = ("status", "plan", "plan_ends_on", "joined_on", "paused_until", "next_checkin_on", "plans_start_on", "adherence")


class ClientDetailSerializer(ClientListSerializer):
    """Full client profile (Edit profile drawer, About card). Staff write."""

    full_name = serializers.CharField(source="user.full_name", required=False)
    phone_number = serializers.CharField(source="user.phone", required=False, allow_blank=True)
    country_code = serializers.CharField(source="user.country_code", required=False)
    new_email = serializers.EmailField(source="user.email", required=False, write_only=True)
    new_password = serializers.CharField(required=False, write_only=True, allow_blank=True, min_length=8)
    trainer_id = serializers.PrimaryKeyRelatedField(source="trainer", queryset=TrainerProfile.objects.all(), required=False, allow_null=True, write_only=True)
    age = serializers.IntegerField(read_only=True)
    weight_change_kg = serializers.DecimalField(max_digits=5, decimal_places=1, read_only=True)
    to_goal_kg = serializers.DecimalField(max_digits=5, decimal_places=1, read_only=True)
    health_issues = HealthIssueSerializer(many=True, read_only=True)
    invite_code = serializers.CharField(source="invite_link.code", read_only=True, default=None)
    last_edited_by = serializers.SerializerMethodField()

    class Meta(ClientListSerializer.Meta):
        fields = ClientListSerializer.Meta.fields + (
            "full_name", "phone_number", "country_code", "new_email", "new_password", "trainer_id", "age", "weight_change_kg",
            "to_goal_kg", "health_issues", "invite_code", "signup_device", "onboarded_at", "approved_at", "paused_at",
            "pause_reason", "archived_at", "plans_start_on", "updated_at", "last_edited_by", "delete_requested_at",
        ) + CLIENT_EDITABLE + CLIENT_PREFS
        read_only_fields = ("onboarded_at", "approved_at", "paused_at", "archived_at", "delete_requested_at")

    def get_last_edited_by(self, obj):
        return person(obj.last_edited_by)

    def validate_new_email(self, v):
        v = v.lower()
        if User.objects.filter(email=v).exclude(pk=self.instance.user_id if self.instance else None).exists():
            raise serializers.ValidationError("This email already has an account")
        return v

    @transaction.atomic
    def update(self, inst, data):
        u = data.pop("user", {})
        pw = data.pop("new_password", "")
        user = inst.user
        email_changed = "email" in u and u["email"] != user.email
        for k, v in u.items():
            setattr(user, k, v)
        if pw:
            user.set_password(pw)
        if email_changed:
            user.email_verified = False
        user.save()
        req = self.context.get("request")
        if req:
            inst.last_edited_by = req.user
        inst = super().update(inst, data)
        if email_changed or pw:
            from .services import safe_notify

            safe_notify(user, "Your sign-in details changed", "Your email or password was changed by your coach.", "info")
        return inst


class ClientCreateSerializer(serializers.Serializer):
    """Add a client drawer (admin + trainer)."""

    full_name = serializers.CharField(max_length=120)
    phone = serializers.CharField(max_length=20)
    country_code = serializers.CharField(max_length=6, required=False, default="+91")
    email = serializers.EmailField(required=False, allow_blank=True)
    gender = serializers.ChoiceField(choices=ClientProfile.Gender.choices, required=False, allow_blank=True)
    date_of_birth = serializers.DateField(required=False, allow_null=True)
    city = serializers.CharField(required=False, allow_blank=True)
    goal = serializers.ChoiceField(choices=ClientProfile.Goal.choices, required=False)
    target_weight_kg = serializers.DecimalField(max_digits=5, decimal_places=1, required=False, allow_null=True)
    height_cm = serializers.DecimalField(max_digits=5, decimal_places=1, required=False, allow_null=True)
    current_weight_kg = serializers.DecimalField(max_digits=5, decimal_places=1, required=False, allow_null=True)
    health_notes = serializers.CharField(required=False, allow_blank=True)
    trainer = serializers.PrimaryKeyRelatedField(queryset=TrainerProfile.objects.all(), required=False, allow_null=True)
    plans_start_on = serializers.DateField(required=False, allow_null=True)
    mode = serializers.ChoiceField(choices=[("active", "Active now"), ("approvals", "Send to Approvals")], default="active")
    send_login_link = serializers.BooleanField(default=True)
    ask_parq = serializers.BooleanField(default=True)

    def validate_phone(self, v):
        digits = "".join(ch for ch in v if ch.isdigit())
        if User.objects.filter(phone__in=[v, digits]).exists() or any(
            "".join(ch for ch in p if ch.isdigit()) == digits for p in User.objects.exclude(phone="").values_list("phone", flat=True)
        ):
            raise serializers.ValidationError("A client or sign-up already uses this number")
        return v

    def validate_email(self, v):
        if v and User.objects.filter(email=v.lower()).exists():
            raise serializers.ValidationError("This email already has an account")
        return v.lower()

    @transaction.atomic
    def create(self, d):
        import secrets

        email = d.get("email") or f"{''.join(ch for ch in d['phone'] if ch.isdigit())}@phone.trainwithvimal.app"
        user = User.objects.create_user(email=email, password=None, full_name=d["full_name"], phone=d["phone"],
                                        country_code=d.get("country_code", "+91"), role=User.Role.CLIENT,
                                        avatar_color=secrets.choice(["c1", "c2", "c3", "c4", "c5", "c6"]))
        approvals = d["mode"] == "approvals"
        cp = ClientProfile(
            user=user, trainer=d.get("trainer"), status=ClientProfile.Status.PENDING if approvals else ClientProfile.Status.ACTIVE,
            goal=d.get("goal") or ClientProfile.Goal.GENERAL, joined_on=timezone.localdate(), signup_device=ClientProfile.Device.STAFF,
            plans_start_on=d.get("plans_start_on"), gender=d.get("gender", ""), date_of_birth=d.get("date_of_birth"),
            city=d.get("city", ""), target_weight_kg=d.get("target_weight_kg"), height_cm=d.get("height_cm"),
            current_weight_kg=d.get("current_weight_kg"), start_weight_kg=d.get("current_weight_kg"), health_notes=d.get("health_notes", ""),
        )
        if not approvals:
            req = self.context.get("request")
            cp.approved_at = timezone.now()
            cp.approved_by = req.user if req else None
        cp.save()
        if d.get("send_login_link") and d.get("email"):
            try:
                from apps.accounts.emails import send_link
                from apps.accounts.models import OneTimeLink

                send_link(user, OneTimeLink.Purpose.LOGIN)
            except Exception:
                pass
        return cp


class ClientSelfSerializer(serializers.ModelSerializer):
    """/me/client-profile/ — the client edits her own About, health, food and preferences."""

    full_name = serializers.CharField(source="user.full_name", required=False)
    email = serializers.EmailField(source="user.email", read_only=True)
    phone = serializers.CharField(source="user.phone", required=False, allow_blank=True)
    trainer = TrainerMiniSerializer(read_only=True)
    age = serializers.IntegerField(read_only=True)
    onboarding_progress = serializers.IntegerField(read_only=True)
    health_issues = HealthIssueSerializer(many=True, required=False)
    injuries = serializers.ListField(child=serializers.CharField(), required=False, write_only=True,
                                     help_text='Chips from the Health step, e.g. ["Knee"] or ["None"]')
    conditions = serializers.ListField(child=serializers.CharField(), required=False, write_only=True)
    injury_note = serializers.CharField(required=False, allow_blank=True, write_only=True)

    class Meta:
        model = ClientProfile
        fields = ("id", "full_name", "email", "phone", "trainer", "status", "goal", "plan", "plan_ends_on", "joined_on", "age",
                  "onboarding_progress", "health_issues", "injuries", "conditions", "injury_note") + CLIENT_EDITABLE + CLIENT_PREFS
        read_only_fields = ("status", "plan", "plan_ends_on", "joined_on")

    def validate(self, attrs):
        conds = attrs.get("conditions") or []
        if "Heart condition" in conds and not attrs.get("doctor_cleared", getattr(self.instance, "doctor_cleared", False)):
            raise serializers.ValidationError({"doctor_cleared": "Doctor’s OK needed with a heart condition"})
        return attrs

    @transaction.atomic
    def update(self, inst, data):
        u = data.pop("user", {})
        for k, v in u.items():
            setattr(inst.user, k, v)
        if u:
            inst.user.save()
        issues = data.pop("health_issues", None)
        injuries = data.pop("injuries", None)
        conditions = data.pop("conditions", None)
        note = data.pop("injury_note", "")
        inst = super().update(inst, data)
        if issues is not None:
            inst.health_issues.all().delete()
            for i in issues:
                HealthIssue.objects.create(client=inst, created_by=inst.user, **i)
        for kind, chips in ((HealthIssue.Kind.INJURY, injuries), (HealthIssue.Kind.CONDITION, conditions)):
            if chips is None:
                continue
            chips = [c for c in chips if c != "None"]
            inst.health_issues.filter(kind=kind, status=HealthIssue.Status.ACTIVE).exclude(area__in=chips).update(
                status=HealthIssue.Status.CLEARED, until=timezone.localdate())
            for c in chips:
                hi, _ = HealthIssue.objects.get_or_create(client=inst, kind=kind, area=c, status=HealthIssue.Status.ACTIVE,
                                                          defaults={"title": c, "since": timezone.localdate(), "created_by": inst.user})
                if kind == HealthIssue.Kind.INJURY and note and (note.lower().find(c.lower().split()[0]) >= 0 or len(chips) == 1):
                    hi.title = note
                    hi.save(update_fields=["title"])
        if len(set(inst.onboarding_steps)) >= 5 and not inst.onboarded_at:
            inst.onboarded_at = timezone.now()
            inst.save(update_fields=["onboarded_at"])
            inst.user.onboarded = True
            inst.user.save(update_fields=["onboarded"])
        return inst


class ClientNoteSerializer(serializers.ModelSerializer):
    author_info = serializers.SerializerMethodField()

    class Meta:
        model = ClientNote
        fields = ("id", "client", "author", "author_info", "text", "is_flag", "pinned", "created_at", "updated_at")
        read_only_fields = ("author",)

    def get_author_info(self, obj):
        return person(obj.author)


class TrainerChangeSerializer(serializers.ModelSerializer):
    from_trainer = TrainerMiniSerializer(read_only=True)
    to_trainer = TrainerMiniSerializer(read_only=True)
    changed_by = serializers.SerializerMethodField()

    class Meta:
        model = TrainerChange
        fields = ("id", "client", "from_trainer", "to_trainer", "changed_by", "reason", "note_for_trainer", "move_open_checkins",
                  "notify_client", "notify_old_trainer", "created_at")

    def get_changed_by(self, obj):
        return person(obj.changed_by)


class ChangeTrainerInputSerializer(serializers.Serializer):
    trainer = serializers.PrimaryKeyRelatedField(queryset=TrainerProfile.objects.filter(active=True))
    reason = serializers.CharField(required=False, allow_blank=True)
    note_for_trainer = serializers.CharField(required=False, allow_blank=True)
    move_open_checkins = serializers.BooleanField(default=True)
    notify_client = serializers.BooleanField(default=True)
    notify_old_trainer = serializers.BooleanField(default=False)
    force = serializers.BooleanField(default=False, help_text="Allow a trainer who is full")


class ClientNudgeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClientNudge
        fields = ("id", "client", "sent_by", "reason", "channels", "created_at")
        read_only_fields = ("sent_by",)


# ─────────────────────────────────────────────── approvals

SETUP_STEPS = [
    ("Account made", "Email and phone checked"),
    ("Basic details", "Name, age, city"),
    ("Goal and body", "Goal, weight, height"),
    ("Health and PAR-Q", "7 health questions"),
    ("Food preferences", "Diet, allergies"),
]


def _fmt(d):
    return f"{d.normalize():f}" if d is not None else None


def onboarding_answers(cp):
    """Goal / Body / Trains / Food lines in the Approvals review drawer (empty when not filled)."""
    rows = []
    if cp.goal_detail or 2 in cp.onboarding_steps:
        rows.append(("Goal", cp.goal_detail or cp.get_goal_display()))
    body = [f"{_fmt(cp.current_weight_kg)} kg" if cp.current_weight_kg else None, f"{_fmt(cp.height_cm)} cm" if cp.height_cm else None,
            f"{cp.age} years" if cp.age is not None else None]
    body = [b for b in body if b]
    if body:
        rows.append(("Body", " · ".join(body)))
    trains = [cp.get_train_place_display() if cp.train_place else None,
              f"{len(cp.training_days)} days a week" if cp.training_days else None,
              cp.onboarding_answers.get("experience_text") or (cp.get_experience_display() if cp.experience else None)]
    trains = [t for t in trains if t]
    if trains:
        rows.append(("Trains", " · ".join(trains)))
    if cp.food_notes or cp.diet:
        rows.append(("Food", cp.food_notes or cp.get_diet_display()))
    return [{"k": k, "v": v} for k, v in rows]


class ApprovalSerializer(serializers.ModelSerializer):
    client = ClientListSerializer(read_only=True)
    invited_by = TrainerMiniSerializer(read_only=True)
    good_fit = TrainerMiniSerializer(read_only=True)
    requested_trainer = TrainerMiniSerializer(read_only=True)
    assigned_trainer = TrainerMiniSerializer(read_only=True)
    decided_by = serializers.SerializerMethodField()
    invite_code = serializers.CharField(source="invite_link.code", read_only=True, default=None)
    hours_waiting = serializers.FloatField(read_only=True)
    wait_level = serializers.CharField(read_only=True)
    steps_done = serializers.SerializerMethodField()
    health_note = serializers.SerializerMethodField()
    answers = serializers.SerializerMethodField()
    current_trainer = serializers.SerializerMethodField()

    class Meta:
        model = ApprovalRequest
        fields = (
            "id", "kind", "status", "client", "invite_code", "invited_by", "plan", "device", "requested_at", "hours_waiting",
            "wait_level", "steps_done", "health_note", "answers", "good_fit", "requested_trainer", "current_trainer", "reason",
            "assigned_trainer", "decided_by", "decided_at", "reject_reason", "decision_note", "message", "tell_client",
            "ask_finish_setup", "moved_back",
        )

    def get_decided_by(self, obj):
        return person(obj.decided_by)

    def get_steps_done(self, obj):
        return min(5, len(set(obj.client.onboarding_steps)))

    def get_health_note(self, obj):
        return obj.client.health_notes

    def get_answers(self, obj):
        return onboarding_answers(obj.client)

    def get_current_trainer(self, obj):
        t = obj.client.trainer
        return TrainerMiniSerializer(t).data if t else None


class ApprovalDetailSerializer(ApprovalSerializer):
    setup = serializers.SerializerMethodField()
    trainer_choices = serializers.SerializerMethodField()
    info_requests = serializers.SerializerMethodField()

    class Meta(ApprovalSerializer.Meta):
        fields = ApprovalSerializer.Meta.fields + ("setup", "trainer_choices", "info_requests")

    def get_setup(self, obj):
        n = self.get_steps_done(obj)
        return [{"title": t, "detail": d if i < n else "Not done", "done": i < n} for i, (t, d) in enumerate(SETUP_STEPS)]

    def get_trainer_choices(self, obj):
        trainers = list(TrainerProfile.objects.filter(active=True).select_related("user"))
        first = [obj.invited_by_id, obj.good_fit_id]
        trainers.sort(key=lambda t: (first.index(t.id) if t.id in first else 9))
        out = []
        for t in trainers:
            d = TrainerMiniSerializer(t).data
            d["tag"] = "Full" if t.is_full else "Invited her" if t.id == obj.invited_by_id else "Good fit" if t.id == obj.good_fit_id else ""
            out.append(d)
        return out

    def get_info_requests(self, obj):
        return InfoRequestSerializer(obj.info_requests.all(), many=True).data


class InfoRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = InfoRequest
        fields = ("id", "approval", "items", "channels", "message", "sent_by", "resolved_at", "created_at")
        read_only_fields = ("approval", "sent_by", "resolved_at")


class ApproveInputSerializer(serializers.Serializer):
    trainer = serializers.PrimaryKeyRelatedField(queryset=TrainerProfile.objects.filter(active=True), required=False, allow_null=True)
    tell_client = serializers.BooleanField(default=True)
    ask_finish_setup = serializers.BooleanField(default=False)
    message = serializers.CharField(required=False, allow_blank=True)


class RejectInputSerializer(serializers.Serializer):
    reason = serializers.ChoiceField(choices=ApprovalRequest.RejectReason.choices, default="fit")
    message = serializers.CharField(required=False, allow_blank=True)
    tell_client = serializers.BooleanField(default=True)


class AskInfoInputSerializer(serializers.Serializer):
    items = serializers.MultipleChoiceField(choices=InfoRequest.Item.choices)
    channels = serializers.MultipleChoiceField(choices=[("whatsapp", "WhatsApp"), ("email", "Email"), ("app", "App notice")], default=["whatsapp", "email"])
    message = serializers.CharField(required=False, allow_blank=True)
