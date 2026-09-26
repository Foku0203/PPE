from django.conf import settings
from django.contrib import admin
from django.http import Http404
from django.urls import include, path, re_path
from django.views.static import serve


def web_app(request, path=''):
    """Serve the Flutter web build; unknown paths fall back to index.html."""
    web_dir = settings.FLUTTER_WEB_DIR
    if path and (web_dir / path).is_file():
        return serve(request, path, document_root=web_dir)
    if not (web_dir / 'index.html').is_file():
        raise Http404('Flutter web build not found - run `flutter build web` in ppe_mobile_app.')
    return serve(request, 'index.html', document_root=web_dir)


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/', include('ppe.urls')),
    # Served by Django even with DEBUG off, since there is no separate web server in front.
    re_path(r'^media/(?P<path>.*)$', serve, {'document_root': settings.MEDIA_ROOT}),
    re_path(r'^(?!api/|admin/|media/)(?P<path>.*)$', web_app),
]
