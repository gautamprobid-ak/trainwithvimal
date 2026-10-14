from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

api_v1 = [
    path("auth/", include("apps.accounts.urls")),
    path("", include("apps.core.urls")),
    path("", include("apps.people.urls")),
    path("", include("apps.training.urls")),
    path("", include("apps.nutrition.urls")),
    path("", include("apps.habits.urls")),
    path("", include("apps.checkins.urls")),
    path("", include("apps.scheduling.urls")),
    path("", include("apps.content.urls")),
    path("", include("apps.engage.urls")),
]

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/", include(api_v1)),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="docs"),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

admin.site.site_header = "Train With Vimal admin"
admin.site.site_title = "Train With Vimal"
