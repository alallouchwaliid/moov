import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../main_shell.dart';

/// Après l'envoi d'une demande : « Votre place est réservée » ou « Demande envoyée ».
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final accepted = booking.isAccepted;
    final t = booking.trip;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                    color: accepted ? MoovColors.greenSoft : MoovColors.soft, shape: BoxShape.circle),
                child: Icon(accepted ? Icons.check_rounded : Icons.send_rounded,
                    size: 46, color: accepted ? MoovColors.green : MoovColors.blue),
              ),
            ),
            const SizedBox(height: 24),
            Text(accepted ? 'Votre place est réservée.' : 'Demande envoyée !',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              accepted
                  ? 'Retrouvez les coordonnées de ${t.driver.firstName} dans « Trajets » pour organiser le départ.'
                  : '${t.driver.firstName} doit accepter votre demande. Vous serez notifié(e) de sa réponse.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: MoovColors.muted, height: 1.5),
            ),
            const SizedBox(height: 28),
            MoovCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Réservation ${booking.reference}', style: Theme.of(context).textTheme.bodySmall)),
                  statusPill(booking.status),
                ]),
                const SizedBox(height: 14),
                Text(t.route, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(formatTripWhen(t.departureTime, t.arrivalTime), style: Theme.of(context).textTheme.bodySmall),
                const Divider(height: 28),
                Row(children: [
                  UserAvatar(t.driver, size: 36),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.driver.fullName)),
                  Text('${plural(booking.seats, 'place')} · ${formatPrice(booking.totalPrice)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
            const SizedBox(height: 8),
            MoovButton(
              label: 'Voir mes trajets',
              icon: Icons.arrow_forward,
              onPressed: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
                MainShell.switchTab(2);
              },
            ),
            const SizedBox(height: 12),
            MoovButton(
              label: "Retour à l'accueil",
              secondary: true,
              onPressed: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
                MainShell.switchTab(0);
              },
            ),
          ],
        ),
      ),
    );
  }
}
