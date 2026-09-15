import '../data/models/cycle_types.dart';
import 'cycle_phase_estimator.dart';
import 'cycle_state_evaluator.dart';
import 'fertile_window_estimator.dart';
import 'historical_cycle_analyzer.dart';
import 'next_period_predictor.dart';
import 'ovulation_estimator.dart';

/// CycleCalculator is a PURE DOMAIN SERVICE.
///
/// - No Flutter imports
/// - No Firestore imports
/// - No side effects
/// - Fully unit-testable
///
/// All cycle math lives here. UI and services consume the result.
///
/// Cycle Phase Progression:
///   1. Menstrual: Days 1 to periodLength (typically Days 1..5)
///   2. Follicular: Days (periodLength + 1) to (ovulationDay - 2) (typically Days 6..12)
///   3. Ovulation: Days (ovulationDay - 1) to (ovulationDay + 1) (typically Days 13..15)
///   4. Luteal: Days (ovulationDay + 2) to cycleLength (typically Days 16..28)
class CycleCalculator {
  CycleCalculator._();

  // ── Public entry point ───────────────────────────────────────────────────

  /// Computes the current [CycleStatus] for [today] based on [settings].
  static CycleStatus compute({
    required CycleSettings settings,
    required DateTime today,
    DateTime? confirmedPeriodStart,
    Map<String, DayJournal>? allLogs,
    CycleStatistics? stats,
  }) {
    final DateTime anchor = _resolveAnchor(
      settingsAnchor: settings.lastPeriodStart,
      confirmedAnchor: confirmedPeriodStart,
      today: today,
      cycleLength: settings.cycleLength,
    );

    final DateTime todayNorm = _dateOnly(today);
    final DateTime anchorNorm = _dateOnly(anchor);

    final int rawDiff = todayNorm.difference(anchorNorm).inDays;
    final int cycleDay = rawDiff + 1;

    // Determine effective period length for current cycle.
    final int effectivePeriodLength = _effectivePeriodLengthForCycle(
      cycleAnchor: anchorNorm,
      cycleLength: settings.cycleLength,
      today: todayNorm,
      allLogs: allLogs,
      fallback: settings.periodLength,
    );

    final CyclePhase phase = _computePhase(
      cycleDay: cycleDay,
      cycleLength: settings.cycleLength,
      periodLength: effectivePeriodLength,
    );

    final CyclePredictions predictions = _computePredictions(
      anchor: anchorNorm,
      today: todayNorm,
      cycleDay: cycleDay,
      cycleLength: settings.cycleLength,
      periodLength: effectivePeriodLength,
      stats: stats,
    );

    final String dateKey =
        '${todayNorm.year}-${todayNorm.month.toString().padLeft(2, '0')}-${todayNorm.day.toString().padLeft(2, '0')}';
    final DayJournal? todayJournal = allLogs?[dateKey];

    // Evaluate Phase 8 cycle state & overdue confidence decay
    final stateEval = CycleStateEvaluator.evaluate(
      currentDate: todayNorm,
      predictedPeriodStart: predictions.nextPeriodStart,
      currentCycleDay: cycleDay,
      expectedCycleLength: settings.cycleLength,
      baseConfidence: predictions.confidence,
      regularityClass:
          stats?.regularityClass ?? RegularityClass.insufficientData,
      isBleeding: todayJournal?.isBleeding ?? false,
    );

    final EstimatedCyclePhase estimatedPhase = CyclePhaseEstimator.estimate(
      phase: phase,
      cycleDay: cycleDay,
      anchor: anchorNorm,
      periodLength: effectivePeriodLength,
      cycleLength: settings.cycleLength,
      journal: todayJournal,
      confidence: stateEval.adjustedConfidence,
    );

    return CycleStatus(
      cycleDay: cycleDay,
      cycleLength: settings.cycleLength,
      periodLength: effectivePeriodLength,
      phase: phase,
      predictions: predictions,
      periodStartDate: anchorNorm,
      estimatedPhase: estimatedPhase,
      stateCategory: stateEval.category,
      overdueDays: stateEval.overdueDays,
    );
  }

  /// Computes comprehensive historical cycle statistics for [confirmedStarts] (Phase 2).
  static CycleStatistics computeStatistics({
    required List<DateTime> confirmedStarts,
    required int fallbackLength,
  }) {
    return HistoricalCycleAnalyzer.analyze(
      confirmedStarts: confirmedStarts,
      fallbackLength: fallbackLength,
    );
  }

