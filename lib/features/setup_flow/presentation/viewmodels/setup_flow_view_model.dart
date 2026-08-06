import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_service.dart';


class SetupFlowViewModel extends ChangeNotifier {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: First Period
  DateTime _lastPeriodStart = DateTime(2026, 6, 30); // Default to June 30, 2026 as seen in Figma

  // Step 2: Cycle Length
  int _cycleLength = 28;

  // Step 3: Period Length
  int _periodLength = 5;

  // Step 4: Fitness Level
  String? _fitnessLevel;

  // Step 5: Goals
  final List<String> _selectedGoals = [];

  // Step 6: Equipment
  final List<String> _selectedEquipment = [];

  // Getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  DateTime get lastPeriodStart => _lastPeriodStart;
  int get cycleLength => _cycleLength;
  int get periodLength => _periodLength;
  String? get fitnessLevel => _fitnessLevel;
  List<String> get selectedGoals => _selectedGoals;
  List<String> get selectedEquipment => _selectedEquipment;

  double get progress => (_currentStep + 1) / 7.0;

  // Navigation methods
  Future<void> nextStep(VoidCallback onFinish) async {
    if (_currentStep < 6) {
      _currentStep++;
      notifyListeners();
    } else {
      await saveSetupData();
      onFinish();
    }
  }

  Future<void> saveSetupData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await UserService.instance.saveSetupFlowData(
          uid: user.uid,
          lastPeriodStart: _lastPeriodStart,
          cycleLength: _cycleLength,
          periodLength: _periodLength,
          fitnessLevel: _fitnessLevel ?? 'Intermediate',
          selectedGoals: _selectedGoals,
          selectedEquipment: _selectedEquipment,
        );
        await UserService.instance.sendWelcomeNotificationIfNeeded(
          user.uid,
          name: user.displayName,
        );
      }
    } catch (e) {
      // Log error but allow completing flow so app does not freeze
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }


  // Setters
  void setLastPeriodStart(DateTime date) {
    _lastPeriodStart = date;
    notifyListeners();
  }

  void setCycleLength(int length) {
    _cycleLength = length;
    notifyListeners();
  }

  void setPeriodLength(int length) {
    _periodLength = length;
    notifyListeners();
  }

  void setFitnessLevel(String level) {
    _fitnessLevel = level;
    notifyListeners();
  }

  void toggleGoal(String goal) {
    if (_selectedGoals.contains(goal)) {
      _selectedGoals.remove(goal);
    } else {
      _selectedGoals.add(goal);
    }
    notifyListeners();
  }

  void toggleEquipment(String item) {
    if (_selectedEquipment.contains(item)) {
      _selectedEquipment.remove(item);
    } else {
      _selectedEquipment.add(item);
    }
    notifyListeners();
  }
}
