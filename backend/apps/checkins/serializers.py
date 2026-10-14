from django.db import transaction
from rest_framework import serializers

from apps.core.permissions import role_of

from . import services
from .models import (
    CHOICE_TYPES,
    Answer,
    BodyGoal,
    BodyMeasurement,
    BodyWeight,
    CheckinPhoto,
    CheckinReply,
    CheckinSchedule,
    CheckinSubmission,
    Form,
    ProgressPhotoSet,
    Question,
    QuickReply,
)


def initials(name):
    return "".join(w[0] for w in (name or "").split()[:2]).upper()


def person(user):
    if not user:
        return None
    return {"id": user.id, "name": user.full_name, "initials": initials(user.full_name), "avatar_color": user.avatar_color}


def client_info(cp):
    if not cp:
        return None
    return {"id": cp.id, **{k: v for k, v in person(cp.user).items() if k != "id"}, "user_id": cp.user_id}


# ---------------------------------------------------------------- forms
class QuestionSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)
    type_label = serializers.CharField(source="get_type_display", read_only=True)
    added_by_name = serializers.CharField(source="added_by.full_name", read_only=True, default="")

    class Meta:
        model = Question
        fields = (
            "id", "position", "text", "help_text", "type", "type_label", "required", "options", "allow_other",
            "scale_min", "scale_max", "scale_labels", "unit", "metric", "poses", "change_note", "added_by", "added_by_name",
            "source_question",
        )
        read_only_fields = ("source_question",)
        extra_kwargs = {"position": {"required": False}}

    def validate(self, attrs):
        t = attrs.get("type", getattr(self.instance, "type", None))
        if t in CHOICE_TYPES and not (attrs.get("options") or getattr(self.instance, "options", None)):
            raise serializers.ValidationError({"options": "Add at least one option."})
        return attrs


class FormListSerializer(serializers.ModelSerializer):
    status = serializers.CharField(read_only=True)
    kind_label = serializers.CharField(source="get_kind_display", read_only=True)
    question_count = serializers.IntegerField(read_only=True)
    sent_by = serializers.SerializerMethodField()
    client_info = serializers.SerializerMethodField()

    class Meta:
        model = Form
        fields = (
            "id", "name", "kind", "kind_label", "description", "status", "is_published", "is_archived", "is_template",
            "audience", "frequency", "weekday", "day_of_month", "send_time", "channels", "question_count",
            "sent_by", "parent", "client", "client_info", "created_at", "updated_at",
        )

    def get_sent_by(self, obj):
        """Automations that send this form (“How it is sent”). Read from the engage app when it has them."""
        try:
            from django.apps import apps as django_apps

            Automation = django_apps.get_model("engage", "Automation")
        except LookupError:
            return []
        try:
            names = []
            for f in Automation._meta.get_fields():
                if getattr(f, "related_model", None) is Form and f.many_to_one:
                    names = list(Automation.objects.filter(**{f.name: obj}).values_list("name", flat=True))
                    break
            return names
        except Exception:
            return []

    def get_client_info(self, obj):
        return client_info(obj.client)


class FormSerializer(FormListSerializer):
    """Detail + nested write used by the form builder (saves the whole question list at once)."""

    questions = QuestionSerializer(many=True, required=False)

    class Meta(FormListSerializer.Meta):
        fields = FormListSerializer.Meta.fields + ("questions",)
        read_only_fields = ("is_published", "is_archived")

    def _save_questions(self, form, items):
        keep = []
        existing = {q.id: q for q in form.questions.all()}
        for pos, data in enumerate(items):
            data = dict(data)
            qid = data.pop("id", None)
            data["position"] = pos
            if qid and qid in existing:
                q = existing[qid]
                for k, v in data.items():
                    setattr(q, k, v)
                q.save()
            else:
                q = Question.objects.create(form=form, **data)
            keep.append(q.id)
        form.questions.exclude(id__in=keep).delete()

    @transaction.atomic
    def create(self, validated):
        questions = validated.pop("questions", [])
        user = self.context["request"].user
        form = Form.objects.create(created_by=user, updated_by=user, **validated)
        self._save_questions(form, questions)
        return form

    @transaction.atomic
    def update(self, instance, validated):
        questions = validated.pop("questions", None)
        for k, v in validated.items():
            setattr(instance, k, v)
        instance.updated_by = self.context["request"].user
        if questions is not None:
            # design: saving a question moves a published form back to draft until “Publish”
            if instance.is_published and self.context.get("unpublish_on_edit"):
                instance.is_published = False
            self._save_questions(instance, questions)
        instance.save()
        return instance


