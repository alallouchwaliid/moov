import secrets

from django.conf import settings
from django.core.validators import MinValueValidator
from django.db import models


def generate_reference():
    """Référence lisible type « MK-2048 » (maquette), suffixée pour l'unicité."""
    return f"MK-{secrets.randbelow(9000) + 1000}{secrets.token_hex(1).upper()}"


class Booking(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "En attente"
        ACCEPTED = "accepted", "Acceptée"
        REFUSED = "refused", "Refusée"
        CANCELLED = "cancelled", "Annulée"

    ACTIVE_STATUSES = (Status.PENDING, Status.ACCEPTED)

    reference = models.CharField("référence", max_length=12, unique=True, default=generate_reference, editable=False)
    trip = models.ForeignKey("trips.Trip", on_delete=models.CASCADE, related_name="bookings", verbose_name="trajet")
    passenger = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="bookings", verbose_name="passager"
    )
    seats = models.PositiveSmallIntegerField("places", default=1, validators=[MinValueValidator(1)])
    message = models.CharField("message au conducteur", max_length=300, blank=True)
    status = models.CharField("statut", max_length=10, choices=Status.choices, default=Status.PENDING, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "réservation"
        verbose_name_plural = "réservations"
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["trip", "passenger"],
                condition=models.Q(status__in=["pending", "accepted"]),
                name="unique_active_booking_per_trip",
            )
        ]

    def __str__(self):
        return f"{self.reference} · {self.passenger} · {self.trip}"
