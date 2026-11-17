from django.contrib import admin

from .models import Booking


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ["reference", "passenger", "trip", "seats", "status", "created_at"]
    list_filter = ["status"]
    search_fields = ["reference", "passenger__email", "trip__departure_city", "trip__arrival_city"]
    autocomplete_fields = ["passenger"]
    raw_id_fields = ["trip"]
    readonly_fields = ["reference", "created_at", "updated_at"]
