/* ─────────────────────────────────────────────────────────────
   SYD FLOWS – Firestore-Based Admin Authentication Service
   Manages admin accounts directly in Firestore collections with custom logic
   (No Firebase Auth account lockouts or password restrictions).
   ───────────────────────────────────────────────────────────── */
import {
  doc,
  setDoc,
  getDoc,
  getDocs,
  deleteDoc,
  collection,
  query,
  where,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from './config';
import { FIRESTORE_COLLECTIONS } from '@/constants';
import type { AdminStatus, AuthUser } from '@/types';

export const MAX_ADMIN_ACCOUNTS = 3;
const SESSION_STORAGE_KEY = 'syd_admin_session';

type AuthListener = (user: AuthUser | null) => void;
const listeners = new Set<AuthListener>();

function notifyAuthState(user: AuthUser | null): void {
  listeners.forEach((cb) => {
    try {
      cb(user);
    } catch {
      // Ignore listener errors
    }
  });
}

/**
 * Retrieves the currently active admin session from storage.
 */
export function getCurrentAdminUser(): AuthUser | null {
  try {
    const raw = localStorage.getItem(SESSION_STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as AuthUser;
  } catch {
    return null;
  }
}

/**
 * Saves or clears the current admin session in storage.
 */
function setCurrentAdminUser(user: AuthUser | null): void {
  try {
    if (user) {
      localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(user));
    } else {
      localStorage.removeItem(SESSION_STORAGE_KEY);
    }
  } catch {
    // Ignore localStorage errors
  }
  notifyAuthState(user);
}

/**
 * Check if the admin accounts have been initialized and whether registration is allowed in Firestore.
 */
export async function checkIfAdminInitialized(): Promise<AdminStatus> {
  if (!db) {
    return {
      initialized: false,
      allowRegistration: true,
      adminCount: 0,
    };
  }

  try {
    // 1. Primary check: query dedicated admin_users collection
    let adminDocs = (await getDocs(collection(db, FIRESTORE_COLLECTIONS.ADMIN_USERS))).docs;

    // 2. Fallback check: query users collection for role == 'admin'
    if (adminDocs.length === 0) {
      const qFallback = query(
        collection(db, FIRESTORE_COLLECTIONS.USERS),
        where('role', '==', 'admin'),
      );
      adminDocs = (await getDocs(qFallback)).docs;
    }

    const realAdminCount = adminDocs.length;

    let primaryAdminEmail: string | undefined;
    adminDocs.forEach((d) => {
      const email = d.data()?.email;
      if (email && typeof email === 'string' && !primaryAdminEmail) {
        primaryAdminEmail = email.toLowerCase().trim();
      }
    });

    const isInit = realAdminCount > 0;
    const canRegisterMore = realAdminCount < MAX_ADMIN_ACCOUNTS;

    return {
      initialized: isInit,
      allowRegistration: canRegisterMore,
      adminCount: realAdminCount,
      adminEmail: primaryAdminEmail,
    };
  } catch {
    return {
      initialized: false,
      allowRegistration: true,
      adminCount: 0,
    };
  }
}

let isRegisteringAdminFlag = false;

export function getIsRegisteringAdmin(): boolean {
  return isRegisteringAdminFlag;
}

export function setIsRegisteringAdmin(val: boolean): void {
  isRegisteringAdminFlag = val;
}

/**
 * Register an Admin Account directly in Firestore.
 * Creates/Updates the admin profile in Firestore dedicated admin_users collection.
 */
export async function registerFirstAdminAccount(
  email: string,
  password: string,
  displayName: string,
): Promise<AuthUser> {
  if (!db) throw new Error('Firebase is not configured.');
  setIsRegisteringAdmin(true);

  const cleanEmail = email.toLowerCase().trim();
  const cleanDocId = `admin_${cleanEmail.replace(/[^a-zA-Z0-9]/g, '_')}`;

  try {
    // 1. Live check count
    const status = await checkIfAdminInitialized();
    const currentCount = status.adminCount ?? 0;

    // Check if account with this email already exists in admin_users or users
    const qAdmin = query(
      collection(db, FIRESTORE_COLLECTIONS.ADMIN_USERS),
      where('email', '==', cleanEmail),
    );
    let existingSnap = await getDocs(qAdmin);

    if (existingSnap.empty) {
      const qUser = query(
        collection(db, FIRESTORE_COLLECTIONS.USERS),
        where('email', '==', cleanEmail),
      );
      existingSnap = await getDocs(qUser);
    }

    if (existingSnap.empty && currentCount >= MAX_ADMIN_ACCOUNTS) {
      throw new Error(
        'Admin registration is closed. You can update existing credentials via "Forgot or Change Password".',
      );
    }

    const docId = !existingSnap.empty ? existingSnap.docs[0].id : cleanDocId;

    // 2. Save admin user document ONLY in dedicated admin_users collection
    const adminData = {
      uid: docId,
      email: cleanEmail,
      displayName: displayName.trim() || 'SYD FLOWS Admin',
      password: password,
      role: 'admin',
      isSuperAdmin: true,
      updatedAt: serverTimestamp(),
      createdAt: serverTimestamp(),
    };

    await setDoc(doc(db, FIRESTORE_COLLECTIONS.ADMIN_USERS, docId), adminData, { merge: true });

    // Clean up any legacy admin docs from users collection
    cleanupAdminFromUsersCollection().catch(() => {});

    // 3. Set setting marker for backward compatibility
    const updateMarker = {
      adminEmail: cleanEmail,
      password: password,
      displayName: displayName.trim() || 'SYD FLOWS Admin',
      updatedAt: serverTimestamp(),
    };
    await Promise.allSettled([
      setDoc(doc(db, FIRESTORE_COLLECTIONS.VIDEOS, '_settings_admin'), updateMarker, { merge: true }),
      setDoc(doc(db, FIRESTORE_COLLECTIONS.SETTINGS, 'admin_config'), updateMarker, { merge: true }),
    ]);

    const authUser: AuthUser = {
      uid: docId,
      email: cleanEmail,
      displayName: displayName.trim() || 'SYD FLOWS Admin',
    };

    setCurrentAdminUser(authUser);
    return authUser;
  } catch (error: unknown) {
    if (error instanceof Error) throw error;
    throw new Error('Failed to register admin account.');
  } finally {
    setIsRegisteringAdmin(false);
  }
}

/**
 * Sign in with email and password via Firestore logic directly from admin_users collection.
 */
export async function signInWithEmail(email: string, password: string): Promise<AuthUser> {
  if (!db) throw new Error('Firebase Firestore is not configured.');
  const cleanEmail = email.toLowerCase().trim();

  try {
    // 1. Query dedicated admin_users collection
    const qAdmin = query(
      collection(db, FIRESTORE_COLLECTIONS.ADMIN_USERS),
      where('email', '==', cleanEmail),
    );
    let querySnap = await getDocs(qAdmin);

    // 2. Fallback: Query users collection if not found in admin_users
    if (querySnap.empty) {
      const qUser = query(
        collection(db, FIRESTORE_COLLECTIONS.USERS),
        where('email', '==', cleanEmail),
      );
      querySnap = await getDocs(qUser);
    }

    if (querySnap.empty) {
      // Also check if admin exists in settings
      const settingsDoc = await getDoc(doc(db, FIRESTORE_COLLECTIONS.SETTINGS, 'admin_config'));
      if (settingsDoc.exists()) {
        const sData = settingsDoc.data();
        if (sData?.adminEmail?.toLowerCase() === cleanEmail && (!sData.password || sData.password === password)) {
          const authUser: AuthUser = {
            uid: 'admin_master',
            email: cleanEmail,
            displayName: sData.displayName || 'SYD FLOWS Admin',
          };
          setCurrentAdminUser(authUser);
          return authUser;
        }
      }

      // Check if no admins initialized yet -> guide to create one
      const status = await checkIfAdminInitialized();
      if (!status.initialized) {
        throw new Error('No admin accounts found. Please click "Create Admin Account" to set up.');
      }

      throw new Error('Admin account with this email was not found. Please verify your email.');
    }

    // Found matching document
    const userDoc = querySnap.docs[0];
    const data = userDoc.data();

    // Verify role if in users collection
    if (data.role && data.role !== 'admin' && data.isSuperAdmin !== true) {
      throw new Error('Access denied. This account does not have administrator privileges.');
    }

    // Verify password if set in Firestore doc
    if (data.password && data.password !== password) {
      throw new Error('Invalid password. Please enter the correct password or update it below.');
    }

    const authUser: AuthUser = {
      uid: userDoc.id,
      email: cleanEmail,
      displayName: data.displayName || 'SYD FLOWS Admin',
    };

    setCurrentAdminUser(authUser);
    return authUser;
  } catch (error: unknown) {
    if (error instanceof Error) throw error;
    throw new Error('Failed to sign in. Please verify your admin credentials.');
  }
}

/**
 * Sign out the current admin user.
 */
export async function signOutUser(): Promise<void> {
  setCurrentAdminUser(null);
}

/**
 * Subscribe to auth state changes.
 */
export function onAuthStateChange(callback: (user: AuthUser | null) => void): () => void {
  listeners.add(callback);
  // Emit initial state
  callback(getCurrentAdminUser());
  return () => {
    listeners.delete(callback);
  };
}

/**
 * Update / Reset Admin Password in Firestore:
 * Updates the password directly in Firestore admin_users collection for the admin email.
 */
export async function updateAdminPassword(
  email: string,
  currentPassword: string,
  newPassword: string,
): Promise<void> {
  if (!db) throw new Error('Firebase is not configured.');
  const cleanEmail = email.toLowerCase().trim();

  if (!cleanEmail) throw new Error('Please enter your admin email.');
  if (newPassword.length < 6) {
    throw new Error('New password must be at least 6 characters.');
  }

  try {
    const qAdmin = query(
      collection(db, FIRESTORE_COLLECTIONS.ADMIN_USERS),
      where('email', '==', cleanEmail),
    );
    let querySnap = await getDocs(qAdmin);

    if (querySnap.empty) {
      const qUser = query(
        collection(db, FIRESTORE_COLLECTIONS.USERS),
        where('email', '==', cleanEmail),
      );
      querySnap = await getDocs(qUser);
    }

    const cleanDocId = `admin_${cleanEmail.replace(/[^a-zA-Z0-9]/g, '_')}`;
    const targetDocId = !querySnap.empty ? querySnap.docs[0].id : cleanDocId;

    if (!querySnap.empty) {
      const data = querySnap.docs[0].data();
      if (currentPassword && data.password && data.password !== currentPassword) {
        throw new Error('Current password does not match.');
      }
    }

    const updatedData = {
      uid: targetDocId,
      email: cleanEmail,
      password: newPassword,
      role: 'admin',
      isSuperAdmin: true,
      displayName: 'SYD FLOWS Admin',
      updatedAt: serverTimestamp(),
    };

    // Update password directly ONLY in admin_users collection
    await setDoc(doc(db, FIRESTORE_COLLECTIONS.ADMIN_USERS, targetDocId), updatedData, { merge: true });

    // Clean up any legacy admin doc from users collection
    cleanupAdminFromUsersCollection().catch(() => {});

    // Update settings marker
    const updateMarker = {
      password: newPassword,
      adminEmail: cleanEmail,
      updatedAt: serverTimestamp(),
    };

    await Promise.allSettled([
      setDoc(doc(db, FIRESTORE_COLLECTIONS.VIDEOS, '_settings_admin'), updateMarker, { merge: true }),
      setDoc(doc(db, FIRESTORE_COLLECTIONS.SETTINGS, 'admin_config'), updateMarker, { merge: true }),
    ]);
  } catch (error: unknown) {
    if (error instanceof Error) throw error;
    throw new Error('Failed to update admin password in Firestore.');
  }
}

/**
 * Automatically cleans up any legacy admin credential documents accidentally written to the mobile app `users` collection.
 */
export async function cleanupAdminFromUsersCollection(): Promise<void> {
  if (!db) return;
  try {
    const qUsersAdmin = query(
      collection(db, FIRESTORE_COLLECTIONS.USERS),
      where('role', '==', 'admin'),
    );
    const snap = await getDocs(qUsersAdmin);
    for (const docSnap of snap.docs) {
      if (docSnap.id.startsWith('admin_') || docSnap.data().role === 'admin') {
        await deleteDoc(docSnap.ref);
      }
    }
  } catch (err) {
    console.warn('Cleanup of admin docs from users collection skipped:', err);
  }
}
