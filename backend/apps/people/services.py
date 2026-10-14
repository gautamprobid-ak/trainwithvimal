"""Helpers shared by the people views: safe calls into other apps, notifications, activity.

Cross-app data (check-ins, programs, sessions …) is pulled through an optional hook contract so this
app works even when the others are incomplete. Any app may add a module `apps/<app>/dashboard.py` with:

    def admin_dashboard(request) -> dict          # merged into /dashboard/admin/ under extra[<app>]
    def trainer_dashboard(trainer, request) -> dict   # merged into /dashboard/trainer/
    def client_overview(client, request) -> dict      # merged into /clients/{id}/overview/

Well-known keys picked up for the stat cards when present:
    checkins_to_review (int), checkins_overdue_48h (int), checkin_rate (int %), programs_ending (int),
    nutrition_pending (int), today_sessions (list), this_week (list), weight_series (list),
    last_7_days (list), current_plans (list), coaching (dict), schedule (list), attention (list).
"""
import importlib
import logging

from django.apps import apps as django_apps

log = logging.getLogger(__name__)

HOOK_APPS = ("training", "nutrition", "habits", "checkins", "scheduling", "content", "engage")


def call_hooks(func_name, *args):
    out = {}
    for app in HOOK_APPS:
        try:
            mod = importlib.import_module(f"apps.{app}.dashboard")
        except ImportError:
            continue
        fn = getattr(mod, func_name, None)
        if not fn:
            continue
        try:
            res = fn(*args)
        except Exception:  # never break a dashboard because another app failed
            log.exception("dashboard hook %s.%s failed", app, func_name)
            continue
        if isinstance(res, dict):
            out[app] = res
    return out


def pick(extra, key, default=None):
    """First value for `key` across the hook results."""
    for res in extra.values():
        if key in res:
            return res[key]
    return default


def get_model(label):
    try:
        return django_apps.get_model(label)
    except (LookupError, ValueError):
        return None


def safe_notify(user, title, body="", kind="info", link=""):
    if user is None:
        return None
    try:
        from apps.core.services.notify import notify

        return notify(user, title, body, kind=kind, link=link)
    except Exception:  # engage app may not be ready
        log.debug("notify skipped", exc_info=True)
        return None


def safe_activity(actor, verb, target="", client=None, category="client", meta=None):
    try:
        from apps.core.services.activity import log_activity

        return log_activity(actor, verb, target, client=client, category=category, meta=meta)
    except Exception:
        log.debug("activity skipped", exc_info=True)
        return None


def recent_activity(limit=5, user=None, client_ids=None):
    """Latest activity rows from engage.ActivityLog when it exists."""
    Model = get_model("engage.ActivityLog")
    if Model is None:
        return []
    try:
        qs = Model.objects.all().order_by("-created_at")
        if client_ids is not None:
            qs = qs.filter(client_id__in=client_ids)
        if user is not None:
            qs = qs.filter(actor=user)
        rows = []
        for a in qs.select_related("actor")[:limit]:
            actor = getattr(a, "actor", None)
            rows.append({
                "who": actor.full_name if actor else "System",
                "initials": actor.initials if actor else "S",
                "avatar_color": getattr(actor, "avatar_color", "c4") if actor else "c4",
                "text": f"{a.verb} {getattr(a, 'target', '')}".strip(),
                "at": a.created_at,
            })
        return rows
    except Exception:
        log.debug("recent activity skipped", exc_info=True)
        return []
