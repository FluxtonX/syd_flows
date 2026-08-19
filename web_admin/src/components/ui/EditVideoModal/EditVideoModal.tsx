/* ─────────────────────────────────────────────────────────────
   EditVideoModal Component
   Modal for editing workout video metadata in Cloud Firestore
   ───────────────────────────────────────────────────────────── */
import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/Button/Button';
import { updateVideoMetadata } from '@/services/firebase/firestore';
import {
  VIDEO_CATEGORIES,
  CYCLE_PHASES,
  PROPS_OPTIONS,
  DIFFICULTY_LEVELS,
} from '@/constants';
import type { VideoRecord, VideoDocument } from '@/types';
import styles from './EditVideoModal.module.css';

interface EditVideoModalProps {
  isOpen: boolean;
  video: VideoRecord | null;
  onSave: (updatedVideo: VideoRecord) => void;
  onClose: () => void;
}

export function EditVideoModal({
  isOpen,
  video,
  onSave,
  onClose,
}: EditVideoModalProps) {
  const [title, setTitle] = useState('');
  const [trainer, setTrainer] = useState('');
  const [category, setCategory] = useState<string>('Yoga');
  const [cyclePhase, setCyclePhase] = useState<string>('Follicular Phase');
  const [propsUsed, setPropsUsed] = useState<string>('Mat');
  const [difficulty, setDifficulty] = useState<string>('Beginner');
  const [duration, setDuration] = useState('');
  const [description, setDescription] = useState('');
  const [videoSource, setVideoSource] = useState<'youtube' | 'custom'>('custom');
  const [youtubeUrl, setYoutubeUrl] = useState('');
  const [premium, setPremium] = useState<boolean>(true);

  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (video) {
      setTitle(video.title || '');
      setTrainer(video.trainer || '');
      setCategory(video.category || 'Yoga');
      setCyclePhase(video.cyclePhase || 'Follicular Phase');
      setPropsUsed(video.propsUsed || 'Mat');
      setDifficulty(video.difficulty || 'Beginner');
      setDuration(video.duration || '');
      setDescription(video.description || '');
      setVideoSource(video.videoSource || (video.youtubeUrl ? 'youtube' : 'custom'));
      setYoutubeUrl(video.youtubeUrl || '');
      setPremium(video.premium ?? video.isPaid ?? (video.isFree !== undefined ? !video.isFree : true));
      setError(null);
    }
  }, [video]);

  if (!isOpen || !video) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) {
      setError('Title is required');
      return;
    }

    setIsSaving(true);
    setError(null);

    let extractedYoutubeId = '';
    if (videoSource === 'youtube' && youtubeUrl.trim()) {
      const match = youtubeUrl.match(
        /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/,
      );
      if (match && match[1]?.length === 11) {
        extractedYoutubeId = match[1];
      }
    }

    const isPaid = premium;
    const isFree = !premium;

    const updatedData: Partial<Omit<VideoDocument, 'createdAt'>> = {
      title: title.trim(),
      trainer: trainer.trim(),
      category,
      cyclePhase,
      propsUsed,
      difficulty,
      duration: duration.trim(),
      description: description.trim(),
      videoSource,
      premium: isPaid,
      isPaid: isPaid,
      isFree: isFree,
      ...(videoSource === 'youtube'
        ? {
            youtubeUrl: youtubeUrl.trim(),
            youtubeId: extractedYoutubeId,
            videoUrl: youtubeUrl.trim() || video.videoUrl,
          }
        : {
            youtubeUrl: '',
            youtubeId: '',
            videoUrl: video.videoUrl,
          }),
    };

    try {
      await updateVideoMetadata(video.id, updatedData);
      const updatedRecord: VideoRecord = {
        ...video,
        ...updatedData,
      };
      onSave(updatedRecord);
      onClose();
    } catch (err: unknown) {
      console.error('Failed to update video:', err);
      setError(
        err instanceof Error
          ? err.message
          : 'Failed to save changes. Please try again.',
      );
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className={styles.overlay} onClick={onClose}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div className={styles.header}>
          <div className={styles.headerLeft}>
            <div className={styles.icon}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
              </svg>
            </div>
            <div>
              <h3 className={styles.title}>Edit Workout Video</h3>
              <p className={styles.subtitle}>Update metadata for "{video.title}"</p>
            </div>
          </div>
          <button type="button" className={styles.closeBtn} onClick={onClose} aria-label="Close modal">
            &times;
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className={styles.form}>
          {error && <div className={styles.errorBanner}>{error}</div>}

          {/* Title & Trainer */}
          <div className={styles.row2}>
            <div className={styles.field}>
              <label className={styles.label}>Workout Title *</label>
              <input
                type="text"
                className={styles.input}
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Enter workout title"
                required
              />
            </div>
            <div className={styles.field}>
              <label className={styles.label}>Trainer Name *</label>
              <input
                type="text"
                className={styles.input}
                value={trainer}
                onChange={(e) => setTrainer(e.target.value)}
                placeholder="Enter trainer name"
                required
              />
            </div>
          </div>

          {/* Category & Cycle Phase */}
          <div className={styles.row2}>
            <div className={styles.field}>
              <label className={styles.label}>Category *</label>
              <select
                className={styles.select}
                value={category}
                onChange={(e) => setCategory(e.target.value)}
              >
                {VIDEO_CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>
            </div>

            <div className={styles.field}>
              <label className={styles.label}>Cycle Phase *</label>
              <select
                className={styles.select}
                value={cyclePhase}
                onChange={(e) => setCyclePhase(e.target.value)}
              >
                {CYCLE_PHASES.map((phase) => (
                  <option key={phase} value={phase}>
                    {phase}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Props & Difficulty */}
          <div className={styles.row2}>
            <div className={styles.field}>
              <label className={styles.label}>Props Used *</label>
              <select
                className={styles.select}
                value={propsUsed}
                onChange={(e) => setPropsUsed(e.target.value)}
              >
                {PROPS_OPTIONS.map((prop) => (
                  <option key={prop} value={prop}>
                    {prop}
                  </option>
                ))}
              </select>
            </div>

            <div className={styles.field}>
              <label className={styles.label}>Difficulty Level *</label>
              <select
                className={styles.select}
                value={difficulty}
                onChange={(e) => setDifficulty(e.target.value)}
              >
                {DIFFICULTY_LEVELS.map((level) => (
                  <option key={level} value={level}>
                    {level}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Duration */}
          <div className={styles.field}>
            <label className={styles.label}>Duration (e.g. 10 mins or 10:35)</label>
            <input
              type="text"
              className={styles.input}
              value={duration}
              onChange={(e) => setDuration(e.target.value)}
              placeholder="e.g. 10 mins"
            />
          </div>

          {/* Access Tier & Video Source */}
          <div className={styles.row2}>
            <div className={styles.field}>
              <label className={styles.label}>Access Tier *</label>
              <select
                className={styles.select}
                value={premium ? 'paid' : 'free'}
                onChange={(e) => setPremium(e.target.value === 'paid')}
              >
                <option value="free">🎁 Free Workout</option>
                <option value="paid">🔒 Premium / Paid</option>
              </select>
            </div>

            <div className={styles.field}>
              <label className={styles.label}>Video Source *</label>
              <select
                className={styles.select}
                value={videoSource}
                onChange={(e) => setVideoSource(e.target.value as 'youtube' | 'custom')}
              >
                <option value="custom">📁 Custom File Upload</option>
                <option value="youtube">🔗 YouTube Link Embed</option>
              </select>
            </div>
          </div>

          {/* YouTube Video URL */}
          {videoSource === 'youtube' && (
            <div className={styles.field}>
              <label className={styles.label}>YouTube Video URL</label>
              <input
                type="url"
                className={styles.input}
                value={youtubeUrl}
                onChange={(e) => setYoutubeUrl(e.target.value)}
                placeholder="https://www.youtube.com/watch?v=..."
              />
            </div>
          )}

          {/* Description */}
          <div className={styles.field}>
            <label className={styles.label}>Description</label>
            <textarea
              className={styles.textarea}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Describe this workout..."
            />
          </div>

          {/* Actions */}
          <div className={styles.actions}>
            <Button
              type="button"
              variant="ghost"
              onClick={onClose}
              disabled={isSaving}
            >
              Cancel
            </Button>
            <Button type="submit" isLoading={isSaving} disabled={isSaving}>
              Save Changes
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
