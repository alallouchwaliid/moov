/// Modèles de données correspondant aux réponses de l'API Django.
library;

DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String).toLocal();
double _num(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);

class Vehicle {
  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    this.color = '',
    this.plateNumber = '',
    this.seats = 3,
  });

  final int id;
  final String brand;
  final String model;
  final String color;
  final String plateNumber;
  final int seats;

  String get label => '$brand $model${color.isNotEmpty ? ' · $color' : ''}';

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as int,
        brand: j['brand'] as String? ?? '',
        model: j['model'] as String? ?? '',
        color: j['color'] as String? ?? '',
        plateNumber: j['plate_number'] as String? ?? '',
        seats: j['seats'] as int? ?? 3,
      );
}

class User {
  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone = '',
    this.avatar,
    this.bio = '',
    this.city = '',
    this.university = '',
    this.role = 'student',
    this.isVerified = false,
    this.dateJoined,
    this.ratingAverage,
    this.ratingCount = 0,
    this.tripsAsDriver = 0,
    this.tripsAsPassenger = 0,
    this.vehicles = const [],
  });

  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String phone;
  final String? avatar;
  final String bio;
  final String city;
  final String university;
  final String role;
  final bool isVerified;
  final DateTime? dateJoined;
  final double? ratingAverage;
  final int ratingCount;
  final int tripsAsDriver;
  final int tripsAsPassenger;
  final List<Vehicle> vehicles;

  String get fullName => '$firstName $lastName'.trim();
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  int get tripsCount => tripsAsDriver + tripsAsPassenger;

  factory User.fromJson(Map<String, dynamic> j) {
    final rating = j['rating'] as Map<String, dynamic>?;
    final stats = j['stats'] as Map<String, dynamic>?;
    return User(
      id: j['id'] as int,
      firstName: j['first_name'] as String? ?? '',
      lastName: j['last_name'] as String? ?? '',
      email: j['email'] as String?,
      phone: j['phone'] as String? ?? '',
      avatar: j['avatar'] as String?,
      bio: j['bio'] as String? ?? '',
      city: j['city'] as String? ?? '',
      university: j['university'] as String? ?? '',
      role: j['role'] as String? ?? 'student',
      isVerified: j['is_verified'] as bool? ?? false,
      dateJoined: _date(j['date_joined']),
      ratingAverage: rating?['average'] == null ? null : _num(rating!['average']),
      ratingCount: rating?['count'] as int? ?? 0,
      tripsAsDriver: stats?['trips_as_driver'] as int? ?? 0,
      tripsAsPassenger: stats?['trips_as_passenger'] as int? ?? 0,
      vehicles: (j['vehicles'] as List<dynamic>? ?? [])
          .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MyBooking {
  MyBooking({required this.id, required this.status, required this.reference});
  final int id;
  final String status;
  final String reference;
}

class Trip {
  Trip({
    required this.id,
    required this.driver,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.pricePerSeat,
    this.departurePlace = '',
    this.arrivalPlace = '',
    this.arrivalTime,
    this.vehicle,
    this.seatsTotal = 0,
    this.availableSeats = 0,
    this.luggage = 'medium',
    this.smokingAllowed = false,
    this.petsAllowed = false,
    this.autoAccept = false,
    this.description = '',
    this.status = 'published',
    this.isDriver = false,
    this.myBooking,
  });

  final int id;
  final User driver;
  final Vehicle? vehicle;
  final String departureCity;
  final String departurePlace;
  final String arrivalCity;
  final String arrivalPlace;
  final DateTime departureTime;
  final DateTime? arrivalTime;
  final int seatsTotal;
  final int availableSeats;
  final double pricePerSeat;
  final String luggage;
  final bool smokingAllowed;
  final bool petsAllowed;
  final bool autoAccept;
  final String description;
  final String status;
  final bool isDriver;
  final MyBooking? myBooking;

  String get route => '$departureCity → $arrivalCity';
  bool get isPublished => status == 'published';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get hasStarted => departureTime.isBefore(DateTime.now());
  int get bookedSeats => seatsTotal - availableSeats;

  factory Trip.fromJson(Map<String, dynamic> j) {
    final mb = j['my_booking'] as Map<String, dynamic>?;
    return Trip(
      id: j['id'] as int,
      driver: User.fromJson(j['driver'] as Map<String, dynamic>),
      vehicle: j['vehicle'] == null ? null : Vehicle.fromJson(j['vehicle'] as Map<String, dynamic>),
      departureCity: j['departure_city'] as String? ?? '',
      departurePlace: j['departure_place'] as String? ?? '',
      arrivalCity: j['arrival_city'] as String? ?? '',
      arrivalPlace: j['arrival_place'] as String? ?? '',
      departureTime: _date(j['departure_time'])!,
      arrivalTime: _date(j['arrival_time']),
      seatsTotal: j['seats_total'] as int? ?? 0,
      availableSeats: j['available_seats'] as int? ?? 0,
      pricePerSeat: _num(j['price_per_seat']),
      luggage: j['luggage'] as String? ?? 'medium',
      smokingAllowed: j['smoking_allowed'] as bool? ?? false,
      petsAllowed: j['pets_allowed'] as bool? ?? false,
      autoAccept: j['auto_accept'] as bool? ?? false,
      description: j['description'] as String? ?? '',
      status: j['status'] as String? ?? 'published',
      isDriver: j['is_driver'] as bool? ?? false,
      myBooking: mb == null
          ? null
          : MyBooking(id: mb['id'] as int, status: mb['status'] as String, reference: mb['reference'] as String),
    );
  }
}

class Contact {
  Contact({required this.name, this.phone = '', this.email = ''});
  final String name;
  final String phone;
  final String email;
}

class Booking {
  Booking({
    required this.id,
    required this.reference,
    required this.trip,
    required this.passenger,
    required this.seats,
    required this.status,
    required this.totalPrice,
    this.message = '',
    this.contact,
    this.createdAt,
  });

  final int id;
  final String reference;
  final Trip trip;
  final User passenger;
  final int seats;
  final String message;
  final String status;
  final double totalPrice;
  final Contact? contact;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isActive => isPending || isAccepted;

  factory Booking.fromJson(Map<String, dynamic> j) {
    final c = j['contact'] as Map<String, dynamic>?;
    return Booking(
      id: j['id'] as int,
      reference: j['reference'] as String? ?? '',
      trip: Trip.fromJson(j['trip'] as Map<String, dynamic>),
      passenger: User.fromJson(j['passenger'] as Map<String, dynamic>),
      seats: j['seats'] as int? ?? 1,
      message: j['message'] as String? ?? '',
      status: j['status'] as String? ?? 'pending',
      totalPrice: _num(j['total_price']),
      contact: c == null
          ? null
          : Contact(
              name: c['name'] as String? ?? '',
              phone: c['phone'] as String? ?? '',
              email: c['email'] as String? ?? '',
            ),
      createdAt: _date(j['created_at']),
    );
  }
}

class Review {
  Review({
    required this.id,
    required this.author,
    required this.rating,
    this.comment = '',
    this.tripLabel = '',
    this.createdAt,
  });

  final int id;
  final User author;
  final int rating;
  final String comment;
  final String tripLabel;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'] as int,
        author: User.fromJson(j['author'] as Map<String, dynamic>),
        rating: j['rating'] as int,
        comment: j['comment'] as String? ?? '',
        tripLabel: j['trip_label'] as String? ?? '',
        createdAt: _date(j['created_at']),
      );
}

class SavedRoute {
  SavedRoute({
    required this.id,
    required this.departureCity,
    required this.arrivalCity,
    this.departurePlace = '',
    this.arrivalPlace = '',
  });

  final int id;
  final String departureCity;
  final String departurePlace;
  final String arrivalCity;
  final String arrivalPlace;

  factory SavedRoute.fromJson(Map<String, dynamic> j) => SavedRoute(
        id: j['id'] as int,
        departureCity: j['departure_city'] as String? ?? '',
        departurePlace: j['departure_place'] as String? ?? '',
        arrivalCity: j['arrival_city'] as String? ?? '',
        arrivalPlace: j['arrival_place'] as String? ?? '',
      );
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.isRead,
    this.tripId,
    this.bookingId,
    this.createdAt,
  });

  final int id;
  final String kind;
  final String title;
  final String body;
  final bool isRead;
  final int? tripId;
  final int? bookingId;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as int,
        kind: j['kind'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        isRead: j['is_read'] as bool? ?? false,
        tripId: j['trip'] as int?,
        bookingId: j['booking'] as int?,
        createdAt: _date(j['created_at']),
      );
}

/// Réponse paginée de DRF : {count, next, previous, results}.
class Paged<T> {
  Paged({required this.count, required this.results, this.hasNext = false});
  final int count;
  final List<T> results;
  final bool hasNext;

  factory Paged.fromJson(dynamic json, T Function(Map<String, dynamic>) parse) {
    if (json is List) {
      return Paged(count: json.length, results: json.map((e) => parse(e as Map<String, dynamic>)).toList());
    }
    final map = json as Map<String, dynamic>;
    return Paged(
      count: map['count'] as int? ?? 0,
      hasNext: map['next'] != null,
      results: (map['results'] as List<dynamic>).map((e) => parse(e as Map<String, dynamic>)).toList(),
    );
  }
}
