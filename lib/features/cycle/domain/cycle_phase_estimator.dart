import '../data/models/cycle_types.dart';

/// Pure domain service for medically safe cycle phase estimation (Phase 7).
///
/// Pure Dart — zero dependencies on Flutter or Firestore.
/// Distinguishes observed vs estimated vs predicted phases.
/// NEVER makes unfounded direct claims about hormone levels (e.g. "Estrogen is rising").
class CyclePhaseEstimator {
  CyclePhaseEstimator._();

  /// Estimates detailed phase metadata, nature, confidence, and medically safe display name.
  static EstimatedCyclePhase estimate({
    required CyclePhase phase,
    required int cycleDay,
    required DateTime anchor,
    required int periodLength,
    required int cycleLength,
    DayJournal? journal,
    PredictionConfidence confidence = PredictionConfidence.medium,
  }) {
    final DateTime anchorNorm = DateTime(anchor.year, anchor.month, anchor.day);

    // 1. Nature Determination
    final PhaseNature nature;
    if (journal != null && journal.isBleeding) {
      nature = PhaseNature.observed;
    } else if (cycleDay > cycleLength) {
      nature = PhaseNature.predicted;
    } else {
      nature = PhaseNature.estimated;
    }

    // 2. Safe Display Name Determination (Never claims direct hormone lab readings)
    final String safeDisplayName = _getSafeDisplayName(phase, nature);

    // 3. Staleness Evaluation (Phase 11 Calendar Projection Safety)
    final bool isStale =
        (cycleDay > cycleLength + 14) ||
        (confidence == PredictionConfidence.insufficient);

    // 4. Phase Boundary Dates Calculation
    final DateTime startDate = anchorNorm.add(Duration(days: cycleDay - 1));
    final DateTime endDate = anchorNorm.add(Duration(days: cycleLength - 1));

    return EstimatedCyclePhase(
      phase: phase,
      nature: nature,
      confidence: confidence,
      safeDisplayName: safeDisplayName,
      startDate: startDate,
      endDate: endDate,
      isStale: isStale,
    );
  }

  static String _getSafeDisplayName(CyclePhase phase, PhaseNature nature) {
    if (nature == PhaseNature.observed) {
      return 'Observed Menstrual Phase';
    }
    if (nature == PhaseNature.predicted) {
      return 'Predicted Menstrual Phase';
    }

    switch (phase) {
      case CyclePhase.menstrual:
        return 'Estimated Menstrual Phase';
      case CyclePhase.follicular:
        return 'Estimated Follicular Phase';
      case CyclePhase.ovulation:
        return 'Estimated Ovulation Phase';
      case CyclePhase.luteal:
        return 'Estimated Luteal Phase';
      case CyclePhase.unknown:
        return 'Unknown Phase';
    }
  }
}
