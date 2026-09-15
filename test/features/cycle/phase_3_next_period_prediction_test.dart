import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/domain/cycle_calculator.dart';
import 'package:syd_flow/features/cycle/domain/historical_cycle_analyzer.dart';
import 'package:syd_flow/features/cycle/domain/next_period_predictor.dart';

void main() {
  group('Phase 3 — Next Period Prediction Engine', () {
    final DateTime baseAnchor = DateTime(2026, 9, 1);
    final DateTime today = DateTime(2026, 9, 15);

    test('1. Insufficient data (<2 cycles) produces insufficient confidence and 3-day range margin', () {
      final prediction = NextPeriodPredictor.predict(
        anchor: baseAnchor,
        today: today,
        cycleLength: 28,
      );

      expect(prediction.confidence, equals(PredictionConfidence.insufficient));
      expect(prediction.predictedDate, equals(DateTime(2026, 9, 29)));
      expect(prediction.earliestDate, equals(DateTime(2026, 9, 26)));
      expect(prediction.latestDate, equals(DateTime(2026, 10, 2)));
      expect(prediction.rangeDisplay, contains('Sep 26'));
      expect(prediction.rangeDisplay, contains('Oct 2'));
    });

    test('2. Highly consistent history (stdDev <= 2.0, count >= 3) produces High confidence', () {
      final starts = [
        DateTime(2026, 6, 9),
        DateTime(2026, 7, 7),  // 28 days
        DateTime(2026, 8, 4),  // 28 days
        DateTime(2026, 9, 1),  // 28 days
      ];

      final stats = HistoricalCycleAnalyzer.analyze(
        confirmedStarts: starts,
        fallbackLength: 28,
      );

      final prediction = NextPeriodPredictor.predict(
        anchor: baseAnchor,
        today: today,
        cycleLength: 28,
        stats: stats,
      );

      expect(prediction.confidence, equals(PredictionConfidence.high));
      expect(prediction.predictedDate, equals(DateTime(2026, 9, 29)));
    });

    test('3. Variable history produces Medium/Low confidence with dynamic uncertainty margin', () {
      final starts = [
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 26), // 25 days
        DateTime(2026, 6, 29), // 34 days
        DateTime(2026, 7, 26), // 27 days
        DateTime(2026, 9, 1),  // 37 days
      ];

      final stats = HistoricalCycleAnalyzer.analyze(
        confirmedStarts: starts,
        fallbackLength: 28,
      );

      final prediction = NextPeriodPredictor.predict(
        anchor: baseAnchor,
        today: today,
        cycleLength: 28,
        stats: stats,
      );

      expect(
        prediction.confidence,
        anyOf(equals(PredictionConfidence.medium), equals(PredictionConfidence.low)),
      );
      // Margin should scale with standard deviation
      final margin = prediction.predictedDate.difference(prediction.earliestDate).inDays;
      expect(margin, greaterThanOrEqualTo(2));
    });

    test('4. CycleCalculator integration populates additive CyclePredictions fields seamlessly', () {
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

      expect(status.predictions.periodPrediction, isNotNull);
      expect(status.predictions.confidence, equals(PredictionConfidence.insufficient));
      expect(status.predictions.earliestPeriodStart, isNotNull);
      expect(status.predictions.latestPeriodStart, isNotNull);
    });
  });
}
