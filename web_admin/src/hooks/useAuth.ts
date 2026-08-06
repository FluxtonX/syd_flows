/* ─────────────────────────────────────────────────────────────
   Hook – useAuth
   Manages Firebase auth state with session persistence.
   Only the admin email (VITE_ADMIN_EMAIL) is allowed to log in.
   Any other Firebase user is signed out immediately.
   ───────────────────────────────────────────────────────────── */
import { useState, useEffect, useCallback } from 'react';
import type { User } from 'firebase/auth';
import { signInWithEmail, signOutUser, onAuthStateChange } from '@/services/firebase/auth';
import type { AuthUser } from '@/types';

interface UseAuthReturn {
  user: AuthUser | null;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  clearError: () => void;
}

/** The single allowed admin email — set in VITE_ADMIN_EMAIL env var */
const ADMIN_EMAIL = import.meta.env.VITE_ADMIN_EMAIL as string | undefined;

function mapFirebaseUser(user: User): AuthUser {
  return {
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
  };
}

/**
 * Check if a Firebase user is the allowed admin.
 * If VITE_ADMIN_EMAIL is not set, allow any authenticated user (dev mode).
 */
function isAdminUser(firebaseUser: User): boolean {
  if (!ADMIN_EMAIL || ADMIN_EMAIL.trim() === '') return true; // No whitelist set → allow all
  return firebaseUser.email?.toLowerCase() === ADMIN_EMAIL.toLowerCase();
}

export function useAuth(): UseAuthReturn {
  const [user, setUser] = useState<AuthUser | null>(null);
  // Start as true so the AuthGuard shows a spinner while Firebase resolves auth state.
  // onAuthStateChange calls back immediately (even with null), so this clears fast.
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Subscribe to Firebase auth state on mount
  useEffect(() => {
    const unsubscribe = onAuthStateChange(async (firebaseUser) => {
      if (firebaseUser) {
        if (isAdminUser(firebaseUser)) {
          // ✅ Authorized admin
          setUser(mapFirebaseUser(firebaseUser));
        } else {
          // 🚫 Not the admin — sign them out silently
          setUser(null);
          setError('Access denied. This panel is restricted to the admin account.');
          await signOutUser();
        }
      } else {
        setUser(null);
      }
      setIsLoading(false);
    });

    return unsubscribe; // cleanup on unmount
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    setError(null);
    setIsLoading(true);
    try {
      // Pre-check: reject immediately if the email isn't the admin email
      if (ADMIN_EMAIL && ADMIN_EMAIL.trim() !== '' && email.toLowerCase() !== ADMIN_EMAIL.toLowerCase()) {
        throw new Error('Access denied. Only the admin account can log in.');
      }
      await signInWithEmail(email, password);
      // auth state listener will update `user`
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Login failed. Please try again.';
      setError(message);
      throw new Error(message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const logout = useCallback(async () => {
    setError(null);
    try {
      await signOutUser();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Logout failed. Please try again.');
    }
  }, []);

  const clearError = useCallback(() => setError(null), []);

  return { user, isLoading, error, login, logout, clearError };
}
