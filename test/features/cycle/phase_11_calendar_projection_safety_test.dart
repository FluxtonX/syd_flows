import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/cycle_phase_estimator.dart';

void main() {
  group('Phase 11 — Calendar Projection Safety', () {
    final DateTime baseDate = DateTime(2026, 9, 1);

    test('Active cycle phase (Day 10 of 28) is not marked as stale', () {
      final estimated = CyclePhaseEstimator.estimate(
        phase: CyclePhase.follicular,
        cycleDay: 10,
        anchor: baseDate,
        periodLength: 5,
        cycleLength: 28,
        confidence: PredictionConfidence.high,
      );

      expect(estimated.isStale, isFalse);
    });

    test('Far overdue cycle phase (Day 45 of 28) is marked as stale', () {
      final estimated = CyclePhaseEstimator.estimate(
        phase: CyclePhase.luteal,
        cycleDay: 45, // > 28 + 14 days overdue
        anchor: baseDate,
        periodLength: 5,
        cycleLength: 28,
        confidence: PredictionConfidence.low,
      );

      expect(estimated.isStale, isTrue);
    });

    test('Insufficient confidence prediction is marked as stale', () {
      final estimated = CyclePhaseEstimator.estimate(
        phase: CyclePhase.follicular,
        cycleDay: 10,
        anchor: baseDate,
        periodLength: 5,
        cycleLength: 28,
        confidence: PredictionConfidence.insufficient,
      );

      expect(estimated.isStale, isTrue);
    });
  });
}
