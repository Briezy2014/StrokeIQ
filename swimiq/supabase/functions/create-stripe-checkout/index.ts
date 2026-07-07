import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type CheckoutRequest = {
  tier?: string;
  billing_cycle?: string;
  success_url?: string;
  cancel_url?: string;
};

const VALID_TIERS = new Set(["basic", "pro", "elite"]);
const VALID_CYCLES = new Set(["monthly", "annual"]);

function priceEnvKey(tier: string, cycle: string): string {
  return `STRIPE_PRICE_${tier.toUpperCase()}_${cycle.toUpperCase()}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY");
    if (!stripeSecret) {
      return jsonError("STRIPE_SECRET_KEY is not configured.", 503);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonError("Missing Authorization header.", 401);
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await userClient.auth
      .getUser();
    if (userError || !userData.user) {
      return jsonError("Unauthorized.", 401);
    }

    const body = (await req.json()) as CheckoutRequest;
    const tier = (body.tier ?? "").trim().toLowerCase();
    const cycle = (body.billing_cycle ?? "monthly").trim().toLowerCase();

    if (!VALID_TIERS.has(tier)) {
      return jsonError("Invalid tier. Use basic, pro, or elite.", 400);
    }
    if (!VALID_CYCLES.has(cycle)) {
      return jsonError("Invalid billing_cycle. Use monthly or annual.", 400);
    }

    const priceId = Deno.env.get(priceEnvKey(tier, cycle));
    if (!priceId) {
      return jsonError(
        `Missing Stripe price env: ${priceEnvKey(tier, cycle)}`,
        503,
      );
    }

    const defaultSuccess = Deno.env.get("STRIPE_SUCCESS_URL") ??
      "https://swimiqapp.com/?checkout=success";
    const defaultCancel = Deno.env.get("STRIPE_CANCEL_URL") ??
      "https://swimiqapp.com/?checkout=cancel";

    const params = new URLSearchParams();
    params.set("mode", "subscription");
    params.set("line_items[0][price]", priceId);
    params.set("line_items[0][quantity]", "1");
    params.set("success_url", body.success_url?.trim() || defaultSuccess);
    params.set("cancel_url", body.cancel_url?.trim() || defaultCancel);
    params.set("client_reference_id", userData.user.id);
    params.set("metadata[supabase_user_id]", userData.user.id);
    params.set("metadata[tier]", tier);
    params.set("metadata[billing_cycle]", cycle);
    if (userData.user.email) {
      params.set("customer_email", userData.user.email);
    }

    const stripeResponse = await fetch(
      "https://api.stripe.com/v1/checkout/sessions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${stripeSecret}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: params,
      },
    );

    const session = await stripeResponse.json();
    if (!stripeResponse.ok) {
      console.error("Stripe checkout error:", session);
      return jsonError(session.error?.message ?? "Stripe checkout failed.", 502);
    }

    return new Response(
      JSON.stringify({ url: session.url, session_id: session.id }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error(error);
    return jsonError("Unexpected server error.", 500);
  }
});

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
