import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/data/models/period_record.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';

void main() {
  group('Phase 1 — Data Semantics & Observed-Data Integrity', () {
    final DateTime baseDate = DateTime(2026, 9, 10);
    final settings = CycleSettings(
      lastPeriodStart: baseDate,
      cycleLength: 28,
      periodLength: 5,
    );

    test('1. Normal period start establishes Menstrual phase on Day 1', () {
      final status = CycleCalculator.compute(
        settings: settings,
        today: baseDate, // Sep 10
        confirmedPeriodStart: baseDate,
      );

      expect(status.cycleDay, equals(1));
      expect(status.phase, equals(CyclePhase.menstrual));
    });

    test(
      '2. Day 6 of 5-day period becomes Follicular when intermediate days are unlogged',
      () {
        final todayDay6 = DateTime(2026, 9, 15);
        final logsMap = {
          '2026-09-10': DayJournal(
            flow: 'heavy',
            moods: [],
            symptoms: [],
            energy: 0.8,
            notes: '',
            isPeriodStart: true,
          ),
        };

        final status = CycleCalculator.compute(
          settings: settings,
          today: todayDay6, // Sep 15 (Day 6)
          confirmedPeriodStart: baseDate,
          allLogs: logsMap,
        );

        expect(status.cycleDay, equals(6));
        expect(status.phase, equals(CyclePhase.follicular));
      },
    );

    test('3. Spotting before period does NOT force Menstrual phase', () {
      final spottingDate = DateTime(2026, 9, 8); // 2 days before period start
      final logsMap = {
        '2026-09-08': DayJournal(
          flow: 'spotting',
          moods: [],
          symptoms: ['cramps'],
          energy: 0.6,
          notes: 'Light spotting',
        ),
      };

      final phase = CycleCalculator.phaseForDate(
        date: spottingDate,
        anchor: baseDate,
        cycleLength: 28,
        periodLength: 5,
        allLogs: logsMap,
      );

      expect(phase, isNot(equals(CyclePhase.menstrual)));
    });

    test(
      '4. Spotting on Day 18 (Luteal Phase) does NOT force Menstrual phase',
      () {
        final lutealSpottingDate = DateTime(2026, 9, 27); // Day 18
        final logsMap = {
          '2026-09-27': DayJournal(
            flow: 'spotting',
            moods: [],
            symptoms: [],
            energy: 0.7,
            notes: 'Mid-luteal spotting',
          ),
        };

        final phase = CycleCalculator.phaseForDate(
          date: lutealSpottingDate,
          anchor: baseDate,
          cycleLength: 28,
          periodLength: 5,
          allLogs: logsMap,
        );

        expect(phase, equals(CyclePhase.luteal));
      },
    );

    test(
      '5. DayJournal.isBleeding is false for spotting, none, null, and empty',
      () {
        expect(
          DayJournal(
            flow: 'heavy',
            moods: [],
            symptoms: [],
            energy: 0.5,
            notes: '',
          ).isBleeding,
          isTrue,
        );
        expect(
          DayJournal(
            flow: 'medium',
            moods: [],
            symptoms: [],
            energy: 0.5,
            notes: '',
          ).isBleeding,
          isTrue,
        );
        expect(
          DayJournal(
            flow: 'light',
            moods: [],
            symptoms: [],
            energy: 0.5,
            notes: '',
          ).isBleeding,
          isTrue,
        );
        expect(
          DayJournal(
            flow: 'spotting',
            moods: [],
            symptoms: [],
            energy: 0.5,
            notes: '',
          ).isBleeding,
          isFalse,
        );
        expect(
          DayJournal(
            flow: 'none',
            moods: [],
            symptoms: [],
            energy: 0.5,
            notes: '',
          ).isBleeding,
          isFalse,
        );
        expect(
          DayJournal(
            flow: null,
            moods: [],
            symptoms: [],
            energy: 0.5,
            notes: '',
          ).isBleeding,
          isFalse,
        );
        expect(
          DayJournal(
            flow: '',
            moods: [],
            symptoms: [],
            energy: 0.5,
            notes: '',
          ).isBleeding,
          isFalse,
        );
      },
    );

    test(
      '6. User changes period start date — status resyncs to new anchor',
      () {
        final newAnchor = DateTime(2026, 9, 11); // Shift start to Sep 11
        final status = CycleCalculator.compute(
          settings: settings,
          today: DateTime(2026, 9, 11),
          confirmedPeriodStart: newAnchor,
        );

        expect(status.cycleDay, equals(1));
        expect(status.periodStartDate, equals(newAnchor));
      },
    );

    test(
      '7. PeriodRecord deserializes default source and confidence safely',
      () {
        final rec = PeriodRecord(
          id: '2026-09-10',
          startDate: DateTime(2026, 9, 10),
          createdAt: DateTime.now(),
        );

        expect(rec.source, equals(PeriodSource.userConfirmed));
        expect(rec.confidence, equals(1.0));
      },
    );

    test(
      '8. Future dates are predicted safely without false historical classification',
      () {
        final futureDate = DateTime(
          2026,
          10,
          8,
        ); // Day 29 -> Day 1 of next predicted cycle
        final phase = CycleCalculator.phaseForDate(
          date: futureDate,
          anchor: baseDate,
          cycleLength: 28,
          periodLength: 5,
          confirmedStarts: [baseDate],
        );

        expect(phase, equals(CyclePhase.menstrual));
      },
    );
    test('9. Explicit flow=none or isPeriodEnd ends Menstrual phase early on Day 3', () {
      final day3Date = DateTime(2026, 9, 12); // Day 3
      final logsMap = {
        '2026-09-10': DayJournal(
          flow: 'heavy',
          moods: [],
          symptoms: [],
          energy: 0.5,
          notes: '',
          isPeriodStart: true,
        ),
        '2026-09-11': DayJournal(
          flow: 'medium',
          moods: [],
          symptoms: [],
          energy: 0.6,
          notes: '',
        ),
        '2026-09-12': DayJournal(
          flow: 'none',
          moods: [],
          symptoms: [],
          energy: 0.8,
          notes: 'Period ended',
          isPeriodEnd: true,
        ),
      };

      final status = CycleCalculator.compute(
        settings: settings,
        today: day3Date, // Sep 12 (Day 3)
        confirmedPeriodStart: baseDate,
        allLogs: logsMap,
      );

      expect(status.periodLength, equals(2));
      expect(status.phase, equals(CyclePhase.follicular));
    });
  });
}
