import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';

void main() {
  group('CalendarDayState & Actual vs Predicted Precedence Tests', () {
    test('Logged bleeding on day 6 overrides predicted 5-day period length', () {
      final anchor = DateTime(2026, 9, 1);
      final logsMap = {
        '2026-09-01': DayJournal(flow: 'heavy', moods: [], symptoms: [], energy: 0.5, notes: '', isPeriodStart: true),
        '2026-09-02': DayJournal(flow: 'medium', moods: [], symptoms: [], energy: 0.5, notes: ''),
        '2026-09-03': DayJournal(flow: 'medium', moods: [], symptoms: [], energy: 0.5, notes: ''),
        '2026-09-04': DayJournal(flow: 'light', moods: [], symptoms: [], energy: 0.5, notes: ''),
        '2026-09-05': DayJournal(flow: 'light', moods: [], symptoms: [], energy: 0.5, notes: ''),
        '2026-09-06': DayJournal(flow: 'light', moods: [], symptoms: [], energy: 0.5, notes: ''), // Day 6 logged bleeding!
      };

      final phaseDay6 = CycleCalculator.phaseForDate(
        date: DateTime(2026, 9, 6),
        anchor: anchor,
        cycleLength: 28,
        periodLength: 5,
        allLogs: logsMap,
      );

      // Actual logged bleeding on day 6 MUST be menstrual phase, not follicular
      expect(phaseDay6, equals(CyclePhase.menstrual));
    });

    test('CalendarDayState distinguishes actualPeriod from predictedPeriod', () {
      expect(CalendarDayState.values, contains(CalendarDayState.actualPeriod));
      expect(CalendarDayState.values, contains(CalendarDayState.predictedPeriod));
      expect(CalendarDayState.values, contains(CalendarDayState.estimatedOvulation));
      expect(CalendarDayState.values, contains(CalendarDayState.fertileWindow));
    });
  });
}
