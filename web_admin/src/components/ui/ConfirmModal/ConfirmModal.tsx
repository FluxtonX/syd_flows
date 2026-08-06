/* ─────────────────────────────────────────────────────────────
   ConfirmModal Component – Modal for confirming dangerous actions
   ───────────────────────────────────────────────────────────── */
import type { ReactNode } from 'react';
import { Button } from '@/components/ui/Button/Button';
import styles from './ConfirmModal.module.css';

interface ConfirmModalProps {
  isOpen: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  confirmVariant?: 'danger' | 'primary';
  icon?: ReactNode;
  isLoading?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export function ConfirmModal({
  isOpen,
  title,
  message,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  confirmVariant = 'danger',
  icon,
  isLoading = false,
  onConfirm,
  onCancel,
}: ConfirmModalProps) {
  if (!isOpen) return null;

  return (
    <div className={styles.overlay} onClick={onCancel} aria-modal="true" role="dialog">
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <div className={styles.header}>
          <div className={styles.icon} aria-hidden="true">
            {icon ?? (
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="3 6 5 6 21 6" />
                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                <line x1="10" y1="11" x2="10" y2="17" />
                <line x1="14" y1="11" x2="14" y2="17" />
              </svg>
            )}
          </div>
          <div className={styles.content}>
            <h3 className={styles.title}>{title}</h3>
            <p className={styles.message}>{message}</p>
          </div>
        </div>

        <div className={styles.actions}>
          <Button
            type="button"
            variant="ghost"
            size="sm"
            onClick={onCancel}
            disabled={isLoading}
          >
            {cancelLabel}
          </Button>

          <Button
            type="button"
            variant="primary"
            size="sm"
            isLoading={isLoading}
            disabled={isLoading}
            onClick={onConfirm}
            style={
              confirmVariant === 'danger'
                ? {
                    background: 'linear-gradient(135deg, #ef4444, #dc2626)',
                    borderColor: 'transparent',
                    boxShadow: '0 0 16px rgba(239, 68, 68, 0.4)',
                  }
                : undefined
            }
          >
            {confirmLabel}
          </Button>
        </div>
      </div>
    </div>
  );
}
