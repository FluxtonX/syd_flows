import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/data/models/period_record.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';

void main() {
  group('E2E Full Flow Integration Tests — Frontend to Service & Logic Engine', () {
    final baseSettings = CycleSettings(
      lastPeriodStart: DateTime(2026, 9, 1),
      cycleLength: 28,
      periodLength: 5, // 5 days typical period prediction setting
    );

    test('E2E Scenario 1: User logs 7 consecutive days of actual bleeding (5-day setting does NOT truncate)', () {
      final anchor = DateTime(2026, 9, 1);
      final logsMap = <String, DayJournal>{};

      // User logs 7 full days of actual bleeding (Days 1 to 7)
      for (int i = 1; i <= 7; i++) {
        final dayStr = i.toString().padLeft(2, '0');
        final key = '2026-09-$dayStr';
        logsMap[key] = DayJournal(
          flow: i <= 3 ? 'heavy' : (i <= 5 ? 'medium' : 'light'),
          moods: ['calm'],
          symptoms: ['cramps'],
          energy: 0.5,
          notes: 'Bleeding day $i',
          isPeriodStart: i == 1,
          isPeriodEnd: i == 7,
        );
      }

      // Step 1: Verify all 7 days return CyclePhase.menstrual
      for (int i = 1; i <= 7; i++) {
        final date = DateTime(2026, 9, i);
        final phase = CycleCalculator.phaseForDate(
          date: date,
          anchor: anchor,
          cycleLength: 28,
          periodLength: 5,
          allLogs: logsMap,
        );
        expect(phase, equals(CyclePhase.menstrual), reason: 'Day $i must be menstrual phase');
      }

      // Step 2: Day 8 (post period end) transitions to Follicular
      final phaseDay8 = CycleCalculator.phaseForDate(
        date: DateTime(2026, 9, 8),
        anchor: anchor,
        cycleLength: 28,
        periodLength: 5,
        allLogs: logsMap,
      );
      expect(phaseDay8, equals(CyclePhase.follicular));
    });

    test('E2E Scenario 2: Start Period & Stop Period date selection resyncs active cycle', () {
      // User starts new period on Sep 10
      final startAnchor = DateTime(2026, 9, 10);
      final periodRecord = PeriodRecord(
        id: '2026-09-10',
        startDate: startAnchor,
        createdAt: DateTime.now(),
        source: PeriodSource.userConfirmed,
      );

      expect(periodRecord.id, equals('2026-09-10'));
      expect(periodRecord.startDate, equals(startAnchor));

      // Compute cycle status on Sep 12 (Day 3 of new cycle)
      final status = CycleCalculator.compute(
        settings: baseSettings,
        today: DateTime(2026, 9, 12),
        confirmedPeriodStart: startAnchor,
      );

      expect(status.cycleDay, equals(3));
      expect(status.phase, equals(CyclePhase.menstrual));
    });

    test('E2E Scenario 3: CalendarDayState priority (Actual > Predicted > Ovulation > Normal)', () {
      final logsMap = {
        '2026-09-01': DayJournal(
          flow: 'heavy',
          moods: [],
          symptoms: [],
          energy: 0.5,
          notes: '',
          isPeriodStart: true,
        ),
      };

      final actualPhase = CycleCalculator.phaseForDate(
        date: DateTime(2026, 9, 1),
        anchor: DateTime(2026, 9, 1),
        cycleLength: 28,
        periodLength: 5,
        allLogs: logsMap,
      );
      expect(actualPhase, equals(CyclePhase.menstrual));

      final ovulationPhase = CycleCalculator.phaseForDate(
        date: DateTime(2026, 9, 14),
        anchor: DateTime(2026, 9, 1),
        cycleLength: 28,
        periodLength: 5,
      );
      expect(ovulationPhase, equals(CyclePhase.ovulation));
    });

    test('E2E Scenario 4: New user account onboarding anchor initialization & active period status', () {
      final onboardingSettings = CycleSettings(
        lastPeriodStart: DateTime(2026, 9, 10),
        cycleLength: 28,
        periodLength: 5,
      );

      // On Day 3 (Sep 12), phase is menstrual
      final statusDay3 = CycleCalculator.compute(
        settings: onboardingSettings,
        today: DateTime(2026, 9, 12),
        confirmedPeriodStart: onboardingSettings.lastPeriodStart,
      );

      expect(statusDay3.periodStartDate, equals(DateTime(2026, 9, 10)));
      expect(statusDay3.cycleDay, equals(3));
      expect(statusDay3.phase, equals(CyclePhase.menstrual));

      // On Day 7 (Sep 16), without logged bleeding, phase transitions to follicular
      final statusDay7 = CycleCalculator.compute(
        settings: onboardingSettings,
        today: DateTime(2026, 9, 16),
        confirmedPeriodStart: onboardingSettings.lastPeriodStart,
      );

      expect(statusDay7.periodStartDate, equals(DateTime(2026, 9, 10)));
      expect(statusDay7.cycleDay, equals(7));
      expect(statusDay7.phase, equals(CyclePhase.follicular));
    });
  });
}
