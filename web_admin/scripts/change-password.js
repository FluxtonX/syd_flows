#!/usr/bin/env node
/**
 * ─────────────────────────────────────────────────────────────
 * SYD FLOWS Web Admin – Change Admin Password Script
 * ─────────────────────────────────────────────────────────────
 * Usage:
 *   node scripts/change-password.js <current-password> <new-password>
 *
 * Example:
 *   node scripts/change-password.js YourStr0ngP@ss! MyNewP@ss123!
 *
 * The admin email is read automatically from VITE_ADMIN_EMAIL in .env
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

// ── 1. Read .env ─────────────────────────────────────────────
const envPath = path.join(__dirname, '../.env');

if (!fs.existsSync(envPath)) {
  console.error('\n❌  .env file not found at web_admin/.env\n');
  process.exit(1);
}

const envContent = fs.readFileSync(envPath, 'utf8');
const env = {};
envContent.split('\n').forEach((line) => {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith('#')) return;
  const eqIndex = trimmed.indexOf('=');
  if (eqIndex === -1) return;
  env[trimmed.substring(0, eqIndex).trim()] = trimmed.substring(eqIndex + 1).trim();
});

// ── 2. Validate ──────────────────────────────────────────────
const API_KEY      = env['VITE_FIREBASE_API_KEY'];
const ADMIN_EMAIL  = env['VITE_ADMIN_EMAIL'];
const currentPass  = process.argv[2];
const newPass      = process.argv[3];

if (!API_KEY) {
  console.error('\n❌  VITE_FIREBASE_API_KEY is missing in .env\n');
  process.exit(1);
}

if (!ADMIN_EMAIL) {
  console.error('\n❌  VITE_ADMIN_EMAIL is missing in .env');
  console.error('   Set it to the admin email and try again.\n');
  process.exit(1);
}

if (!currentPass || !newPass) {
  console.error('\n❌  Usage: node scripts/change-password.js <current-password> <new-password>');
  console.error('   Example: node scripts/change-password.js OldP@ss! NewP@ss123!\n');
  process.exit(1);
}

if (newPass.length < 6) {
  console.error('\n❌  New password must be at least 6 characters\n');
  process.exit(1);
}

if (currentPass === newPass) {
  console.error('\n❌  New password must be different from the current password\n');
  process.exit(1);
}

console.log('\n🔄  Changing admin password...');
console.log(`   Email : ${ADMIN_EMAIL}\n`);

// ── Helper: make HTTPS POST request ──────────────────────────
function post(path, body) {
  return new Promise((resolve, reject) => {
    const bodyStr = JSON.stringify(body);
    const options = {
      hostname: 'identitytoolkit.googleapis.com',
      path: `${path}?key=${API_KEY}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(bodyStr),
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => resolve(JSON.parse(data)));
    });

    req.on('error', reject);
    req.write(bodyStr);
    req.end();
  });
}

// ── 3. Step 1: Sign in to get idToken ────────────────────────
try {
  const signInResult = await post('/v1/accounts:signInWithPassword', {
    email: ADMIN_EMAIL,
    password: currentPass,
    returnSecureToken: true,
  });

  if (signInResult.error) {
    const code = signInResult.error.message;
    if (code === 'INVALID_PASSWORD' || code === 'INVALID_LOGIN_CREDENTIALS') {
      console.error('❌  Current password is incorrect. Please try again.\n');
    } else if (code === 'USER_NOT_FOUND') {
      console.error('❌  Admin user not found in Firebase Auth.');
      console.error('   Create it first: node scripts/create-admin.js\n');
    } else {
      console.error('❌  Sign-in failed:', code, '\n');
    }
    process.exit(1);
  }

  const idToken = signInResult.idToken;

  // ── 4. Step 2: Update password using idToken ────────────────
  const updateResult = await post('/v1/accounts:update', {
    idToken,
    password: newPass,
    returnSecureToken: true,
  });

  if (updateResult.error) {
    console.error('❌  Password update failed:', updateResult.error.message, '\n');
    process.exit(1);
  }

  // ── SUCCESS ─────────────────────────────────────────────────
  console.log('✅  Admin password changed successfully!\n');
  console.log('┌─────────────────────────────────────────────────────┐');
  console.log(`│  Email        : ${ADMIN_EMAIL}`);
  console.log(`│  New Password : ${'*'.repeat(newPass.length)}`);
  console.log('└─────────────────────────────────────────────────────┘\n');
  console.log('   All existing sessions have been invalidated.');
  console.log('   Log in again at http://localhost:5173/login\n');

} catch (err) {
  console.error('\n❌  Network error:', err.message);
  console.error('   Check your internet connection and try again.\n');
  process.exit(1);
}
