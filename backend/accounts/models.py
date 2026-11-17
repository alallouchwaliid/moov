from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.core.validators import RegexValidator
from django.db import models
from django.db.models import Avg, Count


class UserManager(BaseUserManager):
    """Gestionnaire d'utilisateurs : l'email remplace le nom d'utilisateur."""

    use_in_migrations = True

    def _create_user(self, email, password, **extra):
        if not email:
            raise ValueError("L'adresse email est obligatoire.")
        email = self.normalize_email(email).lower()
        user = self.model(email=email, **extra)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, **extra):
        extra.setdefault("is_staff", False)
        extra.setdefault("is_superuser", False)
        return self._create_user(email, password, **extra)

    def create_superuser(self, email, password=None, **extra):
        extra.setdefault("is_staff", True)
        extra.setdefault("is_superuser", True)
        extra.setdefault("is_verified", True)
        return self._create_user(email, password, **extra)


phone_validator = RegexValidator(
    regex=r"^\+212[67]\d{8}$",
    message="Format attendu : +212 suivi de 9 chiffres commençant par 6 ou 7.",
)


class User(AbstractUser):
    class Role(models.TextChoices):
        STUDENT = "student", "Étudiant"
        STAFF = "staff", "Personnel universitaire"

    username = None
    email = models.EmailField("adresse email", unique=True)
    phone = models.CharField(
        "téléphone", max_length=13, blank=True, validators=[phone_validator]
    )
    avatar = models.ImageField("photo", upload_to="avatars/", blank=True, null=True)
    bio = models.CharField("présentation", max_length=280, blank=True)
    city = models.CharField("ville", max_length=80, blank=True)
    university = models.CharField("université / campus", max_length=120, blank=True)
    role = models.CharField(
        "statut", max_length=10, choices=Role.choices, default=Role.STUDENT
    )
    is_verified = models.BooleanField(
        "identité vérifiée",
        default=False,
        help_text="Validé par un administrateur depuis le back-office.",
    )

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["first_name", "last_name"]

    objects = UserManager()

    class Meta:
        verbose_name = "utilisateur"
        verbose_name_plural = "utilisateurs"
        ordering = ["-date_joined"]

    def __str__(self):
        return f"{self.get_full_name() or self.email}"

    def rating_summary(self):
        """Note moyenne et nombre d'avis reçus (avis non masqués)."""
        data = self.reviews_received.filter(is_hidden=False).aggregate(
            average=Avg("rating"), count=Count("id")
        )
        avg = data["average"]
        return {"average": round(avg, 1) if avg is not None else None, "count": data["count"]}


class Vehicle(models.Model):
    owner = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="vehicles", verbose_name="propriétaire"
    )
    brand = models.CharField("marque", max_length=50)
    model = models.CharField("modèle", max_length=50)
    color = models.CharField("couleur", max_length=30, blank=True)
    plate_number = models.CharField("immatriculation", max_length=20, blank=True)
    seats = models.PositiveSmallIntegerField("places passagers", default=3)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "véhicule"
        verbose_name_plural = "véhicules"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.brand} {self.model}{' · ' + self.color if self.color else ''}"
