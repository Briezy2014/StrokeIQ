/**
 * Deploy Stripe Edge Functions on Windows-friendly Node.
 * Usage: node scripts/deploy-stripe-functions.mjs
 */
import { execSync, spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const PROJECT_REF = 'bryurwyeosbffvfpdbv';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const IS_WIN = process.platform === 'win32';

function resolveNpx() {
  const candidates = [
    process.env.ProgramFiles && path.join(process.env.ProgramFiles, 'nodejs', 'npx.cmd'),
    process.env['ProgramFiles(x86)'] &&
      path.join(process.env['ProgramFiles(x86)'], 'nodejs', 'npx.cmd'),
    'npx.cmd',
    'npx',
  ].filter(Boolean);

  for (const candidate of candidates) {
    if (candidate === 'npx' || candidate === 'npx.cmd' || existsSync(candidate)) {
      return candidate;
    }
  }
  return IS_WIN ? 'npx.cmd' : 'npx';
}

const NPX = resolveNpx();

function run(label, supabaseArgs) {
  // Build one command string so Windows can run .cmd via the shell.
  const quoted = supabaseArgs
    .map((arg) => (/\s/.test(arg) ? `"${arg}"` : arg))
    .join(' ');
  const command = IS_WIN
    ? `"${NPX}" --yes supabase ${quoted}`
    : `${NPX} --yes supabase ${quoted}`;

  console.log(`\n[${label}] ${command}`);
  try {
    execSync(command, {
      cwd: ROOT,
      stdio: 'inherit',
      env: process.env,
      shell: IS_WIN ? 'cmd.exe' : true,
    });
  } catch {
    console.error(`[ERROR] Stopped at ${label}.`);
    process.exit(1);
  }
}

function alreadyLoggedIn() {
  try {
    const result = spawnSync(
      IS_WIN ? 'cmd.exe' : NPX,
      IS_WIN
        ? ['/d', '/s', '/c', `"${NPX}" --yes supabase projects list`]
        : ['--yes', 'supabase', 'projects', 'list'],
      {
        cwd: ROOT,
        encoding: 'utf8',
        env: process.env,
        shell: false,
        timeout: 120000,
      },
    );
    if (result.status !== 0) return false;
    const out = `${result.stdout || ''}${result.stderr || ''}`;
    return out.includes(PROJECT_REF) || /[a-z]{20}/.test(out);
  } catch {
    return false;
  }
}

console.log('SwimIQ Stripe deploy');
console.log(`Project: ${PROJECT_REF}`);
console.log(`Folder:  ${ROOT}`);
console.log(`npx:     ${NPX}`);

if (alreadyLoggedIn()) {
  console.log('\n[1/3 login] Already logged in — skipping browser login.');
} else {
  run('1/3 login', ['login']);
}

run('2/3 create-stripe-checkout', [
  'functions',
  'deploy',
  'create-stripe-checkout',
  `--project-ref=${PROJECT_REF}`,
  '--use-api',
]);

run('3/3 stripe-webhook', [
  'functions',
  'deploy',
  'stripe-webhook',
  `--project-ref=${PROJECT_REF}`,
  '--use-api',
]);

console.log(`
[OK] Stripe functions deployed.

NEXT - Stripe website:
  Developers -> Webhooks -> Add endpoint
  https://${PROJECT_REF}.supabase.co/functions/v1/stripe-webhook

Then paste Signing secret (whsec_...) as STRIPE_WEBHOOK_SECRET
in Supabase Edge Function secrets.
`);
