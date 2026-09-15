import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';
import 'package:syd_flow/features/cycle/domain/fertile_window_estimator.dart';
import 'package:syd_flow/features/cycle/domain/historical_cycle_analyzer.dart';
import 'package:syd_flow/features/cycle/domain/ovulation_estimator.dart';

void main() {
  group('Phase 4 — Ovulation Estimation Engine', () {
    final DateTime baseAnchor = DateTime(2026, 9, 1);
    final DateTime today = DateTime(2026, 9, 10); // Day 10 of current cycle (before ovulation on Day 14)

    test('1. Baseline calendar ovulation estimate produces calendarEstimate basis', () {
      final ovulation = OvulationEstimator.estimate(
        anchor: baseAnchor,
        today: today,
        cycleLength: 28,
        periodLength: 5,
      );

      // In a 28-day cycle starting Sep 1, ovulation is ~Day 14 (Sep 14)
      expect(ovulation.basis, equals(OvulationBasis.calendarEstimate));
      expect(ovulation.estimatedOvulationDate.day, equals(14));
      expect(ovulation.earliestPossibleDate.isBefore(ovulation.estimatedOvulationDate), isTrue);
      expect(ovulation.latestPossibleDate.isAfter(ovulation.estimatedOvulationDate), isTrue);
    });

    test('2. 3+ completed cycles produces historicalPattern basis', () {
      final starts = [
        DateTime(2026, 6, 9),
        DateTime(2026, 7, 7),
        DateTime(2026, 8, 4),
        DateTime(2026, 9, 1),
      ];

      final stats = HistoricalCycleAnalyzer.analyze(
        confirmedStarts: starts,
        fallbackLength: 28,
      );

      final ovulation = OvulationEstimator.estimate(
        anchor: baseAnchor,
        today: today,
        cycleLength: 28,
        periodLength: 5,
        stats: stats,
      );

      expect(ovulation.basis, equals(OvulationBasis.historicalPattern));
    });

    test('3. Biological impossibility lowers confidence instead of hard clamping to false date', () {
      // 18-day cycle with 7-day period length -> raw ovulation day 4 <= periodLength + 2
      final ovulation = OvulationEstimator.estimate(
        anchor: baseAnchor,
        today: today,
        cycleLength: 18,
        periodLength: 7,
      );

      expect(ovulation.confidence, equals(PredictionConfidence.low));
    });
  });

  group('Phase 5 — Fertile Window Engine', () {
    final DateTime baseAnchor = DateTime(2026, 9, 1);
    final DateTime today = DateTime(2026, 9, 10);

    test('1. Fertile window spans 5 days prior to earliest ovulation to 1 day after latest ovulation', () {
      final ovulation = OvulationEstimator.estimate(
        anchor: baseAnchor,
        today: today,
        cycleLength: 28,
        periodLength: 5,
      );

      final fertile = FertileWindowEstimator.estimate(ovulationEst: ovulation);

      expect(fertile.fertileWindowStart.isBefore(ovulation.earliestPossibleDate), isTrue);
      expect(fertile.fertileWindowEnd.isAfter(ovulation.latestPossibleDate), isTrue);
      expect(fertile.confidence, equals(ovulation.confidence));
      expect(fertile.basis, equals(ovulation.basis));
      expect(fertile.rangeDisplay, contains('Sep'));
    });

    test('2. CycleCalculator populates additive fertileWindowEstimation field seamlessly', () {
      final settings = CycleSettings(
        lastPeriodStart: baseAnchor,
        cycleLength: 28,
        periodLength: 5,
      );

      final status = CycleCalculator.compute(
        settings: settings,
        today: today,
        confirmedPeriodStart: baseAnchor,
      );

      expect(status.predictions.ovulationEstimation, isNotNull);
      expect(status.predictions.fertileWindowEstimation, isNotNull);
      expect(status.predictions.fertileWindowEstimation!.rangeDisplay, isNotEmpty);
    });
  });
}
