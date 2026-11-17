import 'package:flutter/material.dart';

import '../../api/moov_api.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../bookings/booking_confirmation_screen.dart';
import '../bookings/booking_detail_screen.dart';
import '../main_shell.dart';
import '../profile/reviews_screen.dart';
import '../trips/manage_trip_screen.dart';

/// Détail d'un trajet : itinéraire, conducteur, avis, réservation.
class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, required this.tripId, this.passengers = 1});
  final int tripId;
  final int passengers;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Trip? _trip;
  List<Review> _reviews = [];
  int _reviewCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final trip = await MoovApi.trip(widget.tripId);
      final reviews = await MoovApi.reviewsFor(trip.driver.id);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _reviews = reviews.results.take(3).toList();
        _reviewCount = reviews.count;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _book() async {
    if (!await requireLogin(context)) return;
    if (!mounted) return;
    await _load(); // statut à jour (ex. si c'est son propre trajet)
    final trip = _trip;
    if (trip == null || !mounted) return;
    if (trip.isDriver || trip.myBooking != null || trip.availableSeats < 1) return;

    final booking = await showModalBottomSheet<Booking>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BookingSheet(trip: trip, initialSeats: widget.passengers.clamp(1, trip.availableSeats)),
    );
    if (booking != null && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingConfirmationScreen(booking: booking)));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du trajet')),
      body: trip == null
          ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const Loading())
          : RefreshIndicator(onRefresh: _load, child: _content(trip)),
      bottomNavigationBar: trip == null ? null : _bottomBar(trip),
    );
  }

  Widget _content(Trip t) {
    final muted = Theme.of(context).textTheme.bodySmall;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      children: [
        if (!t.isPublished) ...[
          Align(alignment: Alignment.centerLeft, child: statusPill(t.status)),
          const SizedBox(height: 14),
        ],
        Row(children: [
          Expanded(child: Text(formatDayLong(t.departureTime), style: const TextStyle(fontWeight: FontWeight.w700))),
          if (t.arrivalTime != null) Text(formatDuration(t.departureTime, t.arrivalTime!), style: muted),
        ]),
        const SizedBox(height: 18),
        TripTimeline(trip: t),
        const Divider(),
        InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReviewsScreen(user: t.driver))),
          child: Row(children: [
            UserAvatar(t.driver, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.driver.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 3),
                Text(ratingText(t.driver), style: muted),
              ]),
            ),
            const Icon(Icons.chevron_right, color: MoovColors.muted),
          ]),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (t.driver.isVerified) const Pill.green('Identité vérifiée', icon: Icons.verified_user_outlined),
          if (t.vehicle != null) Text(t.vehicle!.label, style: muted),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 18, runSpacing: 8, children: [
          _feature(Icons.people_outline, '${plural(t.availableSeats, 'place')} sur ${t.seatsTotal}'),
          _feature(Icons.luggage_outlined, luggageLabels[t.luggage] ?? t.luggage),
          _feature(t.smokingAllowed ? Icons.smoking_rooms : Icons.smoke_free, t.smokingAllowed ? 'Fumeur' : 'Non fumeur'),
          if (t.petsAllowed) _feature(Icons.pets, 'Animaux acceptés'),
          if (t.autoAccept) _feature(Icons.bolt, 'Réservation instantanée'),
        ]),
        if (t.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          MoovCard(soft: true, child: Text(t.description)),
        ],
        const Divider(),
        Text('Avis & commentaires', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (_reviews.isEmpty)
          Text("${t.driver.firstName} n'a pas encore reçu d'avis.", style: muted)
        else
          for (final r in _reviews) ReviewTile(review: r),
        if (_reviewCount > _reviews.length)
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReviewsScreen(user: t.driver))),
            child: Text('Voir les $_reviewCount avis →'),
          ),
      ],
    );
  }

  Widget _feature(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 19, color: MoovColors.muted),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: MoovColors.muted, fontSize: 14)),
      ]);

  Widget _bottomBar(Trip t) {
    Widget bar(Widget left, Widget right) => SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: MoovColors.line)),
            ),
            child: Row(children: [Expanded(child: left), const SizedBox(width: 12), right]),
          ),
        );

    if (t.isDriver) {
      return bar(
        const Text('Vous conduisez ce trajet', style: TextStyle(fontWeight: FontWeight.w600)),
        MoovButton(
          label: 'Gérer',
          expand: false,
          icon: Icons.arrow_forward,
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ManageTripScreen(tripId: t.id)));
            _load();
          },
        ),
      );
    }

    if (t.myBooking != null) {
      return bar(
        Row(children: [statusPill(t.myBooking!.status)]),
        MoovButton(
          label: 'Ma réservation',
          expand: false,
          onPressed: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: t.myBooking!.id)));
            _load();
          },
        ),
      );
    }

    final seats = widget.passengers.clamp(1, t.availableSeats < 1 ? 1 : t.availableSeats);
    final canBook = t.isPublished && !t.hasStarted && t.availableSeats > 0;
    return bar(
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total · ${plural(seats, 'passager')}', style: Theme.of(context).textTheme.bodySmall),
        Text(formatPrice(t.pricePerSeat * seats),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: MoovColors.blue)),
      ]),
      MoovButton(
        label: !t.isPublished || t.hasStarted ? 'Indisponible' : (t.availableSeats > 0 ? 'Réserver' : 'Complet'),
        icon: canBook ? Icons.arrow_forward : null,
        expand: false,
        onPressed: canBook ? _book : null,
      ),
    );
  }
}

