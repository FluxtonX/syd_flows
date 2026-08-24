/* ─────────────────────────────────────────────────────────────
   Hook – useVideoUpload
   Orchestrates: thumbnail upload → video upload → Firestore save
   ───────────────────────────────────────────────────────────── */
import { useState, useCallback } from 'react';
import { uploadFile } from '@/services/cloudinary/upload';
import { saveVideoMetadata } from '@/services/firebase/firestore';
import { CLOUDINARY_FOLDERS } from '@/constants';
import type { UploadProgress } from '@/types';
import type { UploadVideoFormValues } from '@/utils/validators';

interface UseVideoUploadReturn {
  uploadVideo: (data: UploadVideoFormValues) => Promise<string>;
  progress: UploadProgress;
  isUploading: boolean;
  error: string | null;
  clearError: () => void;
}

const DEFAULT_PROGRESS: UploadProgress = { thumbnail: 0, video: 0 };

function extractYouTubeId(url?: string): string {
  if (!url) return '';
  const regExp = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/;
  const match = url.match(regExp);
  return match && match[1]?.length === 11 ? match[1] : '';
}

export function useVideoUpload(): UseVideoUploadReturn {
  const [progress, setProgress] = useState<UploadProgress>(DEFAULT_PROGRESS);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const uploadVideo = useCallback(async (data: UploadVideoFormValues): Promise<string> => {
    setIsUploading(true);
    setError(null);
    setProgress(DEFAULT_PROGRESS);

    try {
      const thumbnailFile = data.thumbnail ? data.thumbnail[0] : null;
      let thumbnailUrl = '';
      let thumbnailPublicId = '';
      let videoUrl = '';
      let videoPublicId = '';
      let youtubeId = '';

      const isPaid = Boolean(data.premium);
      const isFree = !isPaid;
      const isYouTube = data.videoSource === 'youtube';

      // Step 1: Upload thumbnail if provided
      if (thumbnailFile) {
        const thumbnailResult = await uploadFile(
          thumbnailFile,
          CLOUDINARY_FOLDERS.THUMBNAILS,
          'image',
          (percent) => setProgress((prev) => ({ ...prev, thumbnail: percent })),
        );
        thumbnailUrl = thumbnailResult.secureUrl;
        thumbnailPublicId = thumbnailResult.publicId;
      }

      // Step 2: Handle Video URL / File Upload
      if (isYouTube) {
        if (!data.youtubeUrl) {
          throw new Error('Please enter a valid YouTube URL.');
        }
        videoUrl = data.youtubeUrl;
        youtubeId = extractYouTubeId(data.youtubeUrl);
        setProgress((prev) => ({ ...prev, video: 100 }));
      } else {
        if (!data.video || data.video.length === 0) {
          throw new Error('Please select a video file to upload.');
        }
        const videoFile = data.video[0];
        const videoResult = await uploadFile(
          videoFile,
          CLOUDINARY_FOLDERS.VIDEOS,
          'video',
          (percent) => setProgress((prev) => ({ ...prev, video: percent })),
        );
        videoUrl = videoResult.secureUrl;
        videoPublicId = videoResult.publicId;
      }

      // Step 3: Save metadata to Firestore
      const docId = await saveVideoMetadata({
        title: data.title,
        description: data.description,
        category: data.category,
        difficulty: data.difficulty,
        duration: data.duration || '00:00',
        trainer: data.trainer,
        premium: isPaid,
        isPaid,
        isFree,
        videoSource: data.videoSource,
        youtubeUrl: isYouTube ? data.youtubeUrl : '',
        youtubeId: isYouTube ? youtubeId : '',
        propsUsed: data.propsUsed,
        cyclePhase: data.cyclePhase,
        recommendedPhases: data.recommendedPhases ?? [],
        benefits: data.benefits ?? [],
        symptoms: data.symptoms ?? [],
        thumbnailUrl,
        thumbnailPublicId,
        videoUrl,
        videoPublicId,
      });

      return docId;
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : 'An unexpected error occurred during upload.';
      setError(message);
      throw new Error(message);
    } finally {
      setIsUploading(false);
    }
  }, []);

  const clearError = useCallback(() => setError(null), []);

  return { uploadVideo, progress, isUploading, error, clearError };
}
