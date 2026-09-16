/// Shared cycle domain types used across the entire app.
///
/// This file has NO Flutter imports and NO Firestore imports.
/// It is the single source of truth for CyclePhase, DayJournal, and CycleStatus.
library;

// ── Cycle Phase ─────────────────────────────────────────────────────────────

/// The phase of the menstrual cycle.
enum CyclePhase {
  menstrual,
  follicular,
  ovulation,
  luteal,
  unknown;

  /// Human-readable display name (e.g. 'Menstrual Phase').
  String get displayName {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Menstrual Phase';
      case CyclePhase.follicular:
        return 'Follicular Phase';
      case CyclePhase.ovulation:
        return 'Ovulation Phase';
      case CyclePhase.luteal:
        return 'Luteal Phase';
      case CyclePhase.unknown:
        return 'Unknown Phase';
    }
  }

  /// Short label (e.g. 'Menstrual').
  String get shortLabel {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Menstrual';
      case CyclePhase.follicular:
        return 'Follicular';
      case CyclePhase.ovulation:
        return 'Ovulation';
      case CyclePhase.luteal:
        return 'Luteal';
      case CyclePhase.unknown:
        return 'Unknown';
    }
  }
}

// ── Calendar Day State ───────────────────────────────────────────────────────

/// Visual and semantic state of a single calendar day cell for rendering.
enum CalendarDayState {
  actualPeriod,        // Logged menstrual bleeding or confirmed actual period day
  predictedPeriod,     // Predicted future period window (unlogged bleeding)
  estimatedOvulation,  // Predicted peak ovulation date
  fertileWindow,       // Fertile window days surrounding ovulation
  follicular,          // Follicular phase
  luteal,              // Luteal phase
  normal,              // Unshaded / normal day
}

enum PeriodSource {
  userConfirmed,
  userCorrected,
  observedFlow,
  inferred;

  String get label {
    switch (this) {
      case PeriodSource.userConfirmed:
        return 'user_confirmed';
      case PeriodSource.userCorrected:
        return 'user_corrected';
      case PeriodSource.observedFlow:
        return 'observed_flow';
      case PeriodSource.inferred:
        return 'inferred';
    }
  }

  static PeriodSource parse(String? value) {
    switch (value) {
      case 'user_confirmed':
        return PeriodSource.userConfirmed;
      case 'user_corrected':
        return PeriodSource.userCorrected;
      case 'observed_flow':
        return PeriodSource.observedFlow;
      case 'inferred':
        return PeriodSource.inferred;
      default:
        return PeriodSource.userConfirmed;
    }
  }
}

// ── Day Journal ──────────────────────────────────────────────────────────────

/// Daily cycle journal entry data model.
class DayJournal {
  final String? flow;
  final List<String> moods;
  final List<String> symptoms;
  final double energy;
  final String notes;

  /// Whether this entry marks the confirmed start of a new period cycle.
  final bool isPeriodStart;

  /// Whether this entry marks the confirmed end of the active period.
  final bool isPeriodEnd;

  DayJournal({
    this.flow,
    required this.moods,
    required this.symptoms,
    required this.energy,
    required this.notes,
    this.isPeriodStart = false,
    this.isPeriodEnd = false,
  });

  /// True ONLY if actual menstrual bleeding is reported ('heavy', 'medium', 'light').
  /// False for 'none', 'spotting', null, or empty string.
  bool get isBleeding {
    if (flow == null || flow!.isEmpty) return false;
    final f = flow!.toLowerCase();
    return f != 'none' && f != 'spotting';
  }

  /// True if light spotting is reported (distinguished from active menstrual flow).
  bool get isSpotting {
    if (flow == null || flow!.isEmpty) return false;
    return flow!.toLowerCase() == 'spotting';
  }

  bool get isEmpty =>
      (flow == null || flow!.isEmpty) &&
      moods.isEmpty &&
      symptoms.isEmpty &&
      notes.isEmpty;

  String get summaryText {
    final parts = <String>[];
    if (isPeriodStart) parts.add('🔴 Period started');
    if (flow != null && flow!.isNotEmpty) {
      final cap = flow![0].toUpperCase() + flow!.substring(1);
      parts.add('Flow: $cap');
    }
    if (moods.isNotEmpty) {
      parts.add('Mood: ${moods.join(", ")}');
    }
    if (symptoms.isNotEmpty) {
      parts.add('Symptoms: ${symptoms.join(", ")}');
    }
    parts.add('Energy: ${(energy * 100).toInt()}%');
    if (notes.isNotEmpty) {
      parts.add('Notes: "$notes"');
    }
    return parts.join(' • ');
  }
}

