/* ─────────────────────────────────────────────────────────────
   ErrorBoundary – Catches unexpected React render errors
   ───────────────────────────────────────────────────────────── */
import { Component, type ReactNode, type ErrorInfo } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('[ErrorBoundary] Uncaught error:', error, info);
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) return this.props.fallback;

      return (
        <div style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexDirection: 'column',
          gap: '16px',
          background: '#090d16',
          color: '#f9fafb',
          fontFamily: 'Inter, system-ui, sans-serif',
          padding: '32px',
          textAlign: 'center',
        }}>
          <div style={{
            width: 56,
            height: 56,
            background: 'rgba(239,68,68,0.15)',
            border: '1px solid rgba(239,68,68,0.4)',
            borderRadius: 16,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 24,
          }}>⚠</div>
          <h1 style={{ fontSize: 22, fontWeight: 700, margin: 0 }}>
            Something went wrong
          </h1>
          <p style={{ color: '#9ca3af', maxWidth: 400, lineHeight: 1.6, margin: 0 }}>
            {this.state.error?.message ?? 'An unexpected error occurred.'}
          </p>
          <button
            onClick={() => window.location.reload()}
            style={{
              marginTop: 8,
              padding: '10px 24px',
              background: 'linear-gradient(135deg, #6366f1, #ec4899)',
              border: 'none',
              borderRadius: 10,
              color: '#fff',
              fontWeight: 600,
              fontSize: 14,
              cursor: 'pointer',
            }}
          >
            Reload Page
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
