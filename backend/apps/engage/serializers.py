from django.db import transaction
from django.utils import timezone
from rest_framework import serializers

from .models import (
    CHANNEL_LIMITS, TRIGGER_DEFAULTS, TRIGGER_INFO, ActivityLog, AlertRule, Automation, AutomationRun, AutomationStarter,
    AutomationStep, Channel, DnsRecord, Integration, MessageLog, MessageTemplate, Notification, NotificationSettings,
    RolePermission, TemplateText, TrainerTask, WorkspaceSettings,
)

CHANNEL_KEYS = [c.value for c in Channel]
DAYS = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


def _channels_field():
    return serializers.ListField(child=serializers.ChoiceField(choices=CHANNEL_KEYS), required=False)


def channels_line(chs):
    labels = dict(Channel.choices)
    return " and ".join(labels[c] for c in chs) if chs else "No channel yet"


# ------------------------------------------------------------------ notifications

class NotificationSerializer(serializers.ModelSerializer):
    is_read = serializers.BooleanField(read_only=True)
    actor_name = serializers.CharField(source="actor.full_name", read_only=True, default="")
    actor_initials = serializers.CharField(source="actor.initials", read_only=True, default="")
    actor_color = serializers.CharField(source="actor.avatar_color", read_only=True, default="")

    class Meta:
        model = Notification
        fields = ("id", "title", "body", "kind", "link", "icon", "tone", "action_label", "read_at", "is_read",
                  "actor", "actor_name", "actor_initials", "actor_color", "client", "created_at")
        read_only_fields = ("read_at", "created_at", "actor")


class NotificationSettingsSerializer(serializers.ModelSerializer):
    items = serializers.SerializerMethodField()

    class Meta:
        model = NotificationSettings
        fields = ("prefs", "quiet_hours_enabled", "quiet_from", "quiet_to", "items", "updated_at")

    def get_items(self, obj):
        prefs = {**obj.defaults_for(obj.user), **(obj.prefs or {})}
        return [{"key": k, "label": label, "help": help_, "on": bool(prefs.get(k))} for k, label, help_ in obj.keys_for(obj.user)]

    def validate_prefs(self, value):
        allowed = {k for k, *_ in self.instance.keys_for(self.instance.user)} if self.instance else set()
        bad = set(value) - allowed
        if bad:
            raise serializers.ValidationError(f"Unknown keys: {', '.join(sorted(bad))}")
        return {**(self.instance.prefs or {}), **{k: bool(v) for k, v in value.items()}}


# ------------------------------------------------------------------ activity

class ActivityLogSerializer(serializers.ModelSerializer):
    who = serializers.CharField(source="display_actor", read_only=True)
    category_label = serializers.CharField(source="get_category_display", read_only=True)
    text = serializers.SerializerMethodField()
    client_name = serializers.CharField(source="client.user.full_name", read_only=True, default="")

    class Meta:
        model = ActivityLog
        fields = ("id", "actor", "who", "actor_role", "verb", "text", "target", "client", "client_name", "category",
                  "category_label", "note", "old_value", "new_value", "source", "meta", "occurred_at")
        read_only_fields = ("actor",)

    def get_text(self, obj):
        return f"{obj.display_actor} {obj.verb}".strip()


# ------------------------------------------------------------------ templates

class TemplateTextSerializer(serializers.ModelSerializer):
    subject_limit = serializers.SerializerMethodField()
    body_limit = serializers.SerializerMethodField()

    class Meta:
        model = TemplateText
        fields = ("id", "channel", "subject", "body", "enabled", "subject_limit", "body_limit")

    def get_subject_limit(self, obj):
        return CHANNEL_LIMITS.get(obj.channel, (0, 0))[0]

    def get_body_limit(self, obj):
        return CHANNEL_LIMITS.get(obj.channel, (0, 0))[1]

    def validate(self, attrs):
        ch = attrs.get("channel") or getattr(self.instance, "channel", None)
        sub_max, body_max = CHANNEL_LIMITS.get(ch, (120, 5000))
        if sub_max and len(attrs.get("subject", "")) > sub_max:
            raise serializers.ValidationError({"subject": f"At most {sub_max} characters."})
        if len(attrs.get("body", "")) > body_max:
            raise serializers.ValidationError({"body": f"At most {body_max} characters."})
        return attrs


