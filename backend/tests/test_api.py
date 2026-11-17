"""Tests du parcours complet : inscription → publication/réservation → évaluation."""
from datetime import timedelta

from django.utils import timezone
from rest_framework.test import APITestCase

from accounts.models import User
from bookings.models import Booking
from trips.models import Trip

PASSWORD = "Moov!2026secure"


class BaseAPITest(APITestCase):
    def register(self, email, first="Amira", last="Test"):
        res = self.client.post("/api/auth/register/", {
            "email": email, "password": PASSWORD, "first_name": first, "last_name": last, "phone": "+212612345678",
        }, format="json")
        self.assertEqual(res.status_code, 201, res.data)
        return res.data

    def auth(self, tokens):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")

    def make_trip(self, **kw):
        data = {
            "departure_city": "Rabat", "departure_place": "Gare Rabat Ville",
            "arrival_city": "Benguerir", "arrival_place": "Campus UM6P",
            "departure_time": (timezone.now() + timedelta(days=2)).isoformat(),
            "seats_total": 3, "price_per_seat": "150.00",
        }
        data.update(kw)
        return self.client.post("/api/trips/", data, format="json")


class AuthTests(BaseAPITest):
    def test_register_login_me(self):
        self.register("amira@um6p.ma")
        res = self.client.post("/api/auth/login/", {"email": "amira@um6p.ma", "password": PASSWORD}, format="json")
        self.assertEqual(res.status_code, 200)
        self.assertIn("access", res.data)
        self.auth(res.data)
        me = self.client.get("/api/me/")
        self.assertEqual(me.data["email"], "amira@um6p.ma")
        patch = self.client.patch("/api/me/", {"bio": "Basée à Rabat."}, format="json")
        self.assertEqual(patch.data["bio"], "Basée à Rabat.")

    def test_duplicate_email_and_bad_phone(self):
        self.register("a@um6p.ma")
        res = self.client.post("/api/auth/register/", {
            "email": "A@um6p.ma", "password": PASSWORD, "first_name": "x", "last_name": "y",
        }, format="json")
        self.assertEqual(res.status_code, 400)
        res = self.client.post("/api/auth/register/", {
            "email": "b@um6p.ma", "password": PASSWORD, "first_name": "x", "last_name": "y", "phone": "0612345678",
        }, format="json")
        self.assertEqual(res.status_code, 400)
        self.assertIn("phone", res.data)

    def test_me_requires_auth(self):
        self.assertEqual(self.client.get("/api/me/").status_code, 401)

    def test_logout_blacklists_refresh(self):
        tokens = self.register("c@um6p.ma")
        self.auth(tokens)
        self.assertEqual(self.client.post("/api/auth/logout/", {"refresh": tokens["refresh"]}, format="json").status_code, 205)
        self.assertEqual(self.client.post("/api/auth/refresh/", {"refresh": tokens["refresh"]}, format="json").status_code, 401)


