/* ─────────────────────────────────────────────────────────────
   SYD FLOWS Web Admin – Zod Validation Schemas
   ───────────────────────────────────────────────────────────── */
import { z } from 'zod';
import {
  ACCEPTED_IMAGE_TYPES,
  MAX_THUMBNAIL_SIZE_BYTES,
  DIFFICULTY_LEVELS,
  CYCLE_PHASES,
  MAX_THUMBNAIL_SIZE_MB,
} from '@/constants';

/** Login form schema */
export const loginSchema = z.object({
  email: z
    .string()
    .min(1, 'Email is required')
    .email('Please enter a valid email address'),
  password: z
    .string()
    .min(1, 'Password is required')
    .min(6, 'Password must be at least 6 characters'),
});

export type LoginFormValues = z.infer<typeof loginSchema>;

/** Helper: validate a FileList has exactly one file of the right type/size */
const fileListSchema = (
  acceptedTypes: string[],
  maxBytes: number,
  maxMb: number,
  label: string,
) =>
  z
    .any()
    .refine((files: unknown) => files instanceof FileList && files.length > 0, {
      message: `${label} is required`,
    })
    .refine(
      (files: unknown) =>
        files instanceof FileList && acceptedTypes.includes(files[0]?.type),
      {
        message: `${label} must be one of: ${acceptedTypes.map((t) => t.split('/')[1]).join(', ')}`,
      },
    )
    .refine(
      (files: unknown) =>
        files instanceof FileList && files[0]?.size <= maxBytes,
      {
        message: `${label} must be smaller than ${maxMb}MB`,
      },
    );

/** Upload video form schema */
export const uploadVideoSchema = z.object({
  title: z
    .string()
    .min(1, 'Title is required')
    .max(100, 'Title must be 100 characters or less'),
  description: z
    .string()
    .min(1, 'Description is required')
    .max(500, 'Description must be 500 characters or less'),
  category: z.string().min(1, 'Please select or enter a category'),
  difficulty: z.enum(DIFFICULTY_LEVELS, {
    errorMap: () => ({ message: 'Please select a difficulty level' }),
  }),
  cyclePhase: z.enum(CYCLE_PHASES, {
    errorMap: () => ({ message: 'Please select a cycle phase' }),
  }),
  /** Multi-select props — at least one required */
  propsUsed: z.array(z.string()).min(1, 'Please select at least one prop / equipment'),
  duration: z.string().optional().default('00:00'),
  trainer: z
    .string()
    .min(1, 'Trainer name is required')
    .max(80, 'Trainer name must be 80 characters or less'),
  videoSource: z.enum(['youtube', 'custom']).default('custom'),
  youtubeUrl: z.string().optional(),
  premium: z.boolean(),
  /** Array of benefit text entries */
  benefits: z.array(z.string().min(1)).optional().default([]),
  /** Symptom-friendly tags */
  symptoms: z.array(z.string()).optional().default([]),
  /** Recommended cycle phases (multi-select) */
  recommendedPhases: z.array(z.string()).optional().default([]),
  thumbnail: fileListSchema(
    ACCEPTED_IMAGE_TYPES,
    MAX_THUMBNAIL_SIZE_BYTES,
    MAX_THUMBNAIL_SIZE_MB,
    'Thumbnail',
  ),
  video: z.any().optional(),
});

export type UploadVideoFormValues = z.infer<typeof uploadVideoSchema>;
