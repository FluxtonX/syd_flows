import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/helpers.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign In with Email & Password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      Helpers.log('Firebase Auth Error (SignIn): ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      Helpers.log('Auth Error (SignIn): $e');
      rethrow;
    }
  }

  // Sign Up with Email & Password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (credential.user != null && name.trim().isNotEmpty) {
        await credential.user!.updateDisplayName(name.trim());
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      Helpers.log('Firebase Auth Error (SignUp): ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      Helpers.log('Auth Error (SignUp): $e');
      rethrow;
    }
  }

  // Sign In with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Force account selection dialog by signing out any previous local google session first
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Helpers.log('Firebase Auth Error (Google): ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      Helpers.log('Auth Error (Google): $e');
      rethrow;
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      Helpers.log('Firebase Auth Error (Reset): ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      Helpers.log('Auth Error (Reset): $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      Helpers.log('Google sign-out cleanup ignored: $e');
    }
    await _auth.signOut();
  }
}
