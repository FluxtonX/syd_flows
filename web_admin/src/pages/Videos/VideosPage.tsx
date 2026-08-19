/* ─────────────────────────────────────────────────────────────
   VideosPage – Full Workout Videos Management Page
   Lists all uploaded videos with search, filters, edit & delete
   ───────────────────────────────────────────────────────────── */
import { useAuth } from '@/hooks/useAuth';
import { AppLayout } from '@/components/layout/AppLayout/AppLayout';
import { WorkoutVideosTable } from '@/components/ui/WorkoutVideosTable/WorkoutVideosTable';
import styles from './VideosPage.module.css';

export function VideosPage() {
  const { user } = useAuth();
  const displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'admin';

  return (
    <AppLayout>
      <div className={styles.page}>
        {/* Top Header */}
        <div className={styles.header}>
          <div className={styles.titleGroup}>
            <h1 className={styles.title}>
              Video library
            </h1>
            <p className={styles.subtitle}>
              Browse, filter, and manage every workout video in one place. Signed in as {displayName}.
            </p>
          </div>
        </div>

        {/* Full Filterable Workout Videos Table */}
        <WorkoutVideosTable />
      </div>
    </AppLayout>
  );
}