class FullJourneyTests(BaseAPITest):
    def setUp(self):
        self.driver_tokens = self.register("youssef@um6p.ma", "Youssef", "Amrani")
        self.passenger_tokens = self.register("salma@um6p.ma", "Salma", "Idrissi")
        self.driver = User.objects.get(email="youssef@um6p.ma")
        self.passenger = User.objects.get(email="salma@um6p.ma")

    def test_full_journey(self):
        # Le conducteur ajoute son véhicule et publie un trajet
        self.auth(self.driver_tokens)
        v = self.client.post("/api/me/vehicles/", {"brand": "Toyota", "model": "Corolla", "color": "Bleue", "seats": 3}, format="json")
        self.assertEqual(v.status_code, 201)
        trip = self.make_trip(vehicle_id=v.data["id"])
        self.assertEqual(trip.status_code, 201, trip.data)
        trip_id = trip.data["id"]
        self.assertEqual(trip.data["available_seats"], 3)

        # Recherche publique (sans compte)
        self.client.credentials()
        date = trip.data["departure_time"][:10]
        res = self.client.get("/api/trips/", {"departure_city": "rabat", "arrival_city": "benguerir", "date": date})
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(self.client.get("/api/trips/", {"arrival_city": "Fès"}).data["count"], 0)

        # Le passager demande 2 places
        self.auth(self.passenger_tokens)
        b = self.client.post("/api/bookings/", {"trip_id": trip_id, "seats": 2, "message": "Bonjour !"}, format="json")
        self.assertEqual(b.status_code, 201, b.data)
        self.assertEqual(b.data["status"], "pending")
        self.assertIsNone(b.data["contact"])
        booking_id = b.data["id"]
        # Pas de double réservation
        self.assertEqual(self.client.post("/api/bookings/", {"trip_id": trip_id}, format="json").status_code, 400)
        # Le passager ne peut pas accepter sa propre demande
        self.assertEqual(self.client.post(f"/api/bookings/{booking_id}/accept/").status_code, 403)

        # Le conducteur voit la demande, est notifié, et accepte
        self.auth(self.driver_tokens)
        received = self.client.get("/api/bookings/received/", {"status": "pending"})
        self.assertEqual(received.data["count"], 1)
        self.assertEqual(self.client.get("/api/notifications/", {"is_read": "false"}).data["count"], 1)
        acc = self.client.post(f"/api/bookings/{booking_id}/accept/")
        self.assertEqual(acc.status_code, 200)
        self.assertEqual(acc.data["status"], "accepted")
        self.assertEqual(acc.data["contact"]["email"], "salma@um6p.ma")
        self.assertEqual(self.client.get(f"/api/trips/{trip_id}/").data["available_seats"], 1)

        # Avis impossible avant la fin du trajet
        self.auth(self.passenger_tokens)
        early = self.client.post("/api/reviews/", {"trip_id": trip_id, "target_id": self.driver.id, "rating": 5}, format="json")
        self.assertEqual(early.status_code, 400)

        # Le trajet a lieu, le conducteur le marque terminé
        Trip.objects.filter(pk=trip_id).update(departure_time=timezone.now() - timedelta(hours=3))
        self.auth(self.driver_tokens)
        self.assertEqual(self.client.post(f"/api/trips/{trip_id}/complete/").data["status"], "completed")

        # Évaluations croisées
        self.auth(self.passenger_tokens)
        r = self.client.post("/api/reviews/", {
            "trip_id": trip_id, "target_id": self.driver.id, "rating": 5,
            "comment": "Ponctuel et trajet confortable.",
        }, format="json")
        self.assertEqual(r.status_code, 201, r.data)
        dup = self.client.post("/api/reviews/", {"trip_id": trip_id, "target_id": self.driver.id, "rating": 4}, format="json")
        self.assertEqual(dup.status_code, 400)
        bad = self.client.post("/api/reviews/", {"trip_id": trip_id, "target_id": self.passenger.id, "rating": 5}, format="json")
        self.assertEqual(bad.status_code, 400)

        self.auth(self.driver_tokens)
        r2 = self.client.post("/api/reviews/", {"trip_id": trip_id, "target_id": self.passenger.id, "rating": 4}, format="json")
        self.assertEqual(r2.status_code, 201, r2.data)
        out_of_range = self.client.post("/api/reviews/", {"trip_id": trip_id, "target_id": self.passenger.id, "rating": 6}, format="json")
        self.assertEqual(out_of_range.status_code, 400)

        profile = self.client.get(f"/api/users/{self.driver.id}/")
        self.assertEqual(profile.data["rating"], {"average": 5.0, "count": 1})
        self.assertEqual(self.client.get("/api/me/").data["stats"]["trips_as_driver"], 1)

        # Signalement d'un avis par la personne évaluée
        report = self.client.post(f"/api/reviews/{r.data['id']}/report/", {"reason": "test"}, format="json")
        self.assertEqual(report.status_code, 200)

    def test_overbooking_is_prevented(self):
        self.auth(self.driver_tokens)
        trip_id = self.make_trip(seats_total=1).data["id"]
        third = self.register("omar@um6p.ma", "Omar", "Khattabi")

        self.auth(self.passenger_tokens)
        b1 = self.client.post("/api/bookings/", {"trip_id": trip_id}, format="json").data["id"]
        self.auth(third)
        b2 = self.client.post("/api/bookings/", {"trip_id": trip_id}, format="json").data["id"]

        self.auth(self.driver_tokens)
        self.assertEqual(self.client.post(f"/api/bookings/{b1}/accept/").status_code, 200)
        self.assertEqual(self.client.post(f"/api/bookings/{b2}/accept/").status_code, 400)
        # Trajet complet : n'apparaît plus si on demande au moins 1 place
        self.client.credentials()
        self.assertEqual(self.client.get("/api/trips/", {"seats": 1}).data["count"], 0)

    def test_driver_cannot_book_own_trip_and_refuse_flow(self):
        self.auth(self.driver_tokens)
        trip_id = self.make_trip().data["id"]
        self.assertEqual(self.client.post("/api/bookings/", {"trip_id": trip_id}, format="json").status_code, 400)

        self.auth(self.passenger_tokens)
        bid = self.client.post("/api/bookings/", {"trip_id": trip_id}, format="json").data["id"]
        self.auth(self.driver_tokens)
        self.assertEqual(self.client.post(f"/api/bookings/{bid}/refuse/").data["status"], "refused")
        self.assertEqual(self.client.post(f"/api/bookings/{bid}/accept/").status_code, 400)

    def test_cancel_trip_cancels_bookings(self):
        self.auth(self.driver_tokens)
        trip_id = self.make_trip().data["id"]
        self.auth(self.passenger_tokens)
        bid = self.client.post("/api/bookings/", {"trip_id": trip_id}, format="json").data["id"]
        # Seul le conducteur peut annuler
        self.assertEqual(self.client.post(f"/api/trips/{trip_id}/cancel/").status_code, 403)
        self.auth(self.driver_tokens)
        self.assertEqual(self.client.post(f"/api/trips/{trip_id}/cancel/").data["status"], "cancelled")
        self.assertEqual(Booking.objects.get(pk=bid).status, "cancelled")
        self.assertEqual(self.client.get("/api/trips/mine/", {"status": "cancelled"}).data["count"], 1)

    def test_past_departure_rejected(self):
        self.auth(self.driver_tokens)
        res = self.make_trip(departure_time=(timezone.now() - timedelta(hours=1)).isoformat())
        self.assertEqual(res.status_code, 400)

    def test_passenger_cancels_and_auto_accept(self):
        self.auth(self.driver_tokens)
        trip_id = self.make_trip(auto_accept=True).data["id"]
        self.auth(self.passenger_tokens)
        b = self.client.post("/api/bookings/", {"trip_id": trip_id}, format="json")
        self.assertEqual(Booking.objects.get(pk=b.data["id"]).status, "accepted")
        self.assertEqual(self.client.post(f"/api/bookings/{b.data['id']}/cancel/").data["status"], "cancelled")
        # Peut re-réserver après annulation
        self.assertEqual(self.client.post("/api/bookings/", {"trip_id": trip_id}, format="json").status_code, 201)

    def test_saved_routes(self):
        self.auth(self.passenger_tokens)
        res = self.client.post("/api/saved-routes/", {"departure_city": "Marrakech", "arrival_city": "Benguerir"}, format="json")
        self.assertEqual(res.status_code, 201)
        self.assertEqual(self.client.get("/api/saved-routes/").data["count"], 1)
