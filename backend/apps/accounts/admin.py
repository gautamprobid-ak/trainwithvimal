from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import DeviceToken, InviteLink, OneTimeLink, User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    ordering = ("full_name",)
    list_display = ("full_name", "email", "role", "email_verified", "onboarded", "is_active", "last_active_at")
    list_filter = ("role", "email_verified", "onboarded", "is_active")
    search_fields = ("full_name", "email", "phone")
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Profile", {"fields": ("full_name", "role", "phone", "country_code", "avatar", "avatar_url", "avatar_color")}),
        ("Status", {"fields": ("email_verified", "onboarded", "is_active", "last_active_at")}),
        ("Preferences", {"fields": ("push_enabled", "camera_allowed", "photos_allowed", "whatsapp_enabled", "email_updates", "units", "language")}),
        ("Django", {"fields": ("is_staff", "is_superuser", "groups", "user_permissions")}),
    )
    add_fieldsets = ((None, {"classes": ("wide",), "fields": ("email", "full_name", "role", "password1", "password2")}),)


@admin.register(InviteLink)
class InviteLinkAdmin(admin.ModelAdmin):
    list_display = ("code", "trainer", "status", "expires_at", "max_uses", "joined_count", "pending_count")
    list_filter = ("status",)
    search_fields = ("code", "label")


admin.site.register(OneTimeLink)
admin.site.register(DeviceToken)
