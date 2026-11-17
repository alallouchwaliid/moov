from django.contrib.auth import password_validation
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import User, Vehicle


class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ["id", "brand", "model", "color", "plate_number", "seats", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate_seats(self, value):
        if not 1 <= value <= 8:
            raise serializers.ValidationError("Entre 1 et 8 places passagers.")
        return value


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8, style={"input_type": "password"})

    class Meta:
        model = User
        fields = ["id", "email", "password", "first_name", "last_name", "phone", "role"]
        extra_kwargs = {"first_name": {"required": True}, "last_name": {"required": True}}

    def validate_email(self, value):
        value = value.lower()
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("Un compte existe déjà avec cet email.")
        return value

    def validate(self, attrs):
        password_validation.validate_password(attrs["password"], User(**{k: v for k, v in attrs.items() if k != "password"}))
        return attrs

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)


class RatingSerializer(serializers.Serializer):
    average = serializers.FloatField(allow_null=True)
    count = serializers.IntegerField()


class PublicUserSerializer(serializers.ModelSerializer):
    """Profil visible par les autres membres (carte conducteur, avis…)."""

    full_name = serializers.CharField(source="get_full_name", read_only=True)
    rating = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id", "first_name", "last_name", "full_name", "avatar", "bio", "city",
            "university", "role", "is_verified", "date_joined", "rating",
        ]
        read_only_fields = fields

    def get_rating(self, obj) -> RatingSerializer:
        return obj.rating_summary()


class MeSerializer(serializers.ModelSerializer):
    """Profil complet de l'utilisateur connecté (lecture + édition)."""

    full_name = serializers.CharField(source="get_full_name", read_only=True)
    rating = serializers.SerializerMethodField()
    vehicles = VehicleSerializer(many=True, read_only=True)
    stats = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id", "email", "first_name", "last_name", "full_name", "phone", "avatar",
            "bio", "city", "university", "role", "is_verified", "date_joined",
            "rating", "stats", "vehicles",
        ]
        read_only_fields = ["id", "email", "is_verified", "date_joined"]

    def get_rating(self, obj) -> RatingSerializer:
        return obj.rating_summary()

    def get_stats(self, obj) -> dict:
        from bookings.models import Booking
        from trips.models import Trip

        return {
            "trips_as_driver": obj.trips.filter(status=Trip.Status.COMPLETED).count(),
            "trips_as_passenger": obj.bookings.filter(
                status=Booking.Status.ACCEPTED, trip__status=Trip.Status.COMPLETED
            ).count(),
        }


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, min_length=8)

    def validate_old_password(self, value):
        if not self.context["request"].user.check_password(value):
            raise serializers.ValidationError("Mot de passe actuel incorrect.")
        return value

    def validate_new_password(self, value):
        password_validation.validate_password(value, self.context["request"].user)
        return value


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()


class MoovTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Renvoie aussi le profil de l'utilisateur à la connexion."""

    def validate(self, attrs):
        data = super().validate(attrs)
        data["user"] = MeSerializer(self.user, context=self.context).data
        return data
