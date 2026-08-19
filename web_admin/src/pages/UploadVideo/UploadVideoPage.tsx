/* ─────────────────────────────────────────────────────────────
   Upload Video Page – Matching Screenshot 2 Layout & SYD FLOW Theme
   ───────────────────────────────────────────────────────────── */
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { AppLayout } from '@/components/layout/AppLayout/AppLayout';
import { Input } from '@/components/ui/Input/Input';
import { Select } from '@/components/ui/Select/Select';
import { Button } from '@/components/ui/Button/Button';
import { FileUpload } from '@/components/ui/FileUpload/FileUpload';
import { ProgressBar } from '@/components/ui/ProgressBar/ProgressBar';
import { useVideoUpload } from '@/hooks/useVideoUpload';
import { uploadVideoSchema, type UploadVideoFormValues } from '@/utils/validators';
import { VIDEO_CATEGORIES, CYCLE_PHASES, PROPS_OPTIONS, DIFFICULTY_LEVELS, ROUTES, ACCEPTED_IMAGE_TYPES, ACCEPTED_VIDEO_TYPES } from '@/constants';
import styles from './UploadVideoPage.module.css';

const categoryOptions = VIDEO_CATEGORIES.map((c) => ({ value: c, label: c }));
const cyclePhaseOptions = CYCLE_PHASES.map((p) => ({ value: p, label: p }));
const propsOptions = PROPS_OPTIONS.map((pr) => ({ value: pr, label: pr }));
const difficultyOptions = DIFFICULTY_LEVELS.map((d) => ({ value: d, label: d }));

/** Helper to extract video duration (MM:SS) and auto-formatted title from File */
function extractVideoMetadata(file: File): Promise<{ duration: string; title: string }> {
  return new Promise((resolve) => {
    const rawName = file.name.replace(/\.[^/.]+$/, '');
    const title = rawName
      .replace(/[-_]+/g, ' ')
      .replace(/\s+/g, ' ')
      .trim()
      .replace(/\b\w/g, (char) => char.toUpperCase());

    const video = document.createElement('video');
    video.preload = 'metadata';

    video.onloadedmetadata = () => {
      window.URL.revokeObjectURL(video.src);
      const totalSecs = Math.floor(video.duration);
      if (isNaN(totalSecs) || !isFinite(totalSecs)) {
        resolve({ duration: '00:00', title });
        return;
      }
      const mins = Math.floor(totalSecs / 60);
      const secs = totalSecs % 60;
      const formattedDuration = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
      resolve({ duration: formattedDuration, title });
    };

    video.onerror = () => {
      resolve({ duration: '00:00', title });
    };

    video.src = URL.createObjectURL(file);
  });
}

