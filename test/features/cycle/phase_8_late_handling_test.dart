import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';
import 'package:syd_flow/features/cycle/domain/cycle_state_evaluator.dart';
import 'package:syd_flow/features/cycle/domain/historical_cycle_analyzer.dart';

void main() {
  group('Phase 8 — Late / Missed / Stale Prediction Handling', () {
    final DateTime baseDate = DateTime(2026, 9, 1);
    final CycleSettings defaultSettings = CycleSettings(
      lastPeriodStart: baseDate,
      cycleLength: 28,
      periodLength: 5,
    );

    final List<DateTime> regularStarts = [
      baseDate.subtract(const Duration(days: 84)),
      baseDate.subtract(const Duration(days: 56)),
      baseDate.subtract(const Duration(days: 28)),
      baseDate,
    ];

    test(
      'Normal ongoing cycle (Day 10) returns active state with no overdue days',
      () {
        final today = baseDate.add(const Duration(days: 9)); // Day 10
        final stats = HistoricalCycleAnalyzer.analyze(
          confirmedStarts: regularStarts,
          fallbackLength: 28,
        );

        final status = CycleCalculator.compute(
          settings: defaultSettings,
          today: today,
          stats: stats,
        );

        expect(status.stateCategory, equals(CycleStateCategory.active));
        expect(status.overdueDays, equals(0));
      },
    );

    test(
      'Approaching expected period start (Day 27) returns expected state',
      () {
        final today = baseDate.add(
          const Duration(days: 26),
        ); // Day 27 (1 day before Sep 29)
        final stats = HistoricalCycleAnalyzer.analyze(
          confirmedStarts: regularStarts,
          fallbackLength: 28,
        );

        final status = CycleCalculator.compute(
          settings: defaultSettings,
          today: today,
          stats: stats,
        );

        expect(status.stateCategory, equals(CycleStateCategory.expected));
        expect(status.overdueDays, equals(0));
      },
    );

    test(
      'Overdue period (3 days late) returns late state and decays confidence by 1 step',
      () {
        final today = baseDate.add(
          const Duration(days: 31),
        ); // 3 days past predicted Sep 29 start
        final stats = HistoricalCycleAnalyzer.analyze(
          confirmedStarts: regularStarts,
          fallbackLength: 28,
        );

        final eval = CycleStateEvaluator.evaluate(
          currentDate: today,
          predictedPeriodStart: baseDate.add(const Duration(days: 28)),
          currentCycleDay: 32,
          expectedCycleLength: 28,
          baseConfidence: PredictionConfidence.high,
          regularityClass: stats.regularityClass,
        );

        expect(eval.category, equals(CycleStateCategory.late));
        expect(eval.overdueDays, equals(3));
        expect(eval.adjustedConfidence, equals(PredictionConfidence.medium));
      },
    );

    test('Overdue period (5 days late) decays confidence by 2 steps', () {
      final today = baseDate.add(
        const Duration(days: 33),
      ); // 5 days past predicted Sep 29 start
      final stats = HistoricalCycleAnalyzer.analyze(
        confirmedStarts: regularStarts,
        fallbackLength: 28,
      );

      final eval = CycleStateEvaluator.evaluate(
        currentDate: today,
        predictedPeriodStart: baseDate.add(const Duration(days: 28)),
        currentCycleDay: 34,
        expectedCycleLength: 28,
        baseConfidence: PredictionConfidence.high,
        regularityClass: stats.regularityClass,
      );

      expect(eval.category, equals(CycleStateCategory.late));
      expect(eval.overdueDays, equals(5));
      expect(eval.adjustedConfidence, equals(PredictionConfidence.low));
    });

    test('Overdue period (>7 days late) decays confidence to insufficient', () {
      final today = baseDate.add(
        const Duration(days: 38),
      ); // 10 days past predicted Sep 29 start
      final stats = HistoricalCycleAnalyzer.analyze(
        confirmedStarts: regularStarts,
        fallbackLength: 28,
      );

      final eval = CycleStateEvaluator.evaluate(
        currentDate: today,
        predictedPeriodStart: baseDate.add(const Duration(days: 28)),
        currentCycleDay: 39,
        expectedCycleLength: 28,
        baseConfidence: PredictionConfidence.high,
        regularityClass: stats.regularityClass,
      );

      expect(eval.category, equals(CycleStateCategory.late));
      expect(eval.overdueDays, equals(10));
      expect(
        eval.adjustedConfidence,
        equals(PredictionConfidence.insufficient),
      );
    });

    test('Logging active bleeding yields confirmed state', () {
      final today = baseDate.add(const Duration(days: 2));
      final journalMap = {
        '2026-09-03': DayJournal(
          flow: 'medium',
          moods: [],
          symptoms: [],
          energy: 3.0,
          notes: '',
        ),
      };

      final status = CycleCalculator.compute(
        settings: defaultSettings,
        today: today,
        allLogs: journalMap,
      );

      expect(status.stateCategory, equals(CycleStateCategory.confirmed));
    });

    test('Insufficient data yields insufficientData state', () {
      final eval = CycleStateEvaluator.evaluate(
        currentDate: baseDate.add(const Duration(days: 10)),
        predictedPeriodStart: baseDate.add(const Duration(days: 28)),
        currentCycleDay: 11,
        expectedCycleLength: 28,
        baseConfidence: PredictionConfidence.insufficient,
        regularityClass: RegularityClass.insufficientData,
      );

      expect(eval.category, equals(CycleStateCategory.insufficientData));
      expect(
        eval.adjustedConfidence,
        equals(PredictionConfidence.insufficient),
      );
    });
  });
}
