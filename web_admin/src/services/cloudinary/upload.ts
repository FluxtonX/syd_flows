/* ─────────────────────────────────────────────────────────────
   Cloudinary – Upload Service
   ───────────────────────────────────────────────────────────── */
import axios from 'axios';
import type { CloudinaryUploadResult } from '@/types';

const CLOUD_NAME = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME as string;
const UPLOAD_PRESET = import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET as string;

const CLOUDINARY_BASE_URL = `https://api.cloudinary.com/v1_1/${CLOUD_NAME}`;

interface CloudinaryResponse {
  secure_url: string;
  public_id: string;
}

interface CloudinaryErrorResponse {
  error?: { message: string };
}

/**
 * Upload a single file (image or video) to Cloudinary via unsigned upload preset.
 *
 * @param file         The file to upload
 * @param folder       Cloudinary destination folder (e.g. 'syd-flows/workout-videos')
 * @param resourceType 'image' or 'video'
 * @param onProgress   Optional progress callback (0–100)
 */
export async function uploadFile(
  file: File,
  folder: string,
  resourceType: 'image' | 'video',
  onProgress?: (percent: number) => void,
): Promise<CloudinaryUploadResult> {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_preset', UPLOAD_PRESET);
  formData.append('folder', folder);

  try {
    const response = await axios.post<CloudinaryResponse>(
      `${CLOUDINARY_BASE_URL}/${resourceType}/upload`,
      formData,
      {
        onUploadProgress: (progressEvent) => {
          if (progressEvent.total && onProgress) {
            const percent = Math.round(
              (progressEvent.loaded * 100) / progressEvent.total,
            );
            onProgress(percent);
          }
        },
      },
    );

    return {
      secureUrl: response.data.secure_url,
      publicId: response.data.public_id,
    };
  } catch (error: unknown) {
    throw new Error(getCloudinaryErrorMessage(error));
  }
}

const API_KEY = import.meta.env.VITE_CLOUDINARY_API_KEY as string | undefined;
const API_SECRET = import.meta.env.VITE_CLOUDINARY_API_SECRET as string | undefined;

/**
 * Generates SHA-1 signature for Cloudinary API requests using Web Crypto API.
 */
async function generateSha1Signature(
  params: Record<string, string>,
  secret: string,
): Promise<string> {
  const sortedKeys = Object.keys(params).sort();
  const serialized =
    sortedKeys.map((key) => `${key}=${params[key]}`).join('&') + secret;
  const encoder = new TextEncoder();
  const data = encoder.encode(serialized);
  const hashBuffer = await window.crypto.subtle.digest('SHA-1', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Delete a media asset (image or video) from Cloudinary using its publicId.
 */
export async function deleteCloudinaryAsset(
  publicId: string,
  resourceType: 'image' | 'video',
): Promise<boolean> {
  if (!CLOUD_NAME || !publicId) return false;

  const formData = new FormData();
  formData.append('public_id', publicId);

  if (API_KEY && API_SECRET) {
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const signature = await generateSha1Signature(
      { public_id: publicId, timestamp },
      API_SECRET,
    );
    formData.append('api_key', API_KEY);
    formData.append('timestamp', timestamp);
    formData.append('signature', signature);
  } else if (UPLOAD_PRESET) {
    formData.append('upload_preset', UPLOAD_PRESET);
  }

  try {
    const response = await axios.post(
      `${CLOUDINARY_BASE_URL}/${resourceType}/destroy`,
      formData,
    );
    return response.data?.result === 'ok';
  } catch (error) {
    console.warn(`[Cloudinary Delete] Failed to delete ${resourceType} (${publicId}):`, error);
    return false;
  }
}

/** Maps Cloudinary/Axios errors to precise user-friendly messages */
function getCloudinaryErrorMessage(error: unknown): string {
  if (axios.isAxiosError(error)) {
    if (!error.response) {
      return 'Network error. Please check your internet connection and try again.';
    }

    const status = error.response.status;
    // Extract the actual Cloudinary error message from the response body
    const cloudinaryMsg = (error.response.data as CloudinaryErrorResponse)?.error?.message ?? '';

    // Signed preset used for unsigned upload (most common cause of 400)
    if (
      status === 400 &&
      cloudinaryMsg.toLowerCase().includes('upload preset must be whitelisted')
    ) {
      return (
        'Upload preset "' + UPLOAD_PRESET + '" is set to Signed mode. ' +
        'Change it to Unsigned in Cloudinary Dashboard → Settings → Upload Presets → Edit → Signing Mode: Unsigned.'
      );
    }

    if (status === 400) {
      return cloudinaryMsg
        ? `Cloudinary error: ${cloudinaryMsg}`
        : `Upload rejected (400). Check that the upload preset "${UPLOAD_PRESET}" exists and is set to Unsigned mode.`;
    }

    if (status === 401 || status === 403) {
      return `Upload permission denied. Ensure the "${UPLOAD_PRESET}" preset is set to Unsigned in Cloudinary Settings.`;
    }

    if (status === 404) {
      return `Cloud name or upload preset not found. Check VITE_CLOUDINARY_CLOUD_NAME and VITE_CLOUDINARY_UPLOAD_PRESET in .env`;
    }

    if (status === 413) {
      return 'File is too large for Cloudinary to accept. Try a smaller file.';
    }

    return cloudinaryMsg
      ? `Upload failed: ${cloudinaryMsg}`
      : `Upload failed (${status}). Please try again.`;
  }

  return 'An unexpected error occurred during upload. Please try again.';
}
