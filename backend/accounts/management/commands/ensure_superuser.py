"""Crée le compte administrateur à partir de variables d'environnement, s'il n'existe pas.

Utile sur un hébergeur sans console (offre gratuite Render) :
  DJANGO_SUPERUSER_EMAIL, DJANGO_SUPERUSER_PASSWORD
Sans ces variables, la commande ne fait rien.
"""
import os

from django.core.management.base import BaseCommand

from accounts.models import User


class Command(BaseCommand):
    help = "Crée l'administrateur défini par DJANGO_SUPERUSER_EMAIL / DJANGO_SUPERUSER_PASSWORD."

    def handle(self, *args, **options):
        email = os.environ.get("DJANGO_SUPERUSER_EMAIL", "").strip().lower()
        password = os.environ.get("DJANGO_SUPERUSER_PASSWORD", "")
        if not email or not password:
            self.stdout.write("Pas de DJANGO_SUPERUSER_EMAIL/PASSWORD : aucun administrateur créé.")
            return
        if User.objects.filter(email=email).exists():
            self.stdout.write(f"Administrateur {email} déjà présent.")
            return
        User.objects.create_superuser(email=email, password=password, first_name="Admin", last_name="MOOV")
        self.stdout.write(self.style.SUCCESS(f"Administrateur {email} créé."))
