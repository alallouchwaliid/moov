from rest_framework import generics, permissions, status, viewsets
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import User, Vehicle
from .serializers import (
    ChangePasswordSerializer,
    LogoutSerializer,
    MeSerializer,
    MoovTokenObtainPairSerializer,
    PublicUserSerializer,
    RegisterSerializer,
    VehicleSerializer,
)


class RegisterView(generics.CreateAPIView):
    """Inscription par email + mot de passe. Renvoie directement les tokens JWT."""

    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "user": MeSerializer(user, context={"request": request}).data,
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(TokenObtainPairView):
    serializer_class = MoovTokenObtainPairSerializer


class LogoutView(APIView):
    """Invalide le refresh token (blacklist)."""

    serializer_class = LogoutSerializer

    def post(self, request):
        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            RefreshToken(serializer.validated_data["refresh"]).blacklist()
        except TokenError:
            return Response({"detail": "Token invalide ou expiré."}, status=status.HTTP_400_BAD_REQUEST)
        return Response(status=status.HTTP_205_RESET_CONTENT)


class MeView(generics.RetrieveUpdateDestroyAPIView):
    """Profil de l'utilisateur connecté. PATCH accepte du multipart pour l'avatar."""

    serializer_class = MeSerializer
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_object(self):
        return self.request.user

    def perform_destroy(self, instance):
        # Désactivation plutôt que suppression : conserve l'historique des trajets/avis.
        instance.is_active = False
        instance.save(update_fields=["is_active"])


class ChangePasswordView(APIView):
    serializer_class = ChangePasswordSerializer

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        request.user.set_password(serializer.validated_data["new_password"])
        request.user.save(update_fields=["password"])
        return Response({"detail": "Mot de passe modifié."})


class PublicUserView(generics.RetrieveAPIView):
    """Profil public d'un membre."""

    serializer_class = PublicUserSerializer
    queryset = User.objects.filter(is_active=True)


class VehicleViewSet(viewsets.ModelViewSet):
    """Véhicules de l'utilisateur connecté."""

    serializer_class = VehicleSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Vehicle.objects.none()
        return self.request.user.vehicles.all()

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)
