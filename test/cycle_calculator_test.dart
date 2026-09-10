import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';

void main() {
  group('CycleCalculator Phase Bounds Tests', () {
    test('Standard 28-day cycle with 5-day period has valid Follicular phase span', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 1),
        cycleLength: 28,
        periodLength: 5,
      );

      final status = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 8), // Day 8 -> Follicular
      );

      expect(status.cycleDay, equals(8));
      expect(status.phase, equals(CyclePhase.follicular));
    });

    test('Long period (8 days) does NOT collapse Follicular phase to 1 day', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 1),
        cycleLength: 28,
        periodLength: 8,
      );

      // Day 9, 10, 11, 12 should be Follicular phase
      final statusDay10 = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 10), // Day 10
      );

      expect(statusDay10.phase, equals(CyclePhase.follicular));
    });

    test('CycleSettings.fromSetupFlowMap parses various timestamp types safely', () {
      final mapWithString = {
        'lastPeriodStart': '2026-09-01T00:00:00.000Z',
        'cycleLength': 28,
        'periodLength': 5,
      };

      final parsed = CycleSettings.fromSetupFlowMap(mapWithString);
      expect(parsed.cycleLength, equals(28));
      expect(parsed.periodLength, equals(5));
      expect(parsed.lastPeriodStart.year, equals(2026));
    });
  });
}
