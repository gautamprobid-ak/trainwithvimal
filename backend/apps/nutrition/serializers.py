from decimal import Decimal

from django.db import transaction
from rest_framework import serializers

from apps.core.permissions import role_of

from .models import (
    MACROS, Food, FoodImport, FoodLogEntry, FoodSwap, FoodUnit, MealDayChange, MealItem, MealItemAlternative, MealLog,
    MealOption, MealPlan, MealPlanAssignment, NutritionTarget, PlanMeal, Recipe, RecipeIngredient, UnitSuggestion,
)
from .services import amount_text, fmt_macros


# ---------------------------------------------------------------- foods
class FoodUnitSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)

    class Meta:
        model = FoodUnit
        fields = ("id", "name", "grams", "position")


class FoodSwapSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)
    alternative_name = serializers.CharField(source="alternative.name", read_only=True)

    class Meta:
        model = FoodSwap
        fields = ("id", "alternative", "alternative_name", "match", "position")


class UnitSuggestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = UnitSuggestion
        fields = ("id", "name", "grams", "position")


def sync_children(parent_qs, rows, create, fields):
    """Upsert children by id; delete the ones not sent."""
    keep = []
    existing = {o.id: o for o in parent_qs}
    for pos, row in enumerate(rows):
        row = dict(row)
        row.setdefault("position", pos)
        oid = row.pop("id", None)
        if oid and oid in existing:
            obj = existing[oid]
            for f in fields:
                if f in row:
                    setattr(obj, f, row[f])
            obj.save()
        else:
            obj = create(**{f: row[f] for f in fields if f in row})
        keep.append(obj.id)
    for oid, obj in existing.items():
        if oid not in keep:
            obj.delete()
    return keep


class FoodSerializer(serializers.ModelSerializer):
    units = FoodUnitSerializer(many=True, required=False)
    swaps = FoodSwapSerializer(many=True, required=False)
    is_custom = serializers.BooleanField(read_only=True)
    group_label = serializers.CharField(source="get_group_display", read_only=True)
    diet_label = serializers.CharField(source="get_diet_display", read_only=True)
    per_100g = serializers.SerializerMethodField()
    per_serving = serializers.SerializerMethodField()
    serving = serializers.SerializerMethodField()
    used_in = serializers.SerializerMethodField()

    class Meta:
        model = Food
        fields = (
            "id", "name", "local_name", "brand", "group", "group_label", "category", "diet", "diet_label",
            "kcal", "protein", "carbs", "fat", "fibre", "sodium_mg", "iron_mg", "calcium_mg", "potassium_mg",
            "default_unit_name", "default_qty", "qty_step", "is_liquid", "is_raw", "source", "reference", "is_custom",
            "owner_client", "archived", "units", "swaps", "per_100g", "per_serving", "serving", "used_in", "created_at", "updated_at",
        )
        read_only_fields = ("owner_client",)

    def get_per_100g(self, o):
        return {"kcal": float(o.kcal), "protein": float(o.protein), "carbs": float(o.carbs), "fat": float(o.fat), "fibre": float(o.fibre)}

    def get_per_serving(self, o):
        g = o.default_grams
        m = fmt_macros(o.macros_for_grams(g))
        m["fibre"] = round(float(o.fibre * g / 100), 1)
        m["grams"] = float(g)
        return m

    def get_serving(self, o):
        """Display text like '1 katori · 150 g' or '2 × 1 piece · 140 g'."""
        u, q = o.default_unit_name, o.default_qty
        if u == "g":
            return f"{int(q)} g"
        g = o.unit_grams(u) * q
        return (f"{u} · {g.normalize():f} g" if q == 1 else f"{q.normalize():f} × {u} · {g.normalize():f} g")

    def get_used_in(self, o):
        if not self.context.get("detail"):
            return None
        rows = (MealItem.objects.filter(food=o, option__meal__plan__kind=MealPlan.Kind.TEMPLATE)
                .values_list("option__meal__plan__id", "option__meal__plan__name", "option__meal__name").distinct())
        out = {}
        for pid, pname, meal in rows:
            out.setdefault(pid, {"plan": pid, "name": pname, "meals": []})
            if meal not in out[pid]["meals"]:
                out[pid]["meals"].append(meal)
        return list(out.values())

    def validate(self, attrs):
        units = attrs.get("units")
        if units is not None and not any(u["name"] == "g" for u in units):
            units.insert(0, {"name": "g", "grams": Decimal("1")})
        return attrs

    def _children(self, food, units, swaps):
        if units is not None:
            sync_children(food.units.all(), units, lambda **kw: FoodUnit.objects.create(food=food, **kw), ("name", "grams", "position"))
        if swaps is not None:
            sync_children(food.swaps.all(), swaps, lambda **kw: FoodSwap.objects.create(food=food, **kw), ("alternative", "match", "position"))

    @transaction.atomic
    def create(self, validated):
        units = validated.pop("units", None) or [{"name": "g", "grams": Decimal("1")}]
        swaps = validated.pop("swaps", None)
        food = Food.objects.create(**validated)
        self._children(food, units, swaps)
        return food

    @transaction.atomic
    def update(self, food, validated):
        units = validated.pop("units", None)
        swaps = validated.pop("swaps", None)
        for k, v in validated.items():
            setattr(food, k, v)
        food.save()
        self._children(food, units, swaps)
        return food


class FoodImportSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodImport
        fields = ("id", "file_name", "file", "status", "duplicates", "egg_is_non_veg", "mappings", "rows",
                  "created_count", "updated_count", "skipped_count", "uploaded_by", "created_at")
        read_only_fields = ("status", "created_count", "updated_count", "skipped_count", "uploaded_by")


# ---------------------------------------------------------------- recipes
class RecipeIngredientSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)
    food_name = serializers.CharField(source="food.name", read_only=True)

    class Meta:
        model = RecipeIngredient
        fields = ("id", "food", "food_name", "unit_name", "quantity", "position")


class RecipeSerializer(serializers.ModelSerializer):
    ingredients = RecipeIngredientSerializer(many=True, required=False)
    totals = serializers.SerializerMethodField()
    per_serving = serializers.SerializerMethodField()

    class Meta:
        model = Recipe
        fields = ("id", "name", "description", "method", "diet", "servings", "serving_name", "prep_minutes",
                  "archived", "ingredients", "totals", "per_serving", "created_at", "updated_at")

    def get_totals(self, o):
        return fmt_macros(o.totals())

    def get_per_serving(self, o):
        return fmt_macros(o.per_serving())

    @transaction.atomic
    def create(self, validated):
        ings = validated.pop("ingredients", [])
        rec = Recipe.objects.create(**validated)
        sync_children(rec.ingredients.none(), ings, lambda **kw: RecipeIngredient.objects.create(recipe=rec, **kw), ("food", "unit_name", "quantity", "position"))
        return rec

    @transaction.atomic
    def update(self, rec, validated):
        ings = validated.pop("ingredients", None)
        for k, v in validated.items():
            setattr(rec, k, v)
        rec.save()
        if ings is not None:
            sync_children(rec.ingredients.all(), ings, lambda **kw: RecipeIngredient.objects.create(recipe=rec, **kw), ("food", "unit_name", "quantity", "position"))
        return rec


# ---------------------------------------------------------------- meal plans (nested builder save)
class AlternativeSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)
    food_name = serializers.CharField(source="food.name", read_only=True)
    amount = serializers.SerializerMethodField()
    macros = serializers.SerializerMethodField()

    class Meta:
        model = MealItemAlternative
        fields = ("id", "food", "food_name", "unit_name", "quantity", "amount", "match", "position", "macros")

    def get_amount(self, o):
        return amount_text(o.unit_name, o.quantity)

    def get_macros(self, o):
        return fmt_macros(o.macros())


class MealItemSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)
    alternatives = AlternativeSerializer(many=True, required=False)
    name = serializers.CharField(source="display_name", read_only=True)
    amount = serializers.SerializerMethodField()
    grams = serializers.SerializerMethodField()
    units = serializers.SerializerMethodField()
    per_100g = serializers.SerializerMethodField()

    class Meta:
        model = MealItem
        fields = ("id", "food", "recipe", "custom_name", "name", "unit_name", "quantity", "amount", "grams", "note", "position",
                  "kcal", "protein", "carbs", "fat", "units", "per_100g", "alternatives")
        extra_kwargs = {k: {"required": False} for k in ("kcal", "protein", "carbs", "fat")}

    def get_amount(self, o):
        return amount_text(o.unit_name, o.quantity)

    def get_grams(self, o):
        g = o.grams
        return float(g) if g is not None else None

    def get_units(self, o):
        return [{"name": u.name, "grams": float(u.grams)} for u in o.food.units.all()] if o.food_id else []

    def get_per_100g(self, o):
        f = o.food
        return {k: float(getattr(f, k)) for k in MACROS} if f else None

    def validate(self, attrs):
        if not (attrs.get("food") or attrs.get("recipe") or attrs.get("custom_name")) and not self.partial:
            raise serializers.ValidationError("Pick a food, a recipe or type a name.")
        return attrs


class MealOptionSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)
    items = MealItemSerializer(many=True, required=False)
    is_default = serializers.SerializerMethodField()
    totals = serializers.SerializerMethodField()

    class Meta:
        model = MealOption
        fields = ("id", "name", "position", "is_default", "totals", "items")

    def get_is_default(self, o):
        return o.meal.default_option_id == o.id if o.meal.default_option_id else o.position == 0

    def get_totals(self, o):
        return fmt_macros({k: sum((getattr(i, k) for i in o.items.all()), Decimal(0)) for k in MACROS})


class PlanMealSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False)
    options = MealOptionSerializer(many=True, required=False)
    default_option_index = serializers.IntegerField(write_only=True, required=False, help_text="Index in options of the default tab")

    class Meta:
        model = PlanMeal
        fields = ("id", "name", "time", "target_kcal", "position", "default_option", "default_option_index", "options")
        read_only_fields = ("default_option",)


class MealPlanAssignmentSerializer(serializers.ModelSerializer):
    client_name = serializers.CharField(source="client.user.full_name", read_only=True)
    plan_name = serializers.CharField(source="plan.name", read_only=True)
    is_custom = serializers.BooleanField(read_only=True)

    class Meta:
        model = MealPlanAssignment
        fields = ("id", "plan", "plan_name", "client", "client_name", "custom_plan", "note", "is_custom", "active",
                  "starts_on", "ends_on", "assigned_by", "created_at")
        read_only_fields = ("assigned_by",)


class MealPlanListSerializer(serializers.ModelSerializer):
    meal_names = serializers.SerializerMethodField()
    option_count = serializers.SerializerMethodField()
    clients = serializers.SerializerMethodField()
    client_count = serializers.SerializerMethodField()
    custom_count = serializers.SerializerMethodField()
    is_live = serializers.SerializerMethodField()

    class Meta:
        model = MealPlan
        fields = ("id", "name", "description", "kind", "diet", "status", "has_unpublished_changes", "is_live", "version", "published_at",
                  "kcal", "protein", "carbs", "fat", "fibre", "water_ml", "allow_swaps", "allow_any_food", "allow_option_switch",
                  "allow_off_plan", "source", "client", "personal_notes", "meal_names", "option_count", "clients", "client_count",
                  "custom_count", "created_by", "created_at", "updated_at")
        read_only_fields = ("status", "has_unpublished_changes", "version", "published_at", "created_by")

    def get_meal_names(self, o):
        return [m.name for m in o.meals.all()]

    def get_option_count(self, o):
        return sum(len(m.options.all()) for m in o.meals.all())

    def _active(self, o):
        return [a for a in o.assignments.all() if a.active]

    def get_clients(self, o):
        return [{"assignment": a.id, "client": a.client_id, "name": a.client.user.full_name, "note": a.note, "custom": a.is_custom,
                 "custom_plan": a.custom_plan_id} for a in self._active(o)]

    def get_client_count(self, o):
        return len(self._active(o))

    def get_custom_count(self, o):
        return sum(1 for a in self._active(o) if a.is_custom)

    def get_is_live(self, o):
        return o.status == MealPlan.Status.PUBLISHED and not o.has_unpublished_changes


class MealPlanSerializer(MealPlanListSerializer):
    """Full tree; a PUT/PATCH with `meals` saves the whole builder at once (upsert by id, delete missing)."""

    meals = PlanMealSerializer(many=True, required=False)

    class Meta(MealPlanListSerializer.Meta):
        fields = MealPlanListSerializer.Meta.fields + ("meals",)

    @transaction.atomic
    def create(self, validated):
        meals = validated.pop("meals", [])
        plan = MealPlan.objects.create(**validated)
        self._save_meals(plan, meals)
        return plan

    @transaction.atomic
    def update(self, plan, validated):
        meals = validated.pop("meals", None)
        for k, v in validated.items():
            setattr(plan, k, v)
        if plan.status == MealPlan.Status.PUBLISHED:
            plan.has_unpublished_changes = True
        plan.save()
        if meals is not None:
            self._save_meals(plan, meals)
        return plan

    def _save_meals(self, plan, meals):
        existing = {m.id: m for m in plan.meals.all()}
        keep = []
        for pos, md in enumerate(meals):
            md = dict(md)
            options = md.pop("options", None)
            default_idx = md.pop("default_option_index", None)
            mid = md.pop("id", None)
            md.setdefault("position", pos)
            meal = existing.get(mid)
            if meal:
                for k, v in md.items():
                    setattr(meal, k, v)
                meal.save()
            else:
                meal = PlanMeal.objects.create(plan=plan, **md)
            keep.append(meal.id)
            if options is not None:
                opt_ids = self._save_options(meal, options)
                if default_idx is not None and 0 <= default_idx < len(opt_ids):
                    meal.default_option_id = opt_ids[default_idx]
                elif meal.default_option_id not in opt_ids:
                    meal.default_option_id = opt_ids[0] if opt_ids else None
                meal.save(update_fields=["default_option"])
        for mid, m in existing.items():
            if mid not in keep:
                m.delete()

    def _save_options(self, meal, options):
        existing = {o.id: o for o in meal.options.all()}
        ids = []
        for pos, od in enumerate(options):
            od = dict(od)
            items = od.pop("items", None)
            oid = od.pop("id", None)
            od.setdefault("position", pos)
            opt = existing.get(oid)
            if opt:
                for k, v in od.items():
                    setattr(opt, k, v)
                opt.save()
            else:
                opt = MealOption.objects.create(meal=meal, **od)
            ids.append(opt.id)
            if items is not None:
                self._save_items(opt, items)
        for oid, o in existing.items():
            if oid not in ids:
                if meal.default_option_id == oid:
                    meal.default_option = None
                    meal.save(update_fields=["default_option"])
                o.delete()
        return ids

    def _save_items(self, opt, items):
        existing = {i.id: i for i in opt.items.all()}
        keep = []
        for pos, idata in enumerate(items):
            idata = dict(idata)
            alts = idata.pop("alternatives", None)
            iid = idata.pop("id", None)
            idata.setdefault("position", pos)
            item = existing.get(iid)
            if item:
                for k, v in idata.items():
                    setattr(item, k, v)
                item.save()
            else:
                item = MealItem.objects.create(option=opt, **idata)
            keep.append(item.id)
            if alts is not None:
                sync_children(item.alternatives.all(), alts, lambda **kw: MealItemAlternative.objects.create(item=item, **kw),
                              ("food", "unit_name", "quantity", "match", "position"))
        for iid, i in existing.items():
            if iid not in keep:
                i.delete()


