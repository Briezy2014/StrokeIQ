/**
 * Deploy Stripe Edge Functions via Supabase Management API.
 * Kara pastes a Personal Access Token once (Windows Credential Manager
 * is not readable from Node after `supabase login`).
 *
 * Usage: node scripts/deploy-stripe-functions.mjs
 */
import {
  createInterface,
} from 'node:readline/promises';
import {
  existsSync,
  mkdirSync,
  readFileSync,
  writeFileSync,
  rmSync,
} from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { deflateRawSync } from 'node:zlib';
import { execSync } from 'node:child_process';

const PROJECT_REF = 'bryurwyeosbffvfpdbv';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const FUNCTIONS_DIR = path.join(ROOT, 'supabase', 'functions');
const TOKEN_FILE = path.join(os.homedir(), '.supabase', 'access-token');
const IS_WIN = process.platform === 'win32';

const FUNCTIONS = [
  { slug: 'create-stripe-checkout', verifyJwt: true },
  { slug: 'stripe-webhook', verifyJwt: false },
];

function readSavedToken() {
  if (process.env.SUPABASE_ACCESS_TOKEN?.trim()) {
    return process.env.SUPABASE_ACCESS_TOKEN.trim();
  }
  if (existsSync(TOKEN_FILE)) {
    const value = readFileSync(TOKEN_FILE, 'utf8').trim();
    if (value) return value;
  }
  return '';
}

function saveToken(token) {
  mkdirSync(path.dirname(TOKEN_FILE), { recursive: true });
  writeFileSync(TOKEN_FILE, `${token}\n`, 'utf8');
}

async function ensureToken() {
  const existing = readSavedToken();
  if (existing.startsWith('sbp_') || existing.length > 20) {
    console.log('[1/3] Using saved Supabase access token.');
    return existing;
  }

  const tokensUrl = 'https://supabase.com/dashboard/account/tokens';
  console.log('');
  console.log('[1/3] We need a Supabase access token (one-time).');
  console.log('');
  console.log('1. A browser page will open.');
  console.log('2. Click: Generate new token');
  console.log('3. Name it: SwimIQ Stripe');
  console.log('4. Copy the token (starts with sbp_)');
  console.log('5. Paste it below and press Enter');
  console.log('');
  console.log(tokensUrl);
  console.log('');

  try {
    if (IS_WIN) {
      execSync(`cmd /c start "" "${tokensUrl}"`, { stdio: 'ignore' });
    } else {
      execSync(`xdg-open "${tokensUrl}"`, { stdio: 'ignore' });
    }
  } catch {
    /* browser open is optional */
  }

  const rl = createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  const pasted = (await rl.question('Paste token here: ')).trim();
  rl.close();

  if (!pasted || pasted.length < 20) {
    console.error('[ERROR] That does not look like a token. Try again.');
    process.exit(1);
  }

  saveToken(pasted);
  console.log(`[OK] Saved token to ${TOKEN_FILE}`);
  return pasted;
}

function crc32(buf) {
  let c = ~0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) {
      c = c & 1 ? (c >>> 1) ^ 0xedb88320 : c >>> 1;
    }
  }
  return ~c >>> 0;
}

