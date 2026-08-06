/* ─────────────────────────────────────────────────────────────
   Select Component
   ───────────────────────────────────────────────────────────── */
import { forwardRef, type SelectHTMLAttributes } from 'react';
import styles from './Select.module.css';

interface SelectOption {
  value: string;
  label: string;
}

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label: string;
  options: SelectOption[];
  placeholder?: string;
  error?: string;
  required?: boolean;
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, options, placeholder, error, required, className = '', value, ...rest }, ref) => {
    const id = `select-${label.toLowerCase().replace(/\s+/g, '-')}`;
    const hasError = Boolean(error);
    const selectValue = value ?? '';

    return (
      <div className={styles.wrapper}>
        <label htmlFor={id} className={styles.label}>
          {label}
          {required && <span className={styles.required} aria-hidden="true"> *</span>}
        </label>
        <div className={styles.selectWrapper}>
          <select
            id={id}
            ref={ref}
            value={selectValue}
            className={[styles.select, hasError ? styles.hasError : '', className]
              .filter(Boolean)
              .join(' ')}
            aria-invalid={hasError}
            aria-describedby={error ? `${id}-error` : undefined}
            {...rest}
          >
            {placeholder && (
              <option value="" disabled hidden={Boolean(selectValue)}>
                {placeholder}
              </option>
            )}
            {options.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
          {/* Custom chevron icon */}
          <svg className={styles.chevron} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <polyline points="6 9 12 15 18 9" />
          </svg>
        </div>
        {error && (
          <span id={`${id}-error`} className={styles.error} role="alert">
            ⚠ {error}
          </span>
        )}
      </div>
    );
  },
);

Select.displayName = 'Select';
