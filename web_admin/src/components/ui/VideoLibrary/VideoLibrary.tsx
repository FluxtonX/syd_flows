/* ─────────────────────────────────────────────────────────────
   VideoLibrary Component
   Fetches and displays all uploaded videos in a filterable grid with Delete capability.
   ───────────────────────────────────────────────────────────── */
import { useState, useEffect, useMemo } from 'react';
import { getVideos, deleteVideo } from '@/services/firebase/firestore';
import { deleteCloudinaryAsset } from '@/services/cloudinary/upload';
import { ConfirmModal } from '@/components/ui/ConfirmModal/ConfirmModal';
import { EditVideoModal } from '@/components/ui/EditVideoModal/EditVideoModal';
import { VIDEO_CATEGORIES } from '@/constants';
import type { VideoRecord } from '@/types';
import { VideoCard } from '../VideoCard/VideoCard';
import styles from './VideoLibrary.module.css';

export function VideoLibrary() {
  const [videos, setVideos] = useState<VideoRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [activeFilter, setActiveFilter] = useState<string>('All');

  const [targetVideo, setTargetVideo] = useState<VideoRecord | null>(null);
  const [editingVideo, setEditingVideo] = useState<VideoRecord | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  const fetchAllVideos = async () => {
    setIsLoading(true);
    const data = await getVideos();
    setVideos(data);
    setIsLoading(false);
  };

  useEffect(() => {
    fetchAllVideos();
  }, []);

  const handleDeleteClick = (video: VideoRecord) => {
    setTargetVideo(video);
  };

  const handleEditClick = (video: VideoRecord) => {
    setEditingVideo(video);
  };

  const handleSaveEdit = (updatedVideo: VideoRecord) => {
    setVideos((prev) =>
      prev.map((v) => (v.id === updatedVideo.id ? updatedVideo : v)),
    );
  };

  const handleConfirmDelete = async () => {
    if (!targetVideo) return;
    setIsDeleting(true);
    try {
      // 1. Delete thumbnail image from Cloudinary if present
      if (targetVideo.thumbnailPublicId) {
        await deleteCloudinaryAsset(targetVideo.thumbnailPublicId, 'image');
      }

      // 2. Delete video file from Cloudinary if present
      if (targetVideo.videoPublicId) {
        await deleteCloudinaryAsset(targetVideo.videoPublicId, 'video');
      }

      // 3. Delete document record from Cloud Firestore
      await deleteVideo(targetVideo.id);

      setVideos((prev) => prev.filter((v) => v.id !== targetVideo.id));
      setTargetVideo(null);
    } catch (err) {
      console.error('Failed to delete video:', err);
    } finally {
      setIsDeleting(false);
    }
  };

  const filtered = useMemo(() => {
    if (activeFilter === 'All') return videos;
    return videos.filter((v) => v.category === activeFilter);
  }, [videos, activeFilter]);

  const filters = ['All', ...VIDEO_CATEGORIES];

  return (
    <section className={styles.section} aria-labelledby="library-title">
      {/* Header */}
      <div className={styles.header}>
        <div className={styles.titleRow}>
          <h2 id="library-title" className={styles.title}>Video Library</h2>
          {!isLoading && (
            <span className={styles.countBadge}>
              {filtered.length} {filtered.length === 1 ? 'video' : 'videos'}
            </span>
          )}
        </div>

        {/* Category filters */}
        {!isLoading && videos.length > 0 && (
          <div className={styles.filters} role="tablist" aria-label="Filter by category">
            {filters.map((f) => (
              <button
                key={f}
                role="tab"
                aria-selected={activeFilter === f}
                className={`${styles.filterBtn} ${activeFilter === f ? styles.filterBtnActive : ''}`}
                onClick={() => setActiveFilter(f)}
              >
                {f}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Grid */}
      <div className={styles.grid}>
        {isLoading ? (
          // Loading skeletons
          Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className={styles.skeleton} aria-hidden="true">
              <div className={styles.skeletonThumb} />
              <div className={styles.skeletonBody}>
                <div className={styles.skeletonLine} style={{ width: '60%' }} />
                <div className={styles.skeletonLine} style={{ width: '90%' }} />
                <div className={styles.skeletonLine} style={{ width: '40%' }} />
              </div>
            </div>
          ))
        ) : filtered.length === 0 ? (
          <div className={styles.empty}>
            <div className={styles.emptyIcon} aria-hidden="true">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <polygon points="23 7 16 12 23 17 23 7" />
                <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
              </svg>
            </div>
            <p className={styles.emptyTitle}>
              {activeFilter === 'All' ? 'No videos uploaded yet' : `No ${activeFilter} videos`}
            </p>
            <p className={styles.emptyText}>
              {activeFilter === 'All'
                ? 'Upload your first workout video using the button above.'
                : `Try a different category filter or upload a ${activeFilter} video.`}
            </p>
          </div>
        ) : (
          filtered.map((video) => (
            <VideoCard
              key={video.id}
              video={video}
              onEdit={handleEditClick}
              onDelete={handleDeleteClick}
            />
          ))
        )}
      </div>

      {/* Edit Video Modal */}
      <EditVideoModal
        isOpen={Boolean(editingVideo)}
        video={editingVideo}
        onSave={handleSaveEdit}
        onClose={() => setEditingVideo(null)}
      />

      {/* Confirmation Modal */}
      <ConfirmModal
        isOpen={Boolean(targetVideo)}
        title="Delete Workout Video"
        message={`Are you sure you want to delete "${targetVideo?.title || 'this video'}"? This action will permanently remove it from Firestore.`}
        confirmLabel="Delete Video"
        cancelLabel="Cancel"
        isLoading={isDeleting}
        onConfirm={handleConfirmDelete}
        onCancel={() => setTargetVideo(null)}
      />
    </section>
  );
}
