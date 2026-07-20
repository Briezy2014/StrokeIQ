/**
 * Deploy Stripe Edge Functions via Supabase Management API + Windows curl.exe.
 * Node FormData/fetch on Windows was returning UV_HANDLE_CLOSING 400s.
 *
 * Usage: node scripts/deploy-stripe-functions.mjs
 */
import { createInterface } from 'node:readline/promises';
import {
  existsSync,
  mkdirSync,
  readFileSync,
  writeFileSync,
  rmSync,
} from 'node:fs';
import { execFileSync } from 'node:child_process';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { deflateRawSync } from 'node:zlib';

const PROJECT_REF = 'bryurwyeosbffvfpdbv';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const FUNCTIONS_DIR = path.join(ROOT, 'supabase', 'functions');
const TOKEN_FILE = path.join(os.homedir(), '.supabase', 'access-token');
const IS_WIN = process.platform === 'win32';
const TMP = path.join(os.tmpdir(), 'swimiq-stripe-deploy');

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
  // Force a fresh token if the previous one may have been exposed on-screen.
  const forceNew = process.env.SWIMIQ_FORCE_NEW_TOKEN === '1';
  if (!forceNew && existing.length > 20) {
    console.log('[1/3] Using saved Supabase access token.');
    return existing;
  }

  const tokensUrl = 'https://supabase.com/dashboard/account/tokens';
  console.log('');
  console.log('[1/3] Create a NEW Supabase access token');
  console.log('');
  console.log('IMPORTANT: If you pasted a token earlier and it showed on screen,');
  console.log('delete that token on the tokens page first.');
  console.log('');
  console.log('1. Browser will open the tokens page');
  console.log('2. Generate new token  (name: SwimIQ Stripe)');
  console.log('3. Copy it');
  console.log('4. Right-click in THIS window → Paste → Enter');
  console.log('');
  console.log(tokensUrl);
  console.log('');

  try {
    if (IS_WIN) {
      execFileSync('cmd.exe', ['/c', 'start', '', tokensUrl], { stdio: 'ignore' });
    }
  } catch {
    /* optional */
  }

  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const pasted = (await rl.question('Paste token here: ')).trim();
  rl.close();

  if (!pasted || pasted.length < 20) {
    console.error('[ERROR] That does not look like a token.');
    process.exit(1);
  }

  saveToken(pasted);
  console.log('[OK] Token saved (kept private on disk).');
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
  // Prefer store (method 0) — fewer unzip quirks on deploy servers.
  const payload = contentBuf;
  const method = 0;
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

function findCurl() {
  const candidates = [
    path.join(process.env.SystemRoot || 'C:\\Windows', 'System32', 'curl.exe'),
    'curl.exe',
    'curl',
  ];
  for (const c of candidates) {
    if (c === 'curl' || c === 'curl.exe' || existsSync(c)) return c;
  }
  return null;
}

function deployWithCurl(token, { slug, verifyJwt }) {
  const entry = path.join(FUNCTIONS_DIR, slug, 'index.ts');
  if (!existsSync(entry)) throw new Error(`Missing ${entry}`);

  mkdirSync(TMP, { recursive: true });
  const zipPath = path.join(TMP, `${slug}.zip`);
  const metaPath = path.join(TMP, `${slug}-meta.json`);
  writeFileSync(zipPath, zipOneFile('index.ts', readFileSync(entry)));
  writeFileSync(
    metaPath,
    JSON.stringify({
      name: slug,
      entrypoint_path: 'index.ts',
      verify_jwt: verifyJwt,
    }),
  );

  const curl = findCurl();
  if (!curl) {
    throw new Error('curl.exe not found. Windows 10+ should include it.');
  }

  const url =
    `https://api.supabase.com/v1/projects/${PROJECT_REF}` +
    `/functions/deploy?slug=${encodeURIComponent(slug)}`;

  console.log(`Uploading ${slug} with curl.exe ...`);

  // Write args to avoid cmd.exe mangling JSON quotes.
  const out = execFileSync(
    curl,
    [
      '-sS',
      '-X',
      'POST',
      url,
      '-H',
      `Authorization: Bearer ${token}`,
      '-F',
      `metadata=<${metaPath};type=application/json`,
      '-F',
      `file=@${zipPath};type=application/zip`,
      '-w',
      '\nHTTP_STATUS:%{http_code}',
    ],
    {
      encoding: 'utf8',
      maxBuffer: 10 * 1024 * 1024,
    },
  );

  const statusMatch = out.match(/HTTP_STATUS:(\d+)/);
  const status = statusMatch ? Number(statusMatch[1]) : 0;
  const body = out.replace(/\nHTTP_STATUS:\d+\s*$/, '').trim();

  if (status < 200 || status >= 300) {
    throw new Error(`${slug} deploy failed (${status}): ${body}`);
  }

  console.log(`[OK] ${slug}`);
  if (body) {
    try {
      const parsed = JSON.parse(body);
      if (parsed.slug || parsed.name) {
        console.log(`     version=${parsed.version ?? '?'} status=${parsed.status ?? '?'}`);
      }
    } catch {
      console.log(body.slice(0, 200));
    }
  }

  try {
    rmSync(zipPath, { force: true });
    rmSync(metaPath, { force: true });
  } catch {
    /* ignore */
  }
}

async function main() {
  console.log('SwimIQ Stripe deploy (curl upload)');
  console.log(`Project: ${PROJECT_REF}`);
  console.log(`Folder:  ${ROOT}`);
  console.log('');

  // Always ask for a fresh token this run if saved token exists from the
  // failed attempt that was visible on screen — safer default for Kara.
  if (existsSync(TOKEN_FILE) && process.env.SWIMIQ_KEEP_TOKEN !== '1') {
    console.log('For safety, create a NEW token (delete the old one first).');
    try {
      rmSync(TOKEN_FILE, { force: true });
    } catch {
      /* ignore */
    }
  }

  const token = await ensureToken();

  console.log('\n[2/3] Deploy create-stripe-checkout ...');
  deployWithCurl(token, FUNCTIONS[0]);

  console.log('\n[3/3] Deploy stripe-webhook ...');
  deployWithCurl(token, FUNCTIONS[1]);

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
