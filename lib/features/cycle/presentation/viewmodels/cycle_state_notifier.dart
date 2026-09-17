import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cycle_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/cycle_types.dart';
import '../../data/models/period_record.dart';
import '../../domain/cycle_calculator.dart';

/// App-wide ChangeNotifier that holds the authoritative [CycleStatus].
///
/// Listens to:
/// 1. Auth state changes
/// 2. User profile (for setupFlow / cycle settings)
/// 3. Cycle logs (for isPeriodStart flags on daily log docs)
/// 4. Periods subcollection (for confirmed period records)
///
/// All screens consume this via CycleProvider.of(context).
/// The UI never does cycle math — it reads from [currentStatus].
class CycleStateNotifier extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────

  CycleStatus _currentStatus = CycleStatus.empty;
  CycleSettings _settings = CycleSettings.defaults;
  bool _isLoading = true;
  String? _error;

  CycleStatus get currentStatus => _currentStatus;
  CycleSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// True ONLY when the user has an actively confirmed, running period.
  ///
  /// Conditions that must ALL be true:
  ///   1. There is at least one confirmed period start (PeriodRecord subcollection
  ///      OR a cycle_log with isPeriodStart == true).
  ///   2. The current phase is Menstrual (algorithm agrees we are inside the window).
  ///   3. No `isPeriodEnd` log exists within the active cycle window (anchor → anchor + 14d).
  ///
  /// This is the single gating condition for the "Active Period / Stop Period" banner.
  /// Purely algorithmic phase predictions NEVER trigger this getter.
  bool get hasActivePeriod {
    // Condition 1: must have a confirmed period start
    final confirmedStarts = _getConfirmedStartDates();
    if (confirmedStarts.isEmpty) return false;

    final DateTime today = DateTime.now();
    final DateTime todayNorm = DateTime(today.year, today.month, today.day);

    final DateTime anchor = DateTime(
      _currentStatus.periodStartDate.year,
      _currentStatus.periodStartDate.month,
      _currentStatus.periodStartDate.day,
    );

    // Today must be on or after the anchor, and within 14 days of anchor
    final int daysSinceStart = todayNorm.difference(anchor).inDays;
    if (daysSinceStart < 0 || daysSinceStart >= 14) return false;

    // Condition 2: scan the active period window for an explicit isPeriodEnd log
    for (final entry in _allLogs.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      final dateNorm = DateTime(date.year, date.month, date.day);
      if (!dateNorm.isBefore(anchor) &&
          !dateNorm.isAfter(todayNorm) &&
          entry.value.isPeriodEnd) {
        return false; // User explicitly ended this period
      }
    }

    return true;
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  StreamSubscription<dynamic>? _authSub;
  StreamSubscription<dynamic>? _profileSub;
  StreamSubscription<Map<String, DayJournal>>? _logsSub;
  StreamSubscription<List<PeriodRecord>>? _periodsSub;

  // Raw data from subscriptions
  Map<String, DayJournal> _allLogs = {};
  List<PeriodRecord> _periodRecords = [];

  // ── Constructor ───────────────────────────────────────────────────────────

  CycleStateNotifier() {
    _initAuthListener();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  void _initAuthListener() {
    _authSub = AuthService.instance.authStateChanges.listen((user) {
      if (user == null) {
        _cancelDataSubscriptions();
        _currentStatus = CycleStatus.empty;
        _settings = CycleSettings.defaults;
        _isLoading = false;
        _error = null;
        notifyListeners();
      } else {
        _subscribeToUserData(user.uid);
      }
    });
  }

  void _subscribeToUserData(String uid) {
    _cancelDataSubscriptions();
    _isLoading = true;
    notifyListeners();

    // 1. Profile stream (cycle settings live here in setupFlow map or top-level user doc)
    _profileSub = UserService.instance
        .getUserProfileStream(uid)
        .listen(
          (docSnap) {
            final data = docSnap.data();
            if (data != null) {
              if (data['setupFlow'] is Map) {
                final setupMap = Map<String, dynamic>.from(
                  data['setupFlow'] as Map,
                );
                _settings = CycleSettings.fromSetupFlowMap(setupMap);
              } else if (data['cycleLength'] != null ||
                  data['lastPeriodStart'] != null ||
                  data['periodLength'] != null) {
                _settings = CycleSettings.fromSetupFlowMap(
                  Map<String, dynamic>.from(data),
                );
              }
              _recompute();
            }
          },
          onError: (e) {
            Helpers.log('CycleStateNotifier profile stream error: $e');
            _error = 'Failed to load cycle settings';
            _isLoading = false;
            notifyListeners();
          },
        );

    // 2. All cycle logs (full stream — needed for cross-month anchor detection)
    _logsSub = CycleService.instance
        .streamCycleLogs(uid)
        .listen(
          (logsMap) {
            _allLogs = logsMap;
            // Fix #2+5: Self-healing cleanup — if any PeriodRecord exists in Firestore
            // but its corresponding cycle_log has isPeriodStart=false (user deselected it),
            // proactively delete the stale PeriodRecord. This handles legacy data and
            // any edge cases where the delete-on-unselect previously failed silently.
            _cleanupStalePeriodRecords(uid, logsMap);
            _recompute();
          },
          onError: (e) {
            Helpers.log('CycleStateNotifier logs stream error: $e');
          },
        );

    // 3. Confirmed period records subcollection
    _periodsSub = CycleService.instance
        .streamPeriodRecords(uid)
        .listen(
          (records) {
            _periodRecords = records;
            _recompute();
          },
          onError: (e) {
            Helpers.log('CycleStateNotifier periods stream error: $e');
          },
        );
  }

  // ── Core Computation ──────────────────────────────────────────────────────

  void _recompute() {
    final DateTime today = DateTime.now();

    // Collect all confirmed period start dates (from subcollection & logs)
    final List<DateTime> confirmedStarts = _getConfirmedStartDates(today);

    // Find the most recent confirmed period anchor
    final DateTime? confirmedAnchor = confirmedStarts.isNotEmpty
        ? confirmedStarts.first
        : null;

    // Only apply adaptive rolling averages if user has sufficient history (2+ completed cycles)
    final bool hasSufficientHistory = confirmedStarts.length >= 2;

    final int effectiveCycleLength = hasSufficientHistory
        ? CycleCalculator.computeAdaptiveCycleLength(
            confirmedStarts: confirmedStarts,
            fallbackLength: _settings.cycleLength,
          )
        : _settings.cycleLength;

    final int effectivePeriodLength = hasSufficientHistory
        ? CycleCalculator.computeAdaptivePeriodLength(
            confirmedStarts: confirmedStarts,
            allLogs: _allLogs,
            fallbackLength: _settings.periodLength,
            cycleLength: effectiveCycleLength,
          )
        : _settings.periodLength;

    final updatedSettings = _settings.copyWith(
      cycleLength: effectiveCycleLength,
      periodLength: effectivePeriodLength,
    );

    final CycleStatistics stats = CycleCalculator.computeStatistics(
      confirmedStarts: confirmedStarts,
      fallbackLength: _settings.cycleLength,
    );

    try {
      _currentStatus = CycleCalculator.compute(
        settings: updatedSettings,
        today: today,
        confirmedPeriodStart: confirmedAnchor,
        allLogs: _allLogs,
        stats: stats,
      );
      _isLoading = false;
      _error = null;
      _checkAndTriggerNotifications(_currentStatus.predictions);
    } catch (e) {
      Helpers.log('CycleStateNotifier compute error: $e');
      _error = 'Cycle calculation failed';
      _isLoading = false;
    }

    notifyListeners();
  }

  void _checkAndTriggerNotifications(CyclePredictions predictions) {
    try {
      final daysToPeriod = predictions.daysUntilNextPeriod;
      if (daysToPeriod == 2) {
        NotificationService.instance.showNotification(
          id: 101,
          title: 'Period Reminder 🌸',
          body:
              'Your next period is predicted to start in 2 days. Take time to rest and prepare!',
        );
      } else if (daysToPeriod == 0) {
        NotificationService.instance.showNotification(
          id: 102,
          title: 'Cycle Update 🌸',
          body:
              'Your period is predicted to start today. Log your flow and symptoms in SYD FLOW!',
        );
      }

      final daysToOvulation = predictions.daysUntilOvulation;
      if (daysToOvulation == 1) {
        NotificationService.instance.showNotification(
          id: 103,
          title: 'Ovulation Window 💫',
          body:
              'Ovulation phase is predicted tomorrow. Energy levels are peaking!',
        );
      }
    } catch (e) {
      Helpers.log('Notification trigger error: $e');
    }
  }

  /// Collects all confirmed period start dates sorted descending.
  List<DateTime> _getConfirmedStartDates([DateTime? maxDate]) {
    final Map<String, DateTime> uniqueMap = {};
    final cutoff = maxDate ?? DateTime.now();

    // From PeriodRecord subcollection
    for (final rec in _periodRecords) {
      if (!rec.startDate.isAfter(cutoff)) {
        final key =
            '${rec.startDate.year}-${rec.startDate.month}-${rec.startDate.day}';
        uniqueMap[key] = rec.startDate;
      }
    }

    // From daily logs with isPeriodStart == true
    for (final entry in _allLogs.entries) {
      if (entry.value.isPeriodStart) {
        final date = DateTime.tryParse(entry.key);
        if (date != null && !date.isAfter(cutoff)) {
          final key = '${date.year}-${date.month}-${date.day}';
          if (!uniqueMap.containsKey(key)) {
            uniqueMap[key] = date;
          }
        }
      }
    }

    // ── Source 3: Setup Flow anchor ──────────────────────────────────────────
    // ONLY include as a confirmed start if isBaselineOnly is FALSE.
    // When isBaselineOnly = true, the anchor is purely a prediction calibration
    // reference and must NOT count toward adaptive cycle length calculations.
    // This prevents the setup baseline from triggering hasSufficientHistory
    // and skewing the adaptive engine for brand-new users.
    if (!_settings.isBaselineOnly) {
      final anchor = _settings.lastPeriodStart;
      if (!anchor.isAfter(cutoff)) {
        final key = '${anchor.year}-${anchor.month}-${anchor.day}';
        if (!uniqueMap.containsKey(key)) {
          uniqueMap[key] = anchor;
        }
      }
    }

    final list = uniqueMap.values.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending
    return list;
  }

  // ── Phase for Calendar Date ───────────────────────────────────────────────

  /// Returns the [CalendarDayState] for any calendar [date], distinguishing
  /// actual user-logged bleeding from predicted phase math windows.
  CalendarDayState dayStateForCalendarDate(DateTime date) {
    final DateTime dateNorm = DateTime(date.year, date.month, date.day);
    final String y = dateNorm.year.toString();
    final String m = dateNorm.month.toString().padLeft(2, '0');
    final String d = dateNorm.day.toString().padLeft(2, '0');
    final String key = '$y-$m-$d';

    final DayJournal? log = _allLogs[key];
    final bool isUserLoggedBleeding =
        log != null && (log.isBleeding || log.isPeriodStart);

    // Priority 1: Actual logged data takes precedence over algorithm predictions!
    if (isUserLoggedBleeding) {
      return CalendarDayState.actualPeriod;
    }

    // Priority 2: Predictions & phase math
    final CyclePhase phase = phaseForCalendarDate(dateNorm);

    if (phase == CyclePhase.menstrual) {
      // Find the latest confirmed start before or on this date
      final confirmedStarts = _getConfirmedStartDates();
      DateTime? relevantStart;
      for (final start in confirmedStarts) {
        final startNorm = DateTime(start.year, start.month, start.day);
        if (!dateNorm.isBefore(startNorm)) {
          relevantStart = startNorm;
          break; // Since it's sorted descending, this is the most recent
        }
      }

      if (relevantStart != null) {
        final diff = dateNorm.difference(relevantStart).inDays;
        if (diff < 14) {
          // Check if there's an isPeriodEnd between relevantStart and dateNorm
          bool ended = false;
          for (int i = 0; i < diff; i++) {
            final checkDate = relevantStart.add(Duration(days: i));
            final String cy = checkDate.year.toString();
            final String cm = checkDate.month.toString().padLeft(2, '0');
            final String cd = checkDate.day.toString().padLeft(2, '0');
            final logEntry = _allLogs['$cy-$cm-$cd'];
            if (logEntry != null && logEntry.isPeriodEnd) {
              ended = true;
              break;
            }
          }
          if (!ended) {
            return CalendarDayState.actualPeriod;
          }
        }
      }

      // Predicted menstrual phase window (no user bleeding log on this date)
      return CalendarDayState.predictedPeriod;
    }

    if (phase == CyclePhase.ovulation) {
      final predictions = currentStatus.predictions;
      final ovDate = predictions.ovulationDate;
      if (ovDate.year == dateNorm.year &&
          ovDate.month == dateNorm.month &&
          ovDate.day == dateNorm.day) {
        return CalendarDayState.estimatedOvulation;
      }
      return CalendarDayState.fertileWindow;
    }

    if (phase == CyclePhase.follicular) {
      return CalendarDayState.follicular;
    }

    if (phase == CyclePhase.luteal) {
      return CalendarDayState.luteal;
    }

    return CalendarDayState.normal;
  }

  /// Returns the [CyclePhase] for any calendar [date].
  /// Uses actual flow logs for Clue-style dynamic phase transitions.
  CyclePhase phaseForCalendarDate(DateTime date) {
    // Compute adaptive period length for predicted future cycle shading
    final List<DateTime> confirmedStarts = _getConfirmedStartDates();
    final int adaptivePeriodLen = CycleCalculator.computeAdaptivePeriodLength(
      confirmedStarts: confirmedStarts,
      allLogs: _allLogs,
      fallbackLength: _currentStatus.periodLength,
      cycleLength: _currentStatus.cycleLength,
    );

    return CycleCalculator.phaseForDate(
      date: date,
      anchor: _currentStatus.periodStartDate,
      cycleLength: _currentStatus.cycleLength,
      periodLength: _currentStatus.periodLength,
      confirmedStarts: confirmedStarts,
      allLogs: _allLogs,
      adaptivePeriodLength: adaptivePeriodLen,
    );
  }

  /// Returns the cycle day number for any calendar [date].
  int cycleDayForDate(DateTime date) {
    return CycleCalculator.cycleDayForDate(
      date: date,
      anchor: _currentStatus.periodStartDate,
      cycleLength: _currentStatus.cycleLength,
    );
  }

  // ── Force Refresh ─────────────────────────────────────────────────────────

  /// Forces a recompute without waiting for a new stream event.
  void refresh() => _recompute();

  // ── Self-Healing Cleanup ─────────────────────────────────────────────────

  /// Fix #2+5: Finds any PeriodRecord whose corresponding cycle_log has
  /// [isPeriodStart] == false and deletes it from Firestore.
  ///
  /// This handles:
  /// 1. Legacy data — records created before delete-on-unselect was implemented.
  /// 2. Edge cases — any previous silent delete failures.
  ///
  /// Fire-and-forget (async, non-blocking). Errors are logged only.
  void _cleanupStalePeriodRecords(String uid, Map<String, DayJournal> logsMap) {
    if (_periodRecords.isEmpty) return;

    for (final record in List<PeriodRecord>.from(_periodRecords)) {
      final y = record.startDate.year.toString();
      final m = record.startDate.month.toString().padLeft(2, '0');
      final d = record.startDate.day.toString().padLeft(2, '0');
      final dateKey = '$y-$m-$d';

      final log = logsMap[dateKey];
      // If the log exists and explicitly marks isPeriodStart = false,
      // then the user deselected it — the PeriodRecord is stale, delete it.
      if (log != null && !log.isPeriodStart) {
        CycleService.instance
            .deletePeriodRecord(uid: uid, dateKey: dateKey)
            .then((_) {
              Helpers.log(
                'CycleStateNotifier: cleaned up stale PeriodRecord for $dateKey',
              );
            })
            .catchError((e) {
              Helpers.log('CycleStateNotifier: cleanup error for $dateKey: $e');
            });
      }
    }

    // ── Phantom Baseline Cleanup ─────────────────────────────────────────────
    // If the setup anchor is marked as baseline-only (isBaselineOnly: true),
    // any period record at that date was created by the old setup flow and is
    // a phantom. Auto-delete it and clear the isPeriodStart flag on its
    // companion cycle_log so the adaptive engine sees only real cycles.
    if (!_settings.isBaselineOnly) return;

    final anchor = _settings.lastPeriodStart;
    final anchorKey = CycleService.instance.formatDateKey(
      anchor.year,
      anchor.month,
      anchor.day,
    );

    final hasPhantomRecord = _periodRecords.any((rec) {
      final recKey = CycleService.instance.formatDateKey(
        rec.startDate.year,
        rec.startDate.month,
        rec.startDate.day,
      );
      return recKey == anchorKey;
    });

    if (hasPhantomRecord) {
      // Delete the phantom period record from the periods subcollection.
      CycleService.instance
          .deletePeriodRecord(uid: uid, dateKey: anchorKey)
          .then((_) {
            Helpers.log(
              'CycleStateNotifier: deleted phantom baseline period record: $anchorKey',
            );
          })
          .catchError((e) {
            Helpers.log(
              'CycleStateNotifier: phantom cleanup error for $anchorKey: $e',
            );
          });

      // Also clear isPeriodStart on the companion cycle_log if it exists,
      // so _getConfirmedStartDates Source 2 (logs) also excludes this date.
      final log = logsMap[anchorKey];
      if (log != null && log.isPeriodStart) {
        CycleService.instance
            .saveDailyLog(
              uid: uid,
              dateKey: anchorKey,
              journal: DayJournal(
                flow: log.flow,
                moods: log.moods,
                symptoms: log.symptoms,
                energy: log.energy,
                notes: log.notes,
                isPeriodStart: false, // Clear phantom flag
                isPeriodEnd: false,
              ),
              isPeriodStart: false,
            )
            .then((_) {
              Helpers.log(
                'CycleStateNotifier: cleared phantom isPeriodStart flag on cycle_log: $anchorKey',
              );
            })
            .catchError((e) {
              Helpers.log(
                'CycleStateNotifier: phantom log clear error for $anchorKey: $e',
              );
            });
      }
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void _cancelDataSubscriptions() {
    _profileSub?.cancel();
    _logsSub?.cancel();
    _periodsSub?.cancel();
    _profileSub = null;
    _logsSub = null;
    _periodsSub = null;
    _allLogs = {};
    _periodRecords = [];
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelDataSubscriptions();
    super.dispose();
  }
}