function zipOneFile(name, contentBuf) {
  const nameBuf = Buffer.from(name, 'utf8');
  const compressed = deflateRawSync(contentBuf);
  const useDeflate = compressed.length < contentBuf.length;
  const payload = useDeflate ? compressed : contentBuf;
  const method = useDeflate ? 8 : 0;
  const crc = crc32(contentBuf);

  const local = Buffer.alloc(30 + nameBuf.length);
  local.writeUInt32LE(0x04034b50, 0);
  local.writeUInt16LE(20, 4);
  local.writeUInt16LE(0, 6);
  local.writeUInt16LE(method, 8);
  local.writeUInt16LE(0, 10);
  local.writeUInt16LE(0, 12);
  local.writeUInt32LE(crc, 14);
  local.writeUInt32LE(payload.length, 18);
  local.writeUInt32LE(contentBuf.length, 22);
  local.writeUInt16LE(nameBuf.length, 26);
  local.writeUInt16LE(0, 28);
  nameBuf.copy(local, 30);

  const central = Buffer.alloc(46 + nameBuf.length);
  central.writeUInt32LE(0x02014b50, 0);
  central.writeUInt16LE(20, 4);
  central.writeUInt16LE(20, 6);
  central.writeUInt16LE(0, 8);
  central.writeUInt16LE(method, 10);
  central.writeUInt16LE(0, 12);
  central.writeUInt16LE(0, 14);
  central.writeUInt32LE(crc, 16);
  central.writeUInt32LE(payload.length, 20);
  central.writeUInt32LE(contentBuf.length, 24);
  central.writeUInt16LE(nameBuf.length, 28);
  central.writeUInt16LE(0, 30);
  central.writeUInt16LE(0, 32);
  central.writeUInt16LE(0, 34);
  central.writeUInt16LE(0, 36);
  central.writeUInt32LE(0, 38);
  central.writeUInt32LE(0, 42);
  nameBuf.copy(central, 46);

  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(0, 4);
  end.writeUInt16LE(0, 6);
  end.writeUInt16LE(1, 8);
  end.writeUInt16LE(1, 10);
  end.writeUInt32LE(central.length, 12);
  end.writeUInt32LE(local.length + payload.length, 16);
  end.writeUInt16LE(0, 20);

  return Buffer.concat([local, payload, central, end]);
}

async function deployFunction(token, { slug, verifyJwt }) {
  const entry = path.join(FUNCTIONS_DIR, slug, 'index.ts');
  if (!existsSync(entry)) {
    throw new Error(`Missing ${entry}`);
  }

  const source = readFileSync(entry);
  const zipBuf = zipOneFile('index.ts', source);
  const tmpDir = path.join(os.tmpdir(), 'swimiq-stripe-deploy');
  mkdirSync(tmpDir, { recursive: true });
  const zipPath = path.join(tmpDir, `${slug}.zip`);
  writeFileSync(zipPath, zipBuf);

  const form = new FormData();
  form.append(
    'metadata',
    JSON.stringify({
      name: slug,
      entrypoint_path: 'index.ts',
      verify_jwt: verifyJwt,
    }),
  );
  form.append(
    'file',
    new Blob([new Uint8Array(zipBuf)], { type: 'application/zip' }),
    `${slug}.zip`,
  );

  const url =
    `https://api.supabase.com/v1/projects/${PROJECT_REF}` +
    `/functions/deploy?slug=${encodeURIComponent(slug)}`;
  console.log(`Uploading ${slug} ...`);

  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: form,
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`${slug} deploy failed (${res.status}): ${text}`);
  }
  console.log(`[OK] ${slug}`);
  try {
    rmSync(zipPath, { force: true });
  } catch {
    /* ignore */
  }
}

async function main() {
  console.log('SwimIQ Stripe deploy');
  console.log(`Project: ${PROJECT_REF}`);
  console.log(`Folder:  ${ROOT}`);
  console.log('');

  const token = await ensureToken();

  console.log('\n[2/3] Deploy create-stripe-checkout ...');
  await deployFunction(token, FUNCTIONS[0]);

  console.log('\n[3/3] Deploy stripe-webhook ...');
  await deployFunction(token, FUNCTIONS[1]);

  console.log(`
[OK] Stripe functions deployed.

NEXT - in Stripe website:
  Developers -> Webhooks -> Add endpoint
  https://${PROJECT_REF}.supabase.co/functions/v1/stripe-webhook

Then paste Signing secret (whsec_...) as STRIPE_WEBHOOK_SECRET
in Supabase Edge Function secrets.
`);
}

main().catch((err) => {
  console.error(`[ERROR] ${err.message || err}`);
  process.exit(1);
});
