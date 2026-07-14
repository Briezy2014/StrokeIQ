// SwimIQ - WHY Gemini video fails. Writes GEMINI-DIAGNOSIS.txt (ASCII only)
// Run: node scripts/diagnose-gemini.js
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const root = path.join(__dirname, '..');
const envFile = path.join(root, '.env');
const outFile = path.join(root, 'GEMINI-DIAGNOSIS.txt');
const email = process.env.SWIMIQ_TEST_EMAIL || 'demo@swimiqapp.com';
const password = process.env.SWIMIQ_TEST_PASSWORD || 'SwimIQ';

const lines = [];
function log(msg) {
  console.log(msg);
  lines.push(msg);
}

function request(method, urlStr, headers, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(urlStr);
    const lib = url.protocol === 'https:' ? https : http;
    const opts = {
      method,
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname + url.search,
      headers: headers || {},
    };
    const req = lib.request(opts, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        resolve({ status: res.statusCode, body: data });
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

function parseEnv(text) {
  let url = null;
  let key = null;
  for (const line of text.split(/\r?\n/)) {
    const u = line.match(/^\s*SUPABASE_URL\s*=\s*(.+)\s*$/);
    if (u) url = u[1].trim();
    const k = line.match(/^\s*SUPABASE_ANON_KEY\s*=\s*(.+)\s*$/);
    if (k) key = k[1].trim();
  }
  if (url && !url.startsWith('https://')) url = 'https://' + url;
  url = url.replace('https:https//', 'https://').replace('https//', 'https://');
  return { url, key };
}

async function main() {
  log('============================================================');
  log(' SWIMIQ GEMINI VIDEO DIAGNOSIS');
  log(' ' + new Date().toISOString().slice(0, 16).replace('T', ' '));
  log('============================================================');
  log('');

  if (!fs.existsSync(envFile)) {
    log('ERROR: Missing swimiq\\.env');
    log('FIX: Run KARA-CLICK-THIS.bat once (creates .env with Supabase keys).');
    writeOut(1);
    return;
  }

  const { url, key } = parseEnv(fs.readFileSync(envFile, 'utf8'));
  if (!url || !key || url.includes('your-project')) {
    log('ERROR: .env needs real SUPABASE_URL and SUPABASE_ANON_KEY.');
    writeOut(1);
    return;
  }

  log('Supabase URL: ' + url);
  log('');

  const fnUrl = url.replace(/\/$/, '') + '/functions/v1/analyze-swim-video';

  log('--- TEST 1: Is analyze-swim-video deployed? ---');
  try {
    const probe = await request('POST', fnUrl, {
      apikey: key,
      'Content-Type': 'application/json',
    }, '{}');
    if (probe.status === 401) {
      log('OK - function EXISTS (401 without login is normal).');
    } else if (probe.status === 404) {
      log('FAIL - function NOT deployed.');
      log('FIX: Double-click KARA-GEMINI-FIX-NOW.bat');
      writeOut(1);
      return;
    } else {
      log('Response code: ' + probe.status);
    }
  } catch (e) {
    log('FAIL - could not reach Supabase: ' + e.message);
    writeOut(1);
    return;
  }
  log('');

  log('--- TEST 2: Login (same as SwimIQ app) ---');
  log('Trying email: ' + email);
  let accessToken = null;
  try {
    const tokenUrl = url.replace(/\/$/, '') + '/auth/v1/token?grant_type=password';
    const loginBody = JSON.stringify({ email, password });
    const login = await request('POST', tokenUrl, {
      apikey: key,
      Authorization: 'Bearer ' + key,
      'Content-Type': 'application/json',
    }, loginBody);
    if (login.status !== 200) {
      log('FAIL - login HTTP ' + login.status);
      log(login.body.slice(0, 500));
      log('');
      log('FIX: Use the email/password you sign into SwimIQ with.');
      log('Or add demo@swimiqapp.com in Supabase (see seed_demo_master.sql).');
      writeOut(1);
      return;
    }
    const parsed = JSON.parse(login.body);
    accessToken = parsed.access_token;
    if (!accessToken) {
      log('FAIL - no access token in login response.');
      writeOut(1);
      return;
    }
    log('OK - login works.');
  } catch (e) {
    log('FAIL - login error: ' + e.message);
    writeOut(1);
    return;
  }
  log('');

  log('--- TEST 3: Video server health check ---');
  try {
    const healthBody = JSON.stringify({ health_check: true });
    const health = await request('POST', fnUrl, {
      apikey: key,
      Authorization: 'Bearer ' + accessToken,
      'Content-Type': 'application/json',
    }, healthBody);
    if (health.status === 200) {
      const data = JSON.parse(health.body);
      if (data.ok === true) {
        const version = data.function_version || 'unknown';
        const current = '2026-gemini-auto-model-v3';
        if (version !== current) {
          log('FAIL - OLD server version deployed: ' + version);
          log('  Need: ' + current);
          log('');
          log('FIX: Double-click KARA-GEMINI-FIX-NOW.bat (no GEMINI_MODEL secret needed).');
        } else {
          log('OK - Video server ready.');
          log('  Version: ' + version);
          log('  Gemini model: ' + (data.gemini_model || 'unknown'));
          if (data.available_models) {
            log('  Models your key can use: ' + JSON.stringify(data.available_models));
          }
          log('');
          log('Tap ANALYZE on your clip again in the app.');
        }
      } else {
        log('FAIL - Gemini model probe failed.');
        if (data.model_probe_error) log('  ' + data.model_probe_error);
        if (data.available_models) {
          log('  Models found: ' + JSON.stringify(data.available_models));
        }
        log('');
        log('FIX (no GEMINI_MODEL secret needed - only GEMINI_API_KEY):');
        log('  1. aistudio.google.com/apikey -> Create API key in NEW project');
        log('  2. Supabase secrets -> replace GEMINI_API_KEY value');
        log('  3. KARA-GEMINI-FIX-NOW.bat -> redeploy');
      }
    } else {
      log('FAIL - health check HTTP ' + health.status);
      log(health.body.slice(0, 800));
      log('');
      if (health.body.includes('GEMINI_API_KEY')) {
        log('FIX: Supabase - Project Settings - Edge Functions - Secrets');
        log('     Add GEMINI_API_KEY from aistudio.google.com/apikey');
      }
      if (health.body.includes('storage_path')) {
        log('FIX: Run KARA-GEMINI-FIX-NOW.bat (old server code).');
      }
    }
  } catch (e) {
    log('FAIL - health check: ' + e.message);
  }
  log('');

  log('--- NEXT STEPS ---');
  log('1. KARA-SEE-UPDATES-NOW.bat');
  log('2. Video tab - tap Analyze on your clip');
  log('3. Tap Analyze again (wait 90 sec)');
  log('');
  log('Report: ' + outFile);
  log('============================================================');
  writeOut(0);
}

function writeOut(code) {
  fs.writeFileSync(outFile, lines.join('\r\n') + '\r\n', 'ascii');
  process.exit(code);
}

main().catch((e) => {
  log('');
  log('ERROR: ' + e.message);
  writeOut(1);
});
