import 'package:flutter/material.dart';

import '../../api/moov_api.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../bookings/booking_detail_screen.dart';
import 'manage_trip_screen.dart';

/// « Vos trajets » : réservations (passager) et trajets publiés (conducteur).
class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => MyTripsScreenState();
}

enum _Tab { all, passenger, driver }

class MyTripsScreenState extends State<MyTripsScreen> {
  _Tab _tab = _Tab.all;
  List<Booking> _bookings = [];
  List<Trip> _trips = [];
  Map<int, int> _pendingByTrip = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([MoovApi.myBookings(), MoovApi.myTrips(), MoovApi.receivedPending()]);
      if (!mounted) return;
      final pending = <int, int>{};
      for (final b in results[2] as List<Booking>) {
        pending[b.trip.id] = (pending[b.trip.id] ?? 0) + 1;
      }
      setState(() {
        _bookings = results[0] as List<Booking>;
        _trips = results[1] as List<Trip>;
        _pendingByTrip = pending;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _bookingUpcoming(Booking b) => b.isActive && b.trip.isPublished;
  bool _tripUpcoming(Trip t) => t.isPublished;

  @override
  Widget build(BuildContext context) {
    final showPassenger = _tab != _Tab.driver;
    final showDriver = _tab != _Tab.passenger;

    // Les demandes refusées/annulées sans suite restent visibles dans l'historique.
    final upcoming = <(DateTime, Widget)>[
      if (showPassenger)
        for (final b in _bookings.where(_bookingUpcoming)) (b.trip.departureTime, _bookingCard(b)),
      if (showDriver)
        for (final t in _trips.where(_tripUpcoming)) (t.departureTime, _tripCard(t)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final past = <(DateTime, Widget)>[
      if (showPassenger)
        for (final b in _bookings.where((b) => !_bookingUpcoming(b))) (b.trip.departureTime, _bookingCard(b)),
      if (showDriver)
        for (final t in _trips.where((t) => !_tripUpcoming(t))) (t.departureTime, _tripCard(t)),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text('Vos trajets', style: Theme.of(context).textTheme.headlineSmall),
            Text('Réservations et historique', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            SegmentedButton<_Tab>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _Tab.all, label: Text('Tous')),
                ButtonSegment(value: _Tab.passenger, label: Text('Passager')),
                ButtonSegment(value: _Tab.driver, label: Text('Conducteur')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
            if (_loading)
              const Padding(padding: EdgeInsets.only(top: 80), child: Loading())
            else if (_error != null)
              ErrorView(message: _error!, onRetry: reload)
            else if (upcoming.isEmpty && past.isEmpty)
              const EmptyState(
                icon: Icons.event_note_outlined,
                title: 'Aucun trajet pour le moment',
                message: 'Réservez une place depuis « Recherche » ou publiez votre propre trajet.',
              )
            else ...[
              const SectionTitle('En cours & à venir'),
              if (upcoming.isEmpty)
                Text('Rien de prévu.', style: Theme.of(context).textTheme.bodySmall)
              else
                ...upcoming.map((e) => e.$2),
              if (past.isNotEmpty) ...[
                const SectionTitle('Historique'),
                ...past.map((e) => e.$2),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _bookingCard(Booking b) {
    final t = b.trip;
    final status = t.isCancelled ? 'cancelled' : (t.isCompleted && b.isAccepted ? 'completed' : b.status);
    return MoovCard(
      soft: b.isAccepted && t.isPublished,
      onTap: () async {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id)));
        reload();
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.airline_seat_recline_normal, size: 18, color: MoovColors.blue),
          const SizedBox(width: 6),
          Expanded(child: Text('Passager · ${b.reference}', style: Theme.of(context).textTheme.bodySmall)),
          statusPill(status),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text(t.route, style: Theme.of(context).textTheme.titleMedium)),
          Text(formatPrice(b.totalPrice), style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Text('${formatTripWhen(t.departureTime, t.arrivalTime)} · ${plural(b.seats, 'place')}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        Row(children: [
          UserAvatar(t.driver, size: 28),
          const SizedBox(width: 8),
          Expanded(child: Text(t.driver.fullName, style: const TextStyle(fontSize: 14))),
          if (t.isCompleted && b.isAccepted)
            const Text('Laisser un avis →', style: TextStyle(color: MoovColors.blue, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _tripCard(Trip t) {
    final pending = _pendingByTrip[t.id] ?? 0;
    return MoovCard(
      highlight: pending > 0,
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ManageTripScreen(tripId: t.id)));
        reload();
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.directions_car_outlined, size: 18, color: MoovColors.blue),
          const SizedBox(width: 6),
          Expanded(child: Text('Vous conduisez', style: Theme.of(context).textTheme.bodySmall)),
          statusPill(t.status),
        ]),
        const SizedBox(height: 10),
        Text(t.route, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(formatTripWhen(t.departureTime, t.arrivalTime), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text('${t.bookedSeats}/${t.seatsTotal} places réservées · ${formatPrice(t.pricePerSeat)}/pl.',
                style: const TextStyle(fontSize: 14)),
          ),
          if (pending > 0)
            Pill(plural(pending, 'demande'), icon: Icons.mark_email_unread_outlined,
                color: MoovColors.orange, background: MoovColors.orangeSoft)
          else
            const Icon(Icons.chevron_right, color: MoovColors.muted),
        ]),
      ]),
    );
  }
}
