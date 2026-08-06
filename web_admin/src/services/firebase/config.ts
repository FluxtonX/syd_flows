/* ─────────────────────────────────────────────────────────────
   Firebase – App Initialization (Safe / Graceful)
   ───────────────────────────────────────────────────────────── */
import { initializeApp, getApps, getApp, type FirebaseApp } from 'firebase/app';
import { getAuth, type Auth } from 'firebase/auth';
import { getFirestore, type Firestore } from 'firebase/firestore';

const apiKey = import.meta.env.VITE_FIREBASE_API_KEY;
const authDomain = import.meta.env.VITE_FIREBASE_AUTH_DOMAIN;
const projectId = import.meta.env.VITE_FIREBASE_PROJECT_ID;
const storageBucket = import.meta.env.VITE_FIREBASE_STORAGE_BUCKET;
const appId = import.meta.env.VITE_FIREBASE_APP_ID;

/** True if all required Firebase env vars are present and non-empty */
export const isFirebaseConfigured =
  Boolean(apiKey) &&
  Boolean(authDomain) &&
  Boolean(projectId) &&
  Boolean(appId);

let app: FirebaseApp | null = null;
let auth: Auth | null = null;
let db: Firestore | null = null;

if (isFirebaseConfigured) {
  const firebaseConfig = {
    apiKey: apiKey as string,
    authDomain: authDomain as string,
    projectId: projectId as string,
    storageBucket: storageBucket as string,
    appId: appId as string,
  };

  // Prevent duplicate initialization during HMR
  app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();
  auth = getAuth(app);
  db = getFirestore(app);
}

export { auth, db };
export default app;