class MessageTemplateSerializer(serializers.ModelSerializer):
    texts = TemplateTextSerializer(many=True, required=False)
    group_label = serializers.CharField(source="get_group_display", read_only=True)
    used_in = serializers.SerializerMethodField()

    class Meta:
        model = MessageTemplate
        fields = ("id", "key", "name", "group", "group_label", "when_sent", "event_key", "system_note", "is_custom", "enabled",
                  "position", "texts", "used_in", "updated_at")
        extra_kwargs = {"key": {"required": False}}

    def get_used_in(self, obj):
        """'Where it is used': automations + step numbers using this template."""
        out = {}
        for s in obj.automation_steps.select_related("automation").all():
            steps = list(s.automation.steps.values_list("id", flat=True))
            out.setdefault(s.automation, []).append((steps.index(s.id) + 1, s.channels))
        res = []
        for a, xs in out.items():
            if len(xs) == 1:
                where = f"Step {xs[0][0]} · {channels_line(xs[0][1])}"
            else:
                where = "Steps " + " and ".join(str(n) for n, _ in xs)
            res.append({"automation": a.id, "name": a.name, "where": where})
        return res

    def _save_texts(self, tpl, texts):
        for t in texts:
            TemplateText.objects.update_or_create(template=tpl, channel=t["channel"], defaults={
                "subject": t.get("subject", ""), "body": t.get("body", ""), "enabled": t.get("enabled", True)})

    @transaction.atomic
    def create(self, validated):
        texts = validated.pop("texts", [])
        if not validated.get("key"):
            base = "custom-" + str(MessageTemplate.objects.count())
            validated["key"] = base
        validated.setdefault("is_custom", True)
        tpl = super().create(validated)
        self._save_texts(tpl, texts)
        return tpl

    @transaction.atomic
    def update(self, instance, validated):
        texts = validated.pop("texts", None)
        tpl = super().update(instance, validated)
        if texts is not None:
            self._save_texts(tpl, texts)
        return tpl


class PreviewSerializer(serializers.Serializer):
    channel = serializers.ChoiceField(choices=CHANNEL_KEYS, required=False)
    subject = serializers.CharField(required=False, allow_blank=True)
    body = serializers.CharField(required=False, allow_blank=True)
    variables = serializers.DictField(child=serializers.CharField(allow_blank=True), required=False)
    client = serializers.IntegerField(required=False)


class AlertRuleSerializer(serializers.ModelSerializer):
    channels = _channels_field()

    class Meta:
        model = AlertRule
        fields = ("id", "key", "name", "description", "channels", "recipients", "enabled", "position")


# ------------------------------------------------------------------ automations

class AutomationStepSerializer(serializers.ModelSerializer):
    channels = _channels_field()
    template_key = serializers.SlugRelatedField(source="template", slug_field="key", queryset=MessageTemplate.objects.all(),
                                                required=False, allow_null=True)
    template_name = serializers.CharField(source="template.name", read_only=True, default="")
    line = serializers.SerializerMethodField()

    class Meta:
        model = AutomationStep
        fields = ("id", "position", "kind", "wait_amount", "wait_unit", "template", "template_key", "template_name", "form_key",
                  "channels", "task_text", "task_for", "line")
        read_only_fields = ("position",)
        extra_kwargs = {"template": {"required": False, "allow_null": True}}

    def get_line(self, s):
        """Plain-words line ('Wait 1 day', 'Send “Welcome” by Email and Push')."""
        if s.kind == "wait":
            unit = s.wait_unit.rstrip("s") if s.wait_amount == 1 else s.wait_unit
            return f"Wait {s.wait_amount} {unit}"
        if s.kind == "form":
            return f"Send the form “{s.form_key}” by {channels_line(s.channels)}"
        if s.kind == "message":
            return f"Send “{s.template.name if s.template else 'a template'}” by {channels_line(s.channels)}"
        return f"Task for the {'owner' if s.task_for == 'owner' else 'assigned trainer'}: {s.task_text}"

    def validate(self, attrs):
        kind = attrs.get("kind")
        if kind == "wait":
            if not attrs.get("wait_amount"):
                raise serializers.ValidationError({"wait_amount": "Wait at least 1."})
            attrs.setdefault("wait_unit", "days")
        if kind == "assign":
            attrs.setdefault("task_for", "trainer")
        return attrs