// ── Period Event ─────────────────────────────────────────────────────────────

/// Conceptual model for period intervals distinguishing observed vs predicted data.
class PeriodEvent {
  final DateTime startDate;
  final DateTime? endDate;
  final PeriodSource source;
  final double confidence;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PeriodEvent({
    required this.startDate,
    this.endDate,
    this.source = PeriodSource.userConfirmed,
    this.confidence = 1.0,
    required this.createdAt,
    this.updatedAt,
  });
}

// ── Prediction Confidence ────────────────────────────────────────────────────

/// Confidence level for algorithmic cycle predictions.
enum PredictionConfidence {
  insufficient,
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case PredictionConfidence.insufficient:
        return 'Insufficient Data';
      case PredictionConfidence.low:
        return 'Low';
      case PredictionConfidence.medium:
        return 'Medium';
      case PredictionConfidence.high:
        return 'High';
    }
  }
}

// ── Confidence Score Value Object ────────────────────────────────────────────

/// Unified deterministic confidence score breakdown (Phase 6 Engine).
class ConfidenceScore {
  final PredictionConfidence rating;
  final int cycleCount;
  final double variability;
  final double dataCompleteness;
  final int currentCycleDeviation;
  final String explanation;

  const ConfidenceScore({
    required this.rating,
    required this.cycleCount,
    required this.variability,
    required this.dataCompleteness,
    required this.currentCycleDeviation,
    required this.explanation,
  });
}

// ── Period Prediction Value Object ───────────────────────────────────────────

/// Comprehensive prediction model for the next period including range and uncertainty (Phase 3).
class PeriodPrediction {
  final DateTime predictedDate;
  final DateTime earliestDate;
  final DateTime latestDate;
  final PredictionConfidence confidence;
  final String rangeDisplay;

  const PeriodPrediction({
    required this.predictedDate,
    required this.earliestDate,
    required this.latestDate,
    required this.confidence,
    required this.rangeDisplay,
  });
}

// ── Ovulation Basis ───────────────────────────────────────────────────────────

/// Source authority for ovulation estimations.
enum OvulationBasis {
  calendarEstimate,
  historicalPattern,
  userObservation;

  String get label {
    switch (this) {
      case OvulationBasis.calendarEstimate:
        return 'Calendar Estimate';
      case OvulationBasis.historicalPattern:
        return 'Historical Pattern';
      case OvulationBasis.userObservation:
        return 'User Observation';
    }
  }
}

// ── Ovulation Estimation Value Object ────────────────────────────────────────

/// Comprehensive estimation model for ovulation including uncertainty range & basis (Phase 4).
class OvulationEstimation {
  final DateTime estimatedOvulationDate;
  final DateTime earliestPossibleDate;
  final DateTime latestPossibleDate;
  final PredictionConfidence confidence;
  final OvulationBasis basis;

  const OvulationEstimation({
    required this.estimatedOvulationDate,
    required this.earliestPossibleDate,
    required this.latestPossibleDate,
    required this.confidence,
    this.basis = OvulationBasis.calendarEstimate,
  });
}

// ── Fertile Window Value Object ───────────────────────────────────────────────

/// Comprehensive estimation model for fertile window including ovulation uncertainty (Phase 5).
class FertileWindowEstimation {
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final PredictionConfidence confidence;
  final OvulationBasis basis;
  final String rangeDisplay;

  const FertileWindowEstimation({
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.confidence,
    required this.basis,
    required this.rangeDisplay,
  });
}

// ── Cycle Predictions ────────────────────────────────────────────────────────

/// Predicted upcoming cycle dates.
class CyclePredictions {
  final DateTime nextPeriodStart;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final DateTime ovulationDate;

  // Phase 3 additive fields for range & uncertainty
  final DateTime? earliestPeriodStart;
  final DateTime? latestPeriodStart;
  final PredictionConfidence confidence;
  final PeriodPrediction? periodPrediction;

  // Phase 4 additive fields for ovulation estimation
  final OvulationEstimation? ovulationEstimation;

