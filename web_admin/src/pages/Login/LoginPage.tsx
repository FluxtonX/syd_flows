/* ─────────────────────────────────────────────────────────────
   SYD FLOWS – Admin Login & Password Management
   ───────────────────────────────────────────────────────────── */
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { Input } from '@/components/ui/Input/Input';
import { Button } from '@/components/ui/Button/Button';
import { ROUTES } from '@/constants';
import type { AdminStatus } from '@/types';
import logoImg from '@/assets/images/web_logo.jpeg';
import workoutVideo from '@/assets/video/Ultimate 10 Minute Yoga Stretch for Stress Relief _ Relaxation & Renewal.mp4';
import styles from './LoginPage.module.css';

export function LoginPage() {
  const { user, login, setupFirstAdmin, changePassword, checkAdminStatus, isLoading, error, clearError } = useAuth();
  const navigate = useNavigate();

  // Mode: 'login' | 'register' | 'change-password'
  const [mode, setMode] = useState<'login' | 'register' | 'change-password'>('login');
  const [adminStatus, setAdminStatus] = useState<AdminStatus | null>(null);

  // Sign in form state
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  // Register form state
  const [registerName, setRegisterName] = useState('SYD FLOWS');
  const [registerEmail, setRegisterEmail] = useState('');
  const [registerPassword, setRegisterPassword] = useState('');
  const [registerConfirmPassword, setRegisterConfirmPassword] = useState('');
  const [showRegisterPassword, setShowRegisterPassword] = useState(false);
  const [showRegisterConfirmPassword, setShowRegisterConfirmPassword] = useState(false);

  // Change password form state
  const [changeEmail, setChangeEmail] = useState('');
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmNewPassword, setConfirmNewPassword] = useState('');
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmNewPassword, setShowConfirmNewPassword] = useState(false);

  // Feedback states
  const [formError, setFormError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Check admin registration status on mount and mode switch
  useEffect(() => {
    checkAdminStatus()
      .then((status) => {
        setAdminStatus(status);
        if (status.adminEmail && !email && !changeEmail && !registerEmail) {
          setEmail(status.adminEmail);
          setChangeEmail(status.adminEmail);
          setRegisterEmail(status.adminEmail);
        }
      })
      .catch(() => { });
  }, [checkAdminStatus, mode]);

  // Redirect to Dashboard when authenticated
  useEffect(() => {
    if (user) {
      navigate(ROUTES.DASHBOARD, { replace: true });
    }
  }, [user, navigate]);

  const handleLoginSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    setFormError(null);
    setSuccessMessage(null);

    if (!email.trim() || !password.trim()) {
      setFormError('Please enter both admin email and password.');
      return;
    }

    setSubmitting(true);
    try {
      await login(email.trim(), password);
    } catch {
      // Error is caught and surfaced by useAuth
    } finally {
      setSubmitting(false);
    }
  };

  const handleRegisterSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    setFormError(null);
    setSuccessMessage(null);

    if (!registerName.trim()) {
      setFormError('Please enter the administrator name.');
      return;
    }
    if (!registerEmail.trim()) {
      setFormError('Please enter your admin email address.');
      return;
    }
    if (registerPassword.length < 6) {
      setFormError('Password must be at least 6 characters.');
      return;
    }
    if (registerPassword !== registerConfirmPassword) {
      setFormError('Passwords do not match. Please verify.');
      return;
    }

    setSubmitting(true);
    try {
      await setupFirstAdmin(registerEmail.trim(), registerPassword, registerName.trim());
      setSuccessMessage('Admin account saved successfully! Signing in...');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Registration failed. Please try again.';
      setFormError(msg);
    } finally {
      setSubmitting(false);
    }
  };

  const handleChangePasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    setFormError(null);
    setSuccessMessage(null);

    if (!changeEmail.trim()) {
      setFormError('Please enter your admin email address.');
      return;
    }
    if (newPassword.length < 6) {
      setFormError('New password must be at least 6 characters.');
      return;
    }
    if (newPassword !== confirmNewPassword) {
      setFormError('New passwords do not match. Please verify.');
      return;
    }

    setSubmitting(true);
    try {
      await changePassword(changeEmail.trim(), currentPassword, newPassword);
      setSuccessMessage('Admin password updated successfully in Firestore! You can now sign in.');
      setEmail(changeEmail.trim());
      setPassword(newPassword);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmNewPassword('');
      setMode('login');
    } catch {
      // Error handled by useAuth
    } finally {
      setSubmitting(false);
    }
  };

  const activeError = formError || error;

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
              Manage subscriptions, plans and pricing
            </li>
            <li className={styles.featureItem}>
              <span className={styles.featureDot} />
              Approve subscriber requests in real-time
            </li>
          </ul>
        </div>
      </aside>

      {/* ── Right form area ── */}
      <section className={styles.formArea}>
        <div className={styles.formCard}>
          <div className={styles.formHeader}>
            <h2 className={styles.formTitle}>
              {mode === 'login'
                ? 'Admin Portal'
                : mode === 'register'
                  ? 'Create Admin Account'
                  : 'Update / Reset Password'}
            </h2>
            <p className={styles.formSubtitle}>
              {mode === 'login'
                ? 'Sign in with your SYD FLOWS admin credentials to continue.'
                : mode === 'register'
                  ? 'Set up an authorized administrator account to manage SYD FLOWS.'
                  : 'Enter your admin email and set your new password directly.'}
            </p>
          </div>

          {/* Success Banner */}
          {successMessage && (
            <div className={styles.successBanner} role="status">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" style={{ flexShrink: 0, marginTop: 1 }}>
                <path d="M20 6L9 17l-5-5" />
              </svg>
              <span>{successMessage}</span>
            </div>
          )}

          {/* Error Banner */}
          {activeError && (
            <div className={styles.errorBanner} role="alert">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true" style={{ flexShrink: 0, marginTop: 1 }}>
                <circle cx="12" cy="12" r="10" />
                <line x1="12" y1="8" x2="12" y2="12" />
                <line x1="12" y1="16" x2="12.01" y2="16" />
              </svg>
              <span>{activeError}</span>
            </div>
          )}

          {/* Mode 1: Sign In Form */}
          {mode === 'login' && (
            <form id="login-form" className={styles.form} onSubmit={handleLoginSubmit} autoComplete="off" noValidate>
              <Input
                label="Admin Email address"
                type="email"
                name="admin_login_email_clean"
                placeholder="admin@sydflows.com"
                autoComplete="off"
                data-lpignore="true"
                data-form-type="other"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />

              <Input
                label="Password"
                type={showPassword ? 'text' : 'password'}
                name="admin_login_pwd_clean"
                placeholder="Enter your password"
                autoComplete="new-password"
                data-lpignore="true"
                data-form-type="other"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                rightElement={
                  <button
                    type="button"
                    className={styles.eyeToggleBtn}
                    onClick={() => setShowPassword((prev) => !prev)}
                    title={showPassword ? 'Hide password' : 'Show password'}
                  >
                    {showPassword ? (
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" />
                        <line x1="1" y1="1" x2="23" y2="23" />
                      </svg>
                    ) : (
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                        <circle cx="12" cy="12" r="3" />
                      </svg>
                    )}
                  </button>
                }
              />

              <div className={styles.actionLinksRow}>
                <button
                  type="button"
                  className={styles.createAccountLinkBtn}
                  onClick={() => {
                    setRegisterName('SYD FLOWS');
                    setRegisterEmail(email || 'admin@sydflows.com');
                    setRegisterPassword('');
                    setRegisterConfirmPassword('');
                    setMode('register');
                    clearError();
                    setFormError(null);
                    setSuccessMessage(null);
                  }}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <line x1="12" y1="5" x2="12" y2="19" />
                    <line x1="5" y1="12" x2="19" y2="12" />
                  </svg>
                  <span>Create Admin Account</span>
                </button>

                <button
                  type="button"
                  className={styles.forgotPasswordBtn}
                  onClick={() => {
                    setChangeEmail(email || 'admin@sydflows.com');
                    setNewPassword('');
                    setConfirmNewPassword('');
                    setMode('change-password');
                    clearError();
                    setFormError(null);
                    setSuccessMessage(null);
                  }}
                >
                  Forgot or Change Password?
                </button>
              </div>

              <Button
                type="submit"
                fullWidth
                isLoading={submitting || isLoading}
                className={styles.submitBtn}
              >
                Sign In to Admin Portal
              </Button>
            </form>
          )}

          {/* Mode 2: Register Form */}
          {mode === 'register' && (
            adminStatus !== null && !adminStatus.allowRegistration ? (
              <div className={styles.closedNoticeCard}>
                <div className={styles.closedNoticeIcon}>
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                    <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                  </svg>
                </div>
                <p className={styles.closedNoticeText}>
                  Admin registration is closed. You can update existing credentials via "Forgot or Change Password".
                </p>
                <Button
                  type="button"
                  onClick={() => {
                    setMode('login');
                    clearError();
                    setFormError(null);
                  }}
                >
                  Back to Sign In
                </Button>
              </div>
            ) : (
              <form id="register-form" className={styles.form} onSubmit={handleRegisterSubmit} autoComplete="off" noValidate>
                <Input
                  label="Administrator Name / Organization"
                  type="text"
                  name="admin_register_name"
                  placeholder="e.g. SYD FLOWS"
                  autoComplete="name"
                  required
                  value={registerName}
                  onChange={(e) => setRegisterName(e.target.value)}
                />

                <Input
                  label="Admin Email address"
                  type="email"
                  name="admin_register_email"
                  placeholder="admin@sydflows.com"
                  autoComplete="off"
                  data-lpignore="true"
                  data-form-type="other"
                  required
                  value={registerEmail}
                  onChange={(e) => setRegisterEmail(e.target.value)}
                />

                <Input
                  label="Password (min 6 characters)"
                  type={showRegisterPassword ? 'text' : 'password'}
                  name="admin_register_password"
                  placeholder="Create password"
                  autoComplete="new-password"
                  data-lpignore="true"
                  data-form-type="other"
                  required
                  value={registerPassword}
                  onChange={(e) => setRegisterPassword(e.target.value)}
                  rightElement={
                    <button
                      type="button"
                      className={styles.eyeToggleBtn}
                      onClick={() => setShowRegisterPassword((prev) => !prev)}
                      title={showRegisterPassword ? 'Hide password' : 'Show password'}
                    >
                      {showRegisterPassword ? (
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" />
                          <line x1="1" y1="1" x2="23" y2="23" />
                        </svg>
                      ) : (
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                          <circle cx="12" cy="12" r="3" />
                        </svg>
                      )}
                    </button>
                  }
                />

                <Input
                  label="Confirm Password"
                  type={showRegisterConfirmPassword ? 'text' : 'password'}
                  name="admin_register_confirm_password"
                  placeholder="Confirm password"
                  autoComplete="new-password"
                  data-lpignore="true"
                  data-form-type="other"
                  required
                  value={registerConfirmPassword}
                  onChange={(e) => setRegisterConfirmPassword(e.target.value)}
                  rightElement={
                    <button
                      type="button"
                      className={styles.eyeToggleBtn}
                      onClick={() => setShowRegisterConfirmPassword((prev) => !prev)}
                      title={showRegisterConfirmPassword ? 'Hide password' : 'Show password'}
                    >
                      {showRegisterConfirmPassword ? (
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" />
                          <line x1="1" y1="1" x2="23" y2="23" />
                        </svg>
                      ) : (
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                          <circle cx="12" cy="12" r="3" />
                        </svg>
                      )}
                    </button>
                  }
                />

                <Button
                  type="submit"
                  fullWidth
                  isLoading={submitting || isLoading}
                  className={styles.submitBtn}
                >
                  Create Admin Account
                </Button>

                <div style={{ textAlign: 'center' }}>
                  <button
                    type="button"
                    className={styles.backToLoginBtn}
                    onClick={() => {
                      setMode('login');
                      clearError();
                      setFormError(null);
                    }}
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                      <line x1="19" y1="12" x2="5" y2="12" />
                      <polyline points="12 19 5 12 12 5" />
                    </svg>
                    <span>Already have an account? Sign In</span>
                  </button>
                </div>
              </form>
            )
          )}

          {/* Mode 3: Change / Reset Password Form */}
          {mode === 'change-password' && (
            <form id="change-password-form" className={styles.form} onSubmit={handleChangePasswordSubmit} autoComplete="off" noValidate>
              <Input
                label="Admin Email"
                type="email"
                name="admin_change_email_clean"
                placeholder="admin@sydflows.com"
                autoComplete="off"
                data-lpignore="true"
                data-form-type="other"
                required
                value={changeEmail}
                onChange={(e) => setChangeEmail(e.target.value)}
              />

              <Input
                label="Current Password"
                type={showCurrentPassword ? 'text' : 'password'}
                name="admin_current_pwd_clean"
                placeholder="Enter current password (if known)"
                autoComplete="current-password"
                data-lpignore="true"
                data-form-type="other"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                rightElement={
                  <button
                    type="button"
                    className={styles.eyeToggleBtn}
                    onClick={() => setShowCurrentPassword((prev) => !prev)}
                    title={showCurrentPassword ? 'Hide password' : 'Show password'}
                  >
                    {showCurrentPassword ? (
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" />
                        <line x1="1" y1="1" x2="23" y2="23" />
                      </svg>
                    ) : (
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                        <circle cx="12" cy="12" r="3" />
                      </svg>
                    )}
                  </button>
                }
              />

              <Input
                label="New Password (min 6 characters)"
                type={showNewPassword ? 'text' : 'password'}
                name="admin_new_pwd_clean"
                placeholder="Enter new password"
                autoComplete="new-password"
                data-lpignore="true"
                data-form-type="other"
                required
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                rightElement={
                  <button
                    type="button"
                    className={styles.eyeToggleBtn}
                    onClick={() => setShowNewPassword((prev) => !prev)}
                    title={showNewPassword ? 'Hide password' : 'Show password'}
                  >
                    {showNewPassword ? (
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" />
                        <line x1="1" y1="1" x2="23" y2="23" />
                      </svg>
                    ) : (
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                        <circle cx="12" cy="12" r="3" />
                      </svg>
                    )}
                  </button>
                }
              />

              <Input
                label="Confirm New Password"
                type={showConfirmNewPassword ? 'text' : 'password'}
                name="admin_confirm_new_pwd_clean"
                placeholder="Confirm new password"
                autoComplete="new-password"
                data-lpignore="true"
                data-form-type="other"
                required
                value={confirmNewPassword}
                onChange={(e) => setConfirmNewPassword(e.target.value)}
                rightElement={
                  <button
                    type="button"
                    className={styles.eyeToggleBtn}
                    onClick={() => setShowConfirmNewPassword((prev) => !prev)}
                    title={showConfirmNewPassword ? 'Hide password' : 'Show password'}
                  >
                    {showConfirmNewPassword ? (
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" />
                        <line x1="1" y1="1" x2="23" y2="23" />
                      </svg>
                    ) : (
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                        <circle cx="12" cy="12" r="3" />
                      </svg>
                    )}
                  </button>
                }
              />

              <Button
                type="submit"
                fullWidth
                isLoading={submitting || isLoading}
                className={styles.submitBtn}
              >
                Update Password
              </Button>

              <div style={{ textAlign: 'center' }}>
                <button
                  type="button"
                  className={styles.backToLoginBtn}
                  onClick={() => {
                    setEmail(changeEmail);
                    setPassword('');
                    setNewPassword('');
                    setConfirmNewPassword('');
                    setMode('login');
                    clearError();
                    setFormError(null);
                  }}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                    <line x1="19" y1="12" x2="5" y2="12" />
                    <polyline points="12 19 5 12 12 5" />
                  </svg>
                  <span>Back to Sign In</span>
                </button>
              </div>
            </form>
          )}

          <p className={styles.footer}>
            SYD FLOWS Web Admin · Authorized access only
          </p>
        </div>
      </section>
    </div>
  );
}
