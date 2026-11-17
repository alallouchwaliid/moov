import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import 'api_client.dart';

/// Critères de recherche de trajets.
class SearchQuery {
  SearchQuery({
    this.from = '',
    this.to = '',
    this.date,
    this.passengers = 1,
    this.maxPrice,
    this.verifiedOnly = false,
    this.departureAfter,
    this.ordering = 'departure_time',
  });

  String from;
  String to;
  DateTime? date;
  int passengers;
  int? maxPrice;
  bool verifiedOnly;
  String? departureAfter; // "HH:MM"
  String ordering;

  SearchQuery copy() => SearchQuery(
        from: from,
        to: to,
        date: date,
        passengers: passengers,
        maxPrice: maxPrice,
        verifiedOnly: verifiedOnly,
        departureAfter: departureAfter,
        ordering: ordering,
      );

  int get activeFilters => (maxPrice != null ? 1 : 0) + (verifiedOnly ? 1 : 0) + (departureAfter != null ? 1 : 0);

  Map<String, dynamic> toQuery(int page) => {
        'departure_city': from.trim(),
        'arrival_city': to.trim(),
        'date': date == null ? null : DateFormat('yyyy-MM-dd').format(date!),
        'seats': passengers,
        'max_price': maxPrice,
        'verified_only': verifiedOnly ? 'true' : null,
        'departure_after': departureAfter,
        'ordering': ordering,
        'page': page,
      };
}

/// Appels typés vers les endpoints MOOV.
class MoovApi {
  // --- Auth & profil
  static Future<Map<String, dynamic>> login(String email, String password) async =>
      await api.post('/auth/login/', {'email': email, 'password': password}) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async =>
      await api.post('/auth/register/', data) as Map<String, dynamic>;

  static Future<void> logout(String refresh) => api.post('/auth/logout/', {'refresh': refresh});

  static Future<void> changePassword(String oldPassword, String newPassword) =>
      api.post('/auth/change-password/', {'old_password': oldPassword, 'new_password': newPassword});

  static Future<User> me() async => User.fromJson(await api.get('/me/') as Map<String, dynamic>);

  static Future<User> updateMe(Map<String, dynamic> data) async =>
      User.fromJson(await api.patch('/me/', data) as Map<String, dynamic>);

  static Future<User> uploadAvatar(XFile file) async => User.fromJson(
      await api.uploadFile('/me/', 'avatar', await file.readAsBytes(), file.name) as Map<String, dynamic>);

  static Future<User> user(int id) async => User.fromJson(await api.get('/users/$id/') as Map<String, dynamic>);

  // --- Véhicules
  static Future<List<Vehicle>> vehicles() async =>
      Paged.fromJson(await api.get('/me/vehicles/'), Vehicle.fromJson).results;

  static Future<Vehicle> addVehicle(Map<String, dynamic> data) async =>
      Vehicle.fromJson(await api.post('/me/vehicles/', data) as Map<String, dynamic>);

  static Future<void> deleteVehicle(int id) => api.delete('/me/vehicles/$id/');

  // --- Trajets
  static Future<Paged<Trip>> searchTrips(SearchQuery q, {int page = 1}) async =>
      Paged.fromJson(await api.get('/trips/', query: q.toQuery(page)), Trip.fromJson);

  static Future<Trip> trip(int id) async => Trip.fromJson(await api.get('/trips/$id/') as Map<String, dynamic>);

  static Future<Trip> publishTrip(Map<String, dynamic> data) async =>
      Trip.fromJson(await api.post('/trips/', data) as Map<String, dynamic>);

  static Future<List<Trip>> myTrips() async {
    final all = <Trip>[];
    var page = 1;
    while (true) {
      final p = Paged.fromJson(await api.get('/trips/mine/', query: {'page': page}), Trip.fromJson);
      all.addAll(p.results);
      if (!p.hasNext) return all;
      page++;
    }
  }

  static Future<Trip> cancelTrip(int id) async =>
      Trip.fromJson(await api.post('/trips/$id/cancel/') as Map<String, dynamic>);

  static Future<Trip> completeTrip(int id) async =>
      Trip.fromJson(await api.post('/trips/$id/complete/') as Map<String, dynamic>);

  static Future<List<Booking>> tripBookings(int tripId) async =>
      Paged.fromJson(await api.get('/trips/$tripId/bookings/'), Booking.fromJson).results;

  // --- Trajets enregistrés
  static Future<List<SavedRoute>> savedRoutes() async =>
      Paged.fromJson(await api.get('/saved-routes/'), SavedRoute.fromJson).results;

  static Future<SavedRoute> saveRoute(String from, String to) async => SavedRoute.fromJson(
      await api.post('/saved-routes/', {'departure_city': from, 'arrival_city': to}) as Map<String, dynamic>);

  static Future<void> deleteSavedRoute(int id) => api.delete('/saved-routes/$id/');

  // --- Réservations
  static Future<Booking> book(int tripId, int seats, String message) async => Booking.fromJson(
      await api.post('/bookings/', {'trip_id': tripId, 'seats': seats, 'message': message}) as Map<String, dynamic>);

  static Future<Booking> booking(int id) async =>
      Booking.fromJson(await api.get('/bookings/$id/') as Map<String, dynamic>);

  static Future<List<Booking>> myBookings() async {
    final all = <Booking>[];
    var page = 1;
    while (true) {
      final p = Paged.fromJson(await api.get('/bookings/', query: {'page': page}), Booking.fromJson);
      all.addAll(p.results);
      if (!p.hasNext) return all;
      page++;
    }
  }

  static Future<List<Booking>> receivedPending() async =>
      Paged.fromJson(await api.get('/bookings/received/', query: {'status': 'pending'}), Booking.fromJson).results;

  static Future<Booking> bookingAction(int id, String action) async =>
      Booking.fromJson(await api.post('/bookings/$id/$action/') as Map<String, dynamic>);

  // --- Avis
  static Future<Paged<Review>> reviewsFor(int userId, {int page = 1}) async =>
      Paged.fromJson(await api.get('/reviews/', query: {'user': userId, 'page': page}), Review.fromJson);

  static Future<void> postReview({required int tripId, required int targetId, required int rating, String comment = ''}) =>
      api.post('/reviews/', {'trip_id': tripId, 'target_id': targetId, 'rating': rating, 'comment': comment});

  static Future<void> reportReview(int id, String reason) => api.post('/reviews/$id/report/', {'reason': reason});

  // --- Notifications
  static Future<List<AppNotification>> notifications() async =>
      Paged.fromJson(await api.get('/notifications/'), AppNotification.fromJson).results;

  static Future<int> unreadCount() async =>
      Paged.fromJson(await api.get('/notifications/', query: {'is_read': 'false'}), AppNotification.fromJson).count;

  static Future<void> markRead(int id) => api.post('/notifications/$id/read/');

  static Future<void> markAllRead() => api.post('/notifications/read-all/');
}
