import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/helpers.dart';

class EditProfileViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();

  int _cycleLength = 28;
  int _periodLength = 5;
  String _fitnessLevel = 'Intermediate';
  final List<String> _selectedGoals = [];
  bool _isLoading = false;
  bool _isFetching = true;
  String? _errorMessage;

  int get cycleLength => _cycleLength;
  int get periodLength => _periodLength;
  String get fitnessLevel => _fitnessLevel;
  List<String> get selectedGoals => List.unmodifiable(_selectedGoals);
  bool get isLoading => _isLoading;
  bool get isFetching => _isFetching;
  String? get errorMessage => _errorMessage;

  EditProfileViewModel() {
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _isFetching = false;
      notifyListeners();
      return;
    }

    try {
      nameController.text = user.displayName ?? '';
      final docSnap = await UserService.instance.getUserProfileStream(user.uid).first;
      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        final rawName = data['displayName'] as String?;
        if (rawName != null && rawName.isNotEmpty) {
          nameController.text = rawName;
        }
        if (data['setupFlow'] is Map) {
          final setup = data['setupFlow'] as Map<String, dynamic>;
          _cycleLength = (setup['cycleLength'] as num?)?.toInt() ?? 28;
          _periodLength = (setup['periodLength'] as num?)?.toInt() ?? 5;
          _fitnessLevel = (setup['fitnessLevel'] as String?) ?? 'Intermediate';
          if (setup['selectedGoals'] is List) {
            _selectedGoals.clear();
            _selectedGoals.addAll(List<String>.from(setup['selectedGoals']));
          }
        }
      }
    } catch (e) {
      Helpers.log('Error loading profile data: $e');
    } finally {
      _isFetching = false;
      notifyListeners();
    }
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

  Future<bool> saveProfile() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _errorMessage = 'Name cannot be empty';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await UserService.instance.updateUserProfileAndPreferences(
          uid: user.uid,
          displayName: name,
          cycleLength: _cycleLength,
          periodLength: _periodLength,
          fitnessLevel: _fitnessLevel,
          selectedGoals: _selectedGoals,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to save changes. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
