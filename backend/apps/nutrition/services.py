"""Day / week maths for the client food screens (Home, Food, Nutrition)."""
from datetime import datetime, time, timedelta
from decimal import Decimal

from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from .models import (
    MACROS, D0, FoodLogEntry, MealDayChange, MealItem, MealLog, MealPlan, MealPlanAssignment,
    NutritionTarget, PlanMeal, dec,
)


def r(v, places="0.1"):
    return float(dec(v, places))


def add(a, b):
    return {k: a.get(k, D0) + b.get(k, D0) for k in MACROS}


def zero():
    return {k: D0 for k in MACROS}


def macros_of(obj):
    return {k: getattr(obj, k) for k in MACROS}


def fmt_macros(m):
    return {"kcal": r(m["kcal"], "1"), "protein": r(m["protein"]), "carbs": r(m["carbs"]), "fat": r(m["fat"])}


def amount_text(unit, qty):
    """60 g · 1 scoop · 10 pieces · 2 medium (same rule as the design)."""
    plural = {"piece": "pieces", "scoop": "scoops", "plate": "plates", "bowl": "bowls", "slice": "slices", "glass": "glasses",
              "egg white": "egg whites", "cube": "cubes", "katori": "katoris", "cup": "cups"}
    q = Decimal(str(qty))
    if unit in ("g", "ml", "", None):
        return f"{int(q.quantize(Decimal('1')))} {unit or 'g'}"
    w = unit[2:] if unit.startswith("1 ") else unit
    qs = str(int(q)) if q == q.to_integral_value() else str(q.quantize(Decimal("0.1")).normalize())
    return f"{qs} {w if q == 1 else plural.get(w, w)}"


# ---------------------------------------------------------------- plan + targets
def active_assignment(client, day):
    return (
        MealPlanAssignment.objects.filter(client=client, active=True)
        .filter(Q(starts_on__isnull=True) | Q(starts_on__lte=day))
        .filter(Q(ends_on__isnull=True) | Q(ends_on__gte=day))
        .select_related("plan", "custom_plan")
        .order_by("-created_at")
        .first()
    )


def plan_for(client, day):
    a = active_assignment(client, day)
    if a:
        return a.effective_plan
    return MealPlan.objects.filter(kind=MealPlan.Kind.CLIENT, client=client).exclude(status=MealPlan.Status.ARCHIVED).first()


def targets_for(client, day, plan=None):
    t = NutritionTarget.objects.filter(client=client, effective_from__lte=day).first()
    if t:
        return {"kcal": t.kcal, "protein": t.protein, "carbs": t.carbs, "fat": t.fat, "fibre": t.fibre, "water_ml": t.water_ml}
    if plan:
        return {"kcal": plan.kcal, "protein": plan.protein, "carbs": plan.carbs, "fat": plan.fat, "fibre": plan.fibre, "water_ml": plan.water_ml}
    return None


def plan_meals(plan):
    if not plan:
        return []
    return list(
        PlanMeal.objects.filter(plan=plan)
        .select_related("default_option")
        .prefetch_related("options__items__food__units", "options__items__recipe", "options__items__alternatives__food__units")
        .order_by("position", "id")
    )


def option_of(meal, option_id=None):
    opts = list(meal.options.all())
    if option_id:
        for o in opts:
            if o.id == option_id:
                return o
    if meal.default_option_id:
        for o in opts:
            if o.id == meal.default_option_id:
                return o
    return opts[0] if opts else None


