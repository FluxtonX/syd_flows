/* ─────────────────────────────────────────────────────────────
   EditVideoModal Component – Updated with Benefits, Symptoms, Phases,
   Multi-Props, Thumbnail edit, and Add Custom Category / Prop
   ───────────────────────────────────────────────────────────── */
import { useState, useEffect, useRef } from 'react';
import { Button } from '@/components/ui/Button/Button';
import { updateVideoMetadata } from '@/services/firebase/firestore';
import { uploadFile } from '@/services/cloudinary/upload';
import { CLOUDINARY_FOLDERS, VIDEO_CATEGORIES, PROPS_OPTIONS, DIFFICULTY_LEVELS, SYMPTOM_OPTIONS, RECOMMENDED_PHASES } from '@/constants';
import type { VideoRecord, VideoDocument } from '@/types';
import styles from './EditVideoModal.module.css';

interface EditVideoModalProps {
  isOpen: boolean;
  video: VideoRecord | null;
  onSave: (updatedVideo: VideoRecord) => void;
  onClose: () => void;
}

export function EditVideoModal({ isOpen, video, onSave, onClose }: EditVideoModalProps) {
  const [title, setTitle] = useState('');
  const [trainer, setTrainer] = useState('');
  const [category, setCategory] = useState<string>('Yoga');
  const [categories, setCategories] = useState<string[]>([...VIDEO_CATEGORIES]);
  const [newCategoryInput, setNewCategoryInput] = useState('');
  const [showAddCategory, setShowAddCategory] = useState(false);

  const [difficulty, setDifficulty] = useState<string>('Beginner');
  const [duration, setDuration] = useState('');
  const [description, setDescription] = useState('');
  const [videoSource, setVideoSource] = useState<'youtube' | 'custom'>('custom');
  const [youtubeUrl, setYoutubeUrl] = useState('');
  const [premium, setPremium] = useState<boolean>(true);

  // Multi-select state
  const [availableProps, setAvailableProps] = useState<string[]>([...PROPS_OPTIONS]);
  const [selectedProps, setSelectedProps] = useState<string[]>([]);
  const [newPropInput, setNewPropInput] = useState('');
  const [showAddProp, setShowAddProp] = useState(false);

  const [selectedPhases, setSelectedPhases] = useState<string[]>([]);
  const [selectedSymptoms, setSelectedSymptoms] = useState<string[]>([]);
  const [benefits, setBenefits] = useState<string[]>([]);
  const [benefitInput, setBenefitInput] = useState('');

  // Thumbnail update
  const [newThumbnailFile, setNewThumbnailFile] = useState<File | null>(null);
  const [thumbnailPreview, setThumbnailPreview] = useState<string | null>(null);
  const [thumbnailUploading, setThumbnailUploading] = useState(false);
  const thumbnailInputRef = useRef<HTMLInputElement>(null);

  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (video) {
      setTitle(video.title || '');
      setTrainer(video.trainer || '');
      const cat = video.category || 'Yoga';
      setCategory(cat);
      if (!VIDEO_CATEGORIES.includes(cat as any)) {
        setCategories((prev) => prev.includes(cat) ? prev : [...prev, cat]);
      }
      setDifficulty(video.difficulty || 'Beginner');
      setDuration(video.duration || '');
      setDescription(video.description || '');
      setVideoSource(video.videoSource || (video.youtubeUrl ? 'youtube' : 'custom'));
      setYoutubeUrl(video.youtubeUrl || '');
      setPremium(video.premium ?? video.isPaid ?? (video.isFree !== undefined ? !video.isFree : true));
      
      const rawProps = video.propsUsed;
      const parsedProps = Array.isArray(rawProps) ? rawProps : (rawProps ? [rawProps] : []);
      setSelectedProps(parsedProps);
      setAvailableProps((prev) => {
        const set = new Set([...prev, ...parsedProps]);
        return Array.from(set);
      });

      setSelectedPhases(video.recommendedPhases ?? []);
      setSelectedSymptoms(video.symptoms ?? []);
      setBenefits(video.benefits ?? []);
      setNewThumbnailFile(null);
      setThumbnailPreview(null);
      setError(null);
      setBenefitInput('');
    }
  }, [video]);

  if (!isOpen || !video) return null;

  const toggleItem = (list: string[], setList: (v: string[]) => void, value: string) => {
    setList(list.includes(value) ? list.filter((v) => v !== value) : [...list, value]);
  };

  const handleAddCategory = () => {
    const trimmed = newCategoryInput.trim();
    if (!trimmed) return;
    if (!categories.includes(trimmed)) {
      setCategories((prev) => [...prev, trimmed]);
    }
    setCategory(trimmed);
    setNewCategoryInput('');
    setShowAddCategory(false);
  };

  const handleAddProp = () => {
    const trimmed = newPropInput.trim();
    if (!trimmed) return;
    if (!availableProps.includes(trimmed)) {
      setAvailableProps((prev) => [...prev, trimmed]);
    }
    if (!selectedProps.includes(trimmed)) {
      setSelectedProps((prev) => [...prev, trimmed]);
    }
    setNewPropInput('');
    setShowAddProp(false);
  };

  const addBenefit = () => {
    const trimmed = benefitInput.trim();
    if (!trimmed) return;
    setBenefits((prev) => [...prev, trimmed]);
    setBenefitInput('');
  };

  const handleThumbnailChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setNewThumbnailFile(file);
    setThumbnailPreview(URL.createObjectURL(file));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) { setError('Title is required'); return; }

    setIsSaving(true);
    setError(null);

    try {
      let thumbnailUrl = video.thumbnailUrl;
      let thumbnailPublicId = video.thumbnailPublicId;

      if (newThumbnailFile) {
        setThumbnailUploading(true);
        const result = await uploadFile(newThumbnailFile, CLOUDINARY_FOLDERS.THUMBNAILS, 'image', () => {});
        thumbnailUrl = result.secureUrl;
        thumbnailPublicId = result.publicId;
        setThumbnailUploading(false);
      }

      let extractedYoutubeId = '';
      if (videoSource === 'youtube' && youtubeUrl.trim()) {
        const match = youtubeUrl.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/);
        if (match && match[1]?.length === 11) extractedYoutubeId = match[1];
      }

      const isPaid = premium;
      const isFree = !premium;

      const updatedData: Partial<Omit<VideoDocument, 'createdAt'>> = {
        title: title.trim(),
        trainer: trainer.trim(),
        category,
        difficulty,
        duration: duration.trim(),
        description: description.trim(),
        videoSource,
        premium: isPaid,
        isPaid,
        isFree,
        propsUsed: selectedProps,
        recommendedPhases: selectedPhases,
        symptoms: selectedSymptoms,
        benefits,
        thumbnailUrl,
        thumbnailPublicId,
        ...(videoSource === 'youtube'
          ? { youtubeUrl: youtubeUrl.trim(), youtubeId: extractedYoutubeId, videoUrl: youtubeUrl.trim() || video.videoUrl }
          : { youtubeUrl: '', youtubeId: '', videoUrl: video.videoUrl }),
      };

      await updateVideoMetadata(video.id, updatedData);
      onSave({ ...video, ...updatedData });
      onClose();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to save changes. Please try again.');
    } finally {
      setIsSaving(false);
      setThumbnailUploading(false);
    }
  };

  const phaseColors: Record<string, string> = {
    'Menstrual Phase': '#FFC6C6', 'Follicular Phase': '#FFD8B3',
    'Ovulation Phase': '#E8D4F0', 'Luteal Phase': '#F3D5E4',
  };

  const chipBase: React.CSSProperties = { padding: '5px 12px', borderRadius: '18px', fontSize: '12px', cursor: 'pointer', transition: 'all 0.15s ease', border: '2px solid transparent' };

  return (
    <div className={styles.overlay} onClick={onClose}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()} style={{ maxHeight: '90vh', overflowY: 'auto' }}>
        {/* Header */}
        <div className={styles.header}>
          <div className={styles.headerLeft}>
            <div className={styles.icon}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" /></svg>
            </div>
            <div>
              <h3 className={styles.title}>Edit Workout Video</h3>
              <p className={styles.subtitle}>Update metadata for "{video.title}"</p>
            </div>
          </div>
          <button type="button" className={styles.closeBtn} onClick={onClose} aria-label="Close modal">&times;</button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className={styles.form}>
          {error && <div className={styles.errorBanner}>{error}</div>}

          {/* Title & Trainer */}
          <div className={styles.row2}>
            <div className={styles.field}>
              <label className={styles.label}>Workout Title *</label>
              <input type="text" className={styles.input} value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Enter workout title" required />
            </div>
            <div className={styles.field}>
              <label className={styles.label}>Trainer Name</label>
              <input type="text" className={styles.input} value={trainer} onChange={(e) => setTrainer(e.target.value)} placeholder="Enter trainer name" />
            </div>
          </div>

          {/* Category & Difficulty */}
          <div className={styles.row2}>
            <div className={styles.field}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
                <label className={styles.label} style={{ marginBottom: 0 }}>Category *</label>
                <button
                  type="button"
                  onClick={() => setShowAddCategory(!showAddCategory)}
                  style={{ background: 'none', border: 'none', color: 'var(--color-primary)', fontSize: '11px', fontWeight: 600, cursor: 'pointer' }}
                >
                  {showAddCategory ? '✕ Cancel' : '+ Add Custom'}
                </button>
              </div>
              {showAddCategory ? (
                <div style={{ display: 'flex', gap: 6 }}>
                  <input
                    type="text"
                    value={newCategoryInput}
                    onChange={(e) => setNewCategoryInput(e.target.value)}
                    onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); handleAddCategory(); } }}
                    placeholder="e.g. Barre, HIIT"
                    className={styles.input}
                    style={{ flex: 1, marginBottom: 0 }}
                  />
                  <button type="button" onClick={handleAddCategory} style={{ padding: '0 12px', borderRadius: 8, border: 'none', background: 'var(--color-primary)', color: 'white', fontSize: '12px', fontWeight: 600, cursor: 'pointer' }}>Add</button>
                </div>
              ) : (
                <select className={styles.select} value={category} onChange={(e) => setCategory(e.target.value)}>
                  {categories.map((cat) => <option key={cat} value={cat}>{cat}</option>)}
                </select>
              )}
            </div>

            <div className={styles.field}>
              <label className={styles.label}>Difficulty Level *</label>
              <select className={styles.select} value={difficulty} onChange={(e) => setDifficulty(e.target.value)}>
                {DIFFICULTY_LEVELS.map((level) => <option key={level} value={level}>{level}</option>)}
              </select>
            </div>
          </div>

          {/* Duration */}
          <div className={styles.field}>
            <label className={styles.label}>Duration (e.g. 10:35)</label>
            <input type="text" className={styles.input} value={duration} onChange={(e) => setDuration(e.target.value)} placeholder="e.g. 10:35" />
          </div>

          {/* Access Tier & Video Source */}
          <div className={styles.row2}>
            <div className={styles.field}>
              <label className={styles.label}>Access Tier *</label>
              <select className={styles.select} value={premium ? 'paid' : 'free'} onChange={(e) => setPremium(e.target.value === 'paid')}>
                <option value="free">🎁 Free Workout</option>
                <option value="paid">🔒 Premium / Paid</option>
              </select>
            </div>
            <div className={styles.field}>
              <label className={styles.label}>Video Source *</label>
              <select className={styles.select} value={videoSource} onChange={(e) => setVideoSource(e.target.value as 'youtube' | 'custom')}>
                <option value="custom">📁 Custom File Upload</option>
                <option value="youtube">🔗 YouTube Link Embed</option>
              </select>
            </div>
          </div>

          {videoSource === 'youtube' && (
            <div className={styles.field}>
              <label className={styles.label}>YouTube Video URL</label>
              <input type="url" className={styles.input} value={youtubeUrl} onChange={(e) => setYoutubeUrl(e.target.value)} placeholder="https://www.youtube.com/watch?v=..." />
            </div>
          )}

          {/* Description */}
          <div className={styles.field}>
            <label className={styles.label}>Description</label>
            <textarea className={styles.textarea} value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Describe this workout..." />
          </div>

          {/* Thumbnail Edit */}
          <div className={styles.field}>
            <label className={styles.label}>Thumbnail Image</label>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: '14px', flexWrap: 'wrap' }}>
              {(thumbnailPreview || video.thumbnailUrl) && (
                <img src={thumbnailPreview ?? video.thumbnailUrl} alt="Thumbnail preview" style={{ width: 80, height: 56, objectFit: 'cover', borderRadius: 8, border: '2px solid var(--color-border)', flexShrink: 0 }} />
              )}
              <div style={{ flex: 1 }}>
                <input ref={thumbnailInputRef} type="file" accept="image/jpeg,image/png,image/webp" style={{ display: 'none' }} onChange={handleThumbnailChange} id="edit-thumbnail-input" />
                <button type="button" onClick={() => thumbnailInputRef.current?.click()} style={{ padding: '8px 16px', borderRadius: 10, border: '1.5px solid var(--color-border)', background: 'transparent', color: 'var(--color-text)', fontSize: '13px', cursor: 'pointer' }}>
                  {newThumbnailFile ? `✓ ${newThumbnailFile.name}` : 'Change Thumbnail…'}
                </button>
                {newThumbnailFile && <p style={{ fontSize: '11px', color: 'var(--color-text-secondary)', marginTop: 4 }}>Will be uploaded when you save changes</p>}
              </div>
            </div>
          </div>

          {/* Props / Equipment Multi-Select + "+ Add Prop" */}
          <div className={styles.field}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
              <label className={styles.label} style={{ marginBottom: 0 }}>
                Props / Equipment{selectedProps.length > 0 && <span style={{ color: 'var(--color-primary)', marginLeft: 6, fontWeight: 400 }}>({selectedProps.length})</span>}
              </label>
              <button
                type="button"
                onClick={() => setShowAddProp(!showAddProp)}
                style={{ background: 'none', border: 'none', color: 'var(--color-primary)', fontSize: '11px', fontWeight: 600, cursor: 'pointer' }}
              >
                {showAddProp ? '✕ Cancel' : '+ Add Prop'}
              </button>
            </div>

            {showAddProp && (
              <div style={{ display: 'flex', gap: 6, marginBottom: 8, marginTop: 4 }}>
                <input
                  type="text"
                  value={newPropInput}
                  onChange={(e) => setNewPropInput(e.target.value)}
                  onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); handleAddProp(); } }}
                  placeholder="e.g. Resistance Band, Foam Roller"
                  className={styles.input}
                  style={{ flex: 1, marginBottom: 0 }}
                />
                <button type="button" onClick={handleAddProp} style={{ padding: '0 12px', borderRadius: 8, border: 'none', background: 'var(--color-primary)', color: 'white', fontSize: '12px', fontWeight: 600, cursor: 'pointer' }}>Add</button>
              </div>
            )}

            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginTop: 6 }}>
              {availableProps.map((prop) => {
                const sel = selectedProps.includes(prop);
                return (<button key={prop} type="button" onClick={() => toggleItem(selectedProps, setSelectedProps, prop)} style={{ ...chipBase, border: `2px solid ${sel ? 'var(--color-primary)' : 'var(--color-border)'}`, background: sel ? 'var(--color-nav-active-bg)' : 'transparent', color: sel ? 'var(--color-primary)' : 'var(--color-text-secondary)', fontWeight: sel ? 600 : 400 }}>{sel ? '✓ ' : ''}{prop}</button>);
              })}
            </div>
          </div>

          {/* Recommended Phases Multi-Select */}
          <div className={styles.field}>
            <label className={styles.label}>Recommended Phases{selectedPhases.length > 0 && <span style={{ color: 'var(--color-primary)', marginLeft: 6, fontWeight: 400 }}>({selectedPhases.length})</span>}</label>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginTop: 6 }}>
              {RECOMMENDED_PHASES.map((phase) => {
                const sel = selectedPhases.includes(phase);
                const bg = phaseColors[phase] ?? '#FFD8B3';
                return (<button key={phase} type="button" onClick={() => toggleItem(selectedPhases, setSelectedPhases, phase)} style={{ ...chipBase, border: `2px solid ${sel ? '#8C654D' : 'transparent'}`, background: sel ? bg : 'var(--color-surface)', color: '#5C3D2A', fontWeight: sel ? 600 : 400, opacity: sel ? 1 : 0.65 }}>{sel ? '✓ ' : ''}{phase}</button>);
              })}
            </div>
          </div>

          {/* Symptom-Friendly Multi-Select */}
          <div className={styles.field}>
            <label className={styles.label}>Symptom-Friendly{selectedSymptoms.length > 0 && <span style={{ color: 'var(--color-primary)', marginLeft: 6, fontWeight: 400 }}>({selectedSymptoms.length})</span>}</label>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginTop: 6 }}>
              {SYMPTOM_OPTIONS.map((symptom) => {
                const sel = selectedSymptoms.includes(symptom);
                return (<button key={symptom} type="button" onClick={() => toggleItem(selectedSymptoms, setSelectedSymptoms, symptom)} style={{ ...chipBase, border: `2px solid ${sel ? 'var(--color-primary)' : 'var(--color-border)'}`, background: sel ? '#FFF6F9' : 'transparent', color: sel ? '#C2507A' : 'var(--color-text-secondary)', fontWeight: sel ? 600 : 400 }}>{sel ? '✓ ' : ''}{symptom}</button>);
              })}
            </div>
          </div>

          {/* Benefits */}
          <div className={styles.field}>
            <label className={styles.label}>Benefits</label>
            {benefits.length > 0 && (
              <div style={{ marginBottom: 8, display: 'flex', flexDirection: 'column', gap: 4 }}>
                {benefits.map((b, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 10px', background: 'var(--color-surface)', borderRadius: 8, border: '1px solid var(--color-border)' }}>
                    <span style={{ flex: 1, fontSize: 13, color: 'var(--color-text)' }}>✓ {b}</span>
                    <button type="button" onClick={() => setBenefits((prev) => prev.filter((_, idx) => idx !== i))} style={{ background: 'none', border: 'none', color: 'var(--color-text-secondary)', cursor: 'pointer', fontSize: 16, padding: '2px' }} aria-label={`Remove ${b}`}>×</button>
                  </div>
                ))}
              </div>
            )}
            <div style={{ display: 'flex', gap: 8 }}>
              <input type="text" value={benefitInput} onChange={(e) => setBenefitInput(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addBenefit(); } }} placeholder="e.g. Improves flexibility" className={styles.input} style={{ flex: 1, marginBottom: 0 }} id="edit-benefit-input" />
              <button type="button" onClick={addBenefit} style={{ padding: '0 16px', borderRadius: 10, border: 'none', background: 'var(--color-primary)', color: 'white', fontSize: 13, fontWeight: 600, cursor: 'pointer', whiteSpace: 'nowrap', height: 40 }}>+ Add</button>
            </div>
          </div>

          {/* Actions */}
          <div className={styles.actions}>
            <Button type="button" variant="ghost" onClick={onClose} disabled={isSaving}>Cancel</Button>
            <Button type="submit" isLoading={isSaving || thumbnailUploading} disabled={isSaving || thumbnailUploading}>
              {thumbnailUploading ? 'Uploading thumbnail…' : 'Save Changes'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
