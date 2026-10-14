from django.db import transaction
from rest_framework import serializers

from .models import (
    WEEKDAYS,
    Exercise,
    ExerciseMuscle,
    PersonalRecord,
    Program,
    ProgramAssignment,
    ProgramDay,
    ProgramWeek,
    SessionExercise,
    SetLog,
    WorkoutExercise,
    WorkoutSession,
)

# ------------------------------------------------------------------ exercises


class ExerciseMuscleSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExerciseMuscle
        fields = ("id", "muscle", "intensity", "note", "position")


class ExerciseListSerializer(serializers.ModelSerializer):
    source = serializers.CharField(read_only=True)
    works_label = serializers.CharField(read_only=True)
    used_in_programs = serializers.IntegerField(read_only=True, required=False)
    has_video = serializers.SerializerMethodField()

    class Meta:
        model = Exercise
        fields = ("id", "slug", "name", "muscle_group", "primary_muscle", "works_label", "equipment", "level", "category", "log_type",
                  "source", "is_custom", "has_video", "video_duration_s", "tone", "image_url", "default_sets", "default_reps",
                  "default_rest_s", "used_in_programs", "archived")

    def get_has_video(self, obj):
        return obj.video_source != "none"


class ExerciseSerializer(serializers.ModelSerializer):
    muscles = ExerciseMuscleSerializer(many=True, required=False)
    source = serializers.CharField(read_only=True)
    works_label = serializers.CharField(read_only=True)
    used_in = serializers.SerializerMethodField()

    class Meta:
        model = Exercise
        fields = "__all__"
        read_only_fields = ("slug", "created_by", "duplicated_from", "created_at", "updated_at")

    def get_used_in(self, obj):
        """"Used in 2 programs": per master program, first day using it, workouts in the plan, clients."""
        out = {}
        for we in obj.placements.filter(day__week__program__client__isnull=True).select_related("day__week__program").order_by(
                "day__week__program_id", "day__week__number", "day__day_index"):
            p = we.day.week.program
            row = out.setdefault(p.pk, {"program": p.pk, "name": p.name, "day": we.day.title, "workouts": 0, "status": p.status,
                                        "clients": p.assignments.filter(status="active").count() + p.master_assignments.filter(status="active").exclude(program=p).count()})
            row["workouts"] += 1
        return list(out.values())

    def _save_muscles(self, ex, muscles):
        if muscles is None:
            return
        ex.muscles.all().delete()
        for i, m in enumerate(muscles):
            ExerciseMuscle.objects.create(exercise=ex, position=m.get("position", i), muscle=m["muscle"],
                                          intensity=m.get("intensity", "light"), note=m.get("note", ""))

    @transaction.atomic
    def create(self, validated):
        muscles = validated.pop("muscles", [])
        ex = super().create(validated)
        self._save_muscles(ex, muscles)
        return ex

    @transaction.atomic
    def update(self, instance, validated):
        muscles = validated.pop("muscles", None)
        ex = super().update(instance, validated)
        self._save_muscles(ex, muscles)
        return ex


# ------------------------------------------------------------------ programs


class WorkoutExerciseSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)
    exercise_name = serializers.CharField(source="exercise.name", read_only=True)
    shown_name = serializers.CharField(read_only=True)
    works_label = serializers.CharField(source="exercise.works_label", read_only=True)
    muscle_group = serializers.CharField(source="exercise.muscle_group", read_only=True)
    log_type = serializers.CharField(source="exercise.log_type", read_only=True)
    summary = serializers.CharField(read_only=True)
    is_customized = serializers.BooleanField(read_only=True)

    class Meta:
        model = WorkoutExercise
        exclude = ("day",)


class ProgramDaySerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)
    weekday = serializers.SerializerMethodField()
    exercises = WorkoutExerciseSerializer(many=True, required=False)
    minutes = serializers.SerializerMethodField()
    total_sets = serializers.IntegerField(read_only=True)

    class Meta:
        model = ProgramDay
        exclude = ("week", "created_at", "updated_at")

    def get_weekday(self, obj):
        return WEEKDAYS[obj.day_index] if obj.day_index < 7 else ""

    def get_minutes(self, obj):
        return obj.computed_minutes()


class ProgramWeekSerializer(serializers.ModelSerializer):
    days = ProgramDaySerializer(many=True, required=False)

    class Meta:
        model = ProgramWeek
        fields = ("id", "number", "note", "days")


class AssignedClientSerializer(serializers.ModelSerializer):
    client_name = serializers.CharField(source="client.user.full_name", read_only=True)
    avatar_color = serializers.CharField(source="client.user.avatar_color", read_only=True)
    goal = serializers.CharField(source="client.get_goal_display", read_only=True)
    trainer_name = serializers.SerializerMethodField()
    version = serializers.SerializerMethodField()

    class Meta:
        model = ProgramAssignment
        fields = ("id", "client", "client_name", "avatar_color", "goal", "trainer_name", "start_date", "status", "version", "program")

    def get_trainer_name(self, obj):
        t = obj.client.trainer
        return t.user.full_name if t else ""

    def get_version(self, obj):
        return "Custom" if obj.program.client_id else "Master"


class ProgramListSerializer(serializers.ModelSerializer):
    days_per_week = serializers.IntegerField(read_only=True)
    week_pattern = serializers.SerializerMethodField()
    clients = serializers.SerializerMethodField()
    client_count = serializers.SerializerMethodField()

    class Meta:
        model = Program
        fields = ("id", "name", "short_name", "goal", "goal_label", "level", "location", "weeks", "days_per_week", "week_pattern", "status",
                  "tags", "tone", "client", "based_on", "edited_at", "clients", "client_count")

    def _assignments(self, obj):
        from django.db.models import Q

        return ProgramAssignment.objects.filter(Q(program=obj) | Q(master=obj), status="active").select_related("client__user", "client__trainer__user", "program")

    def get_week_pattern(self, obj):
        return obj.week_pattern()

    def get_clients(self, obj):
        return AssignedClientSerializer(self._assignments(obj), many=True).data

    def get_client_count(self, obj):
        return self._assignments(obj).count()


