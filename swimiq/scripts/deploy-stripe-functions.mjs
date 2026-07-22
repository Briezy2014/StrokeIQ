/**
 * Deploy Stripe Edge Functions via Supabase Management API + curl.exe.
 *
 * IMPORTANT: The deploy API expects multipart source FILES (like the CLI),
 * NOT a zip archive. Zip uploads return HTTP 400.
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

const PROJECT_REF = 'bryurwyeosbffvfpdbv';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const TOKEN_FILE = path.join(os.homedir(), '.supabase', 'access-token');
const ERROR_LOG = path.join(ROOT, '..', 'STRIPE-DEPLOY-ERROR.txt');
const IS_WIN = process.platform === 'win32';

const FUNCTIONS = [
  {
    slug: 'create-stripe-checkout',
    relPath: 'supabase/functions/create-stripe-checkout/index.ts',
    verifyJwt: true,
  },
  {
    slug: 'stripe-webhook',
    relPath: 'supabase/functions/stripe-webhook/index.ts',
    verifyJwt: false,
  },
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

function writeErrorLog(message) {
  try {
    writeFileSync(ERROR_LOG, `${message}\n`, 'utf8');
    console.error(`Full error also saved to:\n  ${ERROR_LOG}`);
  } catch {
    /* ignore */
  }
}

async function ensureToken() {
  const existing = readSavedToken();
  if (existing.length > 20 && process.env.SWIMIQ_FORCE_NEW_TOKEN !== '1') {
    console.log('[1/3] Using saved Supabase access token.');
    return existing;
  }

  const tokensUrl = 'https://supabase.com/dashboard/account/tokens';
  console.log('');
  console.log('[1/3] Paste a Supabase access token');
  console.log('1. Browser opens the tokens page');
  console.log('2. Generate new token (name: SwimIQ Stripe)');
  console.log('3. Copy it, then paste here and press Enter');
  console.log('');
  console.log(tokensUrl);
  console.log('');

  try {
    if (IS_WIN) {
      execFileSync('cmd.exe', ['/c', 'start', '', tokensUrl], {
        stdio: 'ignore',
      });
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
  console.log('[OK] Token saved.');
  return pasted;
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

function deployWithCurl(token, fn) {
  const absFile = path.join(ROOT, ...fn.relPath.split('/'));
  if (!existsSync(absFile)) {
    throw new Error(`Missing ${absFile}`);
  }

  const curl = findCurl();
  if (!curl) {
    throw new Error('curl.exe not found. Windows 10+ should include it.');
  }

  const meta = {
    name: fn.slug,
    entrypoint_path: fn.relPath,
    verify_jwt: fn.verifyJwt,
  };
  const metaPath = path.join(os.tmpdir(), `swimiq-${fn.slug}-meta.json`);
  writeFileSync(metaPath, JSON.stringify(meta));

  const url =
    `https://api.supabase.com/v1/projects/${PROJECT_REF}` +
    `/functions/deploy?slug=${encodeURIComponent(fn.slug)}`;

  console.log(`Uploading ${fn.slug} (source file, not zip) ...`);
  console.log(`  entrypoint: ${fn.relPath}`);

  // Match Supabase CLI: metadata JSON field + file part named with relative path.
  // Do NOT send a zip — that causes HTTP 400.
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
      `file=@${absFile};filename=${fn.relPath};type=application/typescript`,
      '-w',
      '\nHTTP_STATUS:%{http_code}',
    ],
    {
      encoding: 'utf8',
      maxBuffer: 10 * 1024 * 1024,
      cwd: ROOT,
    },
  );

  const statusMatch = out.match(/HTTP_STATUS:(\d+)/);
  const status = statusMatch ? Number(statusMatch[1]) : 0;
  const body = out.replace(/\nHTTP_STATUS:\d+\s*$/, '').trim();

  try {
    rmSync(metaPath, { force: true });
  } catch {
    /* ignore */
  }

  if (status < 200 || status >= 300) {
    const msg = `${fn.slug} deploy failed (${status}):\n${body}`;
    writeErrorLog(msg);
    throw new Error(msg);
  }

  console.log(`[OK] ${fn.slug}`);
  try {
    const parsed = JSON.parse(body);
    console.log(
      `     version=${parsed.version ?? '?'} status=${parsed.status ?? '?'}`,
    );
  } catch {
    if (body) console.log(body.slice(0, 200));
  }
}

async function main() {
  console.log('SwimIQ Stripe deploy');
  console.log(`Project: ${PROJECT_REF}`);
  console.log(`Folder:  ${ROOT}`);
  console.log('');

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
