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

    // 1. Profile stream (cycle settings live here in setupFlow map)
    _profileSub = UserService.instance.getUserProfileStream(uid).listen(
      (docSnap) {
        final data = docSnap.data();
        if (data != null && data['setupFlow'] is Map) {
          final setupMap = data['setupFlow'] as Map<String, dynamic>;
          _settings = CycleSettings.fromSetupFlowMap(setupMap);
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
    _logsSub = CycleService.instance.streamCycleLogs(uid).listen(
      (logsMap) {
        _allLogs = logsMap;
        _recompute();
      },
      onError: (e) {
        Helpers.log('CycleStateNotifier logs stream error: $e');
      },
    );

    // 3. Confirmed period records subcollection
    _periodsSub = CycleService.instance.streamPeriodRecords(uid).listen(
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
    final DateTime? confirmedAnchor =
        confirmedStarts.isNotEmpty ? confirmedStarts.first : null;

    // Calculate adaptive cycle length from history (fallback to onboarding settings)
    final int adaptiveCycleLength = CycleCalculator.computeAdaptiveCycleLength(
      confirmedStarts: confirmedStarts,
      fallbackLength: _settings.cycleLength,
    );

    // Calculate adaptive period length from actual flow-log history
    final int adaptivePeriodLength = CycleCalculator.computeAdaptivePeriodLength(
      confirmedStarts: confirmedStarts,
      allLogs: _allLogs,
      fallbackLength: _settings.periodLength,
      cycleLength: adaptiveCycleLength,
    );

    final updatedSettings = _settings.copyWith(
      cycleLength: adaptiveCycleLength,
      periodLength: adaptivePeriodLength,
    );

    try {
      _currentStatus = CycleCalculator.compute(
        settings: updatedSettings,
        today: today,
        confirmedPeriodStart: confirmedAnchor,
        allLogs: _allLogs,
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
          body: 'Your next period is predicted to start in 2 days. Take time to rest and prepare!',
        );
      } else if (daysToPeriod == 0) {
        NotificationService.instance.showNotification(
          id: 102,
          title: 'Cycle Update 🌸',
          body: 'Your period is predicted to start today. Log your flow and symptoms in SYD FLOW!',
        );
      }

      final daysToOvulation = predictions.daysUntilOvulation;
      if (daysToOvulation == 1) {
        NotificationService.instance.showNotification(
          id: 103,
          title: 'Ovulation Window 💫',
          body: 'Ovulation phase is predicted tomorrow. Energy levels are peaking!',
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
        final key = '${rec.startDate.year}-${rec.startDate.month}-${rec.startDate.day}';
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

    final list = uniqueMap.values.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending
    return list;
  }

  // ── Phase for Calendar Date ───────────────────────────────────────────────

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