def item_today(item, change):
    """The food in a meal on a day: the planned one or its swap, with that day's portion."""
    alts = list(item.alternatives.all())
    alt = None
    if change and change.alternative_id:
        alt = next((a for a in alts if a.id == change.alternative_id), None)
    if alt:
        qty = change.quantity if change.quantity is not None else alt.quantity
        m = alt.food.macros_for(alt.unit_name, qty)
        name, unit, food = alt.food.name, alt.unit_name, alt.food
    else:
        qty = change.quantity if change and change.quantity is not None else item.quantity
        if item.food_id:
            m = item.food.macros_for(item.unit_name, qty)
        else:
            base = item.quantity or Decimal("1")
            m = {k: getattr(item, k) * qty / base for k in MACROS}
        name, unit, food = item.display_name, item.unit_name, item.food
    return {
        "item": item.id, "name": name, "planned_name": item.display_name, "food": food.id if food else None,
        "unit": unit, "quantity": float(qty), "amount": amount_text(unit, qty),
        "grams": float(food.unit_grams(unit) * qty) if food else None,
        "swapped": bool(alt), "alternative": alt.id if alt else None, "portion_changed": bool(change and change.quantity is not None),
        "macros": fmt_macros(m), "_m": m,
        "alternatives": [
            {"id": a.id, "food": a.food_id, "name": a.food.name, "unit": a.unit_name, "quantity": float(a.quantity),
             "amount": amount_text(a.unit_name, a.quantity), "match": a.match, "macros": fmt_macros(a.macros())}
            for a in alts
        ],
    }


def meal_today(meal, changes, option=None):
    opt = option or option_of(meal)
    items = [item_today(i, changes.get(i.id)) for i in (opt.items.all() if opt else [])]
    total = zero()
    for i in items:
        total = add(total, i.pop("_m"))
    return opt, items, total


def _minutes(dt):
    if not dt:
        return None
    lt = timezone.localtime(dt)
    return lt.hour * 60 + lt.minute


def day_summary(client, day, now=None):
    """Everything the Food / Nutrition / Home screens need for one day."""
    plan = plan_for(client, day)
    targets = targets_for(client, day, plan)
    meals = plan_meals(plan)
    logs = {l.meal_id: l for l in MealLog.objects.filter(client=client, date=day)}
    changes = {c.item_id: c for c in MealDayChange.objects.filter(client=client, date=day)}
    entries = list(FoodLogEntry.objects.filter(client=client, date=day).select_related("meal"))

    out_meals, total, next_meal = [], zero(), None
    for idx, m in enumerate(meals):
        log = logs.get(m.id)
        opt, items, planned = meal_today(m, changes, log.option if log and log.option_id else None)
        status = log.status if log else "planned"
        counted = macros_of(log) if log and log.status == MealLog.Status.EATEN else None
        if counted:
            total = add(total, counted)
        if not log and next_meal is None:
            next_meal = idx
        extra = [e for e in entries if e.meal_id == m.id]
        out_meals.append({
            "id": m.id, "index": idx, "name": m.name, "time": m.time.strftime("%H:%M"),
            "time_label": m.time.strftime("%I:%M %p").lstrip("0").lower(),
            "target_kcal": m.target_kcal, "option": opt.id if opt else None, "option_name": opt.name if opt else "",
            "options": [{"id": o.id, "name": o.name, "default": o.id == (m.default_option_id or (opt.id if opt else None))} for o in m.options.all()],
            "status": status, "log_id": log.id if log else None,
            "eaten_at": timezone.localtime(log.eaten_at).isoformat() if log and log.eaten_at else None,
            "eaten_minute": _minutes(log.eaten_at) if log else None,
            "planned": fmt_macros(planned), "counted": fmt_macros(counted) if counted else None,
            "items": items, "summary": ", ".join(i["name"] if k == 0 else i["name"].lower() for k, i in enumerate(items)),
            "extra_entries": [e.id for e in extra],
        })
    if next_meal is not None:
        out_meals[next_meal]["is_next"] = True

    for e in entries:
        total = add(total, macros_of(e))

    tgt = targets or {"kcal": 0, "protein": 0, "carbs": 0, "fat": 0}
    totals = fmt_macros(total)
    eaten = sum(1 for x in out_meals if x["status"] == "eaten")
    return {
        "date": day.isoformat(),
        "plan": {"id": plan.id, "name": plan.name, "diet": plan.diet, "personal_notes": plan.personal_notes,
                 "allow_swaps": plan.allow_swaps, "allow_any_food": plan.allow_any_food,
                 "allow_option_switch": plan.allow_option_switch, "allow_off_plan": plan.allow_off_plan} if plan else None,
        "targets": targets,
        "totals": totals,
        "left": {k: round(tgt[k] - totals[k], 1) for k in MACROS} if targets else None,
        "percent": {k: (min(100, round(totals[k] / tgt[k] * 100)) if tgt.get(k) else 0) for k in MACROS},
        "meals": out_meals,
        "meals_eaten": eaten, "meals_total": len(out_meals),
        "next_meal": out_meals[next_meal] if next_meal is not None else None,
        "entries": [entry_dict(e) for e in entries],
        "log_rows": log_rows(out_meals, entries),
    }


