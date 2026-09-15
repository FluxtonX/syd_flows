import 'cycle_types.dart';

/// Data model representing historical prediction performance & reconciliation (Phase 9 Engine).
class PredictionReconciliation {
  final String predictionId;
  final DateTime generatedAt;
  final String algorithmVersion;
  final DateTime predictedPeriodStart;
  final DateTime? predictedOvulation;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final PredictionConfidence confidence;
  final DateTime? actualPeriodStart;
  final int? errorDays;

  const PredictionReconciliation({
    required this.predictionId,
    required this.generatedAt,
    this.algorithmVersion = '2.0',
    required this.predictedPeriodStart,
    this.predictedOvulation,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    required this.confidence,
    this.actualPeriodStart,
    this.errorDays,
  });

  /// Factory helper to build reconciliation tracking model from current predictions.
  factory PredictionReconciliation.fromPredictions({
    required String predictionId,
    required DateTime generatedAt,
    required CyclePredictions predictions,
    String algorithmVersion = '2.0',
  }) {
    return PredictionReconciliation(
      predictionId: predictionId,
      generatedAt: generatedAt,
      algorithmVersion: algorithmVersion,
      predictedPeriodStart: predictions.nextPeriodStart,
      predictedOvulation: predictions.ovulationDate,
      fertileWindowStart: predictions.fertileWindowStart,
      fertileWindowEnd: predictions.fertileWindowEnd,
      confidence: predictions.confidence,
    );
  }

  /// Copies this model with actual observed start and computed error days.
  PredictionReconciliation withActualStart(DateTime actual) {
    final actualNorm = DateTime(actual.year, actual.month, actual.day);
    final predictedNorm = DateTime(
      predictedPeriodStart.year,
      predictedPeriodStart.month,
      predictedPeriodStart.day,
    );
    final diff = actualNorm.difference(predictedNorm).inDays;

    return PredictionReconciliation(
      predictionId: predictionId,
      generatedAt: generatedAt,
      algorithmVersion: algorithmVersion,
      predictedPeriodStart: predictedPeriodStart,
      predictedOvulation: predictedOvulation,
      fertileWindowStart: fertileWindowStart,
      fertileWindowEnd: fertileWindowEnd,
      confidence: confidence,
      actualPeriodStart: actualNorm,
      errorDays: diff,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'predictionId': predictionId,
      'generatedAt': generatedAt.toIso8601String(),
      'algorithmVersion': algorithmVersion,
      'predictedPeriodStart': predictedPeriodStart.toIso8601String(),
      'predictedOvulation': predictedOvulation?.toIso8601String(),
      'fertileWindowStart': fertileWindowStart?.toIso8601String(),
      'fertileWindowEnd': fertileWindowEnd?.toIso8601String(),
      'confidence': confidence.name,
      'actualPeriodStart': actualPeriodStart?.toIso8601String(),
      'errorDays': errorDays,
    };
  }

  factory PredictionReconciliation.fromMap(Map<String, dynamic> map) {
    return PredictionReconciliation(
      predictionId: map['predictionId'] as String? ?? '',
      generatedAt: DateTime.tryParse(map['generatedAt'] as String? ?? '') ?? DateTime.now(),
      algorithmVersion: map['algorithmVersion'] as String? ?? '2.0',
      predictedPeriodStart: DateTime.tryParse(map['predictedPeriodStart'] as String? ?? '') ?? DateTime.now(),
      predictedOvulation: map['predictedOvulation'] != null
          ? DateTime.tryParse(map['predictedOvulation'] as String)
          : null,
      fertileWindowStart: map['fertileWindowStart'] != null
          ? DateTime.tryParse(map['fertileWindowStart'] as String)
          : null,
      fertileWindowEnd: map['fertileWindowEnd'] != null
          ? DateTime.tryParse(map['fertileWindowEnd'] as String)
          : null,
      confidence: PredictionConfidence.values.firstWhere(
        (c) => c.name == (map['confidence'] as String? ?? 'medium'),
        orElse: () => PredictionConfidence.medium,
      ),
      actualPeriodStart: map['actualPeriodStart'] != null
          ? DateTime.tryParse(map['actualPeriodStart'] as String)
          : null,
      errorDays: (map['errorDays'] as num?)?.toInt(),
    );
  }
}
