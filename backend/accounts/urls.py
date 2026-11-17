from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import MeView, PublicUserView, VehicleViewSet

router = DefaultRouter()
router.register("me/vehicles", VehicleViewSet, basename="vehicle")

urlpatterns = [
    path("me/", MeView.as_view(), name="me"),
    path("users/<int:pk>/", PublicUserView.as_view(), name="user-detail"),
] + router.urls
