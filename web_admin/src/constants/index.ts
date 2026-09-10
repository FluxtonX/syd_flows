/* ─────────────────────────────────────────────────────────────
   SYD FLOWS Web Admin – Application Constants
   ───────────────────────────────────────────────────────────── */

/** Application routes */
export const ROUTES = {
  ROOT: '/',
  LOGIN: '/login',
  DASHBOARD: '/dashboard',
  VIDEOS: '/videos',
  UPLOAD: '/upload',
  SUBSCRIPTIONS: '/subscriptions',
  SUBSCRIBER_REQUESTS: '/subscriber-requests',
} as const;

/** Workout category options - strictly Yoga, Pilates, Strength, Mobility */
export const VIDEO_CATEGORIES = [
  'Yoga',
  'Pilates',
  'Strength',
  'Mobility',
] as const;

/** Cycle Phase options */
export const CYCLE_PHASES = [
  'Menstrual Phase',
  'Follicular Phase',
  'Ovulation Phase',
  'Luteal Phase',
] as const;

/** Props / Equipment options */
export const PROPS_OPTIONS = [
  'Mat',
  'Light Dumbbells',
  'Heavy Dumbbells',
  'Pilates Ball',
  'Pilates Circle',
  'Chair',
  'Booty Bands',
  'Yoga Blocks',
  'None',
] as const;

/** Difficulty level options */
export const DIFFICULTY_LEVELS = [
  'Beginner',
  'Intermediate',
  'Advanced',
] as const;

/** Cloudinary upload folder names — matches existing syd-flows folder structure */
export const CLOUDINARY_FOLDERS = {
  THUMBNAILS: 'syd-flows/profile-images',
  VIDEOS: 'syd-flows/workout-videos',
} as const;

/** File size limits */
export const MAX_VIDEO_SIZE_MB = 500;
export const MAX_THUMBNAIL_SIZE_MB = 10;
export const MAX_VIDEO_SIZE_BYTES = MAX_VIDEO_SIZE_MB * 1024 * 1024;
export const MAX_THUMBNAIL_SIZE_BYTES = MAX_THUMBNAIL_SIZE_MB * 1024 * 1024;

/** Accepted MIME types */
export const ACCEPTED_VIDEO_TYPES = ['video/mp4', 'video/mov', 'video/quicktime', 'video/x-msvideo'];
export const ACCEPTED_IMAGE_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

/** Firestore collection names */
export const FIRESTORE_COLLECTIONS = {
  VIDEOS: 'videos',
  SETTINGS: 'app_settings',
  SUBSCRIPTION_PLANS: 'subscription_plans',
  USERS: 'users',
  ADMIN_USERS: 'admin_users',
} as const;

/** Default Subscription Plans Configuration */
export const DEFAULT_SUBSCRIPTION_CONFIG = {
  heroTagline: 'PERSONALISED WELLNESS',
  heroTitle: 'Feel supported\nin every phase.',
  heroSubtitle: 'Unlock the complete workout library and deeper cycle guidance.',
  plans: [
    {
      id: 'annual',
      title: 'Annual Plan',
      badge: 'BEST VALUE',
      subtitle: 'First 7 days free, then $59.99/yr',
      price: '$4.99',
      period: '/ month (billed annually)',
      detail: '$59.99 charged annually',
      trialDays: 7,
      enabled: true,
    },
    {
      id: 'monthly',
      title: 'Monthly Plan',
      badge: '',
      subtitle: 'Flexible, cancel anytime',
      price: '$9.99',
      period: '/ month',
      detail: 'Billed monthly',
      trialDays: 0,
      enabled: true,
    },
  ],
};

/** Symptom-friendly options for multi-select */
export const SYMPTOM_OPTIONS = [
  'Bloating',
  'Fatigue',
  'Cramps',
  'Low mood',
  'Headache',
  'Anxious',
  'Back pain',
  'Brain fog',
  'Nausea',
  'Low energy',
] as const;

/** Recommended cycle phases — same as CYCLE_PHASES but used for multi-select */
export const RECOMMENDED_PHASES = [
  'Menstrual Phase',
  'Follicular Phase',
  'Ovulation Phase',
  'Luteal Phase',
] as const;
