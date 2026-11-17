from django.utils import timezone
from rest_framework import serializers

from accounts.serializers import PublicUserSerializer
from trips.models import Trip

from .models import Booking


class TripSummarySerializer(serializers.ModelSerializer):
    driver = PublicUserSerializer(read_only=True)

    class Meta:
        model = Trip
        fields = [
            "id", "driver", "departure_city", "departure_place", "arrival_city", "arrival_place",
            "departure_time", "arrival_time", "price_per_seat", "status",
        ]


class BookingSerializer(serializers.ModelSerializer):
    trip = TripSummarySerializer(read_only=True)
    trip_id = serializers.PrimaryKeyRelatedField(source="trip", queryset=Trip.objects.all(), write_only=True)
    passenger = PublicUserSerializer(read_only=True)
    total_price = serializers.SerializerMethodField()
    contact = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = [
            "id", "reference", "trip", "trip_id", "passenger", "seats", "message",
            "status", "total_price", "contact", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "reference", "status", "created_at", "updated_at"]

    def get_total_price(self, obj) -> str:
        return str(obj.trip.price_per_seat * obj.seats)

    def get_contact(self, obj) -> dict | None:
        """
        Pas de messagerie en V1 : une fois la réservation acceptée, chacun voit
        le téléphone / email de l'autre pour organiser le départ.
        """
        request = self.context.get("request")
        if obj.status != Booking.Status.ACCEPTED or not request:
            return None
        other = obj.trip.driver if request.user.id == obj.passenger_id else obj.passenger
        return {"name": other.get_full_name(), "phone": other.phone, "email": other.email}

    def validate(self, attrs):
        trip = attrs["trip"]
        user = self.context["request"].user
        if trip.driver_id == user.id:
            raise serializers.ValidationError("Vous ne pouvez pas réserver votre propre trajet.")
        if trip.status != Trip.Status.PUBLISHED or trip.departure_time <= timezone.now():
            raise serializers.ValidationError("Ce trajet n'est plus réservable.")
        if Booking.objects.filter(trip=trip, passenger=user, status__in=Booking.ACTIVE_STATUSES).exists():
            raise serializers.ValidationError("Vous avez déjà une réservation en cours pour ce trajet.")
        if attrs.get("seats", 1) > trip.compute_available_seats():
            raise serializers.ValidationError({"seats": "Pas assez de places disponibles."})
        return attrs