class ScheduleSerializer(serializers.ModelSerializer):
    form_name = serializers.CharField(source="form.name", read_only=True, default="")
    client_info = serializers.SerializerMethodField()
    frequency_label = serializers.CharField(source="get_frequency_display", read_only=True)

    class Meta:
        model = CheckinSchedule
        fields = (
            "id", "client", "client_info", "form", "form_name", "purpose", "label", "frequency", "frequency_label",
            "weekday", "day_of_month", "send_time", "channels", "starts_on", "ends_on", "next_due_at", "active",
            "assigned_by", "created_at",
        )
        read_only_fields = ("assigned_by",)
        extra_kwargs = {"client": {"required": False}}

    def get_client_info(self, obj):
        return client_info(obj.client)


# ---------------------------------------------------------------- submissions
class AnswerSerializer(serializers.ModelSerializer):
    question_type = serializers.CharField(source="question.type", read_only=True, default="")

    class Meta:
        model = Answer
        fields = ("id", "position", "question", "question_type", "label", "metric", "value", "number", "text",
                  "previous_text", "trend")


class AnswerInputSerializer(serializers.Serializer):
    question = serializers.IntegerField(required=False)
    label = serializers.CharField(required=False, allow_blank=True)
    metric = serializers.CharField(required=False, allow_blank=True)
    value = serializers.JSONField(required=False, allow_null=True)
    text = serializers.CharField(required=False, allow_blank=True)


class ReplySerializer(serializers.ModelSerializer):
    author_info = serializers.SerializerMethodField()

    class Meta:
        model = CheckinReply
        fields = ("id", "submission", "author", "author_info", "text", "voice_note", "voice_note_url", "voice_seconds",
                  "sent_at", "read_at", "created_at")
        read_only_fields = ("author", "sent_at", "read_at", "submission")

    def get_author_info(self, obj):
        return person(obj.author)


class PhotoSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = CheckinPhoto
        fields = ("id", "client", "submission", "photo_set", "pose", "image", "image_url", "url", "file_name",
                  "taken_on", "created_at")
        read_only_fields = ("client",)
        extra_kwargs = {"image": {"required": False}}

    def get_url(self, obj):
        req = self.context.get("request")
        u = obj.url
        if u and req and u.startswith("/"):
            return req.build_absolute_uri(u)
        return u


