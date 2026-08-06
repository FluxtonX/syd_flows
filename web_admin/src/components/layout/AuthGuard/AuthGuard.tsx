/* ─────────────────────────────────────────────────────────────
   AuthGuard – Redirects unauthenticated users to /login
   ───────────────────────────────────────────────────────────── */
import type { ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { ROUTES } from '@/constants';
import { Spinner } from '@/components/ui/Spinner/Spinner';

interface AuthGuardProps {
  children: ReactNode;
}

export function AuthGuard({ children }: AuthGuardProps) {
  const { user, isLoading } = useAuth();
  const location = useLocation();

  // Wait for auth state to resolve before redirecting
  if (isLoading) {
    return (
      <div
        style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <Spinner size="lg" label="Loading..." />
      </div>
    );
  }

  if (!user) {
    // Preserve the attempted URL so we can redirect back after login
    return <Navigate to={ROUTES.LOGIN} state={{ from: location }} replace />;
  }

  return <>{children}</>;
}