def entry_dict(e):
    return {
        "id": e.id, "name": e.name, "amount": e.amount, "kind": e.kind, "meal": e.meal_id,
        "meal_name": e.meal.name if e.meal_id else e.meal_slot, "minute": _minutes(e.logged_at),
        "logged_at": timezone.localtime(e.logged_at).isoformat() if e.logged_at else None,
        "macros": fmt_macros(macros_of(e)), "off_plan": e.off_plan, "off_plan_reason": e.off_plan_reason, "from_plan": e.from_plan,
    }


def log_rows(meals, entries):
    """Food log tab: eaten plan meals + extra entries, by time."""
    rows = [{"type": "meal", "meal": m["id"], "minute": m["eaten_minute"], "title": m["summary"], "subtitle": f'{m["name"]} · from plan',
             "kcal": m["counted"]["kcal"]} for m in meals if m["status"] == "eaten"]
    rows += [{"type": "entry", "entry": e.id, "minute": _minutes(e.logged_at), "title": e.name,
              "subtitle": f'{e.meal.name if e.meal_id else e.meal_slot} · {e.amount}'.strip(" ·"), "kcal": r(e.kcal, "1")} for e in entries]
    return sorted(rows, key=lambda x: (x["minute"] is None, x["minute"] or 0))


def day_totals(client, day):
    t = zero()
    for l in MealLog.objects.filter(client=client, date=day, status=MealLog.Status.EATEN):
        t = add(t, macros_of(l))
    for e in FoodLogEntry.objects.filter(client=client, date=day):
        t = add(t, macros_of(e))
    return t


def week_summary(client, day):
    """This week (Mon–Sun) bars + averages over logged days, and last-7-day adherence."""
    monday = day - timedelta(days=day.weekday())
    plan = plan_for(client, day)
    targets = targets_for(client, day, plan)
    days, logged = [], []
    for i in range(7):
        d = monday + timedelta(days=i)
        has = MealLog.objects.filter(client=client, date=d, status=MealLog.Status.EATEN).exists() or FoodLogEntry.objects.filter(client=client, date=d).exists()
        t = fmt_macros(day_totals(client, d)) if has and d <= day else None
        days.append({"date": d.isoformat(), "weekday": d.strftime("%a"), "today": d == day, "future": d > day, "totals": t,
                     "over": bool(t and targets and t["kcal"] > targets["kcal"] * 1.03)})
        if t and t["kcal"] > 0:
            logged.append(t)
    avg = {k: round(sum(x[k] for x in logged) / len(logged), 1) for k in MACROS} if logged else None
    return {"week_start": monday.isoformat(), "targets": targets, "days": days, "logged_days": len(logged), "average": avg}


# ---------------------------------------------------------------- actions
def _meal_in_plan(client, day, meal_id):
    plan = plan_for(client, day)
    return PlanMeal.objects.filter(plan=plan, id=meal_id).first() if plan else None


