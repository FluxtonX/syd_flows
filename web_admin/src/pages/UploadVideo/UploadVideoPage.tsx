/* ─────────────────────────────────────────────────────────────
   Upload Video Page – Updated with Benefits, Symptoms, Phases,
   Multi-Props, and Add Custom Category / Prop options
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
import {
  VIDEO_CATEGORIES,
  CYCLE_PHASES,
  PROPS_OPTIONS,
  DIFFICULTY_LEVELS,
  ROUTES,
  ACCEPTED_IMAGE_TYPES,
  ACCEPTED_VIDEO_TYPES,
  SYMPTOM_OPTIONS,
  RECOMMENDED_PHASES,
} from '@/constants';
import styles from './UploadVideoPage.module.css';

const difficultyOptions = DIFFICULTY_LEVELS.map((d) => ({ value: d, label: d }));

function extractVideoMetadata(file: File): Promise<{ duration: string; title: string }> {
  return new Promise((resolve) => {
    const rawName = file.name.replace(/\.[^/.]+$/, '');
    const title = rawName.replace(/[-_]+/g, ' ').replace(/\s+/g, ' ').trim().replace(/\b\w/g, (char) => char.toUpperCase());
    const video = document.createElement('video');
    video.preload = 'metadata';
    video.onloadedmetadata = () => {
      window.URL.revokeObjectURL(video.src);
      const totalSecs = Math.floor(video.duration);
      if (isNaN(totalSecs) || !isFinite(totalSecs)) { resolve({ duration: '00:00', title }); return; }
      const mins = Math.floor(totalSecs / 60);
      const secs = totalSecs % 60;
      resolve({ duration: `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`, title });
    };
    video.onerror = () => resolve({ duration: '00:00', title });
    video.src = URL.createObjectURL(file);
  });
}

export function UploadVideoPage() {
  const navigate = useNavigate();
  const { uploadVideo, progress, isUploading, error: uploadError, clearError } = useVideoUpload();
  const [successId, setSuccessId] = useState<string | null>(null);
  const [detectedDuration, setDetectedDuration] = useState<string | null>(null);

  // Dynamic Categories and Props
  const [categories, setCategories] = useState<string[]>([...VIDEO_CATEGORIES]);
  const [newCategoryInput, setNewCategoryInput] = useState('');
  const [showAddCategory, setShowAddCategory] = useState(false);

  const [availableProps, setAvailableProps] = useState<string[]>([...PROPS_OPTIONS]);
  const [newPropInput, setNewPropInput] = useState('');
  const [showAddProp, setShowAddProp] = useState(false);

  // Dynamic Benefits
  const [benefitInput, setBenefitInput] = useState('');

  const { register, handleSubmit, control, reset, watch, setValue, getValues, formState: { errors } } = useForm<UploadVideoFormValues>({
    resolver: zodResolver(uploadVideoSchema),
    defaultValues: {
      category: VIDEO_CATEGORIES[0],
      difficulty: DIFFICULTY_LEVELS[0],
      cyclePhase: CYCLE_PHASES[0],
      propsUsed: [],
      videoSource: 'custom',
      youtubeUrl: '',
      premium: true,
      duration: '00:00',
      benefits: [],
      symptoms: [],
      recommendedPhases: [],
    },
  });

  const descriptionValue = watch('description') || '';
  const currentBenefits = watch('benefits') || [];
  const currentSymptoms = watch('symptoms') || [];
  const currentPhases = watch('recommendedPhases') || [];
  const currentProps = watch('propsUsed') || [];

  const handleVideoFileSelect = async (files: FileList | null | undefined, fieldChange: (val: unknown) => void) => {
    fieldChange(files);
    if (files && files.length > 0) {
      const { duration, title } = await extractVideoMetadata(files[0]);
      setDetectedDuration(duration);
      setValue('duration', duration, { shouldValidate: true });
      const currentTitle = getValues('title');
      if (!currentTitle || currentTitle.trim() === '') setValue('title', title, { shouldValidate: true });
    } else {
      setDetectedDuration(null);
      setValue('duration', '00:00');
    }
  };

  const handleAddCategory = () => {
    const trimmed = newCategoryInput.trim();
    if (!trimmed) return;
    if (!categories.includes(trimmed)) {
      setCategories((prev) => [...prev, trimmed]);
    }
    setValue('category', trimmed, { shouldValidate: true });
    setNewCategoryInput('');
    setShowAddCategory(false);
  };

  const handleAddProp = () => {
    const trimmed = newPropInput.trim();
    if (!trimmed) return;
    if (!availableProps.includes(trimmed)) {
      setAvailableProps((prev) => [...prev, trimmed]);
    }
    const current = getValues('propsUsed') ?? [];
    if (!current.includes(trimmed)) {
      setValue('propsUsed', [...current, trimmed], { shouldValidate: true });
    }
    setNewPropInput('');
    setShowAddProp(false);
  };

  const addBenefit = () => {
    const trimmed = benefitInput.trim();
    if (!trimmed) return;
    setValue('benefits', [...(getValues('benefits') ?? []), trimmed], { shouldValidate: true });
    setBenefitInput('');
  };

  const removeBenefit = (index: number) => {
    setValue('benefits', (getValues('benefits') ?? []).filter((_, i) => i !== index), { shouldValidate: true });
  };

  const toggle = (field: 'symptoms' | 'recommendedPhases' | 'propsUsed', value: string) => {
    const current = getValues(field) ?? [];
    setValue(field, current.includes(value) ? current.filter((v) => v !== value) : [...current, value], { shouldValidate: true });
  };

  const onSubmit = async (data: UploadVideoFormValues) => {
    clearError(); setSuccessId(null);
    try {
      const docId = await uploadVideo(data);
      setSuccessId(docId); setDetectedDuration(null); setBenefitInput(''); reset();
    } catch { /* handled by hook */ }
  };

  const phaseColors: Record<string, string> = {
    'Menstrual Phase': '#FFC6C6', 'Follicular Phase': '#FFD8B3',
    'Ovulation Phase': '#E8D4F0', 'Luteal Phase': '#F3D5E4',
  };

  const categorySelectOptions = categories.map((c) => ({ value: c, label: c }));

  return (
    <AppLayout>
      <div className={styles.page}>
        <header className={styles.header}>
          <div>
            <h1 className={styles.pageTitle}>Upload Workout Video</h1>
            <p className={styles.pageSubtitle}>Add a new workout video to the library</p>
          </div>
        </header>

        {successId && (
          <div className={styles.successBanner} role="alert">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" /><polyline points="22 4 12 14.01 9 11.01" /></svg>
            Video uploaded successfully! Firestore ID: <strong>{successId}</strong>
            <Button id="upload-another-btn" variant="ghost" size="sm" onClick={() => { setSuccessId(null); setDetectedDuration(null); setBenefitInput(''); reset(); }} style={{ marginLeft: 'auto' }}>Upload Another</Button>
          </div>
        )}

        {uploadError && (
          <div className={styles.errorBanner} role="alert">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line x1="12" y1="16" x2="12.01" y2="16" /></svg>
            {uploadError}
          </div>
        )}

        <div className={styles.formCard}>
          <form id="upload-video-form" onSubmit={handleSubmit(onSubmit)} noValidate>

            <div className={styles.cardHeader}>
              <div className={styles.cardHeaderLeft}>
                <div className={styles.cardHeaderIcon} aria-hidden="true">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="2" y="2" width="20" height="20" rx="4" /><path d="M10 8l6 4-6 4V8z" /></svg>
                </div>
                <div>
                  <h2 className={styles.cardHeaderTitle}>Workout Video Details</h2>
                  <p className={styles.cardHeaderSubtitle}>Configure workout metadata, access tier, and video media file</p>
                </div>
              </div>
              <button type="button" className={styles.tipsBtn}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10" /><line x1="12" y1="16" x2="12" y2="12" /><line x1="12" y1="8" x2="12.01" y2="8" /></svg>
                Tips for best results
              </button>
            </div>

            <div className={styles.configBar}>
              <div className={styles.configGroup}>
                <label className={styles.configLabel}><span>Access Tier</span></label>
                <div className={styles.segmentedControl}>
                  <button type="button" className={`${styles.segmentedBtn} ${!watch('premium') ? styles.segmentedBtnActiveFree : ''}`} onClick={() => setValue('premium', false, { shouldValidate: true })}><span className={styles.segmentedIcon}>🎁</span><span>Free Access</span></button>
                  <button type="button" className={`${styles.segmentedBtn} ${watch('premium') ? styles.segmentedBtnActivePaid : ''}`} onClick={() => setValue('premium', true, { shouldValidate: true })}><span className={styles.segmentedIcon}>🔒</span><span>Paid / Premium</span></button>
                </div>
              </div>
              <div className={styles.configGroup}>
                <label className={styles.configLabel}><span>Video Source</span></label>
                <div className={styles.segmentedControl}>
                  <button type="button" className={`${styles.segmentedBtn} ${watch('videoSource') === 'custom' ? styles.segmentedBtnActive : ''}`} onClick={() => setValue('videoSource', 'custom', { shouldValidate: true })}><span className={styles.segmentedIcon}>📁</span><span>Direct Video Upload</span></button>
                  <button type="button" className={`${styles.segmentedBtn} ${watch('videoSource') === 'youtube' ? styles.segmentedBtnActive : ''}`} onClick={() => setValue('videoSource', 'youtube', { shouldValidate: true })}><span className={styles.segmentedIcon}>🔗</span><span>YouTube Link</span></button>
                </div>
              </div>
            </div>

            {isUploading && (
              <div className={styles.progressSection}>
                <ProgressBar label="Uploading Thumbnail" value={progress.thumbnail} />
                <ProgressBar label="Uploading Workout Video" value={progress.video} />
              </div>
            )}

            <div className={styles.formBody}>
              <div className={styles.leftCol}>

                <div className={styles.row2}>
                  <Input label="Workout Title" type="text" placeholder="e.g. 10 Minute Pilates Booty Burn" required error={errors.title?.message} {...register('title')} />
                  <Input label="Trainer Name" type="text" placeholder="Enter trainer name" required error={errors.trainer?.message} {...register('trainer')} />
                </div>

                <div className={styles.row2}>
                  {/* Category with "+ Add Category" option */}
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
                      <label style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-secondary)' }}>Category *</label>
                      <button
                        type="button"
                        onClick={() => setShowAddCategory(!showAddCategory)}
                        style={{ background: 'none', border: 'none', color: 'var(--color-primary)', fontSize: '12px', fontWeight: 600, cursor: 'pointer' }}
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
                          style={{ flex: 1, padding: '9px 12px', borderRadius: '10px', border: '1.5px solid var(--color-primary)', background: 'var(--color-surface)', color: 'var(--color-text)', fontSize: '13px', outline: 'none' }}
                        />
                        <button type="button" onClick={handleAddCategory} style={{ padding: '0 14px', borderRadius: 10, border: 'none', background: 'var(--color-primary)', color: 'white', fontSize: '12px', fontWeight: 600, cursor: 'pointer' }}>Add</button>
                      </div>
                    ) : (
                      <Controller name="category" control={control} render={({ field }) => (
                        <Select label="" options={categorySelectOptions} placeholder="Select category" required error={errors.category?.message} {...field} />
                      )} />
                    )}
                  </div>

                  <Controller name="difficulty" control={control} render={({ field }) => (
                    <Select label="Difficulty Level *" options={difficultyOptions} placeholder="Select difficulty" required error={errors.difficulty?.message} {...field} />
                  )} />
                </div>

                {/* Duration — always editable, auto-fills from video */}
                <div style={{ marginBottom: '16px' }}>
                  <Input label="Duration (MM:SS)" type="text" placeholder="e.g. 10:30" hint={detectedDuration ? `⏱ Auto-detected: ${detectedDuration}` : 'Enter manually or upload a video to auto-detect'} error={errors.duration?.message} {...register('duration')} />
                </div>

                <div className={styles.textareaWrapper}>
                  <Input as="textarea" label="Description" placeholder="Describe this workout..." required error={errors.description?.message} {...register('description')} />
                  <span className={styles.charCount}>{descriptionValue.length}/500</span>
                </div>

                {watch('videoSource') === 'youtube' && (
                  <div style={{ marginTop: '4px' }}>
                    <Input label="YouTube Video Link *" type="url" placeholder="https://www.youtube.com/watch?v=..." required error={errors.youtubeUrl?.message} {...register('youtubeUrl')} hint="Paste YouTube video URL for streaming playback in the mobile app" />
                  </div>
                )}

                {/* Props / Equipment Multi-Select + "+ Add Custom Prop" */}
                <div style={{ marginTop: '20px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                    <label style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-text-secondary)' }}>
                      Props / Equipment *{currentProps.length > 0 && <span style={{ color: 'var(--color-primary)', marginLeft: 6, fontWeight: 400 }}>({currentProps.length} selected)</span>}
                    </label>
                    <button
                      type="button"
                      onClick={() => setShowAddProp(!showAddProp)}
                      style={{ background: 'none', border: 'none', color: 'var(--color-primary)', fontSize: '12px', fontWeight: 600, cursor: 'pointer' }}
                    >
                      {showAddProp ? '✕ Cancel' : '+ Add Prop'}
                    </button>
                  </div>

                  {showAddProp && (
                    <div style={{ display: 'flex', gap: 6, marginBottom: 10 }}>
                      <input
                        type="text"
                        value={newPropInput}
                        onChange={(e) => setNewPropInput(e.target.value)}
                        onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); handleAddProp(); } }}
                        placeholder="e.g. Resistance Band, Foam Roller"
                        style={{ flex: 1, padding: '8px 12px', borderRadius: '10px', border: '1.5px solid var(--color-primary)', background: 'var(--color-surface)', color: 'var(--color-text)', fontSize: '13px', outline: 'none' }}
                      />
                      <button type="button" onClick={handleAddProp} style={{ padding: '0 14px', borderRadius: 10, border: 'none', background: 'var(--color-primary)', color: 'white', fontSize: '12px', fontWeight: 600, cursor: 'pointer' }}>Add</button>
                    </div>
                  )}

                  {errors.propsUsed && <p style={{ color: '#e74c3c', fontSize: '12px', marginBottom: '8px' }}>{String(errors.propsUsed.message ?? '')}</p>}
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                    {availableProps.map((prop) => {
                      const sel = currentProps.includes(prop);
                      return (<button key={prop} type="button" id={`prop-${prop.replace(/\s+/g, '-').toLowerCase()}`} onClick={() => toggle('propsUsed', prop)} style={{ padding: '6px 14px', borderRadius: '20px', border: `2px solid ${sel ? 'var(--color-primary)' : 'var(--color-border)'}`, background: sel ? 'var(--color-nav-active-bg)' : 'transparent', color: sel ? 'var(--color-primary)' : 'var(--color-text-secondary)', fontSize: '13px', fontWeight: sel ? 600 : 400, cursor: 'pointer', transition: 'all 0.15s ease' }}>{sel ? '✓ ' : ''}{prop}</button>);
                    })}
                  </div>
                </div>

                {/* Recommended Phases Multi-Select */}
                <div style={{ marginTop: '20px' }}>
                  <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '8px', color: 'var(--color-text-secondary)' }}>
                    Recommended Phases{currentPhases.length > 0 && <span style={{ color: 'var(--color-primary)', marginLeft: 6, fontWeight: 400 }}>({currentPhases.length} selected)</span>}
                  </label>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                    {RECOMMENDED_PHASES.map((phase) => {
                      const sel = currentPhases.includes(phase);
                      const bg = phaseColors[phase] ?? '#FFD8B3';
                      return (<button key={phase} type="button" id={`phase-${phase.replace(/\s+/g, '-').toLowerCase()}`} onClick={() => toggle('recommendedPhases', phase)} style={{ padding: '6px 14px', borderRadius: '20px', border: `2px solid ${sel ? '#8C654D' : 'transparent'}`, background: sel ? bg : 'var(--color-surface)', color: '#5C3D2A', fontSize: '13px', fontWeight: sel ? 600 : 400, cursor: 'pointer', transition: 'all 0.15s ease', opacity: sel ? 1 : 0.65 }}>{sel ? '✓ ' : ''}{phase}</button>);
                    })}
                  </div>
                </div>

                {/* Symptom-Friendly Multi-Select */}
                <div style={{ marginTop: '20px' }}>
                  <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '8px', color: 'var(--color-text-secondary)' }}>
                    Symptom-Friendly{currentSymptoms.length > 0 && <span style={{ color: 'var(--color-primary)', marginLeft: 6, fontWeight: 400 }}>({currentSymptoms.length} selected)</span>}
                  </label>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                    {SYMPTOM_OPTIONS.map((symptom) => {
                      const sel = currentSymptoms.includes(symptom);
                      return (<button key={symptom} type="button" id={`symptom-${symptom.replace(/\s+/g, '-').toLowerCase()}`} onClick={() => toggle('symptoms', symptom)} style={{ padding: '6px 14px', borderRadius: '20px', border: `2px solid ${sel ? 'var(--color-primary)' : 'var(--color-border)'}`, background: sel ? '#FFF6F9' : 'transparent', color: sel ? '#C2507A' : 'var(--color-text-secondary)', fontSize: '13px', fontWeight: sel ? 600 : 400, cursor: 'pointer', transition: 'all 0.15s ease' }}>{sel ? '✓ ' : ''}{symptom}</button>);
                    })}
                  </div>
                </div>

                {/* Benefits Dynamic Add/Remove */}
                <div style={{ marginTop: '20px' }}>
                  <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '8px', color: 'var(--color-text-secondary)' }}>Benefits</label>
                  {currentBenefits.length > 0 && (
                    <div style={{ marginBottom: '10px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
                      {currentBenefits.map((b, i) => (
                        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '8px 12px', background: 'var(--color-surface)', borderRadius: '10px', border: '1px solid var(--color-border)' }}>
                          <span style={{ flex: 1, fontSize: '13px', color: 'var(--color-text)' }}>✓ {b}</span>
                          <button type="button" onClick={() => removeBenefit(i)} style={{ background: 'none', border: 'none', color: 'var(--color-text-secondary)', cursor: 'pointer', fontSize: '18px', lineHeight: 1, padding: '2px' }} aria-label={`Remove benefit: ${b}`}>×</button>
                        </div>
                      ))}
                    </div>
                  )}
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <input id="benefit-input" type="text" value={benefitInput} onChange={(e) => setBenefitInput(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addBenefit(); } }} placeholder="e.g. Improves flexibility" style={{ flex: 1, padding: '9px 14px', borderRadius: '10px', border: '1.5px solid var(--color-border)', background: 'var(--color-surface)', color: 'var(--color-text)', fontSize: '13px', outline: 'none' }} />
                    <button id="add-benefit-btn" type="button" onClick={addBenefit} style={{ padding: '9px 18px', borderRadius: '10px', border: 'none', background: 'var(--color-primary)', color: 'white', fontSize: '13px', fontWeight: 600, cursor: 'pointer', whiteSpace: 'nowrap' }}>+ Add</button>
                  </div>
                </div>

              </div>

              {/* Right Column: Media */}
              <div className={styles.rightCol}>
                <div className={styles.uploadBox}>
                  <div className={styles.uploadBoxHeader}>
                    <span className={styles.uploadBoxTitle}>Thumbnail Image *</span>
                    <span className={styles.uploadBoxSubtitle}>Upload a high quality thumbnail image</span>
                  </div>
                  <Controller name="thumbnail" control={control} render={({ field }) => (<FileUpload label="" accept={ACCEPTED_IMAGE_TYPES.join(',')} type="image" required hint="JPG, PNG or WebP • Max 5MB • Recommended 16:9" error={errors.thumbnail?.message as string | undefined} value={field.value as FileList | undefined} onChange={(files) => field.onChange(files)} />)} />
                </div>

                {watch('videoSource') === 'custom' ? (
                  <div className={`${styles.uploadBox} ${watch('premium') ? styles.uploadBoxPaid : styles.uploadBoxFree}`}>
                    <div className={styles.uploadBoxHeader}>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <span className={styles.uploadBoxTitle}>{watch('premium') ? '🔒 Custom Video File (Paid)' : '🎁 Custom Video File (Free)'}</span>
                        {detectedDuration && (<span style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-primary)', background: 'var(--color-nav-active-bg)', padding: '2px 8px', borderRadius: 'var(--radius-full)' }}>⏱ {detectedDuration}</span>)}
                      </div>
                      <span className={styles.uploadBoxSubtitle}>Direct video upload to cloud storage</span>
                    </div>
                    <Controller name="video" control={control} render={({ field }) => (<FileUpload label="" accept={ACCEPTED_VIDEO_TYPES.join(',')} type="video" required hint="MP4, MOV or WebM • Max 2GB" error={errors.video?.message as string | undefined} value={field.value as FileList | undefined} onChange={(files) => handleVideoFileSelect(files as FileList | null | undefined, field.onChange)} />)} />
                  </div>
                ) : (
                  <div className={`${styles.uploadBox} ${watch('premium') ? styles.uploadBoxPaid : styles.uploadBoxFree}`}>
                    <div className={styles.uploadBoxHeader}>
                      <span className={styles.uploadBoxTitle}>{watch('premium') ? '🔒 YouTube Embed (Paid)' : '🎁 YouTube Embed (Free)'}</span>
                      <span className={styles.uploadBoxSubtitle}>This workout video will stream via YouTube link in the SYD FLOW mobile application.</span>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Footer Actions */}
            <div className={styles.formActions}>
              <Button id="cancel-upload-btn" type="button" variant="ghost" onClick={() => navigate(ROUTES.DASHBOARD)} disabled={isUploading}>Cancel</Button>
              <Button id="submit-upload-btn" type="submit" isLoading={isUploading} disabled={isUploading}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="17 8 12 3 7 8" /><line x1="12" y1="3" x2="12" y2="15" />
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
