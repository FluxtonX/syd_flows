import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/confidence_engine.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';
import 'package:syd_flow/features/cycle/domain/cycle_phase_estimator.dart';
import 'package:syd_flow/features/cycle/domain/historical_cycle_analyzer.dart';

void main() {
  group('Phase 6 — Confidence Engine', () {
    test('1. Fewer than 2 cycles produces insufficient confidence with explanation', () {
      final score = ConfidenceEngine.evaluate(
        stats: null,
        currentCycleDay: 10,
        cycleLength: 28,
      );

      expect(score.rating, equals(PredictionConfidence.insufficient));
      expect(score.explanation, contains('Fewer than 2'));
    });

    test('2. 3+ regular cycles produces high confidence rating', () {
      final starts = [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 29), // 28 days
        DateTime(2026, 7, 27), // 28 days
        DateTime(2026, 8, 24), // 28 days
      ];

      final stats = HistoricalCycleAnalyzer.analyze(
        confirmedStarts: starts,
        fallbackLength: 28,
      );

      final score = ConfidenceEngine.evaluate(
        stats: stats,
        currentCycleDay: 10,
        cycleLength: 28,
      );

      expect(score.rating, equals(PredictionConfidence.high));
      expect(score.explanation, contains('Highly consistent'));
    });

    test('3. High cycle deviation lowers confidence', () {
      final starts = [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 29),
        DateTime(2026, 7, 27),
      ];
      final stats = HistoricalCycleAnalyzer.analyze(
        confirmedStarts: starts,
        fallbackLength: 28,
      );

      // Current cycle day 40 (12 days past expected 28)
      final score = ConfidenceEngine.evaluate(
        stats: stats,
        currentCycleDay: 40,
        cycleLength: 28,
      );

      expect(score.rating, equals(PredictionConfidence.low));
    });
  });

  group('Phase 7 — Cycle Phase Estimation Engine', () {
    final DateTime baseAnchor = DateTime(2026, 9, 1);

    test('1. Direct bleeding observation produces observed nature and safe display name', () {
      final journal = DayJournal(
        flow: 'heavy',
        moods: [],
        symptoms: [],
        energy: 0.8,
        notes: '',
      );

      final estPhase = CyclePhaseEstimator.estimate(
        phase: CyclePhase.menstrual,
        cycleDay: 2,
        anchor: baseAnchor,
        periodLength: 5,
        cycleLength: 28,
        journal: journal,
      );

      expect(estPhase.nature, equals(PhaseNature.observed));
      expect(estPhase.safeDisplayName, equals('Observed Menstrual Phase'));
      expect(estPhase.safeDisplayName, isNot(contains('estrogen')));
    });

    test('2. Active cycle without bleeding log produces estimated nature and safe display name', () {
      final estPhase = CyclePhaseEstimator.estimate(
        phase: CyclePhase.follicular,
        cycleDay: 8,
        anchor: baseAnchor,
        periodLength: 5,
        cycleLength: 28,
      );

      expect(estPhase.nature, equals(PhaseNature.estimated));
      expect(estPhase.safeDisplayName, equals('Estimated Follicular Phase'));
      expect(estPhase.safeDisplayName, isNot(contains('progesterone')));
    });

    test('3. Future cycle projection produces predicted nature', () {
      final estPhase = CyclePhaseEstimator.estimate(
        phase: CyclePhase.menstrual,
        cycleDay: 30, // Past cycleLength 28
        anchor: baseAnchor,
        periodLength: 5,
        cycleLength: 28,
      );

      expect(estPhase.nature, equals(PhaseNature.predicted));
      expect(estPhase.safeDisplayName, equals('Predicted Menstrual Phase'));
    });

    test('4. CycleCalculator.compute populates estimatedPhase seamlessly', () {
      final settings = CycleSettings(
        lastPeriodStart: baseAnchor,
        cycleLength: 28,
        periodLength: 5,
      );

      final status = CycleCalculator.compute(
        settings: settings,
        today: DateTime(2026, 9, 10),
        confirmedPeriodStart: baseAnchor,
      );

      expect(status.estimatedPhase, isNotNull);
      expect(status.estimatedPhase!.safeDisplayName, equals('Estimated Follicular Phase'));
    });
  });
}
