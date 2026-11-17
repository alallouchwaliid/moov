"""Crée des données de démonstration inspirées des maquettes MOOV.

Usage : python manage.py seed_demo
Tous les comptes ont le mot de passe : Moov!2026demo
"""
from datetime import timedelta

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from accounts.models import User, Vehicle
from bookings.models import Booking
from reviews.models import Review
from trips.models import SavedRoute, Trip

PASSWORD = "Moov!2026demo"

USERS = [
    ("amira@moov.ma", "Amira", "Benali", "+212612345678", "Rabat", "Basée à Rabat. J'aime découvrir le Maroc et partager la route."),
    ("youssef@moov.ma", "Youssef", "Amrani", "+212623456789", "Rabat", "Conducteur régulier Rabat ⇄ Benguerir."),
    ("salma@moov.ma", "Salma", "Idrissi", "+212634567890", "Casablanca", ""),
    ("omar@moov.ma", "Omar", "El Khattabi", "+212645678901", "Marrakech", ""),
]


class Command(BaseCommand):
    help = "Insère des utilisateurs, trajets, réservations et avis de démonstration."

    @transaction.atomic
    def handle(self, *args, **options):
        users = {}
        for email, first, last, phone, city, bio in USERS:
            user, created = User.objects.get_or_create(
                email=email,
                defaults=dict(first_name=first, last_name=last, phone=phone, city=city, bio=bio,
                              university="UM6P", is_verified=True),
            )
            if created:
                user.set_password(PASSWORD)
                user.save()
            users[first.lower()] = user

        if Trip.objects.filter(driver=users["youssef"]).exists():
            self.stdout.write(self.style.WARNING("Données de démo déjà présentes."))
            return

        corolla = Vehicle.objects.create(owner=users["youssef"], brand="Toyota", model="Corolla", color="Bleue", seats=3)
        clio = Vehicle.objects.create(owner=users["amira"], brand="Renault", model="Clio", color="Blanche", seats=3)

        now = timezone.now().replace(minute=0, second=0, microsecond=0)
        upcoming = Trip.objects.create(
            driver=users["youssef"], vehicle=corolla,
            departure_city="Rabat", departure_place="Gare Rabat Ville",
            arrival_city="Benguerir", arrival_place="Campus UM6P",
            departure_time=now + timedelta(days=3), arrival_time=now + timedelta(days=3, hours=3, minutes=30),
            seats_total=3, price_per_seat=150,
        )
        Trip.objects.create(
            driver=users["amira"], vehicle=clio,
            departure_city="Benguerir", departure_place="Campus UM6P",
            arrival_city="Rabat", arrival_place="Gare Rabat Ville",
            departure_time=now + timedelta(days=5), seats_total=3, price_per_seat=140,
        )
        Trip.objects.create(
            driver=users["omar"], departure_city="Marrakech", departure_place="Gare Guéliz",
            arrival_city="Benguerir", arrival_place="Campus UM6P",
            departure_time=now + timedelta(days=2), seats_total=2, price_per_seat=60,
        )
        Booking.objects.create(trip=upcoming, passenger=users["amira"], seats=1, status=Booking.Status.ACCEPTED)

        past = Trip.objects.create(
            driver=users["youssef"], vehicle=corolla,
            departure_city="Casablanca", departure_place="Gare Casa-Voyageurs",
            arrival_city="Benguerir", arrival_place="Campus UM6P",
            departure_time=now - timedelta(days=10), seats_total=3, price_per_seat=90,
            status=Trip.Status.COMPLETED,
        )
        for name, comment in [
            ("salma", "Ponctuel, rendez-vous facile à trouver et trajet confortable. Je recommande."),
            ("omar", "Très bon trajet jusqu'à Benguerir. Communication claire du début à la fin."),
        ]:
            Booking.objects.create(trip=past, passenger=users[name], status=Booking.Status.ACCEPTED)
            Review.objects.create(trip=past, author=users[name], target=users["youssef"], rating=5, comment=comment)

        SavedRoute.objects.create(user=users["amira"], departure_city="Marrakech", departure_place="Gare Guéliz",
                                  arrival_city="Benguerir", arrival_place="Campus UM6P")
        SavedRoute.objects.create(user=users["amira"], departure_city="Casablanca", departure_place="Gare Casa-Voyageurs",
                                  arrival_city="Benguerir", arrival_place="Campus UM6P")

        self.stdout.write(self.style.SUCCESS(
            f"Démo créée : {len(USERS)} utilisateurs (mot de passe « {PASSWORD} »), 4 trajets, avis et réservations."
        ))
