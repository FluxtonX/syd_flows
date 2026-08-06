/* ─────────────────────────────────────────────────────────────
   FileUpload Component – Drag-and-drop zone with preview
   ───────────────────────────────────────────────────────────── */
import {
  type DragEvent,
  type ChangeEvent,
  useState,
  useCallback,
  forwardRef,
} from 'react';
import styles from './FileUpload.module.css';

interface FileUploadProps {
  label: string;
  accept: string;
  error?: string;
  required?: boolean;
  type: 'image' | 'video';
  hint?: string;
  onChange: (files: FileList | null) => void;
  value?: FileList | null;
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export const FileUpload = forwardRef<HTMLInputElement, FileUploadProps>(
  ({ label, accept, error, required, type, hint, onChange, value }, _ref) => {
    const [isDragging, setIsDragging] = useState(false);
    const [previewUrl, setPreviewUrl] = useState<string | null>(null);

    const selectedFile = value?.[0] ?? null;

    const handleChange = useCallback(
      (files: FileList | null) => {
        if (files?.[0] && type === 'image') {
          const url = URL.createObjectURL(files[0]);
          setPreviewUrl(url);
        }
        onChange(files);
      },
      [onChange, type],
    );

    const handleInputChange = (e: ChangeEvent<HTMLInputElement>) => {
      handleChange(e.target.files);
    };

    const handleDrop = (e: DragEvent<HTMLDivElement>) => {
      e.preventDefault();
      setIsDragging(false);
      handleChange(e.dataTransfer.files);
    };

    const handleDragOver = (e: DragEvent<HTMLDivElement>) => {
      e.preventDefault();
      setIsDragging(true);
    };

    const handleDragLeave = () => setIsDragging(false);

    const handleClear = () => {
      setPreviewUrl(null);
      onChange(null);
    };

    const dropzoneClasses = [
      styles.dropzone,
      isDragging ? styles.dragging : '',
      error ? styles.hasError : '',
      selectedFile ? styles.hasFile : '',
    ]
      .filter(Boolean)
      .join(' ');

    return (
      <div className={styles.wrapper}>
        <label className={styles.label}>
          {label}
          {required && <span className={styles.required} aria-hidden="true"> *</span>}
        </label>

        {!selectedFile ? (
          <div
            className={dropzoneClasses}
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
          >
            <input
              type="file"
              accept={accept}
              className={styles.hiddenInput}
              onChange={handleInputChange}
              aria-label={label}
            />
            {type === 'video' ? (
              <svg className={styles.icon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" aria-hidden="true">
                <polygon points="23 7 16 12 23 17 23 7" />
                <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
              </svg>
            ) : (
              <svg className={styles.icon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" aria-hidden="true">
                <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
                <circle cx="8.5" cy="8.5" r="1.5" />
                <polyline points="21 15 16 10 5 21" />
              </svg>
            )}
            <p className={styles.dropText}>
              <strong>Click to upload</strong> or drag and drop
            </p>
            {hint && <p className={styles.hint}>{hint}</p>}
          </div>
        ) : (
          <div className={styles.preview}>
            {previewUrl && type === 'image' ? (
              <img
                src={previewUrl}
                alt="Thumbnail preview"
                className={styles.previewThumb}
              />
            ) : (
              <svg className={styles.icon} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" style={{ width: 32, height: 32, color: 'var(--color-success)' }} aria-hidden="true">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                <polyline points="22 4 12 14.01 9 11.01" />
              </svg>
            )}
            <div className={styles.previewInfo}>
              <p className={styles.previewName}>{selectedFile.name}</p>
              <p className={styles.previewSize}>{formatFileSize(selectedFile.size)}</p>
            </div>
            <button
              type="button"
              className={styles.clearBtn}
              onClick={handleClear}
              aria-label="Remove file"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <line x1="18" y1="6" x2="6" y2="18" />
                <line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </div>
        )}

        {error && (
          <span className={styles.error} role="alert">
            ⚠ {error}
          </span>
        )}
      </div>
    );
  },
);

FileUpload.displayName = 'FileUpload';