  // ── Helper: Dynamic Ovulation Day ─────────────────────────────────────────

  /// Computes ovulation day dynamically so Follicular phase is guaranteed
  /// a healthy duration (at least 4 days) and Luteal phase does not absorb
  /// the entire cycle when period length is long or cycle length is short.
  static int _calculateOvulationDay({
    required int cycleLength,
    required int periodLength,
  }) {
    final int safePeriodLength = periodLength.clamp(2, 10);
    final int safeCycleLength = cycleLength.clamp(safePeriodLength + 5, 60);

    // Guaranteed minimum 4 days for follicular phase (safePeriodLength + 1 to ovulationDay - 2)
    final int minOvulationDay = safePeriodLength + 6;
    final int maxOvulationDay = safeCycleLength - 2;

    // Standard clinical estimate is cycleLength - 14
    final int rawOvulationDay = safeCycleLength - 14;

    if (minOvulationDay <= maxOvulationDay) {
      return rawOvulationDay.clamp(minOvulationDay, maxOvulationDay);
    } else {
      return (safePeriodLength + safeCycleLength) ~/ 2;
    }
  }

  // ── Phase Boundaries ─────────────────────────────────────────────────────

  /// Computes which phase a [cycleDay] belongs to.
  ///
  /// Boundaries are DYNAMIC — derived from user's [cycleLength] and [periodLength].
  ///
  /// Menstrual : Day 1 to periodLength
  /// Follicular: Day periodLength+1 to ovulationDay-2
  /// Ovulation : Day ovulationDay-1 to ovulationDay+1
  /// Luteal    : Day ovulationDay+2 to cycleLength
  static CyclePhase _computePhase({
    required int cycleDay,
    required int cycleLength,
    required int periodLength,
  }) {
    final int safePeriodLength = periodLength.clamp(2, 10);
    final int safeCycleLength = cycleLength.clamp(safePeriodLength + 5, 60);

    final int ovulationDay = _calculateOvulationDay(
      cycleLength: safeCycleLength,
      periodLength: safePeriodLength,
    );

    final int follicularStart = safePeriodLength + 1;
    final int follicularEnd = ovulationDay - 2;

    final int ovulationStart = ovulationDay - 1;
    final int ovulationEnd = ovulationDay + 1;

    if (cycleDay <= safePeriodLength) return CyclePhase.menstrual;
    if (cycleDay >= follicularStart && cycleDay <= follicularEnd) {
      return CyclePhase.follicular;
    }
    if (cycleDay >= ovulationStart && cycleDay <= ovulationEnd) {
      return CyclePhase.ovulation;
    }
    return CyclePhase.luteal;
  }

  // ── Predictions ──────────────────────────────────────────────────────────

  static CyclePredictions _computePredictions({
    required DateTime anchor,
    required DateTime today,
    required int cycleDay,
    required int cycleLength,
    required int periodLength,
    CycleStatistics? stats,
  }) {
    final int safePeriodLength = periodLength.clamp(2, 10);
    final int safeCycleLength = cycleLength.clamp(safePeriodLength + 5, 60);

    // Next period range & confidence calculation (Phase 3 Engine)
    final PeriodPrediction periodPred = NextPeriodPredictor.predict(
      anchor: anchor,
      today: today,
      cycleLength: safeCycleLength,
      stats: stats,
    );

    // Ovulation range & confidence calculation (Phase 4 Engine)
    final OvulationEstimation ovulationEst = OvulationEstimator.estimate(
      anchor: anchor,
      today: today,
      cycleLength: safeCycleLength,
      periodLength: safePeriodLength,
      stats: stats,
    );

    // Fertile window range & confidence calculation (Phase 5 Engine)
    final FertileWindowEstimation fertileEst = FertileWindowEstimator.estimate(
      ovulationEst: ovulationEst,
      stats: stats,
    );

    return CyclePredictions(
      nextPeriodStart: periodPred.predictedDate,
      earliestPeriodStart: periodPred.earliestDate,
      latestPeriodStart: periodPred.latestDate,
      confidence: periodPred.confidence,
      periodPrediction: periodPred,
      ovulationEstimation: ovulationEst,
      fertileWindowEstimation: fertileEst,
      fertileWindowStart: fertileEst.fertileWindowStart,
      fertileWindowEnd: fertileEst.fertileWindowEnd,
      ovulationDate: ovulationEst.estimatedOvulationDate,
    );
  }

  // ── Effective Period Length ──────────────────────────────────────────────

