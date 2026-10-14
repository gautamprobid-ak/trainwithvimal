"""Foods, recipes, meal plans and what clients eat.

Screens: Admin/Trainer · Nutrition & foods (meal plans tab, food library tab,
Excel import), Meal plan builder, Client profile · Plans / Logs (meals);
Client · Home (food ring, next meal), Food (meal plan of the day: eat / undo /
swap / portions / skip), Log food (search, recent, my foods, quick add,
custom food, off-plan), Nutrition (today ring, week bars, food log, copy
yesterday).

Numbers are stored as numbers: nutrition per 100 g on Food, macros as Decimal,
kcal as Decimal (fractions matter when multiplied by grams).
"""
from decimal import ROUND_HALF_UP, Decimal

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models

from apps.core.models import OrderedModel, TimeStampedModel

D0 = Decimal("0")
MACROS = ("kcal", "protein", "carbs", "fat")


def dec(v, places="0.001"):
    return Decimal(str(v or 0)).quantize(Decimal(places), rounding=ROUND_HALF_UP)


class Diet(models.TextChoices):
    VEG = "veg", "Vegetarian"
    EGG = "egg", "Eggetarian"
    NON_VEG = "non_veg", "Non-veg"
    VEGAN = "vegan", "Vegan"


class FoodGroup(models.TextChoices):
    PROTEIN = "protein", "Protein"
    CARBS = "carbs", "Carbs"
    FATS = "fats", "Fats"
    VEG = "veg", "Veg"
    FRUITS = "fruits", "Fruits"
    DAIRY = "dairy", "Dairy"
    INDIAN = "indian", "Indian dishes"
    BEVERAGES = "beverages", "Beverages"
    OTHER = "other", "Other"


# ---------------------------------------------------------------- foods
class Food(TimeStampedModel):
    """A food in the library. Nutrition is stored per 100 g (ml counts as g).

    `source` says who made it: the built-in Indian database (IFCT/USDA), the
    coaching team ("My foods" on the coach side), a client ("Mine" in Log food)
    or an Excel import.
    """

    class Source(models.TextChoices):
        BUILT_IN = "built_in", "Built-in"
        TEAM = "team", "Your team"
        CLIENT = "client", "Client"
        IMPORT = "import", "Excel import"

    name = models.CharField(max_length=160, db_index=True)
    local_name = models.CharField(max_length=160, blank=True, help_text="Indian / Hindi name, e.g. Dahi, Chaas")
    brand = models.CharField(max_length=80, blank=True)
    group = models.CharField(max_length=12, choices=FoodGroup.choices, default=FoodGroup.OTHER, db_index=True)
    category = models.CharField(max_length=60, blank=True, help_text="Sheet category from an import, e.g. Grains, Legumes")
    diet = models.CharField(max_length=8, choices=Diet.choices, default=Diet.VEG, db_index=True)

    kcal = models.DecimalField(max_digits=7, decimal_places=2, default=0, help_text="per 100 g")
    protein = models.DecimalField(max_digits=6, decimal_places=2, default=0, help_text="g per 100 g")
    carbs = models.DecimalField(max_digits=6, decimal_places=2, default=0, help_text="g per 100 g")
    fat = models.DecimalField(max_digits=6, decimal_places=2, default=0, help_text="g per 100 g")
    fibre = models.DecimalField(max_digits=6, decimal_places=2, default=0, help_text="g per 100 g")
    sodium_mg = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True, help_text="per 100 g")
    iron_mg = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True, help_text="per 100 g")
    calcium_mg = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True, help_text="per 100 g")
    potassium_mg = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True, help_text="per 100 g")

    default_unit_name = models.CharField(max_length=40, default="g", help_text="Unit picked by default when the food is added")
    default_qty = models.DecimalField(max_digits=8, decimal_places=2, default=100, help_text="Quantity of the default unit")
    qty_step = models.DecimalField(max_digits=6, decimal_places=2, default=1, help_text="Stepper step for unit-based amounts (g always steps 10)")
    is_liquid = models.BooleanField(default=False, help_text="Measured in ml (1 ml = 1 g)")
    is_raw = models.BooleanField(default=False, help_text="Raw / uncooked weight")

    source = models.CharField(max_length=10, choices=Source.choices, default=Source.BUILT_IN, db_index=True)
    reference = models.CharField(max_length=60, blank=True, help_text="Data source, e.g. IFCT, USDA, IFCT/USDA")
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    owner_client = models.ForeignKey(
        "people.ClientProfile", on_delete=models.CASCADE, null=True, blank=True, related_name="custom_foods",
        help_text="Set for foods a client created for themselves (only they see them)",
    )
    archived = models.BooleanField(default=False)

    class Meta:
        ordering = ("name",)
        indexes = [models.Index(fields=["source", "group"]), models.Index(fields=["owner_client", "archived"])]

    def __str__(self):
        return self.name

    @property
    def is_custom(self):
        return self.source in {self.Source.TEAM, self.Source.CLIENT}

    def unit_grams(self, unit_name):
        if not unit_name or unit_name == "g" or unit_name == "ml":
            return Decimal("1")
        u = next((u for u in self.units.all() if u.name == unit_name), None)
        return u.grams if u else Decimal("1")

    def macros_for_grams(self, grams):
        g = Decimal(str(grams)) / Decimal("100")
        return {k: getattr(self, k) * g for k in MACROS}

    def macros_for(self, unit_name, qty):
        return self.macros_for_grams(self.unit_grams(unit_name) * Decimal(str(qty)))

    @property
    def default_grams(self):
        return self.unit_grams(self.default_unit_name) * self.default_qty