class NutritionTargetSerializer(serializers.ModelSerializer):
    class Meta:
        model = NutritionTarget
        fields = ("id", "client", "effective_from", "kcal", "protein", "carbs", "fat", "fibre", "water_ml", "set_by", "created_at")
        read_only_fields = ("set_by",)
        extra_kwargs = {"client": {"required": False}}


# ---------------------------------------------------------------- logs
class MealLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = MealLog
        fields = ("id", "client", "date", "meal", "meal_name", "option", "status", "eaten_at", "as_planned", "kcal", "protein", "carbs", "fat", "created_at")
        read_only_fields = fields


class MealDayChangeSerializer(serializers.ModelSerializer):
    class Meta:
        model = MealDayChange
        fields = ("id", "client", "date", "item", "alternative", "quantity")
        read_only_fields = fields


class FoodLogEntrySerializer(serializers.ModelSerializer):
    meal_name = serializers.SerializerMethodField()

    class Meta:
        model = FoodLogEntry
        fields = ("id", "client", "date", "logged_at", "meal", "meal_name", "meal_slot", "kind", "food", "recipe", "name", "amount",
                  "unit_name", "quantity", "grams", "kcal", "protein", "carbs", "fat", "from_plan", "off_plan", "off_plan_reason",
                  "copied_from", "created_at")
        read_only_fields = ("grams", "copied_from")
        extra_kwargs = {"client": {"required": False}, "name": {"required": False}}

    def get_meal_name(self, o):
        return o.meal.name if o.meal_id else o.meal_slot

    def validate(self, attrs):
        kind = attrs.get("kind", getattr(self.instance, "kind", FoodLogEntry.Kind.FOOD))
        food = attrs.get("food", getattr(self.instance, "food", None))
        if kind == FoodLogEntry.Kind.QUICK_ADD and not attrs.get("kcal", getattr(self.instance, "kcal", 0)):
            raise serializers.ValidationError({"kcal": "Enter the calories first. Protein, carbs and fat are optional."})
        if kind == FoodLogEntry.Kind.FOOD and not food and not attrs.get("name", getattr(self.instance, "name", "")):
            raise serializers.ValidationError({"food": "Pick a food or type a name."})
        if food:
            attrs.setdefault("name", food.name)
            if attrs.get("quantity") is None and not self.instance:
                attrs["quantity"] = food.default_qty
                attrs.setdefault("unit_name", food.default_unit_name)
        if kind == FoodLogEntry.Kind.QUICK_ADD:
            attrs.setdefault("name", "Quick add")
            attrs.setdefault("amount", "1 entry")
        if attrs.get("off_plan") is False:
            attrs["off_plan_reason"] = ""
        return attrs

    def _finish(self, obj):
        obj.compute()
        if obj.food_id and obj.quantity is not None and not obj.amount:
            obj.amount = amount_text(obj.unit_name or "g", obj.quantity)
        obj.save()
        return obj

    def create(self, validated):
        return self._finish(FoodLogEntry(**validated))

    def update(self, obj, validated):
        for k, v in validated.items():
            setattr(obj, k, v)
        if "quantity" in validated or "unit_name" in validated:
            obj.amount = validated.get("amount", "")
        return self._finish(obj)


def is_staff_user(user):
    return role_of(user) in {"admin", "trainer"}
