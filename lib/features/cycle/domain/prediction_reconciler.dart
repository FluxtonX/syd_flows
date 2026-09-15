import '../data/models/prediction_reconciliation.dart';

/// Value object summarizing aggregated prediction accuracy & model performance (Phase 9 Engine).
class PredictionAccuracyMetrics {
  final int totalPredictions;
  final int reconciledCount;
  final double meanAbsoluteError;
  final double accuracyWithin2Days;
  final double meanBiasDays;

  const PredictionAccuracyMetrics({
    required this.totalPredictions,
    required this.reconciledCount,
    required this.meanAbsoluteError,
    required this.accuracyWithin2Days,
    required this.meanBiasDays,
  });

  static const PredictionAccuracyMetrics empty = PredictionAccuracyMetrics(
    totalPredictions: 0,
    reconciledCount: 0,
    meanAbsoluteError: 0.0,
    accuracyWithin2Days: 0.0,
    meanBiasDays: 0.0,
  );
}

/// Pure domain service for prediction reconciliation & accuracy metrics (Phase 9 Engine).
class PredictionReconciler {
  const PredictionReconciler._();

  /// Reconciles a past prediction against an actual confirmed period start date.
  static PredictionReconciliation reconcile({
    required PredictionReconciliation prediction,
    required DateTime actualPeriodStart,
  }) {
    return prediction.withActualStart(actualPeriodStart);
  }

  /// Computes statistical accuracy metrics across historical prediction reconciliations.
  static PredictionAccuracyMetrics computeAccuracyMetrics(
    List<PredictionReconciliation> reconciliations,
  ) {
    if (reconciliations.isEmpty) {
      return PredictionAccuracyMetrics.empty;
    }

    final reconciled = reconciliations.where((r) => r.errorDays != null).toList();
    if (reconciled.isEmpty) {
      return PredictionAccuracyMetrics(
        totalPredictions: reconciliations.length,
        reconciledCount: 0,
        meanAbsoluteError: 0.0,
        accuracyWithin2Days: 0.0,
        meanBiasDays: 0.0,
      );
    }

    double totalAbsoluteError = 0.0;
    double totalBias = 0.0;
    int within2DaysCount = 0;

    for (final r in reconciled) {
      final error = r.errorDays!;
      final absError = error.abs();
      totalAbsoluteError += absError;
      totalBias += error;
      if (absError <= 2) {
        within2DaysCount++;
      }
    }

    final double mae = totalAbsoluteError / reconciled.length;
    final double bias = totalBias / reconciled.length;
    final double accuracyPct = (within2DaysCount / reconciled.length) * 100.0;

    return PredictionAccuracyMetrics(
      totalPredictions: reconciliations.length,
      reconciledCount: reconciled.length,
      meanAbsoluteError: double.parse(mae.toStringAsFixed(2)),
      accuracyWithin2Days: double.parse(accuracyPct.toStringAsFixed(1)),
      meanBiasDays: double.parse(bias.toStringAsFixed(2)),
    );
  }
}
