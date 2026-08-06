/* ─────────────────────────────────────────────────────────────
   Spinner Component
   ───────────────────────────────────────────────────────────── */
import styles from './Spinner.module.css';

interface SpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  label?: string;
}

export function Spinner({ size = 'md', label }: SpinnerProps) {
  return (
    <div className={styles.wrapper} role="status" aria-label={label ?? 'Loading'}>
      <div className={`${styles.spinner} ${styles[size]}`} aria-hidden="true" />
      {label && <span className={styles.label}>{label}</span>}
    </div>
  );
}
