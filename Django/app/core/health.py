from django.db import connection
from django.http import JsonResponse


def health(request):
    """Liveness probe: the process is up and answers requests."""
    return JsonResponse({"status": "ok"})


def ready(request):
    """Readiness probe: the app can reach its database."""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
    except Exception:
        return JsonResponse({"status": "database unavailable"}, status=503)
    return JsonResponse({"status": "ready"})
