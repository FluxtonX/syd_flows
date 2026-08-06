/* ─────────────────────────────────────────────────────────────
   Firebase – Firestore Service
   ───────────────────────────────────────────────────────────── */
import {
  collection,
  addDoc,
  deleteDoc,
  updateDoc,
  doc,
  getCountFromServer,
  getDocs,
  query,
  orderBy,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from './config';
import { FIRESTORE_COLLECTIONS } from '@/constants';
import type { VideoDocument, VideoRecord } from '@/types';

/**
 * Save a new video document to the `videos` Firestore collection.
 * Returns the auto-generated document ID.
 */
export async function saveVideoMetadata(
  data: Omit<VideoDocument, 'createdAt'>,
): Promise<string> {
  if (!db) throw new Error('Firebase is not configured. Please set up your .env file.');
  try {
    const videosRef = collection(db, FIRESTORE_COLLECTIONS.VIDEOS);
    const docRef = await addDoc(videosRef, {
      ...data,
      createdAt: serverTimestamp(),
    });
    return docRef.id;
  } catch (error: unknown) {
    throw new Error(getFirestoreErrorMessage(error));
  }
}

/**
 * Update an existing video document in Firestore by document ID.
 */
export async function updateVideoMetadata(
  videoId: string,
  data: Partial<Omit<VideoDocument, 'createdAt'>>,
): Promise<void> {
  if (!db) throw new Error('Firebase is not configured. Please set up your .env file.');
  try {
    const videoRef = doc(db, FIRESTORE_COLLECTIONS.VIDEOS, videoId);
    await updateDoc(videoRef, data);
  } catch (error: unknown) {
    throw new Error(getFirestoreErrorMessage(error));
  }
}

/**
 * Delete a video document from Firestore by document ID.
 */
export async function deleteVideo(videoId: string): Promise<void> {
  if (!db) throw new Error('Firebase is not configured. Please set up your .env file.');
  try {
    const videoRef = doc(db, FIRESTORE_COLLECTIONS.VIDEOS, videoId);
    await deleteDoc(videoRef);
  } catch (error: unknown) {
    throw new Error(getFirestoreErrorMessage(error));
  }
}

/**
 * Get the total count of documents in the `videos` collection.
 * Uses server-side aggregation for efficiency.
 */
export async function getVideoCount(): Promise<number> {
  if (!db) return 0;
  try {
    const videosRef = collection(db, FIRESTORE_COLLECTIONS.VIDEOS);
    const snapshot = await getCountFromServer(videosRef);
    return snapshot.data().count;
  } catch {
    return 0;
  }
}

/**
 * Fetch all videos from Firestore, ordered newest first.
 */
export async function getVideos(): Promise<VideoRecord[]> {
  if (!db) return [];
  try {
    const videosRef = collection(db, FIRESTORE_COLLECTIONS.VIDEOS);
    const q = query(videosRef, orderBy('createdAt', 'desc'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map((docSnapshot) => ({
      id: docSnapshot.id,
      ...(docSnapshot.data() as Omit<VideoRecord, 'id'>),
    }));
  } catch {
    return [];
  }
}

/** Maps Firestore error codes to user-friendly messages */
function getFirestoreErrorMessage(error: unknown): string {
  if (typeof error === 'object' && error !== null && 'code' in error) {
    const code = (error as { code: string }).code;
    switch (code) {
      case 'permission-denied':
        return 'Permission denied. Please ensure you are authenticated.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Firestore operation failed. Please try again.';
    }
  }
  return 'An unexpected error occurred while accessing data.';
}
