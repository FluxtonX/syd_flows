/* ─────────────────────────────────────────────────────────────
   VideoCard Component
   ───────────────────────────────────────────────────────────── */
import { useState } from 'react';
import type { VideoRecord } from '@/types';
import styles from './VideoCard.module.css';

interface VideoCardProps {
  video: VideoRecord;
  onEdit?: (video: VideoRecord) => void;
  onDelete?: (video: VideoRecord) => void;
}

function formatDate(value: unknown): string {
  try {
    const date =
      value && typeof (value as { toDate?: () => Date }).toDate === 'function'
        ? (value as { toDate: () => Date }).toDate()
        : new Date(value as string);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  } catch {
    return '—';
  }
}

export function VideoCard({ video, onEdit, onDelete }: VideoCardProps) {
  const [imgError, setImgError] = useState(false);

  return (
    <article className={styles.card}>
      {/* ── Thumbnail ── */}
      <div className={styles.thumb}>
        {!imgError && video.thumbnailUrl ? (
          <img
            src={video.thumbnailUrl}
            alt={video.title}
            className={styles.thumbImg}
            onError={() => setImgError(true)}
          />
        ) : (
          <div className={styles.thumbFallback} aria-hidden="true">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
              <polygon points="23 7 16 12 23 17 23 7" />
              <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
            </svg>
          </div>
        )}

        {/* Play overlay */}
        <div className={styles.playOverlay} aria-hidden="true">
          <a
            href={video.videoUrl}
            target="_blank"
            rel="noopener noreferrer"
            className={styles.playBtn}
            aria-label={`Play ${video.title}`}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="white" aria-hidden="true">
              <polygon points="5 3 19 12 5 21 5 3" />
            </svg>
          </a>
        </div>

        {/* Premium / Free badge */}
        {video.premium ? (
          <span className={styles.premiumBadge} aria-label="Premium content">
            ★ PREMIUM
          </span>
        ) : (
          <span className={styles.freeBadge} aria-label="Free content">
            FREE
          </span>
        )}

        {/* Duration badge */}
        {video.duration && (
          <span className={styles.durationBadge} aria-label={`Duration: ${video.duration}`}>
            {video.duration}
          </span>
        )}
      </div>

      {/* ── Body ── */}
      <div className={styles.body}>
        {/* Category + Difficulty */}
        <div className={styles.badges}>
          <span className={`${styles.badge} ${styles.badgeCategory}`}>
            {video.category}
          </span>
          <span className={`${styles.badge} ${styles.badgeDifficulty}`}>
            {video.difficulty}
          </span>
        </div>

        {/* Title */}
        <h3 className={styles.title}>{video.title}</h3>

        {/* Meta */}
        <div className={styles.meta}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
            <circle cx="12" cy="7" r="4" />
          </svg>
          {video.trainer}
        </div>
      </div>

      {/* ── Footer ── */}
      <div className={styles.footer}>
        <span className={styles.date}>{formatDate(video.createdAt)}</span>

        <div className={styles.footerActions}>
          <a
            href={video.videoUrl}
            target="_blank"
            rel="noopener noreferrer"
            className={styles.viewBtn}
            aria-label={`View video: ${video.title}`}
          >
            View
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
              <line x1="7" y1="17" x2="17" y2="7" />
              <polyline points="7 7 17 7 17 17" />
            </svg>
          </a>

          {onEdit && (
            <button
              type="button"
              className={styles.deleteIconBtn}
              onClick={() => onEdit(video)}
              title="Edit video metadata"
              aria-label={`Edit ${video.title}`}
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
              </svg>
            </button>
          )}

          {onDelete && (
            <button
              type="button"
              className={styles.deleteIconBtn}
              onClick={() => onDelete(video)}
              title="Delete video"
              aria-label={`Delete ${video.title}`}
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="3 6 5 6 21 6" />
                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
              </svg>
            </button>
          )}
        </div>
      </div>
    </article>
  );
}
