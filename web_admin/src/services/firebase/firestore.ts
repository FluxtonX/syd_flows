/* ─────────────────────────────────────────────────────────────
   Firebase – Firestore Service
   ───────────────────────────────────────────────────────────── */
import {
  collection,
  collectionGroup,
  addDoc,
  setDoc,
  getDoc,
  deleteDoc,
  updateDoc,
  doc,
  getDocs,
  query,
  orderBy,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from './config';
import { FIRESTORE_COLLECTIONS, DEFAULT_SUBSCRIPTION_CONFIG } from '@/constants';
import type {
  VideoDocument,
  VideoRecord,
  SubscriptionPlansConfig,
  SubscriptionRequestRecord,
} from '@/types';

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
    const videos = await getVideos();
    return videos.length;
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
    return snapshot.docs
      .filter((docSnapshot) => !docSnapshot.id.startsWith('_settings'))
      .map((docSnapshot) => ({
        id: docSnapshot.id,
        ...(docSnapshot.data() as Omit<VideoRecord, 'id'>),
      }));
  } catch {
    return [];
  }
}

// ── Subscription Management ───────────────────────────────────

/**
 * Fetch active subscription plans & pricing config from Firestore.
 */
export async function getSubscriptionPlansConfig(): Promise<SubscriptionPlansConfig> {
  if (!db) return DEFAULT_SUBSCRIPTION_CONFIG;
  try {
    const videoSettingsDoc = doc(db, FIRESTORE_COLLECTIONS.VIDEOS, '_settings_plans');
    const snap = await getDoc(videoSettingsDoc);
    if (snap.exists() && snap.data()) {
      const data = snap.data();
      return {
        ...DEFAULT_SUBSCRIPTION_CONFIG,
        ...data,
        plans: Array.isArray(data.plans) && data.plans.length > 0
          ? data.plans
          : DEFAULT_SUBSCRIPTION_CONFIG.plans,
      } as SubscriptionPlansConfig;
    }

    const appSettingsDoc = doc(
      db,
      FIRESTORE_COLLECTIONS.SETTINGS,
      FIRESTORE_COLLECTIONS.SUBSCRIPTION_PLANS,
    );
    const snapOld = await getDoc(appSettingsDoc);
    if (snapOld.exists() && snapOld.data()) {
      const data = snapOld.data();
      return {
        ...DEFAULT_SUBSCRIPTION_CONFIG,
        ...data,
        plans: Array.isArray(data.plans) && data.plans.length > 0
          ? data.plans
          : DEFAULT_SUBSCRIPTION_CONFIG.plans,
      } as SubscriptionPlansConfig;
    }

    return DEFAULT_SUBSCRIPTION_CONFIG;
  } catch (error) {
    console.warn('Error fetching subscription plans config, using defaults:', error);
    return DEFAULT_SUBSCRIPTION_CONFIG;
  }
}

/**
 * Save updated subscription plans & pricing config to Firestore.
 */
export async function saveSubscriptionPlansConfig(
  config: SubscriptionPlansConfig,
): Promise<void> {
  if (!db) throw new Error('Firebase is not configured.');
  try {
    const videoSettingsDoc = doc(db, FIRESTORE_COLLECTIONS.VIDEOS, '_settings_plans');
    const appSettingsDoc = doc(
      db,
      FIRESTORE_COLLECTIONS.SETTINGS,
      FIRESTORE_COLLECTIONS.SUBSCRIPTION_PLANS,
    );

    const dataToSave = {
      ...config,
      updatedAt: serverTimestamp(),
    };

    await Promise.all([
      setDoc(videoSettingsDoc, dataToSave, { merge: true }),
      setDoc(appSettingsDoc, dataToSave, { merge: true }),
    ]);
  } catch (error: unknown) {
    throw new Error(getFirestoreErrorMessage(error));
  }
}

/**
 * Fetch all subscription requests across users, deduplicating per user and enriching with real user profile details.
 */