class SubmissionListSerializer(serializers.ModelSerializer):
    client_info = serializers.SerializerMethodField()
    form_name = serializers.CharField(source="form.name", read_only=True)
    kind_label = serializers.CharField(source="get_kind_display", read_only=True)
    status_label = serializers.CharField(source="get_status_display", read_only=True)
    photo_poses = serializers.SerializerMethodField()
    last_reply = serializers.SerializerMethodField()
    reviewed_by_name = serializers.CharField(source="reviewed_by.full_name", read_only=True, default="")
    age_hours = serializers.SerializerMethodField()

    class Meta:
        model = CheckinSubmission
        fields = (
            "id", "client", "client_info", "form", "form_name", "kind", "kind_label", "schedule", "title",
            "period_number", "plan_label", "status", "status_label", "due_at", "submitted_at", "reminder_sent_at",
            "reviewed_by", "reviewed_by_name", "reviewed_at", "weight_kg", "weight_change_kg", "weight_change_label",
            "workouts_done", "workouts_planned", "workout_label", "meals_on_plan_pct", "sleep_hours", "steps",
            "water_ml", "note", "summary", "signature_name", "signed_at", "photo_poses", "last_reply", "age_hours",
        )
        read_only_fields = ("status", "submitted_at", "reviewed_by", "reviewed_at", "reminder_sent_at", "kind")

    def get_client_info(self, obj):
        return client_info(obj.client)

    def get_photo_poses(self, obj):
        return [p.pose for p in obj.photos.all()]

    def get_last_reply(self, obj):
        replies = list(obj.replies.all())
        return ReplySerializer(replies[-1]).data if replies else None

    def get_age_hours(self, obj):
        from django.utils import timezone

        if not obj.submitted_at:
            return None
        return int((timezone.now() - obj.submitted_at).total_seconds() // 3600)


class SubmissionSerializer(SubmissionListSerializer):
    answers = AnswerSerializer(many=True, read_only=True)
    replies = ReplySerializer(many=True, read_only=True)
    photos = PhotoSerializer(many=True, read_only=True)
    questions = serializers.SerializerMethodField()
    answers_in = AnswerInputSerializer(many=True, write_only=True, required=False)
    submit = serializers.BooleanField(write_only=True, required=False, default=False)

    class Meta(SubmissionListSerializer.Meta):
        fields = SubmissionListSerializer.Meta.fields + ("answers", "replies", "photos", "questions", "answers_in", "submit")

    def get_questions(self, obj):
        return QuestionSerializer(obj.form.questions.all(), many=True).data

    def validate(self, attrs):
        req = self.context["request"]
        form = attrs.get("form") or getattr(self.instance, "form", None)
        if role_of(req.user) == "client" and form and form.client_id and form.client_id != req.user.client_profile.id:
            raise serializers.ValidationError({"form": "Not your form."})
        if role_of(req.user) != "client" and not self.instance and not attrs.get("client"):
            raise serializers.ValidationError({"client": "Pick a client."})
        return attrs

    def create(self, validated):
        answers = validated.pop("answers_in", None)
        do_submit = validated.pop("submit", False)
        validated.setdefault("kind", validated["form"].kind)
        sub = CheckinSubmission.objects.create(**validated)
        if answers is not None:
            services.save_answers(sub, answers)
            if not do_submit:
                sub.status = CheckinSubmission.Status.DRAFT
                sub.save(update_fields=["status"])
        if do_submit:
            missing = services.submit(sub, self.context["request"].user)
            if missing:
                raise serializers.ValidationError({"answers": [f"Answer “{m}” first" for m in missing]})
        return sub

    def update(self, instance, validated):
        answers = validated.pop("answers_in", None)
        validated.pop("submit", None)
        for k, v in validated.items():
            setattr(instance, k, v)
        instance.save()
        if answers is not None:
            services.save_answers(instance, answers)
        return instance


class QuickReplySerializer(serializers.ModelSerializer):
    class Meta:
        model = QuickReply
        fields = ("id", "owner", "text", "position")
        read_only_fields = ("owner",)


# ---------------------------------------------------------------- progress
class BodyWeightSerializer(serializers.ModelSerializer):
    class Meta:
        model = BodyWeight
        fields = ("id", "client", "date", "weight_kg", "source", "submission", "note", "logged_by", "created_at")
        read_only_fields = ("logged_by", "submission")
        extra_kwargs = {"client": {"required": False}}
        validators = []  # upsert on (client, date) in the view

    def validate_weight_kg(self, v):
        if v < 30 or v > 250:
            raise serializers.ValidationError("Weight must be between 30 and 250 kg.")
        return v


class BodyMeasurementSerializer(serializers.ModelSerializer):
    class Meta:
        model = BodyMeasurement
        fields = ("id", "client", "date", "waist_cm", "hips_cm", "chest_cm", "arm_cm", "thigh_cm", "neck_cm",
                  "body_fat_pct", "submission", "note", "measured_by", "created_at")
        read_only_fields = ("measured_by", "submission")
        extra_kwargs = {"client": {"required": False}}
        validators = []


class PhotoSetSerializer(serializers.ModelSerializer):
    photos = PhotoSerializer(many=True, read_only=True)
    poses = serializers.SerializerMethodField()

    class Meta:
        model = ProgressPhotoSet
        fields = ("id", "client", "date", "weight_kg", "label", "source", "submission", "cover_tone", "poses", "photos",
                  "created_at")
        extra_kwargs = {"client": {"required": False}}
        validators = []

    def get_poses(self, obj):
        order = ["front", "side", "back", "flex", "other"]
        return sorted({p.pose for p in obj.photos.all()}, key=order.index)


class BodyGoalSerializer(serializers.ModelSerializer):
    class Meta:
        model = BodyGoal
        fields = ("id", "client", "start_date", "start_weight_kg", "goal_weight_kg", "goal_date", "goal_label", "height_cm",
                  "updated_at")
        extra_kwargs = {"client": {"required": False}}
        validators = []
