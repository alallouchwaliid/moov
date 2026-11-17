from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.db.models import F, Q, Sum, Value
from django.db.models.functions import Coalesce


class TripQuerySet(models.QuerySet):
    def with_availability(self):
        """Ajoute `booked_seats` et `available_seats` (réservations acceptées)."""
        return self.annotate(
            booked_seats=Coalesce(
                Sum("bookings__seats", filter=Q(bookings__status="accepted")), Value(0)
            )
        ).annotate(available_seats=F("seats_total") - F("booked_seats"))


class Trip(models.Model):
    class Status(models.TextChoices):
        PUBLISHED = "published", "Publié"
        CANCELLED = "cancelled", "Annulé"
        COMPLETED = "completed", "Terminé"

    class Luggage(models.TextChoices):
        NONE = "none", "Aucun bagage"
        SMALL = "small", "Petit bagage"
        MEDIUM = "medium", "Bagage moyen"
        LARGE = "large", "Grand bagage"

    driver = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="trips", verbose_name="conducteur"
    )
    vehicle = models.ForeignKey(
        "accounts.Vehicle", on_delete=models.SET_NULL, null=True, blank=True, related_name="trips", verbose_name="véhicule"
    )
    departure_city = models.CharField("ville de départ", max_length=80, db_index=True)
    departure_place = models.CharField("lieu de départ", max_length=150, blank=True)
    arrival_city = models.CharField("ville d'arrivée", max_length=80, db_index=True)
    arrival_place = models.CharField("lieu d'arrivée", max_length=150, blank=True)
    departure_time = models.DateTimeField("date et heure de départ", db_index=True)
    arrival_time = models.DateTimeField("arrivée estimée", null=True, blank=True)
    seats_total = models.PositiveSmallIntegerField(
        "places proposées", validators=[MinValueValidator(1), MaxValueValidator(8)]
    )
    price_per_seat = models.DecimalField(
        "prix par place (MAD)", max_digits=7, decimal_places=2, validators=[MinValueValidator(0)]
    )
    luggage = models.CharField("bagages", max_length=10, choices=Luggage.choices, default=Luggage.MEDIUM)
    smoking_allowed = models.BooleanField("fumeur accepté", default=False)
    pets_allowed = models.BooleanField("animaux acceptés", default=False)
    auto_accept = models.BooleanField(
        "acceptation automatique", default=False,
        help_text="Si activé, les demandes sont acceptées sans validation du conducteur.",
    )
    description = models.TextField("informations complémentaires", max_length=500, blank=True)
    status = models.CharField("statut", max_length=10, choices=Status.choices, default=Status.PUBLISHED, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = TripQuerySet.as_manager()

    class Meta:
        verbose_name = "trajet"
        verbose_name_plural = "trajets"
        ordering = ["departure_time"]

    def __str__(self):
        return f"{self.departure_city} → {self.arrival_city} ({self.departure_time:%d/%m/%Y %H:%M})"

    def compute_available_seats(self):
        booked = self.bookings.filter(status="accepted").aggregate(s=Sum("seats"))["s"] or 0
        return self.seats_total - booked


class SavedRoute(models.Model):
    """« Trajets enregistrés » de l'écran d'accueil (raccourcis de recherche)."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="saved_routes")
    departure_city = models.CharField("ville de départ", max_length=80)
    departure_place = models.CharField("lieu de départ", max_length=150, blank=True)
    arrival_city = models.CharField("ville d'arrivée", max_length=80)
    arrival_place = models.CharField("lieu d'arrivée", max_length=150, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "trajet enregistré"
        verbose_name_plural = "trajets enregistrés"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.departure_city} → {self.arrival_city}"
