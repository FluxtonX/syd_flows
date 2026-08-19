/* ─────────────────────────────────────────────────────────────
   Input Component – Text, Email, Password, Textarea
   ───────────────────────────────────────────────────────────── */
import { forwardRef, type InputHTMLAttributes, type TextareaHTMLAttributes } from 'react';
import styles from './Input.module.css';

interface BaseProps {
  label: string;
  error?: string;
  hint?: string;
  required?: boolean;
  rightElement?: React.ReactNode;
}

type InputProps = BaseProps &
  Omit<InputHTMLAttributes<HTMLInputElement>, 'required'> & {
    as?: 'input';
  };

type TextareaProps = BaseProps &
  Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, 'required'> & {
    as: 'textarea';
  };

type Props = InputProps | TextareaProps;

export const Input = forwardRef<HTMLInputElement | HTMLTextAreaElement, Props>(
  ({ label, error, hint, required, rightElement, as: Tag = 'input', className = '', ...rest }, ref) => {
    const id = `input-${label.toLowerCase().replace(/\s+/g, '-')}`;
    const hasError = Boolean(error);

    const inputClasses = [
      styles.input,
      Tag === 'textarea' ? styles.textarea : '',
      hasError ? styles.hasError : '',
      rightElement ? styles.hasRightElement : '',
      className,
    ]
      .filter(Boolean)
      .join(' ');

    return (
      <div className={styles.wrapper}>
        <label htmlFor={id} className={styles.label}>
          {label}
          {required && <span className={styles.required} aria-hidden="true"> *</span>}
        </label>
        <div className={styles.inputWrapper}>
          {Tag === 'textarea' ? (
            <textarea
              id={id}
              ref={ref as React.Ref<HTMLTextAreaElement>}
              className={inputClasses}
              aria-invalid={hasError}
              aria-describedby={error ? `${id}-error` : hint ? `${id}-hint` : undefined}
              {...(rest as TextareaHTMLAttributes<HTMLTextAreaElement>)}
            />
          ) : (
            <input
              id={id}
              ref={ref as React.Ref<HTMLInputElement>}
              className={inputClasses}
              aria-invalid={hasError}
              aria-describedby={error ? `${id}-error` : hint ? `${id}-hint` : undefined}
              {...(rest as InputHTMLAttributes<HTMLInputElement>)}
            />
          )}
          {rightElement && <div className={styles.rightElement}>{rightElement}</div>}
        </div>
        {error && (
          <span id={`${id}-error`} className={styles.error} role="alert">
            ⚠ {error}
          </span>
        )}
        {hint && !error && (
          <span id={`${id}-hint`} className={styles.hint}>
            {hint}
          </span>
        )}
      </div>
    );
  },
);

Input.displayName = 'Input';