class FoodUnit(OrderedModel):
    """A serving unit of a food: '1 katori' = 150 g. Every food also has 'g' (1 g)."""

    food = models.ForeignKey(Food, on_delete=models.CASCADE, related_name="units")
    name = models.CharField(max_length=40, help_text="e.g. g, 1 katori, 1 scoop, 1 medium")
    grams = models.DecimalField(max_digits=8, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))])

    class Meta(OrderedModel.Meta):
        constraints = [models.UniqueConstraint(fields=["food", "name"], name="uniq_food_unit")]

    def __str__(self):
        return f"{self.food} · {self.name} ({self.grams} g)"


class UnitSuggestion(OrderedModel):
    """Suggestions in the food editor's 'Add unit' menu (1 tsp = 5 g ...)."""

    name = models.CharField(max_length=40, unique=True)
    grams = models.DecimalField(max_digits=8, decimal_places=2)

    def __str__(self):
        return self.name


class FoodSwap(OrderedModel):
    """An approved alternative for a food, with a match % (shown in the food drawer and swap sheets)."""

    food = models.ForeignKey(Food, on_delete=models.CASCADE, related_name="swaps")
    alternative = models.ForeignKey(Food, on_delete=models.CASCADE, related_name="+")
    match = models.PositiveSmallIntegerField(default=80, validators=[MaxValueValidator(100)], help_text="Match %")

    class Meta(OrderedModel.Meta):
        constraints = [models.UniqueConstraint(fields=["food", "alternative"], name="uniq_food_swap")]

    def __str__(self):
        return f"{self.food} → {self.alternative} ({self.match}%)"


class FoodImport(TimeStampedModel):
    """An Excel / CSV food import (2 steps: upload → check and import)."""

    class Status(models.TextChoices):
        PREVIEW = "preview", "Checking"
        IMPORTED = "imported", "Imported"
        CANCELLED = "cancelled", "Cancelled"

    class Duplicates(models.TextChoices):
        SKIP = "skip", "Skip foods I already have"
        REPLACE = "replace", "Replace them"
        KEEP_BOTH = "keep_both", "Keep both"

    file_name = models.CharField(max_length=200, blank=True)
    file = models.FileField(upload_to="food-imports/", blank=True)
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name="+")
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PREVIEW)
    duplicates = models.CharField(max_length=10, choices=Duplicates.choices, default=Duplicates.SKIP)
    egg_is_non_veg = models.BooleanField(default=False, help_text="Egg toggle: treat 'Non-Vegetarian' egg rows as Eggetarian when off")
    mappings = models.JSONField(default=dict, blank=True, help_text="Sheet category → food group mapping")
    rows = models.JSONField(default=list, blank=True, help_text="Parsed rows (name, category, unit, grams, per-100 g values ...)")
    created_count = models.PositiveIntegerField(default=0)
    updated_count = models.PositiveIntegerField(default=0)
    skipped_count = models.PositiveIntegerField(default=0)

    def __str__(self):
        return f"Import {self.file_name or self.pk} ({self.status})"