def trigger_line(t, v, cfg=None):
    cfg = cfg or {}
    if not t:
        return "Pick what starts it"
    lines = {
        "clientApproved": "When a new client is approved",
        "weeklyCheckInDay": f"Every {DAYS[int(cfg.get('weekday') or v or 7)]} at 9 am" if not cfg.get("time") else
        f"Every {DAYS[int(cfg.get('weekday') or v or 7)]} at {_fmt_time(cfg['time'])}",
        "checkInMissed": f"When a check-in is not sent within {v} hours",
        "workoutsMissed": f"When {v} workouts in a row are missed",
        "renewalDue": f"{v} days before a package ends",
        "birthday": "On the client’s birthday at 9 am",
        "inactive": f"When a client has not opened the app for {v} days",
        "streak": f"When a client finishes workouts {v} days in a row",
        "goalReached": "When a client’s weight reaches their goal",
        "weightStuck": f"When weight stays within 0.5 kg for {v} {'week' if v == 1 else 'weeks'}",
    }
    return lines.get(t) or dict(Automation._meta.get_field("trigger").choices).get(t, t)


def _fmt_time(hhmm):
    h, m = (int(x) for x in hhmm.split(":"))
    return f"{h % 12 or 12}:{m:02d} {'am' if h < 12 else 'pm'}"


class AutomationSerializer(serializers.ModelSerializer):
    steps = AutomationStepSerializer(many=True, required=False)
    trigger_label = serializers.CharField(source="get_trigger_display", read_only=True)
    trigger_group = serializers.SerializerMethodField()
    trigger_line = serializers.SerializerMethodField()
    audience_line = serializers.SerializerMethodField()
    trainer_name = serializers.CharField(source="trainer.user.full_name", read_only=True, default="")
    problems = serializers.SerializerMethodField()

    class Meta:
        model = Automation
        fields = ("id", "key", "name", "trigger", "trigger_label", "trigger_group", "trigger_value", "trigger_config", "trigger_line",
                  "conditions", "status", "package", "trainer", "trainer_name", "audience_line", "stop_on_reply", "edited_at",
                  "running_count", "finished_count", "started_30d", "finished_30d", "stopped_30d", "problems", "steps", "created_at")
        read_only_fields = ("edited_at", "running_count", "finished_count", "started_30d", "finished_30d", "stopped_30d")
        extra_kwargs = {"key": {"required": False}}

    def get_trigger_group(self, a):
        return TRIGGER_INFO.get(a.trigger, ("",))[0]

    def get_trigger_line(self, a):
        return trigger_line(a.trigger, a.trigger_value, a.trigger_config)

    def get_audience_line(self, a):
        if a.package:
            return f"Package: {a.package}"
        if a.trainer_id:
            return f"Trainer: {a.trainer.user.full_name}"
        return "All clients"

    def get_problems(self, a):
        return a.problems() if a.pk else []

    def validate(self, attrs):
        status = attrs.get("status")
        if status == "on":
            steps = attrs.get("steps")
            trig = attrs.get("trigger", getattr(self.instance, "trigger", ""))
            if not trig:
                raise serializers.ValidationError({"status": "Pick what starts it"})
            if steps is not None:
                if not steps:
                    raise serializers.ValidationError({"status": "Add at least one step"})
                if steps[-1]["kind"] == "wait":
                    raise serializers.ValidationError({"status": "Add a step that does something after the wait"})
                for i, s in enumerate(steps, 1):
                    if s["kind"] in ("message", "form") and not s.get("channels"):
                        raise serializers.ValidationError({"status": f"Step {i}: pick at least one channel"})
        if attrs.get("trigger") and "trigger_config" not in attrs and not (self.instance and self.instance.trigger == attrs["trigger"]):
            attrs["trigger_config"] = dict(TRIGGER_DEFAULTS.get(attrs["trigger"], {}))
        return attrs

    def _save_steps(self, automation, steps):
        automation.steps.all().delete()
        for i, s in enumerate(steps):
            s.pop("id", None)
            AutomationStep.objects.create(automation=automation, position=i, **s)

    @transaction.atomic
    def create(self, validated):
        steps = validated.pop("steps", [])
        if not validated.get("key"):
            from django.utils.text import slugify
            base = "a-" + (slugify(validated.get("name", "")) or "new")
            key, n = base, 1
            while Automation.objects.filter(key=key).exists():
                n += 1
                key = f"{base}-{n}"
            validated["key"] = key
        req = self.context.get("request")
        validated["created_by"] = req.user if req else None
        a = super().create(validated)
        self._save_steps(a, steps)
        return a

    @transaction.atomic
    def update(self, instance, validated):
        steps = validated.pop("steps", None)
        validated["edited_at"] = timezone.now()
        a = super().update(instance, validated)
        if steps is not None:
            self._save_steps(a, steps)
        if a.status == "on" and a.problems():
            raise serializers.ValidationError({"status": a.problems()[0]})
        return a


