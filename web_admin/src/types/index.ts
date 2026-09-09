/* ─────────────────────────────────────────────────────────────
   SYD FLOWS Web Admin – Types
   ───────────────────────────────────────────────────────────── */

/** Firestore document shape for the `videos` collection */
export interface VideoDocument {
  title: string;
  description: string;
  category: string;
  difficulty: string;
  duration: string;
  trainer: string;
  premium?: boolean;
  isPaid?: boolean;
  isFree?: boolean;
  videoSource: 'youtube' | 'custom';
  youtubeUrl?: string;
  youtubeId?: string;
  /** Supports both legacy string ("Mat") and new multi-select string[] (["Mat","Chair"]) */
  propsUsed: string | string[];
  cyclePhase: string;
  /** Array of recommended cycle phases (multi-select) */
  recommendedPhases?: string[];
  /** Array of benefit descriptions */
  benefits?: string[];
  /** Array of symptom-friendly tags */
  symptoms?: string[];
  thumbnailUrl: string;
  thumbnailPublicId: string;
  videoUrl: string;
  videoPublicId: string;
  createdAt: Date;
}

/** Saved Firestore document (with auto-generated ID) */
export interface VideoRecord extends VideoDocument {
  id: string;
}

/** Authenticated admin user */
export interface AuthUser {
  uid: string;
  email: string | null;
  displayName: string | null;
}

/** Admin Registration & Initialization Status */
export interface AdminStatus {
  initialized: boolean;
  allowRegistration: boolean;
  adminCount?: number;
  adminEmail?: string;
}

/** Per-file upload progress (0–100) */
export interface UploadProgress {
  thumbnail: number;
  video: number;
}

/** Result from a single Cloudinary upload */
export interface CloudinaryUploadResult {
  secureUrl: string;
  publicId: string;
}

/** Upload form field values */
export interface UploadFormValues {
  title: string;
  description: string;
  category: string;
  difficulty: string;
  duration: string;
  trainer: string;
  premium: boolean;
  videoSource: 'youtube' | 'custom';
  youtubeUrl?: string;
  propsUsed: string;
  cyclePhase: string;
  thumbnail?: FileList;
  video?: FileList;
}

/** Individual Subscription Plan */
export interface SubscriptionPlanItem {
  id: string;
  title: string;
  badge?: string;
  subtitle: string;
  price: string;
  period: string;
  detail: string;
  trialDays?: number;
  enabled: boolean;
}

/** Complete Subscription Settings document in /app_settings/subscription_plans */
export interface SubscriptionPlansConfig {
  heroTagline: string;
  heroTitle: string;
  heroSubtitle: string;
  plans: SubscriptionPlanItem[];
  updatedAt?: Date | null;
}

/** Subscription Request from a mobile app user */
export interface SubscriptionRequestRecord {
  id: string;
  userId: string;
  userEmail?: string;
  displayName?: string;
  planId: string;
  status: 'pending' | 'approved' | 'active' | 'rejected' | 'cancelled';
  source?: string;
  requestedAt?: any;
  approvedAt?: any;
}

