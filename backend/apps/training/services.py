"""Business logic shared by views, seed and tasks."""
import datetime as dt
from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from .models import (
    LogType,
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

DAY_FIELDS = ("title", "kind", "is_rest", "note", "estimated_minutes", "equipment_note", "changed_for_client")
EX_FIELDS = (
    "block", "sets", "reps", "rep_min", "rep_max", "per_side", "hold_s", "rest_s", "rpe", "tempo", "superset_group", "note",
    "target_weight_kg", "load_note", "duration_min", "incline_pct", "speed_kmh", "distance_km", "target_note",
    "override_name", "override_video_source", "override_video_url", "override_video_title", "override_steps", "override_cues",
    "changed_for_client", "replaced_exercise_id", "change_note",
)


# ------------------------------------------------------------------ program tree


def copy_day(src: ProgramDay, week: ProgramWeek, day_index=None):
    day = ProgramDay.objects.create(week=week, day_index=src.day_index if day_index is None else day_index,
                                    **{f: getattr(src, f) for f in DAY_FIELDS})
    WorkoutExercise.objects.bulk_create([
        WorkoutExercise(day=day, exercise_id=e.exercise_id, position=e.position, **{f: getattr(e, f) for f in EX_FIELDS})
        for e in src.exercises.all()
    ])
    return day


def copy_week(program: Program, src_number: int, dst_number: int):
    src = program.program_weeks.get(number=src_number)
    dst, _ = ProgramWeek.objects.get_or_create(program=program, number=dst_number)
    dst.days.all().delete()
    for d in src.days.all():
        copy_day(d, dst)
    if dst_number > program.weeks:
        program.weeks = dst_number
        program.save(update_fields=["weeks", "updated_at"])
    return dst


@transaction.atomic
def duplicate_program(program: Program, *, name=None, client=None, user=None):
    new = Program.objects.get(pk=program.pk)
    new.pk = None
    new.name = name or f"{program.name} (copy)"
    new.client = client
    new.based_on = program if client is not None else program.based_on
    new.status = Program.Status.ACTIVE
    new.created_by = user
    new.edited_by = user
    new.edited_at = timezone.now()
    new.save()
    for w in program.program_weeks.all():
        nw = ProgramWeek.objects.create(program=new, number=w.number, note=w.note)
        for d in w.days.all():
            copy_day(d, nw)
    return new


@transaction.atomic
def save_program_tree(program: Program, data: dict, user=None):
    """Builder save: the whole tree in one go. Rows with an id are updated, rows without one
    created, rows left out deleted (logged sessions keep their history via SET_NULL)."""
    for f in ("name", "short_name", "goal", "goal_label", "description", "level", "location", "weeks", "status", "tags", "tone"):
        if f in data:
            setattr(program, f, data[f])
    program.edited_at = timezone.now()
    program.edited_by = user
    program.save()
    if "weeks_data" not in data:
        return program
    keep_weeks = []
    for wd in data["weeks_data"]:
        week, _ = ProgramWeek.objects.get_or_create(program=program, number=wd["number"])
        week.note = wd.get("note", week.note)
        week.save()
        keep_weeks.append(week.pk)
        keep_days = []
        payload_ids = [x["id"] for x in wd.get("days", []) if x.get("id")]
        week.days.exclude(pk__in=payload_ids).delete()
        # park the kept days so moving them between weekdays cannot clash
        for d in ProgramDay.objects.filter(week__program=program, pk__in=payload_ids):
            d.day_index = 100 + d.day_index
            d.save(update_fields=["day_index"])
        for dd in wd.get("days", []):
            day = ProgramDay.objects.filter(pk=dd["id"], week__program=program).first() if dd.get("id") else None
            day = day or ProgramDay(week=week)
            day.week = week
            day.day_index = dd["day_index"]
            for f in DAY_FIELDS:
                if f in dd:
                    setattr(day, f, dd[f])
            if day.is_rest:
                day.kind = ProgramDay.Kind.REST
            day.save()
            keep_days.append(day.pk)
            keep_ex = []
            for pos, ed in enumerate(dd.get("exercises", [])):
                we = None
                if ed.get("id"):
                    we = WorkoutExercise.objects.filter(pk=ed["id"], day__week__program=program).first()
                we = we or WorkoutExercise()
                we.day = day
                we.position = pos
                we.exercise_id = ed.get("exercise") or ed.get("exercise_id") or we.exercise_id
                for f in EX_FIELDS:
                    key = f[:-3] if f.endswith("_id") and f[:-3] in ed else f
                    if key in ed:
                        setattr(we, f, ed[key])
                if "reps" in ed and "rep_min" not in ed:
                    we.rep_min = we.rep_max = None
                we.save()
                keep_ex.append(we.pk)
            day.exercises.exclude(pk__in=keep_ex).delete()
        week.days.exclude(pk__in=keep_days).delete()
    program.program_weeks.exclude(pk__in=keep_weeks).delete()
    return program


# ------------------------------------------------------------------ assignments


@transaction.atomic
def assign_clients(program: Program, client_ids, start_date=None, user=None):
    """Sync the active assignments of a master program to exactly `client_ids`."""
    start_date = start_date or timezone.localdate()
    current = ProgramAssignment.objects.filter(status=ProgramAssignment.Status.ACTIVE).filter(
        models_q_program(program))
    have = {a.client_id: a for a in current}
    added, removed = [], []
    for cid in client_ids:
        if cid in have:
            continue
        # a client follows one workout program at a time: the old one is replaced
        for old in ProgramAssignment.objects.filter(client_id=cid, status=ProgramAssignment.Status.ACTIVE):
            old.status = ProgramAssignment.Status.REPLACED
            old.ended_on = start_date
            old.save(update_fields=["status", "ended_on", "updated_at"])
        a = ProgramAssignment.objects.create(
            client_id=cid, program=program, master=program, start_date=start_date,
            end_date=start_date + dt.timedelta(weeks=program.weeks) - dt.timedelta(days=1), assigned_by=user)
        added.append(a)
    for cid, a in have.items():
        if cid not in client_ids:
            a.status = ProgramAssignment.Status.ENDED
            a.ended_on = timezone.localdate()
            a.end_reason = "Unassigned from the program"
            a.save(update_fields=["status", "ended_on", "end_reason", "updated_at"])
            removed.append(a)
    return added, removed


def models_q_program(program):
    from django.db.models import Q

    return Q(program=program) | Q(master=program)


def active_assignment(client, on=None):
    on = on or timezone.localdate()
    qs = ProgramAssignment.objects.filter(client=client, status=ProgramAssignment.Status.ACTIVE, start_date__lte=on + dt.timedelta(days=7))
    return qs.select_related("program", "master").order_by("-start_date").first()


# ------------------------------------------------------------------ sessions


def _start_values(we: WorkoutExercise, last_sets):
    """Planned values for each set: last time's numbers when there are any, else the target."""
    ex = we.exercise
    out = []
    for i in range(we.sets):
        prev = last_sets[i] if i < len(last_sets) else (last_sets[-1] if last_sets else None)
        v = {"per_side": we.per_side, "is_bodyweight": ex.bodyweight_default}
        if ex.log_type == LogType.CARDIO:
            v["target_duration_s"] = (we.duration_min or 0) * 60 or None
            v["duration_s"] = v["target_duration_s"]
            v["distance_km"] = prev.distance_km if prev else we.distance_km
        elif ex.log_type == LogType.TIME:
            v["target_duration_s"] = we.hold_s
            v["duration_s"] = we.hold_s
        else:
            v["target_reps"] = we.rep_max or we.rep_min
            v["reps"] = v["target_reps"]
            v["target_weight_kg"] = we.target_weight_kg
            v["weight_kg"] = we.target_weight_kg if we.target_weight_kg is not None else (prev.weight_kg if prev else None)
            if prev is not None:
                v["is_bodyweight"] = prev.is_bodyweight
                v["assistance"] = prev.assistance
            if v["is_bodyweight"] and v["weight_kg"] is None:
                v["weight_kg"] = Decimal("0")
        out.append(v)
    return out


def last_sets_for(client, exercise, before=None):
    qs = SetLog.objects.filter(entry__session__client=client, entry__exercise=exercise, entry__session__status=WorkoutSession.Status.COMPLETED,
                               is_warmup=False)
    if before:
        qs = qs.filter(entry__session__scheduled_date__lt=before)
    last = qs.order_by("-entry__session__scheduled_date", "-entry__session_id").values_list("entry_id", flat=True).first()
    return list(SetLog.objects.filter(entry_id=last, is_warmup=False).order_by("set_no")) if last else []


@transaction.atomic
def start_session(client, program_day=None, date=None, title=None):
    date = date or timezone.localdate()
    now = timezone.now()
    existing = WorkoutSession.objects.filter(client=client, scheduled_date=date, program_day=program_day,
                                             status__in=[WorkoutSession.Status.PLANNED, WorkoutSession.Status.IN_PROGRESS]).first()
    if existing:
        if existing.status == WorkoutSession.Status.PLANNED:
            existing.status = WorkoutSession.Status.IN_PROGRESS
            existing.started_at = now
            existing.last_activity_at = now
            existing.save()
        return existing
    a = active_assignment(client, date)
    s = WorkoutSession.objects.create(
        client=client, assignment=a, program_day=program_day, scheduled_date=date,
        title=title or (program_day.title if program_day else "Workout"),
        kind=program_day.kind if program_day else ProgramDay.Kind.STRENGTH,
        week_number=a.week_number(date) if a else None,
        status=WorkoutSession.Status.IN_PROGRESS, started_at=now, last_activity_at=now)
    if program_day:
        for we in program_day.exercises.select_related("exercise"):
            entry = SessionExercise.objects.create(session=s, workout_exercise=we, exercise=we.exercise, name=we.shown_name, position=we.position)
            for i, v in enumerate(_start_values(we, last_sets_for(client, we.exercise, before=date)), start=1):
                SetLog.objects.create(entry=entry, set_no=i, **v)
    s.recalc()
    return s


def touch(session):
    session.last_activity_at = timezone.now()
    session.save(update_fields=["last_activity_at", "updated_at"])


def pause(session, on=True):
    now = timezone.now()
    if on and not session.paused_at:
        session.paused_at = now
    elif not on and session.paused_at:
        session.paused_s += int((now - session.paused_at).total_seconds())
        session.paused_at = None
    session.save(update_fields=["paused_at", "paused_s", "updated_at"])


@transaction.atomic
def finish_session(session, effort=None, note="", rest_s=None, duration_s=None, feeling=""):
    if session.paused_at:
        pause(session, on=False)
    now = timezone.now()
    session.finished_at = now
    session.duration_s = duration_s if duration_s is not None else session.elapsed_s
    session.status = WorkoutSession.Status.COMPLETED
    if effort:
        session.effort = effort
    if note:
        session.note = note
    if feeling:
        session.feeling = feeling
    if rest_s is not None:
        session.rest_s = rest_s
    if effort:
        session.sent_to_coach_at = now
    session.save()
    SetLog.objects.filter(entry__session=session, done=False).update(skipped=True)
    session.recalc()
    records = detect_prs(session)
    return records


def detect_prs(session):
    """Compare each done working set to the client's best before this session."""
    out = []
    for entry in session.entries.select_related("exercise"):
        ex = entry.exercise
        sets = [s for s in entry.sets.all() if s.done and not s.is_warmup]
        if not sets:
            continue
        prev = PersonalRecord.objects.filter(client=session.client, exercise=ex).exclude(session=session)
        if ex.log_type == LogType.TIME:
            best = max(sets, key=lambda s: s.duration_s or 0)
            old = prev.filter(kind=PersonalRecord.Kind.TIME).order_by("-duration_s").first()
            if best.duration_s and (old is None or best.duration_s > old.duration_s):
                out.append(_record(session, best, PersonalRecord.Kind.TIME, duration_s=best.duration_s))
        elif ex.log_type == LogType.WEIGHT_REPS:
            cand = [s for s in sets if s.weight_kg is not None and not s.is_bodyweight and not s.assistance]
            if not cand:
                continue
            best = max(cand, key=lambda s: (s.weight_kg, s.reps or 0))
            old = prev.filter(kind=PersonalRecord.Kind.WEIGHT).order_by("-weight_kg", "-reps").first()
            if old is None or best.weight_kg > old.weight_kg or (best.weight_kg == old.weight_kg and (best.reps or 0) > (old.reps or 0)):
                if old is not None or SetLog.objects.filter(entry__session__client=session.client, entry__exercise=ex).exclude(entry__session=session).exists():
                    out.append(_record(session, best, PersonalRecord.Kind.WEIGHT, weight_kg=best.weight_kg, reps=best.reps))
    return out


def _record(session, s, kind, **vals):
    SetLog.objects.filter(pk=s.pk).update(is_pr=True)
    return PersonalRecord.objects.create(client=session.client, exercise=s.entry.exercise, kind=kind, achieved_on=session.scheduled_date,
                                         session=session, set_log=s, **vals)


@transaction.atomic
def swap_exercise(entry: SessionExercise, new_exercise, reason=""):
    if entry.swapped_from_id is None:
        entry.swapped_from = entry.exercise
    entry.exercise = new_exercise
    entry.name = new_exercise.name
    entry.swap_reason = reason
    entry.save()
    return entry


def restart_session(session):
    SetLog.objects.filter(entry__session=session).update(done=False, skipped=False, done_at=None, done_at_s=None, is_pr=False)
    session.started_at = timezone.now()
    session.paused_at = None
    session.paused_s = 0
    session.time_adjust_s = 0
    session.rest_s = 0
    session.status = WorkoutSession.Status.IN_PROGRESS
    session.save()
    session.recalc()
