import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../main_shell.dart';

/// « Votre trajet est publié ! »
class PublishSuccessScreen extends StatelessWidget {
  const PublishSuccessScreen({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
          children: [
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(color: MoovColors.greenSoft, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 48, color: MoovColors.green),
              ),
            ),
            const SizedBox(height: 24),
            Text('Votre trajet est publié !',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '${trip.driver.firstName}, les passagers peuvent maintenant trouver votre trajet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: MoovColors.muted, height: 1.5),
            ),
            const SizedBox(height: 28),
            MoovCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(trip.route, style: Theme.of(context).textTheme.titleMedium)),
                  statusPill(trip.status),
                ]),
                const SizedBox(height: 6),
                Text(formatTripWhen(trip.departureTime, trip.arrivalTime), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Text(plural(trip.seatsTotal, 'place'))),
                  Text('${formatPrice(trip.pricePerSeat)} par place', style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
            const InfoCallout(
              icon: Icons.notifications_active_outlined,
              text: 'Vous serez notifié à chaque demande de réservation. Acceptez-les depuis l’onglet « Trajets ».',
            ),
            const SizedBox(height: 24),
            MoovButton(
              label: 'Voir mes trajets',
              icon: Icons.arrow_forward,
              onPressed: () {
                Navigator.of(context).pop(false);
                MainShell.switchTab(2);
              },
            ),
            const SizedBox(height: 12),
            MoovButton(
              label: 'Publier un autre trajet',
              secondary: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}