  /// Computes the effective period length for the current/active cycle.
  static int _effectivePeriodLengthForCycle({
    required DateTime cycleAnchor,
    required int cycleLength,
    required DateTime today,
    Map<String, DayJournal>? allLogs,
    required int fallback,
  }) {
    final int safeFallback = fallback.clamp(2, 10);
    if (allLogs == null || allLogs.isEmpty) return safeFallback;

    // Only count active bleeding days in the initial 10-day window from cycle anchor
    final DateTime initialWindowEnd = cycleAnchor.add(const Duration(days: 10));

    int bleedingDays = 0;
    int maxBleedingDayOffset = 0;
    bool hasExplicitEnd = false;
    int explicitEndOffset = 0;

    for (final entry in allLogs.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      final dateNorm = _dateOnly(date);

      // Within initial period window and not after today
      if (!dateNorm.isBefore(cycleAnchor) &&
          dateNorm.isBefore(initialWindowEnd) &&
          !dateNorm.isAfter(today)) {
        final dayOffset = dateNorm.difference(cycleAnchor).inDays + 1;
        final journal = entry.value;

        if (journal.isBleeding) {
          bleedingDays++;
          if (dayOffset > maxBleedingDayOffset) {
            maxBleedingDayOffset = dayOffset;
          }
        } else if (journal.isPeriodEnd || journal.flow?.toLowerCase() == 'none') {
          hasExplicitEnd = true;
          explicitEndOffset = dayOffset - 1;
        }
      }
    }

    // 1. If explicit period end or flow='none' was logged after bleeding, respect observed end
    if (hasExplicitEnd && maxBleedingDayOffset > 0) {
      final int observedLength = explicitEndOffset > 0 ? explicitEndOffset : maxBleedingDayOffset;
      return observedLength.clamp(1, 10);
    }

    if (bleedingDays == 0) return safeFallback;

    // 2. Otherwise preserve fallback or actual bleeding count
    return bleedingDays > safeFallback
        ? bleedingDays.clamp(2, 10)
        : safeFallback;
  }

  // ── Adaptive Period Length ───────────────────────────────────────────────