class ProgramSerializer(ProgramListSerializer):
    """Full tree. PUT/PATCH with `weeks_data` saves the builder in one request."""

    weeks_data = ProgramWeekSerializer(source="program_weeks", many=True, required=False)

    class Meta(ProgramListSerializer.Meta):
        fields = ProgramListSerializer.Meta.fields + ("description", "created_by", "edited_by", "weeks_data", "created_at")
        read_only_fields = ("created_by", "edited_by", "edited_at", "created_at")

    def to_internal_value(self, data):
        weeks = data.get("weeks_data") if hasattr(data, "get") else None
        out = super().to_internal_value(data)
        out.pop("program_weeks", None)
        if weeks is not None:
            out["weeks_data"] = weeks
        return out

    def create(self, validated):
        from .services import save_program_tree

        user = self.context["request"].user
        days_per_week = self.initial_data.get("days_per_week")
        weeks_data = validated.pop("weeks_data", None)
        p = Program.objects.create(created_by=user, edited_by=user, **validated)
        if weeks_data is None:
            # New program modal: N weeks, first `days_per_week` days are workouts, the rest rest days
            n = int(days_per_week or 4)
            weeks_data = [{"number": w, "days": [
                {"day_index": i, "title": f"Day {i + 1}" if i < n else "Rest", "is_rest": i >= n, "kind": "strength" if i < n else "rest"}
                for i in range(7)]} for w in range(1, p.weeks + 1)]
        save_program_tree(p, {"weeks_data": weeks_data}, user)
        return p

    def update(self, instance, validated):
        from .services import save_program_tree

        return save_program_tree(instance, validated, self.context["request"].user)


class ProgramAssignmentSerializer(serializers.ModelSerializer):
    program_name = serializers.CharField(source="program.name", read_only=True)
    master_name = serializers.CharField(source="master.name", read_only=True, default="")
    client_name = serializers.CharField(source="client.user.full_name", read_only=True)
    is_custom = serializers.BooleanField(read_only=True)
    current_week = serializers.IntegerField(read_only=True)
    weeks = serializers.IntegerField(source="program.weeks", read_only=True)
    days_per_week = serializers.IntegerField(source="program.days_per_week", read_only=True)
    assigned_by_name = serializers.CharField(source="assigned_by.full_name", read_only=True, default="")

    class Meta:
        model = ProgramAssignment
        fields = "__all__"
        read_only_fields = ("assigned_by", "created_at", "updated_at")


# ------------------------------------------------------------------ sessions


class SetLogSerializer(serializers.ModelSerializer):
    display = serializers.CharField(read_only=True)

    class Meta:
        model = SetLog
        exclude = ("created_at", "updated_at")
        read_only_fields = ("entry", "is_pr", "done_at")


class SessionExerciseSerializer(serializers.ModelSerializer):
    sets = SetLogSerializer(many=True, read_only=True)
    log_type = serializers.CharField(source="exercise.log_type", read_only=True)
    target = serializers.CharField(source="workout_exercise.summary", read_only=True, default="")
    rest_s = serializers.IntegerField(source="workout_exercise.rest_s", read_only=True, default=0)
    block = serializers.CharField(source="workout_exercise.block", read_only=True, default="")
    swapped_from_name = serializers.CharField(source="swapped_from.name", read_only=True, default="")
    has_pr = serializers.SerializerMethodField()

    class Meta:
        model = SessionExercise
        fields = ("id", "position", "exercise", "name", "workout_exercise", "log_type", "target", "rest_s", "block", "swapped_from",
                  "swapped_from_name", "swap_reason", "added_by_client", "note", "has_pr", "sets")

    def get_has_pr(self, obj):
        return any(s.is_pr for s in obj.sets.all())


class WorkoutSessionListSerializer(serializers.ModelSerializer):
    minutes = serializers.IntegerField(read_only=True)
    has_pr = serializers.BooleanField(read_only=True)
    client_name = serializers.CharField(source="client.user.full_name", read_only=True)

    class Meta:
        model = WorkoutSession
        fields = ("id", "client", "client_name", "title", "kind", "scheduled_date", "week_number", "status", "started_at", "finished_at",
                  "minutes", "effort", "feeling", "note", "skip_reason", "exercises_done", "exercises_total", "sets_done", "sets_total",
                  "volume_kg", "has_pr", "program_day")


class WorkoutSessionSerializer(WorkoutSessionListSerializer):
    entries = SessionExerciseSerializer(many=True, read_only=True)
    elapsed_s = serializers.IntegerField(read_only=True)

    class Meta(WorkoutSessionListSerializer.Meta):
        fields = WorkoutSessionListSerializer.Meta.fields + (
            "assignment", "paused_at", "paused_s", "time_adjust_s", "duration_s", "rest_s", "elapsed_s", "last_activity_at",
            "sent_to_coach_at", "coach_seen_at", "entries")
        read_only_fields = ("started_at", "finished_at", "paused_at", "paused_s", "exercises_done", "exercises_total", "sets_done",
                            "sets_total", "volume_kg", "sent_to_coach_at")


class PersonalRecordSerializer(serializers.ModelSerializer):
    exercise_name = serializers.CharField(source="exercise.name", read_only=True)
    label = serializers.CharField(read_only=True)

    class Meta:
        model = PersonalRecord
        fields = "__all__"