export async function getAllSubscriptionRequests(): Promise<SubscriptionRequestRecord[]> {
  if (!db) return [];
  try {
    const reqGroup = collectionGroup(db, 'subscription_requests');
    const snap = await getDocs(reqGroup);
    const rawList: SubscriptionRequestRecord[] = [];
    const userCache = new Map<string, { email: string; displayName: string }>();

    for (const docSnap of snap.docs) {
      const data = docSnap.data();
      const parentUserDoc = docSnap.ref.parent.parent;
      const userId = parentUserDoc?.id || data.userId || '';

      let email = data.userEmail || '';
      let name = data.displayName || '';

      // If name or email are missing, fetch from parent user document
      if ((!email || !name) && userId) {
        if (!userCache.has(userId)) {
          try {
            const uSnap = await getDoc(doc(db, FIRESTORE_COLLECTIONS.USERS, userId));
            if (uSnap.exists()) {
              const uData = uSnap.data();
              userCache.set(userId, {
                email: uData.email || '',
                displayName: uData.displayName || '',
              });
            } else {
              userCache.set(userId, { email: '', displayName: '' });
            }
          } catch {
            userCache.set(userId, { email: '', displayName: '' });
          }
        }
        const cached = userCache.get(userId);
        if (cached) {
          if (!email && cached.email) email = cached.email;
          if (!name && cached.displayName) name = cached.displayName;
        }
      }

      rawList.push({
        id: docSnap.id,
        userId,
        userEmail: email,
        displayName: name || (email ? email.split('@')[0] : 'App User'),
        planId: data.planId || 'annual',
        status: data.status || 'pending',
        source: data.source || 'mobile_app',
        requestedAt: data.requestedAt,
        approvedAt: data.approvedAt,
      });
    }

    // Deduplicate: show only ONE distinct request per user, prioritizing 'pending' status
    const distinctMap = new Map<string, SubscriptionRequestRecord>();
    for (const req of rawList) {
      if (!req.userId) continue;
      if (!distinctMap.has(req.userId)) {
        distinctMap.set(req.userId, req);
      } else {
        const existing = distinctMap.get(req.userId)!;
        if (req.status === 'pending' && existing.status !== 'pending') {
          distinctMap.set(req.userId, req);
        } else if (req.status === 'approved' && existing.status !== 'pending' && existing.status !== 'approved') {
          distinctMap.set(req.userId, req);
        } else if (req.id === 'current' && existing.id !== 'current' && existing.status !== 'pending') {
          distinctMap.set(req.userId, req);
        }
      }
    }

    return Array.from(distinctMap.values());
  } catch (error) {
    console.warn('Error fetching subscription requests with collectionGroup, falling back to users list:', error);
    try {
      const usersSnap = await getDocs(collection(db, FIRESTORE_COLLECTIONS.USERS));
      const results: SubscriptionRequestRecord[] = [];
      for (const uDoc of usersSnap.docs) {
        const uData = uDoc.data();
        const reqsSnap = await getDocs(
          collection(db, FIRESTORE_COLLECTIONS.USERS, uDoc.id, 'subscription_requests'),
        );
        if (!reqsSnap.empty) {
          // Prioritize pending request doc if present, or doc 'current'
          const docs = reqsSnap.docs;
          const pendingDoc = docs.find((d) => (d.data().status || '').toLowerCase() === 'pending');
          const currentDoc = docs.find((d) => d.id === 'current');
          const rDoc = pendingDoc || currentDoc || docs[0];
          const rData = rDoc.data();
          const email = rData.userEmail || uData.email || '';
          const name = rData.displayName || uData.displayName || (email ? email.split('@')[0] : 'App User');

          results.push({
            id: rDoc.id,
            userId: uDoc.id,
            userEmail: email,
            displayName: name,
            planId: rData.planId || 'annual',
            status: rData.status || 'pending',
            source: rData.source || 'mobile_app',
            requestedAt: rData.requestedAt,
            approvedAt: rData.approvedAt,
          });
        }
      }
      return results;
    } catch {
      return [];
    }
  }
}

/**
 * Approve a user's subscription request and activate user entitlement.
 */
