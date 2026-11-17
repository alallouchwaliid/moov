from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path, re_path
from django.views.static import serve
from django.views.generic import RedirectView
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

admin.site.site_header = "MOOV — Administration"
admin.site.site_title = "MOOV Admin"
admin.site.index_title = "Back-office"

urlpatterns = [
    # Le backend n'a pas de site web : la racine renvoie vers la documentation de l'API.
    path("", RedirectView.as_view(pattern_name="swagger-ui", permanent=False)),
    path("admin/", admin.site.urls),
    path("api/auth/", include("accounts.urls_auth")),
    path("api/", include("accounts.urls")),
    path("api/", include("trips.urls")),
    path("api/", include("bookings.urls")),
    path("api/", include("reviews.urls")),
    path("api/", include("notifications.urls")),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
elif settings.SERVE_MEDIA:
    urlpatterns += [
        re_path(r"^media/(?P<path>.*)$", serve, {"document_root": settings.MEDIA_ROOT}),
    ]