  /// Calculates rolling average period length from completed historical cycles.
  static int computeAdaptivePeriodLength({
    required List<DateTime> confirmedStarts,
    required Map<String, DayJournal> allLogs,
    required int fallbackLength,
    int cycleLength = 28,
  }) {
    if (confirmedStarts.isEmpty) return fallbackLength.clamp(2, 10);

    final sorted = List<DateTime>.from(confirmedStarts)
      ..sort((a, b) => a.compareTo(b));

    final DateTime todayNorm = _dateOnly(DateTime.now());
    final List<int> periodLengths = [];

    for (int i = 0; i < sorted.length; i++) {
      final DateTime cycleAnchor = _dateOnly(sorted[i]);
      final DateTime cycleEnd = (i < sorted.length - 1)
          ? _dateOnly(sorted[i + 1])
          : cycleAnchor.add(Duration(days: cycleLength));

      // Skip current/future cycle (not yet completed)
      if (!cycleEnd.isBefore(todayNorm)) continue;

      int bleedingDays = 0;
      for (final entry in allLogs.entries) {
        final date = DateTime.tryParse(entry.key);
        if (date == null) continue;
        final dateNorm = _dateOnly(date);
        if (!dateNorm.isBefore(cycleAnchor) && dateNorm.isBefore(cycleEnd)) {
          if (entry.value.isBleeding) {
            bleedingDays++;
          }
        }
      }

      if (bleedingDays > 0) {
        periodLengths.add(bleedingDays.clamp(2, 10));
      }
    }

    if (periodLengths.isEmpty) return fallbackLength.clamp(2, 10);

    final double avg =
        periodLengths.reduce((a, b) => a + b) / periodLengths.length.toDouble();
    return avg.round().clamp(2, 10);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static DateTime _resolveAnchor({
    required DateTime settingsAnchor,
    required DateTime? confirmedAnchor,
    required DateTime today,
    required int cycleLength,
  }) {
    final DateTime todayNorm = _dateOnly(today);
    final DateTime settingsNorm = _dateOnly(settingsAnchor);

    if (confirmedAnchor != null) {
      final DateTime confirmedNorm = _dateOnly(confirmedAnchor);
      if (!confirmedNorm.isAfter(todayNorm)) {
        return confirmedNorm;
      }
    }

    if (settingsNorm.isAfter(todayNorm)) {
      return todayNorm;
    }

    return settingsNorm;
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ── Adaptive Cycle Length ────────────────────────────────────────────────

  /// Calculates rolling average cycle length based on confirmed period records (Phase 2).
  static int computeAdaptiveCycleLength({
    required List<DateTime> confirmedStarts,
    required int fallbackLength,
  }) {
    if (confirmedStarts.length < 2) return fallbackLength.clamp(21, 45);

    final stats = HistoricalCycleAnalyzer.analyze(
      confirmedStarts: confirmedStarts,
      fallbackLength: fallbackLength,
    );

    if (stats.cycleCount < 1) return fallbackLength.clamp(21, 45);

    final estimator =
        stats.weightedRecencyLength ??
        stats.medianCycleLength ??
        fallbackLength.toDouble();
    return estimator.round().clamp(21, 45);
  }

  // ── Calendar helpers ─────────────────────────────────────────────────────

  /// Returns the [CyclePhase] for any arbitrary calendar [date].
  static CyclePhase phaseForDate({
    required DateTime date,
    required DateTime anchor,
    required int cycleLength,
    required int periodLength,
    List<DateTime>? confirmedStarts,
    Map<String, DayJournal>? allLogs,
    int? adaptivePeriodLength,
  }) {
    final DateTime dateNorm = _dateOnly(date);

    // ── Priority 1: Observed active menstrual bleeding within initial period window
    if (allLogs != null) {
      final y = dateNorm.year.toString();
      final m = dateNorm.month.toString().padLeft(2, '0');
      final d = dateNorm.day.toString().padLeft(2, '0');
      final key = '$y-$m-$d';
      final entry = allLogs[key];
      if (entry != null && entry.isBleeding) {
        final DateTime anchorNorm = _dateOnly(anchor);
        final int daysFromAnchor = dateNorm.difference(anchorNorm).inDays;
        if (daysFromAnchor >= 0 && daysFromAnchor < 10) {
          return CyclePhase.menstrual;
        }
      }
    }

    // ── Priority 2: Historical confirmed cycle windows ───────────────────
    if (confirmedStarts != null && confirmedStarts.isNotEmpty) {
      final sorted = List<DateTime>.from(confirmedStarts)
        ..sort((a, b) => a.compareTo(b));

      for (int i = 0; i < sorted.length; i++) {
        final DateTime cycleStart = _dateOnly(sorted[i]);
        final DateTime cycleEnd = (i < sorted.length - 1)
            ? _dateOnly(sorted[i + 1])
            : cycleStart.add(Duration(days: cycleLength));

        if (!dateNorm.isBefore(cycleStart) && dateNorm.isBefore(cycleEnd)) {
          final int rawCycleLen = cycleEnd.difference(cycleStart).inDays;
          final int effectiveLen = rawCycleLen >= 15
              ? rawCycleLen
              : cycleLength;

          final int periodLenToUse = adaptivePeriodLength ?? periodLength;

          final int cycleDay = dateNorm.difference(cycleStart).inDays + 1;
          return _computePhase(
            cycleDay: cycleDay,
            cycleLength: effectiveLen,
            periodLength: periodLenToUse,
          );
        }
      }
    }

    // ── Priority 3: Fallback math-only ──────────────────────────────────
    final DateTime anchorNorm = _dateOnly(anchor);

    if (dateNorm.isBefore(anchorNorm)) {
      final int rawDiff = anchorNorm.difference(dateNorm).inDays;
      final int daysBack = rawDiff % cycleLength;
      final int cycleDay = cycleLength - daysBack;
      return _computePhase(
        cycleDay: cycleDay,
        cycleLength: cycleLength,
        periodLength: adaptivePeriodLength ?? periodLength,
      );
    }

    final int rawDiff = dateNorm.difference(anchorNorm).inDays;
    final int cycleDay = (rawDiff % cycleLength) + 1;
    return _computePhase(
      cycleDay: cycleDay,
      cycleLength: cycleLength,
      periodLength: adaptivePeriodLength ?? periodLength,
    );
  }

  /// Returns the cycle day for any arbitrary calendar [date].
  static int cycleDayForDate({
    required DateTime date,
    required DateTime anchor,
    required int cycleLength,
  }) {
    final DateTime dateNorm = _dateOnly(date);
    final DateTime anchorNorm = _dateOnly(anchor);
    final int rawDiff = dateNorm.difference(anchorNorm).inDays;
    if (rawDiff < 0) {
      final int daysBack = (-rawDiff) % cycleLength;
      if (daysBack == 0) return 1;
      return cycleLength - daysBack + 1;
    }
    return (rawDiff % cycleLength) + 1;
  }
}
