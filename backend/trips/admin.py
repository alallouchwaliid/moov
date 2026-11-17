from django.contrib import admin

from bookings.models import Booking

from .models import SavedRoute, Trip


class BookingInline(admin.TabularInline):
    model = Booking
    extra = 0
    fields = ["reference", "passenger", "seats", "status", "created_at"]
    readonly_fields = ["reference", "created_at"]


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = ["__str__", "driver", "seats_total", "price_per_seat", "status", "created_at"]
    list_filter = ["status", "departure_city", "arrival_city"]
    search_fields = ["departure_city", "arrival_city", "driver__email", "driver__last_name"]
    date_hierarchy = "departure_time"
    autocomplete_fields = ["driver"]
    inlines = [BookingInline]
    actions = ["cancel_trips"]

    @admin.action(description="Annuler les trajets sélectionnés (modération)")
    def cancel_trips(self, request, queryset):
        n = queryset.filter(status=Trip.Status.PUBLISHED).update(status=Trip.Status.CANCELLED)
        self.message_user(request, f"{n} trajet(s) annulé(s).")


@admin.register(SavedRoute)
class SavedRouteAdmin(admin.ModelAdmin):
    list_display = ["__str__", "user", "created_at"]
