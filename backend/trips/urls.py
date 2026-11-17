from rest_framework.routers import DefaultRouter

from .views import SavedRouteViewSet, TripViewSet

router = DefaultRouter()
router.register("trips", TripViewSet, basename="trip")
router.register("saved-routes", SavedRouteViewSet, basename="saved-route")

urlpatterns = router.urls
