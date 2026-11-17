import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Bouton principal arrondi (hauteur 52, comme la maquette).
class MoovButton extends StatelessWidget {
  const MoovButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.secondary = false,
    this.danger = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool secondary;
  final bool danger;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bg = danger ? MoovColors.red : (secondary ? MoovColors.soft : MoovColors.blue);
    final fg = secondary ? MoovColors.blue : Colors.white;
    final child = loading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              if (icon != null) ...[const SizedBox(width: 10), Icon(icon, size: 20)],
            ],
          );
    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: loading ? bg : const Color(0xFFC9D2E5),
        disabledForegroundColor: Colors.white,
      ),
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Carte blanche à bords arrondis (ou bleu clair si [soft]).
class MoovCard extends StatelessWidget {
  const MoovCard({super.key, required this.child, this.soft = false, this.onTap, this.padding, this.highlight = false});

  final Widget child;
  final bool soft;
  final bool highlight;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: soft ? MoovColors.soft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: soft
              ? BorderSide.none
              : BorderSide(color: highlight ? MoovColors.blue : MoovColors.line, width: highlight ? 1.6 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding ?? const EdgeInsets.all(18), child: child),
        ),
      ),
    );
  }
}

/// Petite étiquette colorée (« ✓ Publié », « 2 places »…).
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.icon, this.color = MoovColors.blue, this.background = MoovColors.soft});

  const Pill.green(this.text, {super.key, this.icon})
      : color = MoovColors.green,
        background = MoovColors.greenSoft;

  final String text;
  final IconData? icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: color), const SizedBox(width: 5)],
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Statut d'une réservation ou d'un trajet, texte + couleur.
Widget statusPill(String status) {
  switch (status) {
    case 'pending':
      return const Pill('En attente', icon: Icons.schedule, color: MoovColors.orange, background: MoovColors.orangeSoft);
    case 'accepted':
      return const Pill.green('Confirmée', icon: Icons.check_circle_outline);
    case 'refused':
      return const Pill('Refusée', icon: Icons.block, color: MoovColors.red, background: MoovColors.redSoft);
    case 'cancelled':
      return const Pill('Annulé', icon: Icons.close, color: MoovColors.red, background: MoovColors.redSoft);
    case 'published':
      return const Pill.green('Publié', icon: Icons.check);
    case 'completed':
      return const Pill('Terminé', icon: Icons.flag_outlined);
    default:
      return Pill(status);
  }
}

/// Photo de profil, ou initiales si pas de photo.
class UserAvatar extends StatelessWidget {
  const UserAvatar(this.user, {super.key, this.size = 46});

  final User? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = user?.avatar;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFD9E5F3),
      foregroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
      child: Text(
        user?.initials.isNotEmpty == true ? user!.initials : '?',
        style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w700, color: MoovColors.blue),
      ),
    );
  }
}

/// « ★ 4,9 · 128 avis »
String ratingText(User u) {
  if (u.ratingAverage == null) return 'Nouveau membre';
  final avg = u.ratingAverage!.toStringAsFixed(1).replaceAll('.', ',');
  return '★ $avg · ${plural(u.ratingCount, 'avis', 'avis')}';
}

class Stars extends StatelessWidget {
  const Stars(this.rating, {super.key, this.size = 16});
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: MoovColors.blue),
      ),
    );
  }
}

/// Titre de section avec action optionnelle à droite.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

/// Compteur « − valeur + » (prix, places).
class Counter extends StatelessWidget {
  const Counter({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 999, this.step = 1, this.format});

  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, int? next) => IconButton.filledTonal(
          onPressed: next == null ? null : () => onChanged(next),
          icon: Icon(icon),
          style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: MoovColors.blue),
        );
    return Row(
      children: [
        btn(Icons.remove, value - step >= min ? value - step : null),
        Expanded(
          child: Text(
            format?.call(value) ?? '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        btn(Icons.add, value + step <= max ? value + step : null),
      ],
    );
  }
}

/// Écran vide / erreur avec action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: MoovColors.soft, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: MoovColors.blue),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center, style: const TextStyle(color: MoovColors.muted, fontSize: 15, height: 1.45)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 22),
              MoovButton(label: actionLabel!, onPressed: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Oups…',
        message: message,
        actionLabel: 'Réessayer',
        onAction: onRetry,
      );
}

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

/// Encadré d'information (icône + texte), style « callout » de la maquette.
class InfoCallout extends StatelessWidget {
  const InfoCallout({super.key, required this.text, this.title, this.icon = Icons.shield_outlined});
  final String? title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: MoovColors.soft, borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MoovColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!, style: const TextStyle(fontWeight: FontWeight.w700, color: MoovColors.green)),
                if (title != null) const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: MoovColors.muted, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Départ → arrivée avec heures, façon frise verticale.
class TripTimeline extends StatelessWidget {
  const TripTimeline({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    Widget stop(String time, String city, String place, bool start) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 52, child: Text(time, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(start ? Icons.radio_button_checked : Icons.location_on, size: 18, color: MoovColors.blue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(city, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  if (place.isNotEmpty) Text(place, style: const TextStyle(color: MoovColors.muted, fontSize: 14)),
                ],
              ),
            ),
          ],
        );
    return Column(
      children: [
        stop(formatTime(trip.departureTime), trip.departureCity, trip.departurePlace, true),
        Row(children: [
          const SizedBox(width: 60),
          Container(width: 2, height: 30, color: MoovColors.line),
          const SizedBox(width: 12),
          if (trip.arrivalTime != null)
            Text(formatDuration(trip.departureTime, trip.arrivalTime!),
                style: const TextStyle(color: MoovColors.muted, fontSize: 13)),
        ]),
        stop(trip.arrivalTime != null ? formatTime(trip.arrivalTime!) : '--:--', trip.arrivalCity, trip.arrivalPlace, false),
      ],
    );
  }
}

/// Carte résultat de recherche (conducteur, prix, horaires, places).
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, this.onTap, this.highlight = false});
  final Trip trip;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final t = trip;
    return MoovCard(
      onTap: onTap,
      highlight: highlight,
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(t.driver, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.driver.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      '${ratingText(t.driver)}${t.driver.isVerified ? ' · Identité vérifiée' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatPrice(t.pricePerSeat),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MoovColors.blue)),
                  Text('par place', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(formatTime(t.departureTime), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  Text(t.departurePlace.isNotEmpty ? t.departurePlace : t.departureCity,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              Column(children: [
                Text(t.arrivalTime != null ? formatDuration(t.departureTime, t.arrivalTime!) : '',
                    style: Theme.of(context).textTheme.bodySmall),
                const Icon(Icons.arrow_forward, size: 18, color: MoovColors.muted),
              ]),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(t.arrivalTime != null ? formatTime(t.arrivalTime!) : '--:--',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  Text(t.arrivalPlace.isNotEmpty ? t.arrivalPlace : t.arrivalCity,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatDayShort(t.departureTime)}${t.vehicle != null ? ' · ${t.vehicle!.label}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Pill(plural(t.availableSeats, 'place'), icon: Icons.people_outline),
            ],
          ),
        ],
      ),
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? MoovColors.red : MoovColors.navy,
    ));
}

Future<bool> confirmDialog(BuildContext context,
    {required String title, required String message, String confirm = 'Confirmer', bool danger = false}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Retour')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: danger ? MoovColors.red : MoovColors.blue, minimumSize: const Size(80, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}
