/* ─────────────────────────────────────────────────────────────
   RecentVideos Component
   Renders recent videos in a table format with Delete capability
   ───────────────────────────────────────────────────────────── */
import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getVideos, deleteVideo } from '@/services/firebase/firestore';
import { deleteCloudinaryAsset } from '@/services/cloudinary/upload';
import { ConfirmModal } from '@/components/ui/ConfirmModal/ConfirmModal';
import { EditVideoModal } from '@/components/ui/EditVideoModal/EditVideoModal';
import { ROUTES } from '@/constants';
import type { VideoRecord } from '@/types';
import styles from './RecentVideos.module.css';

function formatDate(value: unknown): string {
  try {
    const date =
      value && typeof (value as { toDate?: () => Date }).toDate === 'function'
        ? (value as { toDate: () => Date }).toDate()
        : new Date(value as string);
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  } catch {
    return '—';
  }
}

export function RecentVideos() {
  const [videos, setVideos] = useState<VideoRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [targetVideo, setTargetVideo] = useState<VideoRecord | null>(null);
  const [editingVideo, setEditingVideo] = useState<VideoRecord | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  const fetchRecent = async () => {
    setIsLoading(true);
    const data = await getVideos();
    setVideos(data.slice(0, 5));
    setIsLoading(false);
  };

  useEffect(() => {
    fetchRecent();
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

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <h2 className={styles.title}>Recent Videos</h2>
        <Link to={ROUTES.VIDEOS} className={styles.viewAll}>
          View All
        </Link>
      </div>

      <div className={styles.tableWrapper}>
        <table className={styles.table}>
          <thead>
            <tr>
              <th>Thumbnail</th>
              <th>Title</th>
              <th>Category</th>
              <th>Duration</th>
              <th>Status</th>
              <th>Uploaded At</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr>
                <td colSpan={7} className={styles.emptyState}>
                  Loading recent videos...
                </td>
              </tr>
            ) : videos.length === 0 ? (
              <tr>
                <td colSpan={7} className={styles.emptyState}>
                  No workout videos uploaded yet.
                </td>
              </tr>
            ) : (
              videos.map((video) => (
                <tr key={video.id}>
                  {/* Thumbnail */}
                  <td>
                    <div className={styles.thumbBox}>
                      {video.thumbnailUrl ? (
                        <img src={video.thumbnailUrl} alt={video.title} className={styles.thumbImg} />
                      ) : null}
                      <div className={styles.playOverlay}>
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="white">
                          <polygon points="5 3 19 12 5 21 5 3" />
                        </svg>
                      </div>
                    </div>
                  </td>

                  {/* Title & Description */}
                  <td>
                    <div className={styles.titleCell}>
                      <span className={styles.videoTitle}>{video.title}</span>
                      <span className={styles.videoDesc}>{video.description}</span>
                    </div>
                  </td>

                  {/* Category */}
                  <td>
                    <span className={styles.categoryPill}>{video.category}</span>
                  </td>

                  {/* Duration */}
                  <td>{video.duration || '—'}</td>

                  {/* Status */}
                  <td>
                    <span className={styles.statusBadge}>Live</span>
                  </td>

                  {/* Uploaded At */}
                  <td>{formatDate(video.createdAt)}</td>

                  {/* Action */}
                  <td>
                    <div className={styles.actionGroup}>
                      <a
                        href={video.videoUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className={styles.actionBtn}
                        title="View video asset"
                      >
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                          <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                          <circle cx="12" cy="12" r="3" />
                        </svg>
                      </a>

                      <button
                        type="button"
                        className={styles.actionBtn}
                        title="Edit video metadata"
                        onClick={() => handleEditClick(video)}
                      >
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                          <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                        </svg>
                      </button>

                      <button
                        type="button"
                        className={`${styles.actionBtn} ${styles.deleteBtn}`}
                        title="Delete video"
                        onClick={() => handleDeleteClick(video)}
                      >
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <polyline points="3 6 5 6 21 6" />
                          <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                        </svg>
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Edit Video Modal */}
      <EditVideoModal
        isOpen={Boolean(editingVideo)}
        video={editingVideo}
        onSave={handleSaveEdit}
        onClose={() => setEditingVideo(null)}
      />

      {/* Delete Confirmation Modal */}
      <ConfirmModal
        isOpen={Boolean(targetVideo)}
        title="Delete Workout Video"
        message={`Are you sure you want to delete "${targetVideo?.title || 'this video'}"? This will permanently remove it from Cloud Firestore.`}
        confirmLabel="Delete Video"
        cancelLabel="Cancel"
        isLoading={isDeleting}
        onConfirm={handleConfirmDelete}
        onCancel={() => setTargetVideo(null)}
      />
    </div>
  );
}