@transaction.atomic
def mark_eaten(client, day, meal, at=None, option=None):
    changes = {c.item_id: c for c in MealDayChange.objects.filter(client=client, date=day, item__option__meal=meal)}
    opt, items, m = meal_today(meal, changes, option)
    if at is None:
        at = timezone.now() if day == timezone.localdate() else timezone.make_aware(datetime.combine(day, meal.time))
    log, _ = MealLog.objects.update_or_create(
        client=client, date=day, meal=meal,
        defaults={"status": MealLog.Status.EATEN, "eaten_at": at, "option": opt, "meal_name": meal.name,
                  "as_planned": not changes, **{k: dec(m[k], "0.01") for k in MACROS}},
    )
    return log


def mark_skipped(client, day, meal):
    log, _ = MealLog.objects.update_or_create(
        client=client, date=day, meal=meal,
        defaults={"status": MealLog.Status.SKIPPED, "eaten_at": None, "meal_name": meal.name, **{k: D0 for k in MACROS}},
    )
    return log


def clear_meal(client, day, meal):
    return MealLog.objects.filter(client=client, date=day, meal=meal).delete()[0]


def set_change(client, day, item, alternative=None, quantity=None, clear=False):
    if clear:
        MealDayChange.objects.filter(client=client, date=day, item=item).delete()
        return None
    ch, _ = MealDayChange.objects.update_or_create(client=client, date=day, item=item, defaults={"alternative": alternative, "quantity": quantity})
    if ch.alternative_id is None and ch.quantity is None:
        ch.delete()
        return None
    return ch


@transaction.atomic
def copy_day_entries(client, from_day, to_day):
    have = set(FoodLogEntry.objects.filter(client=client, date=to_day).exclude(copied_from=None).values_list("copied_from_id", flat=True))
    created = []
    for e in FoodLogEntry.objects.filter(client=client, date=from_day):
        if e.id in have:
            continue
        at = None
        if e.logged_at:
            lt = timezone.localtime(e.logged_at)
            at = timezone.make_aware(datetime.combine(to_day, time(lt.hour, lt.minute)))
        new = FoodLogEntry.objects.create(
            client=client, date=to_day, logged_at=at, meal=e.meal, meal_slot=e.meal_slot, kind=e.kind, food=e.food, recipe=e.recipe,
            name=e.name, amount=e.amount, unit_name=e.unit_name, quantity=e.quantity, grams=e.grams,
            kcal=e.kcal, protein=e.protein, carbs=e.carbs, fat=e.fat, off_plan=e.off_plan, off_plan_reason=e.off_plan_reason, copied_from=e,
        )
        created.append(new)
    return created


# ---------------------------------------------------------------- plan copies
@transaction.atomic
def copy_plan(plan, **overrides):
    """Deep copy a plan (Duplicate, or make a client's custom version)."""
    meals = list(plan.meals.prefetch_related("options__items__alternatives").order_by("position", "id"))
    new = MealPlan.objects.get(pk=plan.pk)
    new.pk = None
    new.id = None
    new.status = MealPlan.Status.DRAFT
    new.version = 1
    new.published_at = None
    new.has_unpublished_changes = False
    for k, v in overrides.items():
        setattr(new, k, v)
    new.save()
    for m in meals:
        default_id = m.default_option_id
        nm = PlanMeal.objects.create(plan=new, name=m.name, time=m.time, target_kcal=m.target_kcal, position=m.position)
        for o in m.options.all():
            no = nm.options.create(name=o.name, position=o.position)
            if o.id == default_id:
                nm.default_option = no
            for it in o.items.all():
                ni = MealItem.objects.create(option=no, food=it.food, recipe=it.recipe, custom_name=it.custom_name, unit_name=it.unit_name,
                                             quantity=it.quantity, note=it.note, position=it.position,
                                             kcal=it.kcal, protein=it.protein, carbs=it.carbs, fat=it.fat)
                for a in it.alternatives.all():
                    ni.alternatives.create(food=a.food, unit_name=a.unit_name, quantity=a.quantity, match=a.match, position=a.position)
        if nm.default_option_id:
            nm.save(update_fields=["default_option"])
    return new