/// Un avis : auteur, étoiles, commentaire.
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review, this.onReport});
  final Review review;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          UserAvatar(review.author, size: 32),
          const SizedBox(width: 10),
          Expanded(child: Text(review.author.fullName, style: const TextStyle(fontWeight: FontWeight.w700))),
          Stars(review.rating),
          if (onReport != null)
            IconButton(
              tooltip: 'Signaler',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.flag_outlined, size: 18, color: MoovColors.muted),
              onPressed: onReport,
            ),
        ]),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(review.comment, style: const TextStyle(color: MoovColors.muted)),
        ],
        if (review.tripLabel.isNotEmpty || review.createdAt != null) ...[
          const SizedBox(height: 4),
          Text(
            [review.tripLabel, if (review.createdAt != null) formatMonthYear(review.createdAt!)].join(' · '),
            style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A8)),
          ),
        ],
      ]),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.trip, required this.initialSeats});
  final Trip trip;
  final int initialSeats;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late int _seats = widget.initialSeats;
  final _message = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final booking = await MoovApi.book(widget.trip.id, _seats, _message.text.trim());
      if (mounted) Navigator.of(context).pop(booking);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Réserver', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${t.route} · ${formatTripWhen(t.departureTime, t.arrivalTime)}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          const Text('Nombre de places', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          MoovCard(
            soft: true,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Counter(
              value: _seats,
              min: 1,
              max: t.availableSeats,
              onChanged: (v) => setState(() => _seats = v),
              format: (v) => plural(v, 'place'),
            ),
          ),
          TextField(
            controller: _message,
            maxLength: 300,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Message au conducteur (facultatif)',
              hintText: 'Ex. : je serai devant la gare avec un sac.',
            ),
          ),
          if (_error != null) Text(_error!, style: const TextStyle(color: MoovColors.red)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total', style: Theme.of(context).textTheme.bodySmall),
                Text(formatPrice(t.pricePerSeat * _seats),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: MoovColors.blue)),
              ]),
            ),
            MoovButton(
              label: t.autoAccept ? 'Réserver' : 'Envoyer la demande',
              expand: false,
              loading: _loading,
              onPressed: _confirm,
            ),
          ]),
          const SizedBox(height: 10),
          const Text('Paiement en espèces directement au conducteur le jour du trajet.',
              style: TextStyle(fontSize: 12, color: MoovColors.muted)),
        ],
      ),
    );
  }
}
