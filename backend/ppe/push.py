"""Push delivery for Notification rows (FCM/APNs through Firebase Admin).

Notifications are always stored in the database first (in-app feed / outbox). Push delivery is
best effort: it is enabled only when `firebase_admin` is installed and FIREBASE_CREDENTIALS points to
a service-account JSON file. Without it the mobile app still receives notifications by polling.
"""
import logging
import os

from django.utils import timezone

logger = logging.getLogger(__name__)
_app = None
_disabled = False


def _firebase_app():
    global _app, _disabled
    if _app or _disabled:
        return _app
    credentials_path = os.getenv('FIREBASE_CREDENTIALS')
    if not credentials_path:
        _disabled = True
        return None
    try:
        import firebase_admin
        from firebase_admin import credentials
        _app = firebase_admin.initialize_app(credentials.Certificate(credentials_path))
    except Exception:  # pragma: no cover - depends on deployment
        logger.exception('Firebase push disabled: could not initialise firebase_admin')
        _disabled = True
    return _app


def send_push(notifications) -> None:
    app = _firebase_app()
    if app is None:
        return
    from firebase_admin import messaging

    from .models import DeviceToken
    for notification in notifications:
        tokens = list(DeviceToken.objects.filter(user=notification.recipient, active=True).values_list('token', flat=True))
        if not tokens:
            continue
        data = {key: str(value) for key, value in (notification.payload or {}).items()}
        data['notification_type'] = notification.notification_type
        message = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(title=notification.title, body=notification.message),
            data=data,
        )
        try:
            result = messaging.send_each_for_multicast(message, app=app)
            for token, response in zip(tokens, result.responses):
                if not response.success:
                    DeviceToken.objects.filter(token=token).update(active=False)
            if notification.pk:
                type(notification).objects.filter(pk=notification.pk).update(delivered_at=timezone.now())
        except Exception:  # pragma: no cover - network dependent
            logger.exception('Push delivery failed for notification %s', notification.pk)
