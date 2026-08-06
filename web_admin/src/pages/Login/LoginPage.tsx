/* ─────────────────────────────────────────────────────────────
   Login Page
   ───────────────────────────────────────────────────────────── */
import { useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useAuth } from '@/hooks/useAuth';
import { loginSchema, type LoginFormValues } from '@/utils/validators';
import { Input } from '@/components/ui/Input/Input';
import { Button } from '@/components/ui/Button/Button';
import { ROUTES } from '@/constants';
import logoImg from '@/assets/images/Logo.png';
import workoutVideo from '@/assets/video/Ultimate 10 Minute Yoga Stretch for Stress Relief _ Relaxation & Renewal.mp4';
import styles from './LoginPage.module.css';

export function LoginPage() {
  const { user, login, isLoading, error, clearError } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  // Redirect if already authenticated
  useEffect(() => {
    if (user) {
      const from = (location.state as { from?: { pathname: string } })?.from?.pathname;
      navigate(from ?? ROUTES.DASHBOARD, { replace: true });
    }
  }, [user, navigate, location.state]);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (data: LoginFormValues) => {
    clearError();
    try {
      await login(data.email, data.password);
    } catch {
      // Error is surfaced via useAuth `error` state
    }
  };

  return (
    <div className={styles.page}>
      {/* ── Left branding panel with Ambient Workout Video ── */}
      <aside className={styles.panel} aria-hidden="true">
        <video
          autoPlay
          loop
          muted
          playsInline
          className={styles.bgVideo}
          src={workoutVideo}
        />
        <div className={styles.videoOverlay} />

        <div className={styles.panelContent}>
          <div className={styles.logoMark}>
            <img src={logoImg} alt="SYD FLOWS Logo" className={styles.logoImg} />
          </div>
          <h1 className={styles.appName}>SYD FLOWS</h1>
          <p className={styles.tagline}>
            The all-in-one admin portal for managing your workout video library.
          </p>

          <div className={styles.videoBadge}>
            <span className={styles.livePulse} />
            <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <polygon points="5 3 19 12 5 21 5 3" />
            </svg>
            <span>Previewing Workout Library</span>
          </div>

          <ul className={styles.featureList}>
            <li className={styles.featureItem}>
              <span className={styles.featureDot} />
              Upload workout videos to secure cloud storage
            </li>
            <li className={styles.featureItem}>
              <span className={styles.featureDot} />
              Save metadata directly to Firestore
            </li>
            <li className={styles.featureItem}>
              <span className={styles.featureDot} />
              Manage thumbnails and video previews
            </li>
            <li className={styles.featureItem}>
              <span className={styles.featureDot} />
              Track your full video library
            </li>
          </ul>
        </div>
      </aside>

      {/* ── Right form area ── */}
      <section className={styles.formArea}>
        <div className={styles.formCard}>
          <div className={styles.formHeader}>
            <h2 className={styles.formTitle}>Welcome back</h2>
            <p className={styles.formSubtitle}>Sign in to your admin account to continue.</p>
          </div>

          {/* Global auth error banner */}
          {error && (
            <div className={styles.errorBanner} role="alert">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true" style={{ flexShrink: 0, marginTop: 1 }}>
                <circle cx="12" cy="12" r="10" />
                <line x1="12" y1="8" x2="12" y2="12" />
                <line x1="12" y1="16" x2="12.01" y2="16" />
              </svg>
              {error}
            </div>
          )}

          <form
            id="login-form"
            className={styles.form}
            onSubmit={handleSubmit(onSubmit)}
            noValidate
          >
            <Input
              label="Email address"
              type="email"
              placeholder="admin@sydflows.com"
              autoComplete="email"
              required
              error={errors.email?.message}
              {...register('email')}
            />

            <Input
              label="Password"
              type="password"
              placeholder="Enter your password"
              autoComplete="current-password"
              required
              error={errors.password?.message}
              {...register('password')}
            />

            <Button
              id="login-submit-btn"
              type="submit"
              fullWidth
              isLoading={isSubmitting || isLoading}
              className={styles.submitBtn}
            >
              Sign In
            </Button>
          </form>

          <p className={styles.footer}>
            SYD FLOWS Web Admin v1 · Authorized access only
          </p>
        </div>
      </section>
    </div>
  );
}
