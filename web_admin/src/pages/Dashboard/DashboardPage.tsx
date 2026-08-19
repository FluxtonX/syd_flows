/* ─────────────────────────────────────────────────────────────
   Dashboard Page – Matching Screenshot 1 Layout & SYD FLOW Theme
   ───────────────────────────────────────────────────────────── */
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { getVideoCount } from '@/services/firebase/firestore';
import { Button } from '@/components/ui/Button/Button';
import { AppLayout } from '@/components/layout/AppLayout/AppLayout';
import { WorkoutVideosTable } from '@/components/ui/WorkoutVideosTable/WorkoutVideosTable';
import { ROUTES } from '@/constants';
import styles from './DashboardPage.module.css';

export function DashboardPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [videoCount, setVideoCount] = useState<number | null>(null);

  // Load total video count from Firestore
  useEffect(() => {
    getVideoCount().then(setVideoCount);
  }, []);

  const displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Admin';

  return (
    <AppLayout>
      <div className={styles.page}>
        {/* ── Welcome Header ── */}
        <section aria-label="Welcome section" className={styles.welcomeSection}>
          <div>
            <h1 className={styles.greeting}>
              Welcome back, {displayName} 👋
            </h1>
            <p className={styles.subtitle}>
              Your content workspace for SYD FLOWS.
            </p>
          </div>
        </section>

        {/* ── 3 Stat Cards (Matching Screenshot 1) ── */}
        <section aria-label="Statistics" className={styles.statsRow}>
          {/* Total Videos */}
          <div className={styles.statCard}>
            <div className={`${styles.statIcon} ${styles.statIconPurple}`}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <polygon points="23 7 16 12 23 17 23 7" />
                <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
              </svg>
            </div>
            <div className={styles.statMeta}>
              <span className={styles.statLabel}>Total Videos</span>
              <span className={styles.statValue}>
                {videoCount === null ? '—' : videoCount.toLocaleString()}
              </span>
              <span className={styles.statSubtext}>Uploaded</span>
            </div>
          </div>

          {/* Storage Capacity */}
          <div className={styles.statCard}>
            <div className={`${styles.statIcon} ${styles.statIconGreen}`}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z" />
              </svg>
            </div>
            <div className={styles.statMeta} style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <span className={styles.statLabel}>Cloud Storage</span>
                <span className={styles.statSubtextSuccess}>Active</span>
              </div>
              <span className={styles.statValue}>Media Storage</span>

              {/* Capacity Progress Bar */}
              <div className={styles.storageBarTrack} title="Cloud Storage Capacity (25 GB Allotted)">
                <div
                  className={styles.storageBarFill}
                  style={{ width: `${Math.min(100, Math.max(4, ((videoCount ?? 1) * 0.15 / 25) * 100))}%` }}
                />
              </div>

              <div className={styles.storageUsageDetails}>
                <span>{((videoCount ?? 1) * 0.15).toFixed(1)} GB used</span>
                <span style={{ fontWeight: 600, color: 'var(--color-text-primary)' }}>
                  {(25 - ((videoCount ?? 1) * 0.15)).toFixed(1)} GB remaining
                </span>
              </div>
            </div>
          </div>

          {/* Status */}
          <div className={styles.statCard}>
            <div className={`${styles.statIcon} ${styles.statIconOrange}`}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
              </svg>
            </div>
            <div className={styles.statMeta}>
              <span className={styles.statLabel}>Status</span>
              <span className={styles.statValue} style={{ color: 'var(--color-success)' }}>
                Live
              </span>
              <span className={styles.statSubtext}>Everything is working</span>
            </div>
          </div>
        </section>

        {/* ── Upload CTA Box (Dashed box matching Screenshot 1) ── */}
        <section aria-label="Upload action" className={styles.ctaCard}>
          <div className={styles.ctaLeft}>
            <div className={styles.ctaIconBox}>
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                <polyline points="17 8 12 3 7 8" />
                <line x1="12" y1="3" x2="12" y2="15" />
              </svg>
            </div>
            <div className={styles.ctaContent}>
              <h2 className={styles.ctaTitle}>Upload a New Workout Video</h2>
              <p className={styles.ctaText}>
                Add a new workout video to the library. It will be available for your users instantly.
              </p>
            </div>
          </div>
          <div className={styles.ctaActions}>
            <Button
              id="view-library-btn"
              variant="ghost"
              size="lg"
              onClick={() => navigate(ROUTES.VIDEOS)}
            >
              View library
            </Button>
            <Button
              id="upload-video-btn"
              size="lg"
              onClick={() => navigate(ROUTES.UPLOAD)}
              aria-label="Navigate to upload video form"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                <polyline points="17 8 12 3 7 8" />
                <line x1="12" y1="3" x2="12" y2="15" />
              </svg>
              Upload Video
            </Button>
          </div>
        </section>

        {/* ── Full Workout Videos Table with Filters ── */}
        <WorkoutVideosTable />
      </div>
    </AppLayout>
  );
}