export function UploadVideoPage() {
  const navigate = useNavigate();
  const { uploadVideo, progress, isUploading, error: uploadError, clearError } = useVideoUpload();
  const [successId, setSuccessId] = useState<string | null>(null);
  const [detectedDuration, setDetectedDuration] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    control,
    reset,
    watch,
    setValue,
    getValues,
    formState: { errors },
  } = useForm<UploadVideoFormValues>({
    resolver: zodResolver(uploadVideoSchema),
    defaultValues: {
      category: VIDEO_CATEGORIES[0],
      difficulty: DIFFICULTY_LEVELS[0],
      cyclePhase: CYCLE_PHASES[0],
      propsUsed: PROPS_OPTIONS[0],
      videoSource: 'custom',
      youtubeUrl: '',
      premium: true,
      duration: '00:00',
    },
  });

  const descriptionValue = watch('description') || '';

  const handleVideoFileSelect = async (
    files: FileList | null | undefined,
    fieldChange: (val: unknown) => void,
  ) => {
    fieldChange(files);
    if (files && files.length > 0) {
      const file = files[0];
      const { duration, title } = await extractVideoMetadata(file);

      // Auto-set duration
      setDetectedDuration(duration);
      setValue('duration', duration, { shouldValidate: true });

      // Auto-set title if current title is empty
      const currentTitle = getValues('title');
      if (!currentTitle || currentTitle.trim() === '') {
        setValue('title', title, { shouldValidate: true });
      }
    } else {
      setDetectedDuration(null);
      setValue('duration', '00:00');
    }
  };

  const onSubmit = async (data: UploadVideoFormValues) => {
    clearError();
    setSuccessId(null);
    try {
      const docId = await uploadVideo(data);
      setSuccessId(docId);
      setDetectedDuration(null);
      reset();
    } catch {
      // Error handled by hook
    }
  };

  const handleUploadAnother = () => {
    setSuccessId(null);
    setDetectedDuration(null);
    reset();
  };

  return (
    <AppLayout>
      <div className={styles.page}>
        {/* Page Title Header */}
        <header className={styles.header}>
          <div>
            <h1 className={styles.pageTitle}>Upload Workout Video</h1>
            <p className={styles.pageSubtitle}>
              Add a new workout video to the library
            </p>
          </div>
        </header>

        {/* Success Banner */}
        {successId && (
          <div className={styles.successBanner} role="alert">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
              <polyline points="22 4 12 14.01 9 11.01" />
            </svg>
            Video uploaded successfully! Firestore ID: <strong>{successId}</strong>
            <Button
              id="upload-another-btn"
              variant="ghost"
              size="sm"
              onClick={handleUploadAnother}
              style={{ marginLeft: 'auto' }}
            >
              Upload Another
            </Button>
          </div>
        )}

        {/* Error Banner */}
        {uploadError && (
          <div className={styles.errorBanner} role="alert">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true" style={{ flexShrink: 0, marginTop: 1 }}>
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="8" x2="12" y2="12" />
              <line x1="12" y1="16" x2="12.01" y2="16" />
            </svg>
            {uploadError}
          </div>
        )}

        {/* Main Form Container */}
        <div className={styles.formCard}>
          <form
            id="upload-video-form"
            onSubmit={handleSubmit(onSubmit)}
            noValidate
          >
            {/* Card Header */}
            <div className={styles.cardHeader}>
              <div className={styles.cardHeaderLeft}>
                <div className={styles.cardHeaderIcon} aria-hidden="true">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <rect x="2" y="2" width="20" height="20" rx="4" />
                    <path d="M10 8l6 4-6 4V8z" />
                  </svg>
                </div>
                <div>
                  <h2 className={styles.cardHeaderTitle}>Workout Video Details</h2>
                  <p className={styles.cardHeaderSubtitle}>
                    Configure workout metadata, access tier, and video media file
                  </p>
                </div>
              </div>
              <button type="button" className={styles.tipsBtn}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="12" cy="12" r="10" />
                  <line x1="12" y1="16" x2="12" y2="12" />
                  <line x1="12" y1="8" x2="12.01" y2="8" />
                </svg>
                Tips for best results
              </button>
            </div>

            {/* ── Compact Configuration Control Bar ── */}
            <div className={styles.configBar}>
              {/* Access Tier Switcher */}
              <div className={styles.configGroup}>
                <label className={styles.configLabel}>
                  <span>Access Tier</span>
                </label>
                <div className={styles.segmentedControl}>
                  <button
                    type="button"
                    className={`${styles.segmentedBtn} ${!watch('premium') ? styles.segmentedBtnActiveFree : ''}`}
                    onClick={() => setValue('premium', false, { shouldValidate: true })}
                  >
                    <span className={styles.segmentedIcon}>🎁</span>
                    <span>Free Access</span>
                  </button>
                  <button
                    type="button"
                    className={`${styles.segmentedBtn} ${watch('premium') ? styles.segmentedBtnActivePaid : ''}`}
                    onClick={() => setValue('premium', true, { shouldValidate: true })}
                  >
                    <span className={styles.segmentedIcon}>🔒</span>
                    <span>Paid / Premium</span>
                  </button>
                </div>
              </div>

              {/* Video Media Source Switcher */}
              <div className={styles.configGroup}>
                <label className={styles.configLabel}>
                  <span>Video Source</span>
                </label>
                <div className={styles.segmentedControl}>
                  <button
                    type="button"
                    className={`${styles.segmentedBtn} ${watch('videoSource') === 'custom' ? styles.segmentedBtnActive : ''}`}
                    onClick={() => setValue('videoSource', 'custom', { shouldValidate: true })}
                  >
                    <span className={styles.segmentedIcon}>📁</span>
                    <span>Direct Video Upload</span>
                  </button>
                  <button
                    type="button"
                    className={`${styles.segmentedBtn} ${watch('videoSource') === 'youtube' ? styles.segmentedBtnActive : ''}`}
                    onClick={() => setValue('videoSource', 'youtube', { shouldValidate: true })}
                  >
                    <span className={styles.segmentedIcon}>🔗</span>
                    <span>YouTube Link</span>
                  </button>
                </div>
              </div>
            </div>

            {/* Upload Progress */}
            {isUploading && (
              <div className={styles.progressSection}>
                <ProgressBar label="Uploading Thumbnail" value={progress.thumbnail} />
                <ProgressBar label="Uploading Workout Video" value={progress.video} />
              </div>
            )}

            {/* 2-Column Form Body */}
            <div className={styles.formBody}>
              {/* Left Column: Video Details */}
              <div className={styles.leftCol}>
                {/* Title & Trainer Name side-by-side */}
                <div className={styles.row2}>
                  <Input
                    label="Workout Title"
                    type="text"
                    placeholder="e.g. 10 Minute Pilates Booty Burn"
                    required
                    error={errors.title?.message}
                    {...register('title')}
                  />

                  <Input
                    label="Trainer Name"
                    type="text"
                    placeholder="Enter trainer name"
                    required
                    error={errors.trainer?.message}
                    {...register('trainer')}
                  />
                </div>

                {/* Category & Cycle Phase side-by-side */}
                <div className={styles.row2}>
                  <Controller
                    name="category"
                    control={control}
                    render={({ field }) => (
                      <Select
                        label="Category *"
                        options={categoryOptions}
                        placeholder="Select category"
                        required
                        error={errors.category?.message}
                        {...field}
                      />
                    )}
                  />

                  <Controller
                    name="cyclePhase"
                    control={control}
                    render={({ field }) => (
                      <Select
                        label="Cycle Phase *"
                        options={cyclePhaseOptions}
                        placeholder="Select cycle phase"
                        required
                        error={errors.cyclePhase?.message}
                        {...field}
                      />
                    )}
                  />
                </div>

                {/* Props Used & Difficulty side-by-side */}
                <div className={styles.row2}>
                  <Controller
                    name="propsUsed"
                    control={control}
                    render={({ field }) => (
                      <Select
                        label="Props Used (Equipment) *"
                        options={propsOptions}
                        placeholder="Select props / equipment"
                        required
                        error={errors.propsUsed?.message}
                        {...field}
                      />
                    )}
                  />

                  <Controller
                    name="difficulty"
                    control={control}
                    render={({ field }) => (
                      <Select
                        label="Difficulty Level *"
                        options={difficultyOptions}
                        placeholder="Select difficulty"
                        required
                        error={errors.difficulty?.message}
                        {...field}
                      />
                    )}
                  />
                </div>

                {/* Description */}
                <div className={styles.textareaWrapper}>
                  <Input
                    as="textarea"
                    label="Description"
                    placeholder="Describe this workout..."
                    required
                    error={errors.description?.message}
                    {...register('description')}
                  />
                  <span className={styles.charCount}>{descriptionValue.length}/500</span>
                </div>

                {/* YouTube Link Field (If YouTube mode selected) */}
                {watch('videoSource') === 'youtube' && (
                  <div style={{ marginTop: '4px' }}>
                    <Input
                      label="YouTube Video Link *"
                      type="url"
                      placeholder="https://www.youtube.com/watch?v=..."
                      required
                      error={errors.youtubeUrl?.message}
                      {...register('youtubeUrl')}
                      hint="Paste YouTube video URL for streaming playback in the mobile app"
                    />
                  </div>
                )}
              </div>

              {/* Right Column: Media File Upload Boxes */}
              <div className={styles.rightCol}>
                {/* Thumbnail Image Box */}
                <div className={styles.uploadBox}>
                  <div className={styles.uploadBoxHeader}>
                    <span className={styles.uploadBoxTitle}>Thumbnail Image *</span>
                    <span className={styles.uploadBoxSubtitle}>Upload a high quality thumbnail image</span>
                  </div>
                  <Controller
                    name="thumbnail"
                    control={control}
                    render={({ field }) => (
                      <FileUpload
                        label=""
                        accept={ACCEPTED_IMAGE_TYPES.join(',')}
                        type="image"
                        required
                        hint="JPG, PNG or WebP • Max 5MB • Recommended 16:9"
                        error={errors.thumbnail?.message as string | undefined}
                        value={field.value as FileList | undefined}
                        onChange={(files) => field.onChange(files)}
                      />
                    )}
                  />
                </div>

                {/* HD Custom Video File Upload Box (If Direct Upload selected) */}
                {watch('videoSource') === 'custom' ? (
                  <div className={`${styles.uploadBox} ${watch('premium') ? styles.uploadBoxPaid : styles.uploadBoxFree}`}>
                    <div className={styles.uploadBoxHeader}>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <span className={styles.uploadBoxTitle}>
                          {watch('premium') ? '🔒 Custom Video File (Paid / Subscription)' : '🎁 Custom Video File (Free Workout)'}
                        </span>
                        {detectedDuration && (
                          <span style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-primary)', background: 'var(--color-nav-active-bg)', padding: '2px 8px', borderRadius: 'var(--radius-full)' }}>
                            ⏱ Duration: {detectedDuration}
                          </span>
                        )}
                      </div>
                      <span className={styles.uploadBoxSubtitle}>
                        Direct video upload to cloud storage
                      </span>
                    </div>
                    <Controller
                      name="video"
                      control={control}
                      render={({ field }) => (
                        <FileUpload
                          label=""
                          accept={ACCEPTED_VIDEO_TYPES.join(',')}
                          type="video"
                          required
                          hint="MP4, MOV or WebM • Max 2GB"
                          error={errors.video?.message as string | undefined}
                          value={field.value as FileList | undefined}
                          onChange={(files) => handleVideoFileSelect(files as FileList | null | undefined, field.onChange)}
                        />
                      )}
                    />
                  </div>
                ) : (
                  <div className={`${styles.uploadBox} ${watch('premium') ? styles.uploadBoxPaid : styles.uploadBoxFree}`}>
                    <div className={styles.uploadBoxHeader}>
                      <span className={styles.uploadBoxTitle}>
                        {watch('premium') ? '🔒 YouTube Embed (Paid / Subscription)' : '🎁 YouTube Embed (Free Workout)'}
                      </span>
                      <span className={styles.uploadBoxSubtitle}>
                        This workout video will stream via YouTube link in the SYD FLOW mobile application.
                      </span>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Form Footer Action Buttons */}
            <div className={styles.formActions}>
              <Button
                id="cancel-upload-btn"
                type="button"
                variant="ghost"
                onClick={() => navigate(ROUTES.DASHBOARD)}
                disabled={isUploading}
              >
                Cancel
              </Button>

              <Button
                id="submit-upload-btn"
                type="submit"
                isLoading={isUploading}
                disabled={isUploading}
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                  <polyline points="17 8 12 3 7 8" />
                  <line x1="12" y1="3" x2="12" y2="15" />
                </svg>
                {isUploading ? 'Uploading…' : 'Upload Video'}
              </Button>
            </div>
          </form>
        </div>
      </div>
    </AppLayout>
  );
}
