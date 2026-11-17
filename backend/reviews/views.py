from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import mixins, permissions, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from notifications.services import notify

from .models import Review
from .serializers import ReportSerializer, ReviewSerializer


class ReviewViewSet(mixins.CreateModelMixin, mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    """
    Avis.

    - `GET /api/reviews/?user=<id>` : avis reçus par un membre (profil, carte conducteur).
    - `GET /api/reviews/?trip=<id>` : avis d'un trajet.
    - `POST /api/reviews/` : `{trip_id, target_id, rating (1-5), comment}` après un trajet terminé.
    - `POST /api/reviews/{id}/report/` : signaler un avis à la modération.
    """

    serializer_class = ReviewSerializer
    filterset_fields = {"target": ["exact"], "trip": ["exact"], "author": ["exact"]}

    def get_permissions(self):
        if self.action in ("list", "retrieve"):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        qs = Review.objects.filter(is_hidden=False).select_related("author", "trip")
        user_id = self.request.query_params.get("user")
        if user_id:
            qs = qs.filter(target_id=user_id)
        return qs

    @extend_schema(parameters=[OpenApiParameter("user", int, description="Avis reçus par ce membre")])
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)

    def perform_create(self, serializer):
        review = serializer.save(author=self.request.user)
        notify(
            review.target, "review_received", "Nouvel avis reçu",
            f"{review.author.get_full_name()} vous a attribué {review.rating}★.",
            trip=review.trip,
        )

    @extend_schema(request=ReportSerializer, responses=None)
    @action(detail=True, methods=["post"])
    def report(self, request, pk=None):
        review = self.get_object()
        if review.author_id == request.user.id:
            raise ValidationError("Vous ne pouvez pas signaler votre propre avis.")
        serializer = ReportSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        review.is_reported = True
        review.report_reason = serializer.validated_data["reason"]
        review.save(update_fields=["is_reported", "report_reason"])
        return Response({"detail": "Avis signalé à la modération."})
