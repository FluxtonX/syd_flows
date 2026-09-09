/* ─────────────────────────────────────────────────────────────
   Hook – useAuth
   Manages Firestore-based admin authentication with session persistence.
   ───────────────────────────────────────────────────────────── */
import { useState, useEffect, useCallback } from 'react';
import {
  signInWithEmail,
  signOutUser,
  onAuthStateChange,
  registerFirstAdminAccount,
  checkIfAdminInitialized,
  updateAdminPassword,
} from '@/services/firebase/auth';
import type { AuthUser, AdminStatus } from '@/types';

interface UseAuthReturn {
  user: AuthUser | null;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  setupFirstAdmin: (email: string, password: string, displayName: string) => Promise<void>;
  changePassword: (email: string, currentPass: string, newPass: string) => Promise<void>;
  logout: () => Promise<void>;
  clearError: () => void;
  checkAdminStatus: () => Promise<AdminStatus>;
}

export function useAuth(): UseAuthReturn {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChange((adminUser) => {
      setUser(adminUser);
      setIsLoading(false);
    });

    return unsubscribe;
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    setError(null);
    setIsLoading(true);
    try {
      const authUser = await signInWithEmail(email, password);
      setUser(authUser);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Login failed. Please try again.';
      setError(message);
      throw new Error(message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const setupFirstAdmin = useCallback(
    async (email: string, password: string, displayName: string) => {
      setError(null);
      setIsLoading(true);
      try {
        const adminUser = await registerFirstAdminAccount(email, password, displayName);
        setUser(adminUser);
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Admin setup failed. Please try again.';
        setError(message);
        throw new Error(message);
      } finally {
        setIsLoading(false);
      }
    },
    [],
  );

  const changePassword = useCallback(
    async (email: string, currentPass: string, newPass: string) => {
      setError(null);
      setIsLoading(true);
      try {
        await updateAdminPassword(email, currentPass, newPass);
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Failed to update password.';
        setError(message);
        throw new Error(message);
      } finally {
        setIsLoading(false);
      }
    },
    [],
  );

  const logout = useCallback(async () => {
    setError(null);
    try {
      await signOutUser();
      setUser(null);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Logout failed. Please try again.');
    }
  }, []);

  const clearError = useCallback(() => setError(null), []);

  const checkAdminStatus = useCallback(async () => {
    return await checkIfAdminInitialized();
  }, []);

  return {
    user,
    isLoading,
    error,
    login,
    setupFirstAdmin,
    changePassword,
    logout,
    clearError,
    checkAdminStatus,
  };
}
