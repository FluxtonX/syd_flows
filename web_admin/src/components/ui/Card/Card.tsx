/* ─────────────────────────────────────────────────────────────
   Card Component
   ───────────────────────────────────────────────────────────── */
import type { ReactNode } from 'react';
import styles from './Card.module.css';

interface CardProps {
  title?: string;
  subtitle?: string;
  children: ReactNode;
  glass?: boolean;
  glowing?: boolean;
  padded?: boolean;
  className?: string;
}

export function Card({
  title,
  subtitle,
  children,
  glass = false,
  glowing = false,
  padded = false,
  className = '',
}: CardProps) {
  const classes = [
    styles.card,
    glass ? styles.glass : '',
    glowing ? styles.glowing : '',
    padded ? styles.padded : '',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  if (title) {
    return (
      <div className={classes}>
        <div className={styles.header}>
          <h2 className={styles.title}>{title}</h2>
          {subtitle && <p className={styles.subtitle}>{subtitle}</p>}
        </div>
        <div className={styles.body}>{children}</div>
      </div>
    );
  }

  return <div className={classes}>{children}</div>;
}
