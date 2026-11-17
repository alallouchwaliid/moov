import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/moov_api.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../reviews/review_form_screen.dart';
import '../trip/trip_detail_screen.dart';

/// Réservation côté passager : statut, contact du conducteur, annulation, avis.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final int bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _booking;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final b = await MoovApi.booking(widget.bookingId);
      if (mounted) setState(() => _booking = b);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _cancel() async {
    final ok = await confirmDialog(context,
        title: 'Annuler la réservation ?',
        message: 'Le conducteur sera prévenu et votre place sera libérée.',
        confirm: 'Annuler la réservation',
        danger: true);
    if (!ok) return;
    setState(() => _busy = true);
    try {
      final b = await MoovApi.bookingAction(widget.bookingId, 'cancel');
      if (!mounted) return;
      setState(() => _booking = b);
      showSnack(context, 'Réservation annulée.');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    return Scaffold(
      appBar: AppBar(title: Text(b == null ? 'Réservation' : 'Réservation ${b.reference}')),
      body: b == null
          ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const Loading())
          : RefreshIndicator(onRefresh: _load, child: _content(b)),
    );
  }

  Widget _content(Booking b) {
    final t = b.trip;
    final muted = Theme.of(context).textTheme.bodySmall;
    final canCancel = b.isActive && t.isPublished && !t.hasStarted;
    final canReview = b.isAccepted && t.isCompleted;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      children: [
        MoovCard(
          soft: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(t.route, style: Theme.of(context).textTheme.titleMedium)),
              statusPill(t.isCancelled ? 'cancelled' : b.status),
            ]),
            const SizedBox(height: 6),
            Text(formatTripWhen(t.departureTime, t.arrivalTime), style: muted),
            const SizedBox(height: 16),
            TripTimeline(trip: t),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: t.id))),
                child: const Text('Voir le trajet →'),
              ),
            ),
          ]),
        ),
        Row(children: [
          Expanded(child: Text(plural(b.seats, 'place réservée', 'places réservées'))),
          Text(formatPrice(b.totalPrice), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        ]),
        const SizedBox(height: 6),
        Text('Paiement en espèces au conducteur.', style: muted),
        const Divider(),
        Text('Conducteur', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(children: [
          UserAvatar(t.driver),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.driver.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(ratingText(t.driver), style: muted),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        if (b.contact != null)
          ContactCard(contact: b.contact!)
        else if (b.isPending)
          const InfoCallout(
            icon: Icons.schedule,
            text: 'Les coordonnées du conducteur seront visibles dès que votre demande sera acceptée.',
          ),
        if (b.message.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Votre message', style: muted),
          Text('« ${b.message} »'),
        ],
        const SizedBox(height: 24),
        if (canReview)
          MoovButton(
            label: 'Laisser un avis',
            icon: Icons.star_outline,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ReviewFormScreen(tripId: t.id, tripLabel: t.route, target: t.driver),
            )),
          ),
        if (canCancel)
          MoovButton(label: 'Annuler la réservation', danger: true, loading: _busy, onPressed: _cancel),
      ],
    );
  }
}

/// Coordonnées de l'autre partie (pas de messagerie en V1).
class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String value, String label) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: MoovColors.blue),
          title: Text(value),
          subtitle: Text(label),
          trailing: IconButton(
            tooltip: 'Copier',
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              showSnack(context, '$label copié.');
            },
          ),
        );

    return MoovCard(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Contacter ${contact.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
        if (contact.phone.isNotEmpty) row(Icons.phone_outlined, contact.phone, 'Téléphone'),
        if (contact.email.isNotEmpty) row(Icons.mail_outline, contact.email, 'Email'),
      ]),
    );
  }
}
