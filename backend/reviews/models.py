from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class Review(models.Model):
    """Avis laissé après un trajet terminé, par un passager sur le conducteur ou l'inverse."""

    trip = models.ForeignKey("trips.Trip", on_delete=models.CASCADE, related_name="reviews", verbose_name="trajet")
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="reviews_written", verbose_name="auteur"
    )
    target = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="reviews_received", verbose_name="membre évalué"
    )
    rating = models.PositiveSmallIntegerField("note", validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.CharField("commentaire", max_length=300, blank=True)
    is_reported = models.BooleanField("signalé", default=False, db_index=True)
    report_reason = models.CharField("motif du signalement", max_length=300, blank=True)
    is_hidden = models.BooleanField("masqué (modération)", default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "avis"
        verbose_name_plural = "avis"
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(fields=["trip", "author", "target"], name="unique_review_per_trip"),
            models.CheckConstraint(condition=models.Q(rating__gte=1, rating__lte=5), name="rating_1_to_5"),
        ]

    def __str__(self):
        return f"{self.author} → {self.target} : {self.rating}★"
