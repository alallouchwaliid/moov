from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User, Vehicle


class VehicleInline(admin.TabularInline):
    model = Vehicle
    extra = 0


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    ordering = ["-date_joined"]
    list_display = ["email", "first_name", "last_name", "phone", "role", "is_verified", "is_active", "date_joined"]
    list_filter = ["is_verified", "is_active", "role", "is_staff"]
    search_fields = ["email", "first_name", "last_name", "phone"]
    inlines = [VehicleInline]
    actions = ["verify_users", "block_users", "unblock_users"]

    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Profil", {"fields": ("first_name", "last_name", "phone", "avatar", "bio", "city", "university", "role")}),
        ("Validation", {"fields": ("is_verified", "is_active")}),
        ("Permissions", {"classes": ("collapse",), "fields": ("is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Dates", {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (None, {"classes": ("wide",), "fields": ("email", "first_name", "last_name", "password1", "password2")}),
    )

    @admin.action(description="Valider l'identité des utilisateurs sélectionnés")
    def verify_users(self, request, queryset):
        self.message_user(request, f"{queryset.update(is_verified=True)} utilisateur(s) validé(s).")

    @admin.action(description="Bloquer les utilisateurs sélectionnés")
    def block_users(self, request, queryset):
        self.message_user(request, f"{queryset.exclude(pk=request.user.pk).update(is_active=False)} utilisateur(s) bloqué(s).")

    @admin.action(description="Débloquer les utilisateurs sélectionnés")
    def unblock_users(self, request, queryset):
        self.message_user(request, f"{queryset.update(is_active=True)} utilisateur(s) débloqué(s).")


@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ["__str__", "owner", "plate_number", "seats"]
    search_fields = ["brand", "model", "plate_number", "owner__email"]