  // Phase 5 additive fields for fertile window estimation
  final FertileWindowEstimation? fertileWindowEstimation;

  // Phase 10 additive field for explicit engine versioning
  final String algorithmVersion;

  const CyclePredictions({
    required this.nextPeriodStart,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.ovulationDate,
    this.earliestPeriodStart,
    this.latestPeriodStart,
    this.confidence = PredictionConfidence.medium,
    this.periodPrediction,
    this.ovulationEstimation,
    this.fertileWindowEstimation,
    this.algorithmVersion = '2.0',
  });

  int get daysUntilNextPeriod {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final target = DateTime(
      nextPeriodStart.year,
      nextPeriodStart.month,
      nextPeriodStart.day,
    );
    return target.difference(todayNorm).inDays;
  }

  int get daysUntilOvulation {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final target = DateTime(
      ovulationDate.year,
      ovulationDate.month,
      ovulationDate.day,
    );
    return target.difference(todayNorm).inDays;
  }
}

// ── Phase Nature ─────────────────────────────────────────────────────────────

/// Distinguishes direct observation vs active estimation vs future prediction (Phase 7).
enum PhaseNature {
  observed,
  estimated,
  predicted;

  String get label {
    switch (this) {
      case PhaseNature.observed:
        return 'Observed';
      case PhaseNature.estimated:
        return 'Estimated';
      case PhaseNature.predicted:
        return 'Predicted';
    }
  }
}

// ── Estimated Cycle Phase Value Object ───────────────────────────────────────

/// Medically safe estimation model for cycle phases (Phase 7 Engine).
///
/// Never generates direct claims of hormone levels (e.g. "Estrogen is rising").
class EstimatedCyclePhase {
  final CyclePhase phase;
  final PhaseNature nature;
  final PredictionConfidence confidence;
  final String safeDisplayName;
  final DateTime startDate;
  final DateTime endDate;
  final bool isStale;

  const EstimatedCyclePhase({
    required this.phase,
    required this.nature,
    required this.confidence,
    required this.safeDisplayName,
    required this.startDate,
    required this.endDate,
    this.isStale = false,
  });
}

// ── Cycle State Category ──────────────────────────────────────────────────────

/// Internal cycle state classification for late, missed, or ongoing cycles (Phase 8).
enum CycleStateCategory {
  active,
  expected,
  late,
  confirmed,
  irregular,
  insufficientData;

  String get label {
    switch (this) {
      case CycleStateCategory.active:
        return 'Active';
      case CycleStateCategory.expected:
        return 'Expected';
      case CycleStateCategory.late:
        return 'Late';
      case CycleStateCategory.confirmed:
        return 'Confirmed';
      case CycleStateCategory.irregular:
        return 'Irregular';
      case CycleStateCategory.insufficientData:
        return 'Insufficient Data';
    }
  }
}

// ── Cycle Status ─────────────────────────────────────────────────────────────

/// Complete computed cycle state for today.
///
/// This is a value object — computed by CycleCalculator and consumed by the UI.
class CycleStatus {
  final int cycleDay;
  final int cycleLength;
  final int periodLength;
  final CyclePhase phase;
  final CyclePredictions predictions;
  final DateTime periodStartDate;

  // Phase 7 additive field for safe phase estimation metadata
  final EstimatedCyclePhase? estimatedPhase;

  // Phase 8 additive fields for late/missed/stale cycle handling
  final CycleStateCategory stateCategory;
  final int overdueDays;

  // Phase 10 additive field for explicit engine versioning
  final String algorithmVersion;

  double get progress => (cycleDay / cycleLength).clamp(0.0, 1.0);
  int get daysRemaining => (cycleLength - cycleDay).clamp(0, cycleLength);

  const CycleStatus({
    required this.cycleDay,
    required this.cycleLength,
    required this.periodLength,
    required this.phase,
    required this.predictions,
    required this.periodStartDate,
    this.estimatedPhase,
    this.stateCategory = CycleStateCategory.active,
    this.overdueDays = 0,
    this.algorithmVersion = '2.0',
  });

