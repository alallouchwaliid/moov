import django_filters

from .models import Trip


class TripFilter(django_filters.FilterSet):
    """Recherche : ville de départ, destination, date (+ filtres de la maquette)."""

    departure_city = django_filters.CharFilter(lookup_expr="icontains")
    arrival_city = django_filters.CharFilter(lookup_expr="icontains")
    date = django_filters.DateFilter(field_name="departure_time", lookup_expr="date")
    departure_after = django_filters.TimeFilter(field_name="departure_time", lookup_expr="time__gte")
    max_price = django_filters.NumberFilter(field_name="price_per_seat", lookup_expr="lte")
    seats = django_filters.NumberFilter(field_name="available_seats", lookup_expr="gte", label="Places minimum")
    verified_only = django_filters.BooleanFilter(field_name="driver__is_verified")
    smoking_allowed = django_filters.BooleanFilter()
    pets_allowed = django_filters.BooleanFilter()

    class Meta:
        model = Trip
        fields = ["departure_city", "arrival_city", "date"]
