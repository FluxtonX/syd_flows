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

  DayJournal({
    this.flow,
    required this.moods,
    required this.symptoms,
    required this.energy,
    required this.notes,
    this.isPeriodStart = false,
  });

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

// ── Cycle Predictions ────────────────────────────────────────────────────────

/// Predicted upcoming cycle dates.
class CyclePredictions {
  final DateTime nextPeriodStart;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final DateTime ovulationDate;

  const CyclePredictions({
    required this.nextPeriodStart,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.ovulationDate,
  });

  int get daysUntilNextPeriod {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final target = DateTime(
        nextPeriodStart.year, nextPeriodStart.month, nextPeriodStart.day);
    return target.difference(todayNorm).inDays;
  }

  int get daysUntilOvulation {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final target =
        DateTime(ovulationDate.year, ovulationDate.month, ovulationDate.day);
    return target.difference(todayNorm).inDays;
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

  double get progress => (cycleDay / cycleLength).clamp(0.0, 1.0);
  int get daysRemaining => (cycleLength - cycleDay).clamp(0, cycleLength);

  const CycleStatus({
    required this.cycleDay,
    required this.cycleLength,
    required this.periodLength,
    required this.phase,
    required this.predictions,
    required this.periodStartDate,
  });

  static CycleStatus get empty => CycleStatus(
        cycleDay: 1,
        cycleLength: 28,
        periodLength: 5,
        phase: CyclePhase.unknown,
        periodStartDate: DateTime.now(),
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
    final lastPeriodStartStr = map['lastPeriodStart'] as String?;
    DateTime lastPeriodStart;
    if (lastPeriodStartStr != null && lastPeriodStartStr.isNotEmpty) {
      lastPeriodStart = DateTime.tryParse(lastPeriodStartStr) ?? DateTime.now();
    } else {
      lastPeriodStart = DateTime.now();
    }

    final cycleLength = (map['cycleLength'] as num?)?.toInt() ?? 28;
    final periodLength = (map['periodLength'] as num?)?.toInt() ?? 5;

    return CycleSettings(
      lastPeriodStart: lastPeriodStart,
      cycleLength: cycleLength.clamp(15, 50),
      periodLength: periodLength.clamp(1, 15),
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
