from django.conf import settings
from django.db import models


class Notification(models.Model):
    """
    Notification « in-app ». L'app Flutter interroge /api/notifications/?is_read=false
    et affiche des notifications locales (pas de push en V1, cf. cahier des charges).
    """

    class Kind(models.TextChoices):
        BOOKING_REQUEST = "booking_request", "Nouvelle demande"
        BOOKING_ACCEPTED = "booking_accepted", "Réservation acceptée"
        BOOKING_REFUSED = "booking_refused", "Réservation refusée"
        BOOKING_CANCELLED = "booking_cancelled", "Réservation annulée"
        TRIP_CANCELLED = "trip_cancelled", "Trajet annulé"
        REVIEW_REQUEST = "review_request", "Avis à laisser"
        REVIEW_RECEIVED = "review_received", "Avis reçu"

    recipient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications")
    kind = models.CharField(max_length=20, choices=Kind.choices)
    title = models.CharField(max_length=120)
    body = models.CharField(max_length=300)
    trip = models.ForeignKey("trips.Trip", on_delete=models.CASCADE, null=True, blank=True)
    booking = models.ForeignKey("bookings.Booking", on_delete=models.CASCADE, null=True, blank=True)
    is_read = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.recipient} · {self.title}"