  static CycleStatus get empty => CycleStatus(
    cycleDay: 1,
    cycleLength: 28,
    periodLength: 5,
    phase: CyclePhase.unknown,
    periodStartDate: DateTime.now(),
    stateCategory: CycleStateCategory.active,
    overdueDays: 0,
    predictions: CyclePredictions(
      nextPeriodStart: DateTime.now().add(const Duration(days: 28)),
      fertileWindowStart: DateTime.now().add(const Duration(days: 11)),
      fertileWindowEnd: DateTime.now().add(const Duration(days: 17)),
      ovulationDate: DateTime.now().add(const Duration(days: 14)),
    ),
  );
}

// ── Cycle Settings ───────────────────────────────────────────────────────────

/// User's cycle configuration from onboarding.
class CycleSettings {
  final DateTime lastPeriodStart;
  final int cycleLength;
  final int periodLength;
  final DateTime? updatedAt;

  const CycleSettings({
    required this.lastPeriodStart,
    required this.cycleLength,
    required this.periodLength,
    this.updatedAt,
  });

  static CycleSettings get defaults => CycleSettings(
    lastPeriodStart: DateTime.now(),
    cycleLength: 28,
    periodLength: 5,
  );

  factory CycleSettings.fromSetupFlowMap(Map<String, dynamic> map) {
    final dynamic rawStart = map['lastPeriodStart'] ?? map['periodStartDate'];
    DateTime lastPeriodStart = DateTime.now();

    if (rawStart is String && rawStart.isNotEmpty) {
      lastPeriodStart = DateTime.tryParse(rawStart) ?? DateTime.now();
    } else if (rawStart is int) {
      lastPeriodStart = DateTime.fromMillisecondsSinceEpoch(rawStart);
    } else if (rawStart != null) {
      try {
        final dynamic toDate = (rawStart as dynamic).toDate;
        if (toDate is Function) {
          lastPeriodStart = toDate() as DateTime;
        }
      } catch (_) {
        lastPeriodStart = DateTime.now();
      }
    }

    final cycleLength = (map['cycleLength'] as num?)?.toInt() ?? 28;
    final periodLength = (map['periodLength'] as num?)?.toInt() ?? 5;

    return CycleSettings(
      lastPeriodStart: lastPeriodStart,
      cycleLength: cycleLength.clamp(15, 60),
      periodLength: periodLength.clamp(2, 10),
    );
  }

  CycleSettings copyWith({
    DateTime? lastPeriodStart,
    int? cycleLength,
    int? periodLength,
    DateTime? updatedAt,
  }) {
    return CycleSettings(
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ── Cycle Regularity ─────────────────────────────────────────────────────────

/// Classification of historical cycle regularity based on standard deviation.
enum RegularityClass {
  insufficientData,
  regular,
  slightlyVariable,
  variable,
  highlyVariable;

  String get label {
    switch (this) {
      case RegularityClass.insufficientData:
        return 'Insufficient Data';
      case RegularityClass.regular:
        return 'Regular';
      case RegularityClass.slightlyVariable:
        return 'Slightly Variable';
      case RegularityClass.variable:
        return 'Variable';
      case RegularityClass.highlyVariable:
        return 'Highly Variable';
    }
  }
}

// ── Historical Cycle Statistics ──────────────────────────────────────────────

/// Comprehensive historical statistics for user cycle history (Phase 2 engine).
class CycleStatistics {
  final int cycleCount;
  final double? medianCycleLength;
  final double? meanCycleLength;
  final int? minimumCycleLength;
  final int? maximumCycleLength;
  final double cycleVariability;
  final List<int> recentCycleLengths;
  final RegularityClass regularityClass;
  final double? weightedRecencyLength;

  const CycleStatistics({
    required this.cycleCount,
    this.medianCycleLength,
    this.meanCycleLength,
    this.minimumCycleLength,
    this.maximumCycleLength,
    required this.cycleVariability,
    required this.recentCycleLengths,
    required this.regularityClass,
    this.weightedRecencyLength,
  });

  static CycleStatistics empty(int fallbackLength) => CycleStatistics(
    cycleCount: 0,
    medianCycleLength: fallbackLength.toDouble(),
    meanCycleLength: fallbackLength.toDouble(),
    minimumCycleLength: fallbackLength,
    maximumCycleLength: fallbackLength,
    cycleVariability: 0.0,
    recentCycleLengths: const [],
    regularityClass: RegularityClass.insufficientData,
    weightedRecencyLength: fallbackLength.toDouble(),
  );
}