# ---------------------------------------------------------------- recipes
class Recipe(TimeStampedModel):
    """A recipe made of library foods (parked in the design, but plans can use it)."""

    name = models.CharField(max_length=160)
    description = models.TextField(blank=True)
    method = models.TextField(blank=True)
    diet = models.CharField(max_length=8, choices=Diet.choices, default=Diet.VEG)
    servings = models.PositiveSmallIntegerField(default=1)
    serving_name = models.CharField(max_length=40, default="1 serving")
    prep_minutes = models.PositiveSmallIntegerField(null=True, blank=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    archived = models.BooleanField(default=False)

    class Meta:
        ordering = ("name",)

    def __str__(self):
        return self.name

    def totals(self):
        t = {k: D0 for k in MACROS}
        for ing in self.ingredients.select_related("food").prefetch_related("food__units"):
            m = ing.food.macros_for(ing.unit_name, ing.quantity)
            for k in MACROS:
                t[k] += m[k]
        return t

    def per_serving(self):
        n = Decimal(self.servings or 1)
        return {k: v / n for k, v in self.totals().items()}


class RecipeIngredient(OrderedModel):
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE, related_name="ingredients")
    food = models.ForeignKey(Food, on_delete=models.PROTECT, related_name="+")
    unit_name = models.CharField(max_length=40, default="g")
    quantity = models.DecimalField(max_digits=8, decimal_places=2)

    def __str__(self):
        return f"{self.recipe}: {self.quantity} × {self.unit_name} {self.food}"


# ---------------------------------------------------------------- meal plans
class MealPlan(TimeStampedModel):
    """A master meal plan (template) or a client's own copy ('custom version').

    Tree: MealPlan → PlanMeal (Breakfast 8:00 am, target kcal) → MealOption
    (tabs: Veg / Eggs ...; one is the default) → MealItem (food + qty + unit)
    → MealItemAlternative (approved swaps with their own portion and match %).
    """

    class Kind(models.TextChoices):
        TEMPLATE = "template", "Master plan"
        CLIENT = "client", "Client plan"

    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        PUBLISHED = "published", "Published"
        ARCHIVED = "archived", "Archived"

    class DietType(models.TextChoices):
        VEG = "veg", "Veg"
        EGG = "egg", "Eggetarian"
        NON_VEG = "non_veg", "Non-veg"
        VEGAN = "vegan", "Vegan"

    name = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    kind = models.CharField(max_length=10, choices=Kind.choices, default=Kind.TEMPLATE, db_index=True)
    diet = models.CharField(max_length=8, choices=DietType.choices, default=DietType.VEG, db_index=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.DRAFT, db_index=True)
    has_unpublished_changes = models.BooleanField(default=False, help_text="Edited after publishing (clients have the old version)")
    version = models.PositiveIntegerField(default=1, help_text="Bumps on every publish")
    published_at = models.DateTimeField(null=True, blank=True)

    kcal = models.PositiveIntegerField(default=2000, validators=[MinValueValidator(800), MaxValueValidator(6000)])
    protein = models.PositiveIntegerField(default=120, help_text="g")
    carbs = models.PositiveIntegerField(default=200, help_text="g")
    fat = models.PositiveIntegerField(default=60, help_text="g")
    fibre = models.PositiveIntegerField(default=30, help_text="g")
    water_ml = models.PositiveIntegerField(default=3000)

    # Client permissions (builder toggles)
    allow_swaps = models.BooleanField(default=True, help_text="Client can swap within the approved list")
    allow_any_food = models.BooleanField(default=True, help_text="Client can search any food")
    allow_option_switch = models.BooleanField(default=True, help_text="Client can switch meal options")
    allow_off_plan = models.BooleanField(default=True, help_text="Allow off-plan meals (flagged to coach)")

    source = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="copies", help_text="Master plan this copy came from")
    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, null=True, blank=True, related_name="meal_plans",
                               help_text="Owner client for client plans")
    personal_notes = models.JSONField(default=list, blank=True, help_text="'Made for you' lines: [{label, text}]")
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ("-updated_at",)
        indexes = [models.Index(fields=["kind", "status"])]

    def __str__(self):
        return self.name


