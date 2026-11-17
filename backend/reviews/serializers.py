from django.contrib.auth import get_user_model
from rest_framework import serializers

from accounts.serializers import PublicUserSerializer
from bookings.models import Booking
from trips.models import Trip

from .models import Review

User = get_user_model()


class ReviewSerializer(serializers.ModelSerializer):
    author = PublicUserSerializer(read_only=True)
    trip_id = serializers.PrimaryKeyRelatedField(source="trip", queryset=Trip.objects.all())
    target_id = serializers.PrimaryKeyRelatedField(source="target", queryset=User.objects.all())
    trip_label = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = ["id", "trip_id", "trip_label", "author", "target_id", "rating", "comment", "created_at"]
        read_only_fields = ["id", "created_at"]

    def get_trip_label(self, obj) -> str:
        return f"{obj.trip.departure_city} → {obj.trip.arrival_city}"

    def validate_rating(self, value):
        if not 1 <= value <= 5:
            raise serializers.ValidationError("La note doit être comprise entre 1 et 5.")
        return value

    def validate(self, attrs):
        user = self.context["request"].user
        trip, target = attrs["trip"], attrs["target"]
        if target.id == user.id:
            raise serializers.ValidationError("Vous ne pouvez pas vous évaluer vous-même.")
        if trip.status != Trip.Status.COMPLETED:
            raise serializers.ValidationError("Un avis ne peut être laissé qu'après la réalisation du trajet.")

        accepted = Booking.objects.filter(trip=trip, status=Booking.Status.ACCEPTED)
        passenger_ids = set(accepted.values_list("passenger_id", flat=True))
        if user.id == trip.driver_id:
            allowed = target.id in passenger_ids
        else:
            allowed = user.id in passenger_ids and target.id == trip.driver_id
        if not allowed:
            raise serializers.ValidationError("Vous n'avez pas voyagé avec ce membre sur ce trajet.")

        if Review.objects.filter(trip=trip, author=user, target=target).exists():
            raise serializers.ValidationError("Vous avez déjà laissé un avis pour ce trajet.")
        return attrs


class ReportSerializer(serializers.Serializer):
    reason = serializers.CharField(max_length=300)
