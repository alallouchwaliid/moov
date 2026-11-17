from .models import Notification


def notify(recipient, kind, title, body, trip=None, booking=None):
    return Notification.objects.create(
        recipient=recipient, kind=kind, title=title, body=body, trip=trip, booking=booking
    )