export async function approveSubscriptionRequest(
  userId: string,
  requestId: string,
  planId: string = 'annual',
): Promise<void> {
  if (!db) throw new Error('Firebase is not configured.');
  try {
    // 1. Update all requests for this user to approved and clean duplicates
    try {
      const userReqs = await getDocs(
        collection(db, FIRESTORE_COLLECTIONS.USERS, userId, 'subscription_requests'),
      );
      for (const rDoc of userReqs.docs) {
        await updateDoc(rDoc.ref, {
          status: 'approved',
          approvedAt: serverTimestamp(),
        });
      }
    } catch {
      const reqRef = doc(
        db,
        FIRESTORE_COLLECTIONS.USERS,
        userId,
        'subscription_requests',
        requestId,
      );
      await updateDoc(reqRef, {
        status: 'approved',
        approvedAt: serverTimestamp(),
      });
    }

    // 2. Update user profile subscription field & isPremium
    const userRef = doc(db, FIRESTORE_COLLECTIONS.USERS, userId);
    await setDoc(
      userRef,
      {
        subscription: {
          status: 'active',
          planId,
          source: 'admin_approved',
          updatedAt: serverTimestamp(),
        },
        isPremium: true,
      },
      { merge: true },
    );
  } catch (error: unknown) {
    throw new Error(getFirestoreErrorMessage(error));
  }
}

/**
 * Revoke or cancel a user's subscription.
 */
export async function revokeUserSubscription(
  userId: string,
  requestId?: string,
): Promise<void> {
  if (!db) throw new Error('Firebase is not configured.');
  if (!userId) return;
  try {
    // 1. Update all requests under subcollection
    try {
      const userReqs = await getDocs(
        collection(db, FIRESTORE_COLLECTIONS.USERS, userId, 'subscription_requests'),
      );
      for (const rDoc of userReqs.docs) {
        await setDoc(
          rDoc.ref,
          { status: 'cancelled', revokedAt: serverTimestamp() },
          { merge: true },
        );
      }
    } catch {
      // Fallback
    }

    // 2. Explicitly update 'current' doc
    try {
      const currentRef = doc(
        db,
        FIRESTORE_COLLECTIONS.USERS,
        userId,
        'subscription_requests',
        'current',
      );
      await setDoc(
        currentRef,
        { status: 'cancelled', revokedAt: serverTimestamp() },
        { merge: true },
      );
    } catch {}

    if (requestId && requestId !== 'current') {
      try {
        const reqRef = doc(
          db,
          FIRESTORE_COLLECTIONS.USERS,
          userId,
          'subscription_requests',
          requestId,
        );
        await setDoc(
          reqRef,
          { status: 'cancelled', revokedAt: serverTimestamp() },
          { merge: true },
        );
      } catch {}
    }

    // 3. Reset user entitlement in user document
    const userRef = doc(db, FIRESTORE_COLLECTIONS.USERS, userId);
    await setDoc(
      userRef,
      {
        subscription: {
          status: 'inactive',
          updatedAt: serverTimestamp(),
        },
        isPremium: false,
      },
      { merge: true },
    );
  } catch (error: unknown) {
    throw new Error(getFirestoreErrorMessage(error));
  }
}

/**
 * Delete a user's subscription request completely.
 */
export async function deleteSubscriptionRequest(
  userId: string,
  requestId: string,
): Promise<void> {
  if (!db) throw new Error('Firebase is not configured.');
  if (!userId) return;
  try {
    // 1. Delete all request documents under subcollection
    try {
      const userReqs = await getDocs(
        collection(db, FIRESTORE_COLLECTIONS.USERS, userId, 'subscription_requests'),
      );
      for (const rDoc of userReqs.docs) {
        await deleteDoc(rDoc.ref);
      }
    } catch {}

    // 2. Explicitly delete 'current' doc and requestId doc
    try {
      await deleteDoc(
        doc(db, FIRESTORE_COLLECTIONS.USERS, userId, 'subscription_requests', 'current'),
      );
    } catch {}

    if (requestId && requestId !== 'current') {
      try {
        await deleteDoc(
          doc(db, FIRESTORE_COLLECTIONS.USERS, userId, 'subscription_requests', requestId),
        );
      } catch {}
    }

    // 3. Reset user doc entitlement
    const userRef = doc(db, FIRESTORE_COLLECTIONS.USERS, userId);
    await setDoc(
      userRef,
      {
        subscription: {
          status: 'inactive',
          updatedAt: serverTimestamp(),
        },
        isPremium: false,
      },
      { merge: true },
    );
  } catch (error: unknown) {
    throw new Error(getFirestoreErrorMessage(error));
  }
}

/** Maps Firestore error codes to user-friendly messages */
function getFirestoreErrorMessage(error: unknown): string {
  if (typeof error === 'object' && error !== null && 'code' in error) {
    const code = (error as { code: string }).code;
    switch (code) {
      case 'permission-denied':
        return 'Permission denied. Please ensure you are authenticated as Admin.';
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

