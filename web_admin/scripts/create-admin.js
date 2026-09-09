#!/usr/bin/env node
/**
 * ─────────────────────────────────────────────────────────────
 * SYD FLOWS Web Admin – Create Admin User Script
 * ─────────────────────────────────────────────────────────────
 * Usage:
 *   node scripts/create-admin.js <email> <password>
 *
 * Example:
 *   node scripts/create-admin.js admin@sydflows.com MyStr0ngP@ss!
 * ─────────────────────────────────────────────────────────────
 */

import https from 'https';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// ESM equivalent of __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// ── 1. Read .env file ────────────────────────────────────────
const envPath = path.join(__dirname, '../.env');

if (!fs.existsSync(envPath)) {
  console.error('\n❌  .env file not found at web_admin/.env');
  console.error('   Please create it first using .env.example\n');
  process.exit(1);
}

const envContent = fs.readFileSync(envPath, 'utf8');
const env = {};
envContent.split('\n').forEach((line) => {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith('#')) return;
  const eqIndex = trimmed.indexOf('=');
  if (eqIndex === -1) return;
  const key = trimmed.substring(0, eqIndex).trim();
  const val = trimmed.substring(eqIndex + 1).trim();
  env[key] = val;
});

// ── 2. Validate inputs ───────────────────────────────────────
const API_KEY = env['VITE_FIREBASE_API_KEY'];
const email    = process.argv[2];
const password = process.argv[3];

if (!API_KEY) {
  console.error('\n❌  VITE_FIREBASE_API_KEY is missing in .env\n');
  process.exit(1);
}

if (!email || !password) {
  console.error('\n❌  Usage: node scripts/create-admin.js <email> <password>');
  console.error('   Example: node scripts/create-admin.js admin@sydflows.com MyStr0ngP@ss!\n');
  process.exit(1);
}

if (password.length < 6) {
  console.error('\n❌  Password must be at least 6 characters\n');
  process.exit(1);
}

// ── 3. Create user via Firebase Auth REST API ────────────────
const body = JSON.stringify({
  email,
  password,
  returnSecureToken: true,
});

const options = {
  hostname: 'identitytoolkit.googleapis.com',
  path: `/v1/accounts:signUp?key=${API_KEY}`,
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body),
  },
};

console.log('\n🔄  Creating admin user...');
console.log(`   Email    : ${email}`);
console.log(`   Project  : ${env['VITE_FIREBASE_PROJECT_ID'] ?? 'unknown'}\n`);

// Helper to write to Firestore via REST API
function writeFirestoreDoc(pathDoc, fields, idToken, projectId) {
  return new Promise((resolve) => {
    const docBody = JSON.stringify({ fields });
    const patchOptions = {
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${projectId}/databases/(default)/documents/${pathDoc}`,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${idToken}`,
        'Content-Length': Buffer.byteLength(docBody),
      },
    };

    const req = https.request(patchOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch {
          resolve({ error: 'Failed to parse response' });
        }
      });
    });

    req.on('error', (err) => {
      console.warn('   ⚠️ Could not write to Firestore document:', err.message);
      resolve({ error: err.message });
    });

    req.write(docBody);
    req.end();
  });
}

const req = https.request(options, async (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', async () => {
    const parsed = JSON.parse(data);

    if (parsed.error) {
      const code = parsed.error.message;
      console.error('❌  Firebase error:', friendlyError(code));
      console.error('   Code:', code, '\n');
      process.exit(1);
    }

    // ── SUCCESS ──────────────────────────────────────────────
    const uid = parsed.localId ?? '';
    const idToken = parsed.idToken ?? '';
    const projectId = env['VITE_FIREBASE_PROJECT_ID'] ?? 'syd-flows';

    console.log('✅  Admin user created in Firebase Auth!');
    console.log('🔄  Saving admin credentials in Firestore...');

    const nowIso = new Date().toISOString();
    const userFields = {
      uid: { stringValue: uid },
      email: { stringValue: email },
      displayName: { stringValue: email.split('@')[0] },
      password: { stringValue: password },
      role: { stringValue: 'admin' },
      isSuperAdmin: { booleanValue: true },
      createdAt: { timestampValue: nowIso },
      updatedAt: { timestampValue: nowIso },
    };

    const settingsFields = {
      initialized: { booleanValue: true },
      allowRegistration: { booleanValue: false },
      adminEmail: { stringValue: email.toLowerCase() },
      adminUid: { stringValue: uid },
      password: { stringValue: password },
      updatedAt: { timestampValue: nowIso },
    };

    await Promise.all([
      writeFirestoreDoc(`users/${uid}`, userFields, idToken, projectId),
      writeFirestoreDoc('videos/_settings_admin', settingsFields, idToken, projectId),
      writeFirestoreDoc('app_settings/admin_config', settingsFields, idToken, projectId),
    ]);

    console.log('✅  Admin credentials stored in Firestore.\n');
    console.log('┌─────────────────────────────────────────────────────┐');
    console.log(`│  Email     : ${email}`);
    console.log(`│  Password  : ${password}`);
    console.log(`│  UID       : ${uid}`);
    console.log('└─────────────────────────────────────────────────────┘\n');
    console.log('📋  Next step — add this to your .env file:\n');
    console.log(`   VITE_ADMIN_EMAIL=${email}\n`);
    console.log('   Then log in at your admin panel.\n');
  });
});

req.on('error', (err) => {
  console.error('\n❌  Network error:', err.message);
  console.error('   Check your internet connection and try again.\n');
  process.exit(1);
});

req.write(body);
req.end();

// ── Friendly error messages ──────────────────────────────────
function friendlyError(code) {
  switch (code) {
    case 'EMAIL_EXISTS':
      return 'This email already exists in Firebase Auth. Use a different email or log in directly.';
    case 'INVALID_EMAIL':
      return 'Invalid email address format.';
    case 'WEAK_PASSWORD':
      return 'Password is too weak. Use at least 6 characters with letters and numbers.';
    case 'API_KEY_INVALID':
      return 'Firebase API key is invalid. Check VITE_FIREBASE_API_KEY in .env';
    case 'OPERATION_NOT_ALLOWED':
      return [
        'Email/Password sign-in is not enabled.',
        '   → Firebase Console → Authentication → Sign-in method → Enable Email/Password',
      ].join('\n');
    default:
      return code;
  }
}
