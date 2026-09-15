import 'package:flutter_test/flutter_test.dart';
import 'package:syd_flow/features/cycle/data/models/cycle_types.dart';
import 'package:syd_flow/features/cycle/data/models/prediction_reconciliation.dart';
import 'package:syd_flow/features/cycle/domain/prediction_reconciler.dart';

void main() {
  group('Phase 9 — Prediction Reconciliation', () {
    final DateTime baseDate = DateTime(2026, 9, 1);
    final DateTime predictedStart = DateTime(2026, 9, 29);

    final initialPrediction = PredictionReconciliation(
      predictionId: 'pred_001',
      generatedAt: baseDate,
      algorithmVersion: '2.0',
      predictedPeriodStart: predictedStart,
      confidence: PredictionConfidence.high,
    );

    test('Reconciles actual start date and calculates positive error (+3 days)', () {
      final actualStart = DateTime(2026, 10, 2); // 3 days late
      final reconciled = PredictionReconciler.reconcile(
        prediction: initialPrediction,
        actualPeriodStart: actualStart,
      );

      expect(reconciled.actualPeriodStart, equals(DateTime(2026, 10, 2)));
      expect(reconciled.errorDays, equals(3));
    });

    test('Reconciles actual start date and calculates negative error (-2 days)', () {
      final actualStart = DateTime(2026, 9, 27); // 2 days early
      final reconciled = PredictionReconciler.reconcile(
        prediction: initialPrediction,
        actualPeriodStart: actualStart,
      );

      expect(reconciled.errorDays, equals(-2));
    });

    test('Reconciles exact match (0 error days)', () {
      final actualStart = DateTime(2026, 9, 29);
      final reconciled = PredictionReconciler.reconcile(
        prediction: initialPrediction,
        actualPeriodStart: actualStart,
      );

      expect(reconciled.errorDays, equals(0));
    });

    test('Computes statistical accuracy metrics across multiple predictions', () {
      final p1 = initialPrediction.withActualStart(DateTime(2026, 9, 29)); // 0 error
      final p2 = initialPrediction.withActualStart(DateTime(2026, 10, 1)); // +2 error
      final p3 = initialPrediction.withActualStart(DateTime(2026, 9, 27)); // -2 error
      final p4 = initialPrediction.withActualStart(DateTime(2026, 10, 4)); // +5 error

      final metrics = PredictionReconciler.computeAccuracyMetrics([p1, p2, p3, p4]);

      expect(metrics.totalPredictions, equals(4));
      expect(metrics.reconciledCount, equals(4));
      // MAE: (|0| + |2| + |-2| + |5|) / 4 = 9 / 4 = 2.25
      expect(metrics.meanAbsoluteError, equals(2.25));
      // Accuracy within 2 days: p1, p2, p3 = 3 of 4 = 75.0%
      expect(metrics.accuracyWithin2Days, equals(75.0));
      // Bias: (0 + 2 - 2 + 5) / 4 = 1.25
      expect(metrics.meanBiasDays, equals(1.25));
    });

    test('Serializes to and from Map for Firestore integration', () {
      final reconciled = initialPrediction.withActualStart(DateTime(2026, 10, 2));
      final map = reconciled.toMap();

      expect(map['predictionId'], equals('pred_001'));
      expect(map['algorithmVersion'], equals('2.0'));
      expect(map['errorDays'], equals(3));
      expect(map['confidence'], equals('high'));

      final restored = PredictionReconciliation.fromMap(map);
      expect(restored.predictionId, equals('pred_001'));
      expect(restored.errorDays, equals(3));
      expect(restored.confidence, equals(PredictionConfidence.high));
    });
  });
}
