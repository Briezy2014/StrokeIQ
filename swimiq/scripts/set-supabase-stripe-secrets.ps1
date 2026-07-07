# Paste your Stripe TEST secret key below, then run once from S:\swimiq
# Requires: npm install -g supabase  AND  supabase link --project-ref YOUR_REF

$ErrorActionPreference = "Stop"

$stripeSecretKey = "sk_test_PASTE_YOUR_STRIPE_SECRET_KEY_HERE"

if ($stripeSecretKey -match "PASTE") {
    Write-Host "Edit this file and paste your real sk_test_... key first." -ForegroundColor Red
    exit 1
}

supabase secrets set `
  STRIPE_SECRET_KEY=$stripeSecretKey `
  STRIPE_PRICE_BASIC_MONTHLY=price_1TqfCpAGTU3uDC7zn2vtpFFO `
  STRIPE_PRICE_BASIC_ANNUAL=price_1TqfEGAGTU3uDC7ziSbknFdT `
  STRIPE_PRICE_PRO_MONTHLY=price_1TqfIIAGTU3uDC7zJkgA90xR `
  STRIPE_PRICE_PRO_ANNUAL=price_1TqfJ2AGTU3uDC7zlYPp9evf `
  STRIPE_PRICE_ELITE_MONTHLY=price_1TqfK8AGTU3uDC7zaL5Zj3UQ `
  STRIPE_PRICE_ELITE_ANNUAL=price_1TqfLCAGTU3uDC7zSrjzvNuW `
  STRIPE_SUCCESS_URL=https://swimiqapp.com/?checkout=success `
  STRIPE_CANCEL_URL=https://swimiqapp.com/?checkout=cancel

Write-Host "Done. Check Supabase Dashboard -> Edge Functions -> Secrets." -ForegroundColor Green
