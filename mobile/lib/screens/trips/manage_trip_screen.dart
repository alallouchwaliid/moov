import 'package:flutter/material.dart';

import '../../api/moov_api.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../bookings/booking_detail_screen.dart';
import '../reviews/review_form_screen.dart';

/// Gestion d'un trajet par son conducteur : demandes, annulation, fin du trajet, avis.
class ManageTripScreen extends StatefulWidget {
  const ManageTripScreen({super.key, required this.tripId});
  final int tripId;

  @override
  State<ManageTripScreen> createState() => _ManageTripScreenState();
}

class _ManageTripScreenState extends State<ManageTripScreen> {
  Trip? _trip;
  List<Booking> _bookings = [];
  String? _error;
  final Set<int> _busy = {};
  bool _tripBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([MoovApi.trip(widget.tripId), MoovApi.tripBookings(widget.tripId)]);
      if (!mounted) return;
      setState(() {
        _trip = results[0] as Trip;
        _bookings = results[1] as List<Booking>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _bookingAction(Booking b, String action) async {
    setState(() => _busy.add(b.id));
    try {
      await MoovApi.bookingAction(b.id, action);
      if (mounted) showSnack(context, action == 'accept' ? 'Demande acceptée.' : 'Demande refusée.');
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(b.id));
    }
  }

  Future<void> _tripAction(String action) async {
    final cancel = action == 'cancel';
    final ok = await confirmDialog(
      context,
      title: cancel ? 'Annuler ce trajet ?' : 'Trajet effectué ?',
      message: cancel
          ? 'Toutes les réservations seront annulées et les passagers prévenus.'
          : 'Les demandes en attente seront refusées et chacun pourra laisser un avis.',
      confirm: cancel ? 'Annuler le trajet' : 'Oui, terminé',
      danger: cancel,
    );
    if (!ok) return;
    setState(() => _tripBusy = true);
    try {
      cancel ? await MoovApi.cancelTrip(widget.tripId) : await MoovApi.completeTrip(widget.tripId);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _tripBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _trip;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon trajet')),
      body: t == null
          ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const Loading())
          : RefreshIndicator(onRefresh: _load, child: _content(t)),
    );
  }

  Widget _content(Trip t) {
    final pending = _bookings.where((b) => b.isPending).toList();
    final accepted = _bookings.where((b) => b.isAccepted).toList();
    final others = _bookings.where((b) => !b.isActive).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      children: [
        MoovCard(
          soft: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(formatDayLong(t.departureTime), style: const TextStyle(fontWeight: FontWeight.w700))),
              statusPill(t.status),
            ]),
            const SizedBox(height: 16),
            TripTimeline(trip: t),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Text('${t.bookedSeats}/${t.seatsTotal} places réservées')),
              Text('${formatPrice(t.pricePerSeat)}/place', style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
        if (pending.isNotEmpty) ...[
          SectionTitle('Demandes en attente (${pending.length})'),
          for (final b in pending) _requestCard(b, t),
        ],
        SectionTitle('Passagers confirmés (${accepted.length})'),
        if (accepted.isEmpty)
          Text('Aucun passager pour le moment.', style: Theme.of(context).textTheme.bodySmall)
        else
          for (final b in accepted) _passengerCard(b, t),
        if (others.isNotEmpty) ...[
          const SectionTitle('Refusées ou annulées'),
          for (final b in others)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(b.passenger, size: 36),
              title: Text(b.passenger.fullName),
              subtitle: Text(plural(b.seats, 'place')),
              trailing: statusPill(b.status),
            ),
        ],
        const SizedBox(height: 24),
        if (t.isPublished && t.hasStarted) ...[
          MoovButton(
            label: 'Marquer le trajet comme effectué',
            icon: Icons.flag_outlined,
            loading: _tripBusy,
            onPressed: () => _tripAction('complete'),
          ),
          const SizedBox(height: 12),
        ],
        if (t.isPublished)
          MoovButton(
            label: 'Annuler le trajet',
            danger: true,
            loading: _tripBusy,
            onPressed: () => _tripAction('cancel'),
          ),
        if (t.isPublished && !t.hasStarted)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Après le départ, revenez ici pour marquer le trajet comme effectué et ouvrir les avis.',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }

  Widget _requestCard(Booking b, Trip t) {
    final busy = _busy.contains(b.id);
    return MoovCard(
      highlight: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          UserAvatar(b.passenger),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.passenger.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(ratingText(b.passenger), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          Text(plural(b.seats, 'place'), style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        if (b.message.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('« ${b.message} »', style: const TextStyle(color: MoovColors.muted)),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : () => _bookingAction(b, 'refuse'),
              style: OutlinedButton.styleFrom(foregroundColor: MoovColors.red, minimumSize: const Size(0, 44)),
              child: const Text('Refuser'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: busy || b.seats > t.availableSeats ? null : () => _bookingAction(b, 'accept'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              child: busy
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Accepter'),
            ),
          ),
        ]),
        if (b.seats > t.availableSeats)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Plus assez de places pour accepter cette demande.', style: Theme.of(context).textTheme.bodySmall),
          ),
      ]),
    );
  }

  Widget _passengerCard(Booking b, Trip t) {
    return MoovCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          UserAvatar(b.passenger),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.passenger.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('${plural(b.seats, 'place')} · ${b.reference}', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          if (t.isCompleted)
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ReviewFormScreen(tripId: t.id, tripLabel: t.route, target: b.passenger),
              )),
              child: const Text('Évaluer'),
            ),
        ]),
        if (b.contact != null && t.isPublished) ...[
          const SizedBox(height: 10),
          ContactCard(contact: b.contact!),
        ],
      ]),
    );
  }
}