class PlanMeal(OrderedModel):
    plan = models.ForeignKey(MealPlan, on_delete=models.CASCADE, related_name="meals")
    name = models.CharField(max_length=60, help_text="Breakfast, Lunch, Snack, Dinner, Pre-workout ...")
    time = models.TimeField(help_text="e.g. 08:00")
    target_kcal = models.PositiveIntegerField(default=0)
    default_option = models.ForeignKey("MealOption", on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    def __str__(self):
        return f"{self.plan} · {self.name} {self.time:%H:%M}"

    def get_default_option(self):
        return self.default_option or self.options.order_by("position", "id").first()


class MealOption(OrderedModel):
    meal = models.ForeignKey(PlanMeal, on_delete=models.CASCADE, related_name="options")
    name = models.CharField(max_length=60, default="Option 1", help_text="Tab name: Veg, Eggs, Quick, Eating out ...")

    def __str__(self):
        return f"{self.meal} · {self.name}"


class MealItem(OrderedModel):
    """A food (or recipe, or a free-text line) in a meal option with its portion.

    kcal/protein/carbs/fat hold the computed totals for `quantity` × `unit_name`
    (recomputed on save from the food or recipe).
    """

    option = models.ForeignKey(MealOption, on_delete=models.CASCADE, related_name="items")
    food = models.ForeignKey(Food, on_delete=models.PROTECT, null=True, blank=True, related_name="+")
    recipe = models.ForeignKey(Recipe, on_delete=models.PROTECT, null=True, blank=True, related_name="+")
    custom_name = models.CharField(max_length=160, blank=True, help_text="Free text when there is no food/recipe")
    unit_name = models.CharField(max_length=40, default="g")
    quantity = models.DecimalField(max_digits=8, decimal_places=2, default=1)
    note = models.CharField(max_length=200, blank=True)
    kcal = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    protein = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    carbs = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    fat = models.DecimalField(max_digits=7, decimal_places=2, default=0)

    def __str__(self):
        return f"{self.display_name} · {self.quantity} × {self.unit_name}"

    @property
    def display_name(self):
        return self.food.name if self.food_id else self.recipe.name if self.recipe_id else self.custom_name

    @property
    def grams(self):
        return self.food.unit_grams(self.unit_name) * self.quantity if self.food_id else None

    def compute(self):
        if self.food_id:
            m = self.food.macros_for(self.unit_name, self.quantity)
        elif self.recipe_id:
            per = self.recipe.per_serving()
            m = {k: v * self.quantity for k, v in per.items()}
        else:
            return
        for k in MACROS:
            setattr(self, k, dec(m[k], "0.01"))

    def save(self, *args, **kwargs):
        self.compute()
        super().save(*args, **kwargs)


class MealItemAlternative(OrderedModel):
    """A swap the client may use instead of the item, with its own portion (Oats 60 g → Poha 1 plate, 82 %)."""

    item = models.ForeignKey(MealItem, on_delete=models.CASCADE, related_name="alternatives")
    food = models.ForeignKey(Food, on_delete=models.PROTECT, related_name="+")
    unit_name = models.CharField(max_length=40, default="g")
    quantity = models.DecimalField(max_digits=8, decimal_places=2, default=1)
    match = models.PositiveSmallIntegerField(default=80, validators=[MaxValueValidator(100)], help_text="Match %")

    def __str__(self):
        return f"{self.item} ⇄ {self.food}"

    def macros(self, qty=None):
        return self.food.macros_for(self.unit_name, self.quantity if qty is None else qty)


class MealPlanAssignment(TimeStampedModel):
    """A client on a meal plan. `custom_plan` is their own copy when the coach
    edited it for them ('custom version'); `note` is the version note shown in
    the builder ("Dinner: brown rice 1 × 100 g instead of 1.5")."""

    plan = models.ForeignKey(MealPlan, on_delete=models.CASCADE, related_name="assignments", help_text="Master plan")
    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="meal_plan_assignments")
    custom_plan = models.ForeignKey(MealPlan, on_delete=models.SET_NULL, null=True, blank=True, related_name="custom_assignments")
    note = models.CharField(max_length=300, blank=True, help_text="Version note; non-empty = custom version")
    active = models.BooleanField(default=True, db_index=True)
    starts_on = models.DateField(null=True, blank=True)
    ends_on = models.DateField(null=True, blank=True)
    assigned_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ("-active", "-created_at")
        indexes = [models.Index(fields=["client", "active"])]

    def __str__(self):
        return f"{self.client} · {self.plan}"

    @property
    def effective_plan(self):
        return self.custom_plan or self.plan

    @property
    def is_custom(self):
        return bool(self.note)


class NutritionTarget(TimeStampedModel):
    """A client's daily targets from a date on (latest one with effective_from <= day wins)."""

    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="nutrition_targets")
    effective_from = models.DateField()
    kcal = models.PositiveIntegerField()
    protein = models.PositiveIntegerField(help_text="g")
    carbs = models.PositiveIntegerField(help_text="g")
    fat = models.PositiveIntegerField(help_text="g")
    fibre = models.PositiveIntegerField(default=30, help_text="g")
    water_ml = models.PositiveIntegerField(default=3000)
    set_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")

    class Meta:
        ordering = ("-effective_from",)
        constraints = [models.UniqueConstraint(fields=["client", "effective_from"], name="uniq_target_per_day")]

    def __str__(self):
        return f"{self.client} · {self.kcal} kcal from {self.effective_from}"


