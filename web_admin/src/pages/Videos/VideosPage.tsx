/* ─────────────────────────────────────────────────────────────
   VideosPage – Full Workout Videos Management Page
   Lists all uploaded videos with search, filters, edit & delete
   ───────────────────────────────────────────────────────────── */
import { useState, useEffect, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { AppLayout } from '@/components/layout/AppLayout/AppLayout';
import { ConfirmModal } from '@/components/ui/ConfirmModal/ConfirmModal';
import { EditVideoModal } from '@/components/ui/EditVideoModal/EditVideoModal';
import { getVideos, deleteVideo } from '@/services/firebase/firestore';
import { deleteCloudinaryAsset } from '@/services/cloudinary/upload';
import {
  ROUTES,
  VIDEO_CATEGORIES,
  DIFFICULTY_LEVELS,
} from '@/constants';
import type { VideoRecord } from '@/types';
import styles from './VideosPage.module.css';

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

export function VideosPage() {
  const [videos, setVideos] = useState<VideoRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Filters state
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('All');
  const [tierFilter, setTierFilter] = useState<'All' | 'Free' | 'Paid'>('All');
  const [difficultyFilter, setDifficultyFilter] = useState<string>('All');

  // Modal actions state
  const [editingVideo, setEditingVideo] = useState<VideoRecord | null>(null);
  const [targetDeleteVideo, setTargetDeleteVideo] = useState<VideoRecord | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  const loadAllVideos = async () => {
    setIsLoading(true);
    try {
      const data = await getVideos();
      setVideos(data);
    } catch (err) {
      console.error('Failed to load videos:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadAllVideos();
  }, []);

  // Filtered videos calculation
  const filteredVideos = useMemo(() => {
    return videos.filter((video) => {
      // Search filter
      const query = searchQuery.toLowerCase().trim();
      const matchesSearch =
        !query ||
        (video.title || '').toLowerCase().includes(query) ||
        (video.trainer || '').toLowerCase().includes(query) ||
        (video.description || '').toLowerCase().includes(query);

      // Category filter
      const matchesCategory =
        categoryFilter === 'All' ||
        (video.category || '').toLowerCase() === categoryFilter.toLowerCase();

      // Tier filter
      const isFree = video.isFree || video.videoSource === 'youtube';
      const matchesTier =
        tierFilter === 'All' ||
        (tierFilter === 'Free' && isFree) ||
        (tierFilter === 'Paid' && !isFree);

      // Difficulty filter
      const matchesDifficulty =
        difficultyFilter === 'All' ||
        (video.difficulty || '').toLowerCase() === difficultyFilter.toLowerCase();

      return matchesSearch && matchesCategory && matchesTier && matchesDifficulty;
    });
  }, [videos, searchQuery, categoryFilter, tierFilter, difficultyFilter]);

  // Statistics summaries
  const stats = useMemo(() => {
    const total = videos.length;
    const freeCount = videos.filter((v) => v.isFree || v.videoSource === 'youtube').length;
    const paidCount = total - freeCount;
    return { total, freeCount, paidCount };
  }, [videos]);

  // Handle video edit saved
  const handleSaveEdit = (updatedVideo: VideoRecord) => {
    setVideos((prev) =>
      prev.map((v) => (v.id === updatedVideo.id ? updatedVideo : v)),
    );
  };

  // Handle video deletion confirmed
  const handleConfirmDelete = async () => {
    if (!targetDeleteVideo) return;
    setIsDeleting(true);
    try {
      if (targetDeleteVideo.thumbnailPublicId) {
        await deleteCloudinaryAsset(targetDeleteVideo.thumbnailPublicId, 'image');
      }
      if (targetDeleteVideo.videoPublicId) {
        await deleteCloudinaryAsset(targetDeleteVideo.videoPublicId, 'video');
      }
      await deleteVideo(targetDeleteVideo.id);
      setVideos((prev) => prev.filter((v) => v.id !== targetDeleteVideo.id));
      setTargetDeleteVideo(null);
    } catch (err) {
      console.error('Failed to delete video:', err);
    } finally {
      setIsDeleting(false);
    }
  };

  const hasActiveFilters =
    searchQuery.trim() !== '' ||
    categoryFilter !== 'All' ||
    tierFilter !== 'All' ||
    difficultyFilter !== 'All';

  const clearFilters = () => {
    setSearchQuery('');
    setCategoryFilter('All');
    setTierFilter('All');
    setDifficultyFilter('All');
  };

  return (
    <AppLayout>
      <div className={styles.page}>
        {/* Top Header */}
        <div className={styles.header}>
          <div className={styles.titleGroup}>
            <h1 className={styles.title}>Workout Videos</h1>
            <p className={styles.subtitle}>
              Manage, filter, and organize all uploaded video content for SYD FLOWS
            </p>
          </div>
          <Link to={ROUTES.UPLOAD} className={styles.uploadBtn}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <line x1="12" y1="5" x2="12" y2="19" />
              <line x1="5" y1="12" x2="19" y2="12" />
            </svg>
            <span>Upload Video</span>
          </Link>
        </div>

        {/* Stats Cards Row */}
        <div className={styles.statsGrid}>
          <div className={styles.statCard}>
            <div className={styles.statIcon}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <polygon points="23 7 16 12 23 17 23 7" />
                <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
              </svg>
            </div>
            <div className={styles.statMeta}>
              <span className={styles.statValue}>{stats.total}</span>
              <span className={styles.statLabel}>Total Videos</span>
            </div>
          </div>

          <div className={styles.statCard}>
            <div className={styles.statIcon} style={{ color: '#10B981', background: 'rgba(16, 185, 129, 0.1)' }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M20 12V8H6a2 2 0 0 1-2-2c0-1.1.9-2 2-2h12v4" />
                <path d="M4 6v12c0 1.1.9 2 2 2h14v-4" />
                <path d="M18 12a2 2 0 0 0-2 2c0 1.1.9 2 2 2h4v-4h-4z" />
              </svg>
            </div>
            <div className={styles.statMeta}>
              <span className={styles.statValue}>{stats.freeCount}</span>
              <span className={styles.statLabel}>Free Workouts</span>
            </div>
          </div>

          <div className={styles.statCard}>
            <div className={styles.statIcon} style={{ color: '#D97706', background: 'rgba(245, 158, 11, 0.1)' }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="8" r="7" />
                <polyline points="8.21 13.89 7 23 12 20 17 23 15.79 13.88" />
              </svg>
            </div>
            <div className={styles.statMeta}>
              <span className={styles.statValue}>{stats.paidCount}</span>
              <span className={styles.statLabel}>Premium Workouts</span>
            </div>
          </div>
        </div>

        {/* Filter Controls Bar */}
        <div className={styles.controlsCard}>
          <div className={styles.searchRow}>
            {/* Search Input */}
            <div className={styles.searchBox}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className={styles.searchIcon}>
                <circle cx="11" cy="11" r="8" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
              <input
                type="text"
                className={styles.searchInput}
                placeholder="Search videos by title, trainer, or description..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>

            {/* Category Filter */}
            <select
              className={styles.filterSelect}
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
            >
              <option value="All">All Categories</option>
              {VIDEO_CATEGORIES.map((cat) => (
                <option key={cat} value={cat}>
                  {cat}
                </option>
              ))}
            </select>

            {/* Access Tier Filter */}
            <select
              className={styles.filterSelect}
              value={tierFilter}
              onChange={(e) => setTierFilter(e.target.value as 'All' | 'Free' | 'Paid')}
            >
              <option value="All">All Tiers (Free & Paid)</option>
              <option value="Free">Free Workouts</option>
              <option value="Paid">Premium Workouts</option>
            </select>

            {/* Difficulty Filter */}
            <select
              className={styles.filterSelect}
              value={difficultyFilter}
              onChange={(e) => setDifficultyFilter(e.target.value)}
            >
              <option value="All">All Difficulties</option>
              {DIFFICULTY_LEVELS.map((diff) => (
                <option key={diff} value={diff}>
                  {diff}
                </option>
              ))}
            </select>

            {/* Reset Filters */}
            {hasActiveFilters && (
              <button
                type="button"
                className={styles.clearFiltersBtn}
                onClick={clearFilters}
              >
                Reset Filters
              </button>
            )}
          </div>
        </div>

        {/* Videos Table */}
        <div className={styles.tableContainer}>
          <div className={styles.tableWrapper}>
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>Thumbnail</th>
                  <th>Title & Trainer</th>
                  <th>Category</th>
                  <th>Duration</th>
                  <th>Tier</th>
                  <th>Status</th>
                  <th>Uploaded Date</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  <tr>
                    <td colSpan={8} className={styles.emptyState}>
                      Loading workout videos...
                    </td>
                  </tr>
                ) : filteredVideos.length === 0 ? (
                  <tr>
                    <td colSpan={8} className={styles.emptyState}>
                      <div className={styles.emptyStateContent}>
                        <div className={styles.emptyIcon}>
                          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <circle cx="12" cy="12" r="10" />
                            <line x1="8" y1="12" x2="16" y2="12" />
                          </svg>
                        </div>
                        <div>
                          <strong>No videos found</strong>
                          <p style={{ margin: '4px 0 0 0', opacity: 0.8 }}>
                            {hasActiveFilters
                              ? 'Try adjusting your search query or filter criteria.'
                              : 'No workout videos have been uploaded yet.'}
                          </p>
                        </div>
                      </div>
                    </td>
                  </tr>
                ) : (
                  filteredVideos.map((video) => {
                    const isFree = video.isFree || video.videoSource === 'youtube';

                    return (
                      <tr key={video.id}>
                        {/* Thumbnail */}
                        <td>
                          <div className={styles.thumbBox}>
                            {video.thumbnailUrl ? (
                              <img
                                src={video.thumbnailUrl}
                                alt={video.title}
                                className={styles.thumbImg}
                              />
                            ) : null}
                            <div className={styles.playOverlay}>
                              <svg width="14" height="14" viewBox="0 0 24 24" fill="white">
                                <polygon points="5 3 19 12 5 21 5 3" />
                              </svg>
                            </div>
                          </div>
                        </td>

                        {/* Title & Trainer */}
                        <td>
                          <div className={styles.titleCell}>
                            <span className={styles.videoTitle}>{video.title}</span>
                            {video.trainer && (
                              <span className={styles.videoTrainer}>Trainer: {video.trainer}</span>
                            )}
                          </div>
                        </td>

                        {/* Category */}
                        <td>
                          <span className={styles.categoryPill}>{video.category || 'Yoga'}</span>
                        </td>

                        {/* Duration */}
                        <td>{video.duration || '—'}</td>

                        {/* Tier (Free vs Premium) */}
                        <td>
                          {isFree ? (
                            <span className={styles.tierPillFree}>🎁 Free</span>
                          ) : (
                            <span className={styles.tierPillPaid}>🔒 Premium</span>
                          )}
                        </td>

                        {/* Status */}
                        <td>
                          <span
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: '4px',
                              padding: '2px 8px',
                              borderRadius: '10px',
                              fontSize: '11px',
                              fontWeight: 600,
                              background: '#ECFDF5',
                              color: '#059669',
                            }}
                          >
                            Live
                          </span>
                        </td>

                        {/* Uploaded Date */}
                        <td>{formatDate(video.createdAt)}</td>

                        {/* Actions */}
                        <td>
                          <div className={styles.actionGroup}>
                            <a
                              href={video.videoUrl}
                              target="_blank"
                              rel="noopener noreferrer"
                              className={styles.actionBtn}
                              title="View video asset stream"
                            >
                              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                                <circle cx="12" cy="12" r="3" />
                              </svg>
                            </a>

                            <button
                              type="button"
                              className={styles.actionBtn}
                              title="Edit metadata"
                              onClick={() => setEditingVideo(video)}
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
                              onClick={() => setTargetDeleteVideo(video)}
                            >
                              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                                <polyline points="3 6 5 6 21 6" />
                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                              </svg>
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
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
          isOpen={Boolean(targetDeleteVideo)}
          title="Delete Workout Video"
          message={`Are you sure you want to delete "${targetDeleteVideo?.title || 'this video'}"? This will permanently remove its metadata and Cloudinary media files.`}
          confirmLabel="Delete Video"
          cancelLabel="Cancel"
          isLoading={isDeleting}
          onConfirm={handleConfirmDelete}
          onCancel={() => setTargetDeleteVideo(null)}
        />
      </div>
    </AppLayout>
  );
}
