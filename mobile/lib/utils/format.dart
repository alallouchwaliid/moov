import 'package:intl/intl.dart';

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// « Vendredi 9 octobre 2026 »
String formatDayLong(DateTime d) => _cap(DateFormat('EEEE d MMMM y', 'fr_FR').format(d));

/// « Ven. 9 oct. »
String formatDayShort(DateTime d) => _cap(DateFormat('EEE d MMM', 'fr_FR').format(d));

/// « 08:00 »
String formatTime(DateTime d) => DateFormat('HH:mm').format(d);

/// « mars 2024 »
String formatMonthYear(DateTime d) => DateFormat('MMMM y', 'fr_FR').format(d);

/// « 150 MAD » ou « 72,50 MAD »
String formatPrice(double v) {
  final text = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2).replaceAll('.', ',');
  return '$text MAD';
}

/// « 3 h 30 »
String formatDuration(DateTime start, DateTime end) {
  final minutes = end.difference(start).inMinutes;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}

/// « Vendredi 9 octobre · 08:00–11:30 »
String formatTripWhen(DateTime start, DateTime? end) {
  final day = _cap(DateFormat('EEE d MMM y', 'fr_FR').format(start));
  return end == null ? '$day · ${formatTime(start)}' : '$day · ${formatTime(start)}–${formatTime(end)}';
}

String plural(int n, String singular, [String? pluralForm]) => '$n ${n > 1 ? (pluralForm ?? '${singular}s') : singular}';

const luggageLabels = {
  'none': 'Aucun bagage',
  'small': 'Petit bagage',
  'medium': '1 bagage moyen',
  'large': 'Grand bagage',
};