# ---------------------------------------------------------------- client logs
class MealLog(TimeStampedModel):
    """State of one plan meal on one day: eaten (as planned, with that day's
    swaps/portions) or skipped. kcal/protein/carbs/fat are the snapshot that
    counts for the day."""

    class Status(models.TextChoices):
        EATEN = "eaten", "Eaten"
        SKIPPED = "skipped", "Skipped"

    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="meal_logs")
    date = models.DateField(db_index=True)
    meal = models.ForeignKey(PlanMeal, on_delete=models.SET_NULL, null=True, blank=True, related_name="logs")
    meal_name = models.CharField(max_length=60, blank=True, help_text="Snapshot, kept if the plan meal is removed")
    option = models.ForeignKey(MealOption, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    status = models.CharField(max_length=8, choices=Status.choices, default=Status.EATEN)
    eaten_at = models.DateTimeField(null=True, blank=True)
    as_planned = models.BooleanField(default=True, help_text="No swaps or portion changes that day")
    kcal = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    protein = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    carbs = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    fat = models.DecimalField(max_digits=7, decimal_places=2, default=0)

    class Meta:
        ordering = ("date", "meal__position")
        constraints = [models.UniqueConstraint(fields=["client", "date", "meal"], name="uniq_meal_log")]
        indexes = [models.Index(fields=["client", "date"])]

    def __str__(self):
        return f"{self.client} · {self.date} · {self.meal_name} · {self.status}"


class MealDayChange(TimeStampedModel):
    """A swap and/or portion change on a plan item for one day only ('today only')."""

    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="meal_day_changes")
    date = models.DateField(db_index=True)
    item = models.ForeignKey(MealItem, on_delete=models.CASCADE, related_name="day_changes")
    alternative = models.ForeignKey(MealItemAlternative, on_delete=models.CASCADE, null=True, blank=True, related_name="+")
    quantity = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True, help_text="Portion for the day (of the item or the swap)")

    class Meta:
        ordering = ("date",)
        constraints = [models.UniqueConstraint(fields=["client", "date", "item"], name="uniq_meal_day_change")]

    def __str__(self):
        return f"{self.client} · {self.date} · {self.item}"


class FoodLogEntry(TimeStampedModel):
    """Something the client logged besides 'ate the plan meal': a library food,
    one of their own foods, a quick add (kcal + optional macros), or a copy
    from yesterday. Can be flagged off-plan with a reason."""

    class Kind(models.TextChoices):
        FOOD = "food", "Food"
        QUICK_ADD = "quick_add", "Quick add"
        RECIPE = "recipe", "Recipe"
        TEXT = "text", "Free text"

    class OffPlanReason(models.TextChoices):
        ATE_OUT = "ate_out", "Ate out"
        PARTY = "party", "Party"
        TRAVELLING = "travelling", "Travelling"

    client = models.ForeignKey("people.ClientProfile", on_delete=models.CASCADE, related_name="food_logs")
    date = models.DateField(db_index=True)
    logged_at = models.DateTimeField(null=True, blank=True, help_text="When it was eaten (time in the food log)")
    meal = models.ForeignKey(PlanMeal, on_delete=models.SET_NULL, null=True, blank=True, related_name="+", help_text="Plan meal it was added to")
    meal_slot = models.CharField(max_length=60, blank=True, help_text="Meal name when there is no plan meal")
    kind = models.CharField(max_length=10, choices=Kind.choices, default=Kind.FOOD)
    food = models.ForeignKey(Food, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    recipe = models.ForeignKey(Recipe, on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    name = models.CharField(max_length=160, help_text="Food name or free text, e.g. Green tea, no sugar")
    amount = models.CharField(max_length=60, blank=True, help_text="Display amount, e.g. 1 cup, 30 g")
    unit_name = models.CharField(max_length=40, blank=True)
    quantity = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    grams = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    kcal = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    protein = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    carbs = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    fat = models.DecimalField(max_digits=7, decimal_places=2, default=0)
    from_plan = models.BooleanField(default=False, help_text="Part of the plan (e.g. logged as an item of a plan meal)")
    off_plan = models.BooleanField(default=False)
    off_plan_reason = models.CharField(max_length=12, choices=OffPlanReason.choices, blank=True)
    copied_from = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="+", help_text="Copy yesterday")

    class Meta:
        ordering = ("date", "logged_at", "id")
        indexes = [models.Index(fields=["client", "date"])]
        verbose_name_plural = "food log entries"

    def __str__(self):
        return f"{self.client} · {self.date} · {self.name}"

    def compute(self):
        if self.food_id and self.quantity is not None and self.kind == self.Kind.FOOD:
            g = self.food.unit_grams(self.unit_name or "g") * self.quantity
            self.grams = dec(g, "0.01")
            for k, v in self.food.macros_for_grams(g).items():
                setattr(self, k, dec(v, "0.01"))
