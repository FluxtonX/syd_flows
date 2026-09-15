import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/domain/bounded_cycle_query_builder.dart';

void main() {
  group('Phase 14 — Firestore Performance & Data Bounding', () {
    final DateTime today = DateTime(2026, 9, 15);

    test('Computes correct bounded start date for 180 days lookback', () {
      final start = BoundedCycleQueryBuilder.computeBoundedStartDate(today: today);
      final expected = DateTime(2026, 3, 19);

      expect(start, equals(expected));
    });

    test('Generates precise YYYY-MM-DD date keys within bounded window', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 5);

      final keys = BoundedCycleQueryBuilder.generateBoundedDateKeys(
        startDate: start,
        endDate: end,
      );

      expect(keys.length, equals(5));
      expect(keys.first, equals('2026-09-01'));
      expect(keys.last, equals('2026-09-05'));
    });
  });
}
