import 'package:flutter/material.dart';

import '../api/moov_api.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'bookings/booking_detail_screen.dart';
import 'trips/manage_trip_screen.dart';

/// Notifications in-app (demandes, acceptations, annulations, avis).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification>? _items;
  String? _error;

  static const _icons = {
    'booking_request': Icons.mark_email_unread_outlined,
    'booking_accepted': Icons.check_circle_outline,
    'booking_refused': Icons.block,
    'booking_cancelled': Icons.event_busy_outlined,
    'trip_cancelled': Icons.cancel_outlined,
    'review_request': Icons.star_outline,
    'review_received': Icons.star,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await MoovApi.notifications();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      MoovApi.markRead(n.id).then((_) => _load()).catchError((_) {});
    }
    Widget? target;
    if (n.kind == 'booking_request' || n.kind == 'booking_cancelled') {
      if (n.tripId != null) target = ManageTripScreen(tripId: n.tripId!);
    } else if (n.bookingId != null && n.kind != 'review_received') {
      target = BookingDetailScreen(bookingId: n.bookingId!);
    } else if (n.kind == 'review_request' && n.tripId != null) {
      target = ManageTripScreen(tripId: n.tripId!);
    }
    if (target != null && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => target!));
    }
  }

  Future<void> _readAll() async {
    try {
      await MoovApi.markAllRead();
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (items != null && items.any((n) => !n.isRead))
            TextButton(onPressed: _readAll, child: const Text('Tout lire')),
        ],
      ),
      body: items == null
          ? (_error != null ? ErrorView(message: _error!, onRetry: _load) : const Loading())
          : items.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none,
                  title: 'Aucune notification',
                  message: 'Vous serez prévenu ici des demandes de réservation et des réponses.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final n = items[i];
                      return ListTile(
                        tileColor: n.isRead ? null : MoovColors.soft,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: n.isRead ? MoovColors.line : Colors.white,
                          child: Icon(_icons[n.kind] ?? Icons.notifications_none, color: MoovColors.blue),
                        ),
                        title: Text(n.title,
                            style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700)),
                        subtitle: Text(
                          '${n.body}${n.createdAt != null ? '\n${formatDayShort(n.createdAt!)} · ${formatTime(n.createdAt!)}' : ''}',
                        ),
                        isThreeLine: n.createdAt != null,
                        onTap: () => _open(n),
                      );
                    },
                  ),
                ),
    );
  }
}
