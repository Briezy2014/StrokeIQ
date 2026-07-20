/**
 * Deploy Stripe Edge Functions without Windows batch/npx flag mangling.
 * Usage: node scripts/deploy-stripe-functions.mjs
 */
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const PROJECT_REF = 'bryurwyeosbffvfpdbv';
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function run(label, args) {
  console.log(`\n[${label}] npx ${args.join(' ')}`);
  const result = spawnSync('npx.cmd', args, {
    cwd: ROOT,
    stdio: 'inherit',
    shell: false,
    env: process.env,
  });
  if (result.error) {
    console.error(`[ERROR] ${result.error.message}`);
    process.exit(1);
  }
  if (result.status !== 0) {
    console.error(`[ERROR] Stopped at ${label} (exit ${result.status}).`);
    process.exit(result.status ?? 1);
  }
}

console.log('SwimIQ Stripe deploy');
console.log(`Project: ${PROJECT_REF}`);
console.log(`Folder:  ${ROOT}`);

run('1/3 login', ['--yes', 'supabase', 'login']);
run('2/3 create-stripe-checkout', [
  '--yes',
  'supabase',
  'functions',
  'deploy',
  'create-stripe-checkout',
  `--project-ref=${PROJECT_REF}`,
  '--use-api',
]);
run('3/3 stripe-webhook', [
  '--yes',
  'supabase',
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
