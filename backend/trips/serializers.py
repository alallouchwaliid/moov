from django.utils import timezone
from rest_framework import serializers

from accounts.models import Vehicle
from accounts.serializers import PublicUserSerializer, VehicleSerializer

from .models import SavedRoute, Trip


class TripSerializer(serializers.ModelSerializer):
    driver = PublicUserSerializer(read_only=True)
    vehicle = VehicleSerializer(read_only=True)
    vehicle_id = serializers.PrimaryKeyRelatedField(
        source="vehicle", queryset=Vehicle.objects.all(), write_only=True, required=False, allow_null=True
    )
    available_seats = serializers.SerializerMethodField()
    is_driver = serializers.SerializerMethodField()
    my_booking = serializers.SerializerMethodField()

    class Meta:
        model = Trip
        fields = [
            "id", "driver", "vehicle", "vehicle_id",
            "departure_city", "departure_place", "arrival_city", "arrival_place",
            "departure_time", "arrival_time", "seats_total", "available_seats", "price_per_seat",
            "luggage", "smoking_allowed", "pets_allowed", "auto_accept", "description",
            "status", "is_driver", "my_booking", "created_at",
        ]
        read_only_fields = ["id", "status", "created_at"]

    def get_available_seats(self, obj) -> int:
        value = getattr(obj, "available_seats", None)
        return value if value is not None else obj.compute_available_seats()

    def get_is_driver(self, obj) -> bool:
        request = self.context.get("request")
        return bool(request and request.user.is_authenticated and obj.driver_id == request.user.id)

    def get_my_booking(self, obj) -> dict | None:
        """Réservation active de l'utilisateur connecté sur ce trajet (s'il y en a une)."""
        request = self.context.get("request")
        if not (request and request.user.is_authenticated):
            return None
        booking = (
            obj.bookings.filter(passenger=request.user)
            .exclude(status__in=["cancelled", "refused"])
            .order_by("-created_at")
            .first()
        )
        return {"id": booking.id, "status": booking.status, "reference": booking.reference} if booking else None

    def validate_vehicle_id(self, vehicle):
        if vehicle and vehicle.owner_id != self.context["request"].user.id:
            raise serializers.ValidationError("Ce véhicule ne vous appartient pas.")
        return vehicle

    def validate(self, attrs):
        instance = self.instance
        departure = attrs.get("departure_time", instance.departure_time if instance else None)
        arrival = attrs.get("arrival_time", instance.arrival_time if instance else None)
        if "departure_time" in attrs and departure <= timezone.now():
            raise serializers.ValidationError({"departure_time": "La date de départ doit être dans le futur."})
        if arrival and departure and arrival <= departure:
            raise serializers.ValidationError({"arrival_time": "L'arrivée doit être après le départ."})

        dep_city = attrs.get("departure_city", instance.departure_city if instance else "")
        arr_city = attrs.get("arrival_city", instance.arrival_city if instance else "")
        if dep_city and arr_city and dep_city.strip().lower() == arr_city.strip().lower() and \
                attrs.get("departure_place", getattr(instance, "departure_place", "")) == \
                attrs.get("arrival_place", getattr(instance, "arrival_place", "")):
            raise serializers.ValidationError("Le départ et l'arrivée doivent être différents.")

        if instance and "seats_total" in attrs:
            booked = instance.seats_total - instance.compute_available_seats()
            if attrs["seats_total"] < booked:
                raise serializers.ValidationError(
                    {"seats_total": f"{booked} place(s) déjà réservée(s) : impossible de descendre en dessous."}
                )
        return attrs


class SavedRouteSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedRoute
        fields = ["id", "departure_city", "departure_place", "arrival_city", "arrival_place", "created_at"]
        read_only_fields = ["id", "created_at"]
