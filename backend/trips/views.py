from django.db import transaction
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from bookings.models import Booking
from bookings.serializers import BookingSerializer
from notifications.services import notify

from .filters import TripFilter
from .models import SavedRoute, Trip
from .permissions import IsDriverOrReadOnly
from .serializers import SavedRouteSerializer, TripSerializer


class TripViewSet(viewsets.ModelViewSet):
    """
    Trajets.

    - `GET /api/trips/` : recherche des trajets publiés à venir (consultable sans compte).
      Filtres : `departure_city`, `arrival_city`, `date` (AAAA-MM-JJ), `departure_after` (HH:MM),
      `max_price`, `seats`, `verified_only`. Tri : `ordering=departure_time|price_per_seat`.
    - `GET /api/trips/mine/` : trajets publiés par le conducteur connecté.
    - `POST /api/trips/{id}/cancel/` et `/complete/` : actions du conducteur.
    """

    serializer_class = TripSerializer
    permission_classes = [IsDriverOrReadOnly]
    filterset_class = TripFilter
    ordering_fields = ["departure_time", "price_per_seat", "created_at"]
    ordering = ["departure_time"]

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated(), IsDriverOrReadOnly()]

    def get_queryset(self):
        qs = Trip.objects.with_availability().select_related("driver", "vehicle")
        if self.action == "list":
            return qs.filter(status=Trip.Status.PUBLISHED, departure_time__gt=timezone.now(), driver__is_active=True)
        if self.action == "mine":
            return qs.filter(driver=self.request.user)
        return qs

    def perform_create(self, serializer):
        serializer.save(driver=self.request.user)

    def perform_update(self, serializer):
        if serializer.instance.status != Trip.Status.PUBLISHED:
            raise ValidationError("Seul un trajet publié peut être modifié.")
        serializer.save()

    def destroy(self, request, *args, **kwargs):
        """Un trajet n'est pas supprimé : il est annulé (les passagers sont prévenus)."""
        return self.cancel(request, *args, **kwargs)

    @extend_schema(description="Trajets publiés par l'utilisateur connecté (tous statuts).")
    @action(detail=False, methods=["get"])
    def mine(self, request):
        qs = self.filter_queryset(self.get_queryset())
        status_param = request.query_params.get("status")
        if status_param:
            qs = qs.filter(status=status_param)
        page = self.paginate_queryset(qs)
        return self.get_paginated_response(self.get_serializer(page, many=True).data)

    @extend_schema(request=None, responses=TripSerializer)
    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        trip = self.get_object()
        if trip.status != Trip.Status.PUBLISHED:
            raise ValidationError("Ce trajet ne peut plus être annulé.")
        with transaction.atomic():
            trip.status = Trip.Status.CANCELLED
            trip.save(update_fields=["status", "updated_at"])
            active = trip.bookings.filter(status__in=[Booking.Status.PENDING, Booking.Status.ACCEPTED])
            for booking in active.select_related("passenger"):
                notify(
                    booking.passenger, "trip_cancelled",
                    "Trajet annulé",
                    f"Le trajet {trip.departure_city} → {trip.arrival_city} a été annulé par le conducteur.",
                    trip=trip, booking=booking,
                )
            active.update(status=Booking.Status.CANCELLED, updated_at=timezone.now())
        return Response(self.get_serializer(trip).data)

    @extend_schema(request=None, responses=TripSerializer)
    @action(detail=True, methods=["post"])
    def complete(self, request, pk=None):
        """Marque le trajet comme effectué : ouvre la possibilité de laisser des avis."""
        trip = self.get_object()
        if trip.status != Trip.Status.PUBLISHED:
            raise ValidationError("Ce trajet n'est pas en cours.")
        if trip.departure_time > timezone.now():
            raise ValidationError("Le trajet n'a pas encore commencé.")
        trip.status = Trip.Status.COMPLETED
        trip.save(update_fields=["status", "updated_at"])
        trip.bookings.filter(status=Booking.Status.PENDING).update(status=Booking.Status.REFUSED)
        for booking in trip.bookings.filter(status=Booking.Status.ACCEPTED).select_related("passenger"):
            notify(
                booking.passenger, "review_request", "Comment s'est passé votre trajet ?",
                f"Laissez un avis sur votre trajet {trip.departure_city} → {trip.arrival_city}.",
                trip=trip, booking=booking,
            )
        return Response(self.get_serializer(trip).data)

    @extend_schema(responses=BookingSerializer(many=True))
    @action(detail=True, methods=["get"])
    def bookings(self, request, pk=None):
        """Demandes de réservation reçues pour ce trajet (conducteur uniquement)."""
        trip = self.get_object()
        if trip.driver_id != request.user.id:
            return Response(status=status.HTTP_403_FORBIDDEN)
        qs = trip.bookings.select_related("passenger").order_by("-created_at")
        return Response(BookingSerializer(qs, many=True, context={"request": request}).data)


class SavedRouteViewSet(viewsets.ModelViewSet):
    serializer_class = SavedRouteSerializer
    http_method_names = ["get", "post", "delete"]

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return SavedRoute.objects.none()
        return self.request.user.saved_routes.all()

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
