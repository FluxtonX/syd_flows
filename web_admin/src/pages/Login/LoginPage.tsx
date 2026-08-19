/* ─────────────────────────────────────────────────────────────
   Login Page
   ───────────────────────────────────────────────────────────── */
import { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useAuth } from '@/hooks/useAuth';
import { loginSchema, type LoginFormValues } from '@/utils/validators';
import { Input } from '@/components/ui/Input/Input';
import { Button } from '@/components/ui/Button/Button';
import { ROUTES } from '@/constants';
import logoImg from '@/assets/images/web_logo.jpeg';
import workoutVideo from '@/assets/video/Ultimate 10 Minute Yoga Stretch for Stress Relief _ Relaxation & Renewal.mp4';
import styles from './LoginPage.module.css';

export function LoginPage() {
  const { user, login, isLoading, error, clearError } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [showPassword, setShowPassword] = useState(false);

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
    setValue,
    getValues,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
  });

  const handleFillCredentials = () => {
    setValue('email', 'admin@sydflows.com', { shouldValidate: true, shouldTouch: true });
    setValue('password', 'SydFlows111', { shouldValidate: true, shouldTouch: true });
  };

  const handleEmailClickOrFocus = () => {
    if (!getValues('email')) {
      setValue('email', 'admin@sydflows.com', { shouldValidate: true, shouldTouch: true });
    }
  };

  const handlePasswordClickOrFocus = () => {
    if (!getValues('password')) {
      setValue('password', 'SydFlows111', { shouldValidate: true, shouldTouch: true });
    }
  };

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
              onClick={handleEmailClickOrFocus}
              onFocus={handleEmailClickOrFocus}
            />

            <Input
              label="Password"
              type={showPassword ? 'text' : 'password'}
              placeholder="Enter your password"
              autoComplete="current-password"
              required
              error={errors.password?.message}
              {...register('password')}
              onClick={handlePasswordClickOrFocus}
              onFocus={handlePasswordClickOrFocus}
              rightElement={
                <button
                  type="button"
                  id="toggle-password-visibility-btn"
                  className={styles.eyeToggleBtn}
                  onClick={(e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    setShowPassword((prev) => !prev);
                  }}
                  title={showPassword ? 'Hide password' : 'Show password'}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" />
                      <line x1="1" y1="1" x2="23" y2="23" />
                    </svg>
                  ) : (
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                      <circle cx="12" cy="12" r="3" />
                    </svg>
                  )}
                </button>
              }
            />

            <button
              type="button"
              id="quick-fill-admin-btn"
              className={styles.quickFillBtn}
              onClick={handleFillCredentials}
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
              </svg>
              <span>Auto-fill Admin Credentials</span>
            </button>

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
