/* ─────────────────────────────────────────────────────────────
   Firebase – Authentication Service
   ───────────────────────────────────────────────────────────── */
import {
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  type User,
  type Unsubscribe,
} from 'firebase/auth';
import { auth } from './config';

/**
 * Sign in with email and password.
 * Throws a typed error message for common Firebase auth errors.
 */
export async function signInWithEmail(email: string, password: string): Promise<User> {
  if (!auth) throw new Error('Firebase is not configured. Please set up your .env file.');
  try {
    const credential = await signInWithEmailAndPassword(auth, email, password);
    return credential.user;
  } catch (error: unknown) {
    throw new Error(getAuthErrorMessage(error));
  }
}

/**
 * Sign out the current user.
 */
export async function signOutUser(): Promise<void> {
  if (!auth) return;
  try {
    await signOut(auth);
  } catch {
    throw new Error('Failed to sign out. Please try again.');
  }
}

/**
 * Subscribe to auth state changes.
 * Returns an unsubscribe function. No-ops if Firebase is not configured.
 */
export function onAuthStateChange(callback: (user: User | null) => void): Unsubscribe {
  if (!auth) {
    // Immediately call with null and return a no-op unsubscriber
    callback(null);
    return () => undefined;
  }
  return onAuthStateChanged(auth, callback);
}

/** Maps Firebase auth error codes to user-friendly messages */
function getAuthErrorMessage(error: unknown): string {
  if (typeof error === 'object' && error !== null && 'code' in error) {
    const code = (error as { code: string }).code;
    switch (code) {
      case 'auth/user-not-found':
      case 'auth/wrong-password':
      case 'auth/invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'auth/invalid-email':
        return 'Please enter a valid email address.';
      case 'auth/too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'auth/network-request-failed':
        return 'Network error. Please check your connection.';
      case 'auth/user-disabled':
        return 'This account has been disabled. Please contact support.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
  return 'An unexpected error occurred. Please try again.';
}
