import 'package:flutter_test/flutter_test.dart';
import 'package:moov/utils/format.dart';

void main() {
  test('formatPrice affiche les dirhams sans décimales inutiles', () {
    expect(formatPrice(150), '150 MAD');
    expect(formatPrice(72.5), '72,50 MAD');
  });

  test('formatDuration', () {
    final start = DateTime(2026, 10, 9, 8);
    expect(formatDuration(start, DateTime(2026, 10, 9, 11, 30)), '3 h 30');
    expect(formatDuration(start, DateTime(2026, 10, 9, 8, 45)), '45 min');
  });

  test('plural', () {
    expect(plural(1, 'place'), '1 place');
    expect(plural(3, 'place'), '3 places');
  });
}
