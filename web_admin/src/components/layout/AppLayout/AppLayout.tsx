/* ─────────────────────────────────────────────────────────────
   AppLayout – Sidebar + Header Layout matching SYD FLOWS UI
   ───────────────────────────────────────────────────────────── */
import { useState, type ReactNode } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { ROUTES } from '@/constants';
import { ThemeToggle } from '@/components/ui/ThemeToggle/ThemeToggle';
import { ConfirmModal } from '@/components/ui/ConfirmModal/ConfirmModal';
import logoImg from '@/assets/images/web_logo.jpeg';
import styles from './AppLayout.module.css';

interface AppLayoutProps {
  children: ReactNode;
}

export function AppLayout({ children }: AppLayoutProps) {
  const { user, logout } = useAuth();
  const location = useLocation();
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

  const userInitial = user?.email ? user.email.charAt(0).toUpperCase() : 'A';
  const userDisplayName = user?.displayName || 'Admin';
  const userEmail = user?.email || 'admin@sydflows.com';
  const pageTitle = location.pathname === ROUTES.UPLOAD
    ? 'Upload workout'
    : location.pathname === ROUTES.VIDEOS
      ? 'Video library'
      : 'Overview';

  return (
    <div className={styles.layout}>
      {/* ── Sidebar Navigation ── */}
      <aside className={styles.sidebar} aria-label="Sidebar navigation">
        <div className={styles.sidebarTop}>
          <div className={styles.brand}>
            <div className={styles.logo}>
              <img src={logoImg} alt="SYD FLOWS Logo" className={styles.logoImg} />
            </div>
            <div className={styles.brandText}>
              <span className={styles.brandName}>SYD FLOWS</span>
              <span className={styles.brandTag}>Admin</span>
            </div>
          </div>

          <nav className={styles.navMenu} aria-label="Main menu">
            <NavLink
              to={ROUTES.DASHBOARD}
              className={({ isActive }) =>
                `${styles.navItem} ${isActive ? styles.navItemActive : ''}`
              }
              end
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <rect x="3" y="3" width="7" height="7" rx="1" />
                <rect x="14" y="3" width="7" height="7" rx="1" />
                <rect x="14" y="14" width="7" height="7" rx="1" />
                <rect x="3" y="14" width="7" height="7" rx="1" />
              </svg>
              <span>Dashboard</span>
            </NavLink>

            <NavLink
              to={ROUTES.UPLOAD}
              className={({ isActive }) =>
                `${styles.navItem} ${isActive ? styles.navItemActive : ''}`
              }
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                <polyline points="17 8 12 3 7 8" />
                <line x1="12" y1="3" x2="12" y2="15" />
              </svg>
              <span>Upload Video</span>
            </NavLink>

            <NavLink
              to={ROUTES.VIDEOS}
              className={({ isActive }) =>
                `${styles.navItem} ${isActive ? styles.navItemActive : ''}`
              }
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <rect x="3" y="4" width="18" height="16" rx="2" />
                <path d="M8 4v16M3 9h18" />
              </svg>
              <span>Video Library</span>
            </NavLink>
          </nav>
        </div>

        <div className={styles.sidebarBottom}>
          <button
            id="sidebar-logout-btn"
            className={styles.logoutBtn}
            onClick={() => setShowLogoutConfirm(true)}
            aria-label="Sign out"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
              <polyline points="16 17 21 12 16 7" />
              <line x1="21" y1="12" x2="9" y2="12" />
            </svg>
            <span>Sign Out</span>
          </button>
        </div>
      </aside>

      {/* ── Main Wrapper ── */}
      <div className={styles.mainWrapper}>
        {/* Top Header */}
        <header className={styles.topHeader}>
          <div className={styles.headerLeft}>
            {/* Context breadcrumb / back icon if on upload */}
            {location.pathname === ROUTES.UPLOAD && (
              <NavLink to={ROUTES.DASHBOARD} className={styles.backBtn} aria-label="Back to dashboard">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <line x1="19" y1="12" x2="5" y2="12" />
                  <polyline points="12 19 5 12 12 5" />
                </svg>
              </NavLink>
            )}
            <span className={styles.contextLabel}>{pageTitle}</span>
          </div>

          <div className={styles.headerRight}>
            <NavLink to={ROUTES.UPLOAD} className={styles.headerUploadLink}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                <path d="M12 5v14M5 12h14" />
              </svg>
              <span>New video</span>
            </NavLink>
            <ThemeToggle />
            <div className={styles.userPill}>
              <div className={styles.avatar}>{userInitial}</div>
              <div className={styles.userMeta}>
                <span className={styles.userName}>{userDisplayName}</span>
                <span className={styles.userEmail}>{userEmail}</span>
              </div>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={styles.userChevron}>
                <polyline points="6 9 12 15 18 9" />
              </svg>
            </div>
          </div>
        </header>

        {/* Main Content Area */}
        <main className={styles.main} id="main-content">
          {children}
          <footer className={styles.footer}>
            © {new Date().getFullYear()} SYD FLOWS. All rights reserved.
          </footer>
        </main>
      </div>

      {/* ── Sign Out Confirmation Modal ── */}
      <ConfirmModal
        isOpen={showLogoutConfirm}
        title="Sign Out Confirmation"
        message="Are you sure you want to sign out of the SYD FLOWS Admin Panel?"
        confirmLabel="Sign Out"
        cancelLabel="Cancel"
        confirmVariant="danger"
        icon={
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
            <polyline points="16 17 21 12 16 7" />
            <line x1="21" y1="12" x2="9" y2="12" />
          </svg>
        }
        onConfirm={() => {
          setShowLogoutConfirm(false);
          logout();
        }}
        onCancel={() => setShowLogoutConfirm(false)}
      />
    </div>
  );
}
