import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cycle_service.dart';
import '../../../../core/utils/helpers.dart';
import '../screens/cycle_screen.dart';

class CycleViewModel extends ChangeNotifier {
  int _selectedDay = 1;
  final int _currentYear = 2026;
  final int _currentMonth = 7; // July 2026
  final bool _isLoading = false;
  bool _showSuccessBanner = false;
  Timer? _bannerTimer;

  final Map<int, DayJournal> _journalEntries = {};
  StreamSubscription<Map<String, DayJournal>>? _logSubscription;
  StreamSubscription<dynamic>? _authSubscription;

  CycleViewModel() {
    _initAuthAndFirestoreListener();
  }

  int get selectedDay => _selectedDay;
  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;
  bool get isLoading => _isLoading;
  bool get showSuccessBanner => _showSuccessBanner;
  Map<int, DayJournal> get journalEntries => Map.unmodifiable(_journalEntries);

  void setSelectedDay(int day) {
    if (_selectedDay != day) {
      _selectedDay = day;
      notifyListeners();
    }
  }

  void _initAuthAndFirestoreListener() {
    _authSubscription?.cancel();
    _authSubscription = AuthService.instance.authStateChanges.listen((user) {
      if (user == null) {
        _logSubscription?.cancel();
        _logSubscription = null;
        _journalEntries.clear();
        notifyListeners();
      } else {
        _subscribeToUserLogs(user.uid);
      }
    });
  }

  void _subscribeToUserLogs(String uid) {
    _logSubscription?.cancel();
    _logSubscription = CycleService.instance
        .streamCycleLogs(uid)
        .listen((dateKeyMap) {
      final monthPrefix = '$_currentYear-${_currentMonth.toString().padLeft(2, '0')}';
      bool updated = false;

      dateKeyMap.forEach((dateKey, journal) {
        if (dateKey.startsWith(monthPrefix)) {
          final parts = dateKey.split('-');
          if (parts.length == 3) {
            final day = int.tryParse(parts[2]);
            if (day != null) {
              _journalEntries[day] = journal;
              updated = true;
            }
          }
        }
      });

      if (updated) {
        notifyListeners();
      }
    }, onError: (error) {
      Helpers.log('CycleViewModel Firestore stream error: $error');
    });
  }

  Future<void> saveLog(int day, DayJournal journal) async {
    _journalEntries[day] = journal;
    _showSuccessBanner = true;
    notifyListeners();

    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      _showSuccessBanner = false;
      notifyListeners();
    });

    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        final dateKey = CycleService.instance.formatDateKey(_currentYear, _currentMonth, day);
        await CycleService.instance.saveDailyLog(
          uid: user.uid,
          dateKey: dateKey,
          journal: journal,
          dayNumber: day,
        );
      } catch (e) {
        Helpers.log('Error in CycleViewModel.saveLog: $e');
      }
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _logSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
