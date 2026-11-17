from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import Http404
from django.urls import include, path, re_path
from django.views.static import serve
from django.views.generic import RedirectView
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

admin.site.site_header = "MOOV — Administration"
admin.site.site_title = "MOOV Admin"
admin.site.index_title = "Back-office"



def webapp(request, path=""):
    """Version web installable de l'app MOOV (PWA pour iPhone), compilée dans /webapp."""
    if not (settings.WEBAPP_DIR / "index.html").exists():
        raise Http404("Version web non compilée (voir mobile/README.md).")
    root = settings.WEBAPP_DIR.resolve()
    target = (root / path).resolve()
    if not path or not target.is_relative_to(root) or not target.is_file():
        path = "index.html"  # routes internes de l'app (et jamais de fichier hors de /webapp)
    response = serve(request, path, document_root=settings.WEBAPP_DIR)
    if path == "index.html":
        response["Cache-Control"] = "no-cache"  # toujours charger la dernière version
    return response


urlpatterns = [
    # Ouvrir l'adresse du serveur dans un navigateur mène à l'app web.
    path("", RedirectView.as_view(url="/app/", permanent=False)),
    path("app/", webapp, name="webapp"),
    re_path(r"^app/(?P<path>.+)$", webapp),
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
