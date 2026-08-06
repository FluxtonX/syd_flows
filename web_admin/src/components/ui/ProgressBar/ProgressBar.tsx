/* ─────────────────────────────────────────────────────────────
   ProgressBar Component
   ───────────────────────────────────────────────────────────── */
import styles from './ProgressBar.module.css';

interface ProgressBarProps {
  label: string;
  value: number; // 0–100
}

export function ProgressBar({ label, value }: ProgressBarProps) {
  const clamped = Math.min(100, Math.max(0, value));
  const isComplete = clamped === 100;

  return (
    <div className={`${styles.wrapper} ${isComplete ? styles.complete : ''}`}>
      <div className={styles.header}>
        <span className={styles.label}>{label}</span>
        <span className={styles.percent}>{clamped}%</span>
      </div>
      <div className={styles.track} role="progressbar" aria-valuenow={clamped} aria-valuemin={0} aria-valuemax={100} aria-label={label}>
        <div className={styles.fill} style={{ width: `${clamped}%` }} />
      </div>
    </div>
  );
}