class AutomationStarterSerializer(serializers.ModelSerializer):
    trigger_line = serializers.SerializerMethodField()
    step_count = serializers.SerializerMethodField()

    class Meta:
        model = AutomationStarter
        fields = ("id", "key", "name", "trigger", "trigger_value", "trigger_config", "trigger_line", "steps", "step_count", "note", "position")

    def get_trigger_line(self, s):
        return trigger_line(s.trigger, s.trigger_value, s.trigger_config)

    def get_step_count(self, s):
        return f"{len(s.steps)} steps"


class AutomationRunSerializer(serializers.ModelSerializer):
    client_name = serializers.CharField(source="client.user.full_name", read_only=True)
    client_initials = serializers.CharField(source="client.user.initials", read_only=True)
    client_color = serializers.CharField(source="client.user.avatar_color", read_only=True)
    automation_name = serializers.CharField(source="automation.name", read_only=True)

    class Meta:
        model = AutomationRun
        fields = ("id", "automation", "automation_name", "client", "client_name", "client_initials", "client_color", "status",
                  "status_text", "current_step", "next_step_at", "started_at", "finished_at", "is_test")


class MessageLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = MessageLog
        fields = ("id", "automation", "run", "template", "user", "client", "channel", "subject", "body", "status", "sent_at",
                  "delivered_at", "opened_at")


class TrainerTaskSerializer(serializers.ModelSerializer):
    client_name = serializers.CharField(source="client.user.full_name", read_only=True, default="")
    automation_name = serializers.CharField(source="automation.name", read_only=True, default="")
    done = serializers.SerializerMethodField()

    class Meta:
        model = TrainerTask
        fields = ("id", "title", "client", "client_name", "assignee", "automation", "automation_name", "due_at", "done_at", "done",
                  "created_at")
        read_only_fields = ("done_at",)
        extra_kwargs = {"assignee": {"required": False}}

    def get_done(self, obj):
        return obj.done_at is not None


# ------------------------------------------------------------------ settings

class WorkspaceSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkspaceSettings
        exclude = ("id", "created_at")
        read_only_fields = ("general_saved_at", "branding_applied_at", "updated_at")


class BrandingSerializer(serializers.ModelSerializer):
    """What every signed-in user (client app) may read."""

    class Meta:
        model = WorkspaceSettings
        fields = ("business_name", "logo", "logo_url", "brand_color", "theme", "units", "week_start", "timezone", "language",
                  "currency", "contact_email", "phone", "address", "website")


class RolePermissionSerializer(serializers.ModelSerializer):
    admin = serializers.SerializerMethodField()

    class Meta:
        model = RolePermission
        fields = ("id", "key", "name", "admin", "trainer", "client", "position")
        read_only_fields = ("key", "name", "position")

    def get_admin(self, obj):
        return True


class DnsRecordSerializer(serializers.ModelSerializer):
    status = serializers.SerializerMethodField()

    class Meta:
        model = DnsRecord
        fields = ("id", "record", "record_type", "host", "value", "verified", "status", "checked_at")

    def get_status(self, obj):
        return "Verified" if obj.verified else "Waiting"


class IntegrationSerializer(serializers.ModelSerializer):
    status_label = serializers.CharField(source="get_status_display", read_only=True)
    dns_records = DnsRecordSerializer(many=True, read_only=True)
    meta = serializers.SerializerMethodField()

    class Meta:
        model = Integration
        fields = ("id", "key", "name", "short", "description", "status", "status_label", "meta", "account", "from_address",
                  "linked_count", "uses", "setup_steps", "bg", "fg", "connected_at", "dns_records")
        read_only_fields = ("key", "status", "connected_at")

    def get_meta(self, i):
        if i.status == "on":
            return f"{i.linked_count} clients linked" if i.key == "health" else (i.from_address if i.key == "email" else i.account)
        return "Sending from the platform address for now" if i.status == "dns" else "Not set up"
