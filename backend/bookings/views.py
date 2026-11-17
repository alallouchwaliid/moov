from django.db import transaction
from django.db.models import Q
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response

from notifications.services import notify
from trips.models import Trip

from .models import Booking
from .serializers import BookingSerializer


class BookingViewSet(
    mixins.CreateModelMixin, mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet
):
    """
    Réservations.

    - `POST /api/bookings/` (passager) : `{trip_id, seats, message}`.
    - `GET /api/bookings/` : mes réservations en tant que passager (`?status=`).
    - `GET /api/bookings/received/` : demandes reçues sur mes trajets (`?status=pending`).
    - `POST /api/bookings/{id}/accept/` | `refuse/` (conducteur), `cancel/` (passager).
    """

    serializer_class = BookingSerializer
    filterset_fields = ["status"]

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Booking.objects.none()
        user = self.request.user
        qs = Booking.objects.select_related("trip__driver", "passenger")
        if self.action == "list":
            return qs.filter(passenger=user)
        if self.action == "received":
            return qs.filter(trip__driver=user)
        return qs.filter(Q(passenger=user) | Q(trip__driver=user))

    def perform_create(self, serializer):
        booking = serializer.save(passenger=self.request.user)
        trip = booking.trip
        if trip.auto_accept:
            self._accept(booking)
        else:
            notify(
                trip.driver, "booking_request", "Nouvelle demande de réservation",
                f"{booking.passenger.get_full_name()} souhaite réserver {booking.seats} place(s) "
                f"pour {trip.departure_city} → {trip.arrival_city}.",
                trip=trip, booking=booking,
            )

    @extend_schema(parameters=[OpenApiParameter("status", str)])
    @action(detail=False, methods=["get"])
    def received(self, request):
        qs = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(qs)
        return self.get_paginated_response(self.get_serializer(page, many=True).data)

    # --- Transitions -----------------------------------------------------

    def _accept(self, booking):
        with transaction.atomic():
            # Verrouille le trajet pour éviter la surréservation en cas d'acceptations simultanées.
            trip = Trip.objects.select_for_update().get(pk=booking.trip_id)
            if booking.seats > trip.compute_available_seats():
                raise ValidationError("Plus assez de places disponibles pour accepter cette demande.")
            booking.status = Booking.Status.ACCEPTED
            booking.save(update_fields=["status", "updated_at"])
        notify(
            booking.passenger, "booking_accepted", "Votre place est réservée",
            f"Réservation {booking.reference} confirmée pour {trip.departure_city} → {trip.arrival_city}.",
            trip=trip, booking=booking,
        )

    def _get_for_driver(self, pk):
        booking = get_object_or_404(self.get_queryset(), pk=pk)
        if booking.trip.driver_id != self.request.user.id:
            raise PermissionDenied("Seul le conducteur peut traiter cette demande.")
        if booking.status != Booking.Status.PENDING:
            raise ValidationError("Cette demande a déjà été traitée.")
        return booking

    @extend_schema(request=None, responses=BookingSerializer)
    @action(detail=True, methods=["post"])
    def accept(self, request, pk=None):
        booking = self._get_for_driver(pk)
        self._accept(booking)
        return Response(self.get_serializer(booking).data)

    @extend_schema(request=None, responses=BookingSerializer)
    @action(detail=True, methods=["post"])
    def refuse(self, request, pk=None):
        booking = self._get_for_driver(pk)
        booking.status = Booking.Status.REFUSED
        booking.save(update_fields=["status", "updated_at"])
        notify(
            booking.passenger, "booking_refused", "Demande refusée",
            f"Votre demande pour {booking.trip.departure_city} → {booking.trip.arrival_city} a été refusée.",
            trip=booking.trip, booking=booking,
        )
        return Response(self.get_serializer(booking).data)

    @extend_schema(request=None, responses=BookingSerializer)
    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        booking = get_object_or_404(self.get_queryset(), pk=pk)
        if booking.passenger_id != request.user.id:
            raise PermissionDenied("Seul le passager peut annuler sa réservation.")
        if booking.status not in Booking.ACTIVE_STATUSES:
            raise ValidationError("Cette réservation n'est plus active.")
        if booking.trip.status != Trip.Status.PUBLISHED:
            raise ValidationError("Le trajet n'est plus modifiable.")
        was_accepted = booking.status == Booking.Status.ACCEPTED
        booking.status = Booking.Status.CANCELLED
        booking.save(update_fields=["status", "updated_at"])
        if was_accepted:
            notify(
                booking.trip.driver, "booking_cancelled", "Réservation annulée",
                f"{booking.passenger.get_full_name()} a annulé sa réservation {booking.reference}.",
                trip=booking.trip, booking=booking,
            )
        return Response(self.get_serializer(booking).data, status=status.HTTP_200_OK)
