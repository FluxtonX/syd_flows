/* ─────────────────────────────────────────────────────────────
   App Root Component
   ───────────────────────────────────────────────────────────── */
import { ErrorBoundary } from '@/components/ui/ErrorBoundary/ErrorBoundary';
import { ConfigErrorPage } from '@/pages/ConfigError/ConfigErrorPage';
import { AppRouter } from '@/routes/AppRouter';
import { isFirebaseConfigured } from '@/services/firebase/config';
import { ThemeProvider } from '@/hooks/useTheme';

export default function App() {
  // Show setup instructions if env vars are missing
  if (!isFirebaseConfigured) {
    return <ConfigErrorPage />;
  }

  return (
    <ErrorBoundary>
      <ThemeProvider>
        <AppRouter />
      </ThemeProvider>
    </ErrorBoundary>
  );
}
