import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';

void main() {
  group('PERIOD ALGORITHM RULES - BUG FIX SUITE', () {
    test('TEST 1 - User entered period becomes Day 1', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 10),
        cycleLength: 28,
        periodLength: 5,
      );

      final status = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 11),
        confirmedPeriodStart: DateTime(2026, 9, 11),
      );

      expect(status.periodStartDate, equals(DateTime(2026, 9, 11)));
      expect(status.cycleDay, equals(1));
    });

    test('TEST 2 - Actual data overrides prediction', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 10), // Predicted
        cycleLength: 28,
        periodLength: 5,
      );

      final status = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 12),
        confirmedPeriodStart: DateTime(2026, 9, 11),
      );

      expect(status.periodStartDate, equals(DateTime(2026, 9, 11)));
    });

    test('TEST 3 - Day 1 change resyncs the cycle', () {
      final settingsOld = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 10),
        cycleLength: 28,
        periodLength: 5,
      );
      final statusOld = CycleCalculator.compute(
        settings: settingsOld,
        today: DateTime(2026, 9, 20),
      );

      final statusNew = CycleCalculator.compute(
        settings: settingsOld,
        today: DateTime(2026, 9, 20),
        confirmedPeriodStart: DateTime(2026, 9, 11),
      );

      expect(statusOld.cycleDay, equals(11));
      expect(statusNew.cycleDay, equals(10));
      expect(statusNew.periodStartDate, equals(DateTime(2026, 9, 11)));
    });

    test('TEST 4 - Menstrual phase shifts', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 10),
        cycleLength: 28,
        periodLength: 5,
      );
      
      final oldStatusDay15 = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 15),
      );
      
      final newStatusDay15 = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 15),
        confirmedPeriodStart: DateTime(2026, 9, 14),
      );

      expect(oldStatusDay15.phase, equals(CyclePhase.follicular));
      expect(newStatusDay15.phase, equals(CyclePhase.menstrual));
    });

    test('TEST 5 - Follicular phase shifts', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 10),
        cycleLength: 28,
        periodLength: 5,
      );

      final status = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 16),
        confirmedPeriodStart: DateTime(2026, 9, 10),
      );
      expect(status.phase, equals(CyclePhase.follicular));
    });

    test('TEST 6 - Ovulation shifts', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 10),
        cycleLength: 28,
        periodLength: 5,
      );

      final statusOld = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 10),
      );

      final statusNew = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 11),
        confirmedPeriodStart: DateTime(2026, 9, 11),
      );

      expect(
        statusNew.predictions.ovulationDate.difference(statusOld.predictions.ovulationDate).inDays,
        equals(1),
      );
    });

    test('TEST 7 - Luteal phase shifts', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 10),
        cycleLength: 28,
        periodLength: 5,
      );

      final statusNew = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 10, 5),
        confirmedPeriodStart: DateTime(2026, 9, 11),
      );
      expect(statusNew.phase, equals(CyclePhase.luteal));
    });

    test('TEST 8 - Cycle day calculation', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 10),
        cycleLength: 28,
        periodLength: 5,
      );

      final dates = [
        DateTime(2026, 9, 10),
        DateTime(2026, 9, 11),
        DateTime(2026, 9, 16),
        DateTime(2026, 9, 23),
      ];
      final expectedDays = [1, 2, 7, 14];

      for (int i = 0; i < dates.length; i++) {
        final status = CycleCalculator.compute(
          settings: settings,
          today: dates[i],
        );
        expect(status.cycleDay, equals(expectedDays[i]));
      }
    });

    test('TEST 9 - Historical cycle lengths', () {
      final starts = [
        DateTime(2026, 6, 1),
        DateTime(2026, 7, 1),
        DateTime(2026, 8, 2),
        DateTime(2026, 8, 31),
      ];

      final avgLength = CycleCalculator.computeAdaptiveCycleLength(
        confirmedStarts: starts,
        fallbackLength: 28,
      );
      expect(avgLength, equals(30));
    });

    test('TEST 10 - New period updates future prediction', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 10),
        cycleLength: 28,
        periodLength: 5,
      );

      final statusOld = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 15),
      );

      final statusNew = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 15),
        confirmedPeriodStart: DateTime(2026, 9, 12),
      );

      expect(statusNew.predictions.nextPeriodStart.isAfter(statusOld.predictions.nextPeriodStart), isTrue);
    });

    test('TEST 11 - Multiple period logs', () {
      final starts = [
        DateTime(2026, 9, 1),
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 31),
      ];
      final avgLength = CycleCalculator.computeAdaptiveCycleLength(
        confirmedStarts: starts,
        fallbackLength: 28,
      );
      expect(avgLength, equals(30));
    });

    test('TEST 12 - Prediction must never become actual data (NO WRAP)', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 1),
        cycleLength: 28,
        periodLength: 5,
      );

      // Predicted next period = Sept 29
      final status28 = CycleCalculator.compute(settings: settings, today: DateTime(2026, 9, 28));
      final status29 = CycleCalculator.compute(settings: settings, today: DateTime(2026, 9, 29));
      final status30 = CycleCalculator.compute(settings: settings, today: DateTime(2026, 9, 30));
      final status31 = CycleCalculator.compute(settings: settings, today: DateTime(2026, 10, 1));
      final status32 = CycleCalculator.compute(settings: settings, today: DateTime(2026, 10, 2));

      expect(status28.cycleDay, equals(28));
      expect(status29.cycleDay, equals(29));
      expect(status30.cycleDay, equals(30));
      expect(status31.cycleDay, equals(31));
      expect(status32.cycleDay, equals(32));

      expect(status32.phase, isNot(equals(CyclePhase.menstrual)));
      expect(status32.phase, equals(CyclePhase.luteal)); // Should remain late/luteal
    });

    test('TEST 13 - Actual period after being late', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 1),
        cycleLength: 28,
        periodLength: 5,
      );

      final statusOld = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 10, 2),
      );
      expect(statusOld.cycleDay, equals(32)); // Late cycle

      final statusNew = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 10, 3),
        confirmedPeriodStart: DateTime(2026, 10, 3),
      );
      expect(statusNew.cycleDay, equals(1)); // New cycle starts!
      expect(statusNew.periodStartDate, equals(DateTime(2026, 10, 3)));
    });

    test('TEST 14 - Timezone/date boundary', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime.utc(2026, 9, 10, 23, 59),
        cycleLength: 28,
        periodLength: 5,
      );
      final status = CycleCalculator.compute(
        settings: settings,
        today: DateTime.utc(2026, 9, 11, 0, 1),
      );
      expect(status.cycleDay, equals(2));
    });

    test('TEST 15 - Month/year boundaries', () {
      final settings = CycleSettings(
        lastPeriodStart: DateTime(2025, 12, 30),
        cycleLength: 28,
        periodLength: 5,
      );
      final status = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 1, 1),
      );
      expect(status.cycleDay, equals(3));
    });

    test('TEST 16 - Calendar consistency (PhaseForDate NO WRAP)', () {
      final anchor = DateTime(2026, 9, 1);
      
      final phaseLate = CycleCalculator.phaseForDate(
        date: DateTime(2026, 10, 2),
        anchor: anchor,
        cycleLength: 28,
        periodLength: 5,
      );
      // Day 32 phase should be luteal, NOT menstrual day 4.
      expect(phaseLate, equals(CyclePhase.luteal));
    });
  });
}
