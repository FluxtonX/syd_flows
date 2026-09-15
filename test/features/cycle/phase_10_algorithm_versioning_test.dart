import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';

void main() {
  group('Phase 10 — Algorithm Versioning', () {
    final DateTime baseDate = DateTime(2026, 9, 1);
    final CycleSettings defaultSettings = CycleSettings(
      lastPeriodStart: baseDate,
      cycleLength: 28,
      periodLength: 5,
    );

    test('CycleStatus includes explicit algorithmVersion ("2.0")', () {
      final status = CycleCalculator.compute(
        settings: defaultSettings,
        today: baseDate.add(const Duration(days: 5)),
      );

      expect(status.algorithmVersion, equals('2.0'));
      expect(status.predictions.algorithmVersion, equals('2.0'));
    });

    test('Historical predictions preserve algorithm version tag', () {
      final legacyPredictions = CyclePredictions(
        nextPeriodStart: DateTime(2026, 9, 29),
        fertileWindowStart: DateTime(2026, 9, 12),
        fertileWindowEnd: DateTime(2026, 9, 18),
        ovulationDate: DateTime(2026, 9, 15),
        algorithmVersion: '1.0',
      );

      expect(legacyPredictions.algorithmVersion, equals('1.0'));
    });
  });
}
