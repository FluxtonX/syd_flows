import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_service.dart';

enum AuthState { signIn, signUp, resetPassword }

class AuthViewModel extends ChangeNotifier {
  AuthState _currentState = AuthState.signIn;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  AuthState get currentState => _currentState;
  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get obscurePassword => _obscurePassword;
  String? get errorMessage => _errorMessage;

  void setAuthState(AuthState state) {
    if (_currentState != state) {
      _currentState = state;
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      _obscurePassword = true;
      _isLoading = false;
      _isGoogleLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void setGoogleLoading(bool val) {
    _isGoogleLoading = val;
    notifyListeners();
  }

  void setErrorMessage(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  Future<String> getNextRoute() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return RouteNames.auth;
    final hasCompleted = await UserService.instance.hasUserCompletedSetup(user.uid);
    return hasCompleted ? RouteNames.home : RouteNames.setupFlow;
  }

  Future<bool> handleSignIn() async {
    _errorMessage = null;
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setErrorMessage('Please fill in all required fields');
      return false;
    }

    setLoading(true);
    try {
      final credential = await AuthService.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await UserService.instance.saveUserProfile(credential.user!);
        setLoading(false);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      setErrorMessage(_getReadableAuthError(e.code));
    } catch (e) {
      setErrorMessage('An unexpected error occurred. Please try again.');
    } finally {
      setLoading(false);
    }
    return false;
  }

  Future<bool> handleSignUp() async {
    _errorMessage = null;
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setErrorMessage('Please complete all fields');
      return false;
    }

    if (password.length < 6) {
      setErrorMessage('Password must be at least 6 characters');
      return false;
    }

    setLoading(true);
    try {
      final credential = await AuthService.instance.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );

      if (credential.user != null) {
        await UserService.instance.saveUserProfile(
          credential.user!,
          displayName: name,
        );
        setLoading(false);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      setErrorMessage(_getReadableAuthError(e.code));
    } catch (e) {
      setErrorMessage('An unexpected error occurred. Please try again.');
    } finally {
      setLoading(false);
    }
    return false;
  }

  Future<bool> handleGoogleSignIn() async {
    _errorMessage = null;
    setGoogleLoading(true);
    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential?.user != null) {
        await UserService.instance.saveUserProfile(credential!.user!);
        setGoogleLoading(false);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      setErrorMessage(_getReadableAuthError(e.code));
    } catch (e) {
      setErrorMessage('Google Sign-In failed. Please try again.');
    } finally {
      setGoogleLoading(false);
    }
    return false;
  }

  Future<bool> handleResetPassword() async {
    _errorMessage = null;
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setErrorMessage('Please enter your email address');
      return false;
    }

    setLoading(true);
    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      setErrorMessage(_getReadableAuthError(e.code));
    } catch (e) {
      setErrorMessage('Failed to send reset link. Please check your email.');
    } finally {
      setLoading(false);
    }
    return false;
  }

  String _getReadableAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Choose a stronger password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

