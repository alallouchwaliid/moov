from django.contrib import admin

from .models import Review


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ["author", "target", "rating", "short_comment", "is_reported", "is_hidden", "created_at"]
    list_filter = ["is_reported", "is_hidden", "rating"]
    search_fields = ["comment", "author__email", "target__email", "report_reason"]
    raw_id_fields = ["trip", "author", "target"]
    actions = ["hide_reviews", "restore_reviews"]

    @admin.display(description="commentaire")
    def short_comment(self, obj):
        return (obj.comment[:60] + "…") if len(obj.comment) > 60 else obj.comment

    @admin.action(description="Masquer les avis sélectionnés")
    def hide_reviews(self, request, queryset):
        self.message_user(request, f"{queryset.update(is_hidden=True)} avis masqué(s).")

    @admin.action(description="Rétablir les avis (et lever le signalement)")
    def restore_reviews(self, request, queryset):
        self.message_user(request, f"{queryset.update(is_hidden=False, is_reported=False)} avis rétabli(s).")
