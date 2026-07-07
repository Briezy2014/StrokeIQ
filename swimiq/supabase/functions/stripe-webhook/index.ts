import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  const stripeSecret = Deno.env.get("STRIPE_SECRET_KEY");
  if (!webhookSecret || !stripeSecret) {
    return new Response("Stripe secrets not configured", { status: 503 });
  }

  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return new Response("Missing stripe-signature", { status: 400 });
  }

  const body = await req.text();
  const valid = await verifyStripeSignature(body, signature, webhookSecret);
  if (!valid) {
    return new Response("Invalid signature", { status: 400 });
  }

  const event = JSON.parse(body);
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  try {
    switch (event.type) {
      case "checkout.session.completed":
        await handleCheckoutCompleted(supabase, stripeSecret, event.data.object);
        break;
      case "customer.subscription.updated":
      case "customer.subscription.deleted":
        await handleSubscriptionChange(supabase, event.data.object);
        break;
      default:
        break;
    }
  } catch (error) {
    console.error("Webhook handler error:", error);
    return new Response("Webhook handler failed", { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});

async function handleCheckoutCompleted(
  supabase: ReturnType<typeof createClient>,
  stripeSecret: string,
  session: Record<string, unknown>,
) {
  const userId = (session.client_reference_id as string) ??
    ((session.metadata as Record<string, string>)?.supabase_user_id);
  const subscriptionId = session.subscription as string | null;
  const customerId = session.customer as string | null;
  const metadata = session.metadata as Record<string, string> | undefined;

  if (!userId) {
    console.error("checkout.session.completed missing user id");
    return;
  }

  let tier = metadata?.tier ?? "basic";
  let billingCycle = metadata?.billing_cycle ?? "monthly";
  let status = "active";
  let currentPeriodEnd: string | null = null;

  if (subscriptionId) {
    const sub = await fetchStripeSubscription(stripeSecret, subscriptionId);
    if (sub) {
      tier = metadata?.tier ?? tierFromMetadata(sub);
      billingCycle = metadata?.billing_cycle ?? billingCycleFromMetadata(sub);
      status = (sub.status as string) ?? status;
      currentPeriodEnd = sub.current_period_end
        ? new Date((sub.current_period_end as number) * 1000).toISOString()
        : null;
    }
  }

  await upsertSubscription(supabase, {
    user_id: userId,
    stripe_customer_id: customerId,
    stripe_subscription_id: subscriptionId,
    tier,
    billing_cycle: billingCycle,
    status,
    current_period_end: currentPeriodEnd,
  });
}

async function handleSubscriptionChange(
  supabase: ReturnType<typeof createClient>,
  subscription: Record<string, unknown>,
) {
  const subscriptionId = subscription.id as string;
  const customerId = subscription.customer as string;
  const status = subscription.status as string;
  const metadata = subscription.metadata as Record<string, string> | undefined;
  const currentPeriodEnd = subscription.current_period_end
    ? new Date((subscription.current_period_end as number) * 1000)
      .toISOString()
    : null;

  const { data: existing } = await supabase
    .from("user_subscriptions")
    .select("user_id, tier, billing_cycle, is_demo_master")
    .eq("stripe_subscription_id", subscriptionId)
    .maybeSingle();

  if (existing?.is_demo_master) return;

  let userId = existing?.user_id as string | undefined;
  if (!userId && customerId) {
    const { data: byCustomer } = await supabase
      .from("user_subscriptions")
      .select("user_id")
      .eq("stripe_customer_id", customerId)
      .maybeSingle();
    userId = byCustomer?.user_id as string | undefined;
  }

  if (!userId) {
    console.warn("subscription event with no mapped user:", subscriptionId);
    return;
  }

  const normalizedStatus = status === "active" || status === "trialing"
    ? status
    : "canceled";

  await upsertSubscription(supabase, {
    user_id: userId,
    stripe_customer_id: customerId,
    stripe_subscription_id: subscriptionId,
    tier: metadata?.tier ?? existing?.tier ?? "basic",
    billing_cycle: metadata?.billing_cycle ?? existing?.billing_cycle ??
      "monthly",
    status: normalizedStatus,
    current_period_end: currentPeriodEnd,
  });
}

async function upsertSubscription(
  supabase: ReturnType<typeof createClient>,
  row: Record<string, unknown>,
) {
  const { error } = await supabase.from("user_subscriptions").upsert({
    ...row,
    updated_at: new Date().toISOString(),
  });
  if (error) throw error;
}

async function fetchStripeSubscription(
  stripeSecret: string,
  subscriptionId: string,
) {
  const res = await fetch(
    `https://api.stripe.com/v1/subscriptions/${subscriptionId}`,
    {
      headers: { Authorization: `Bearer ${stripeSecret}` },
    },
  );
  if (!res.ok) return null;
  return await res.json() as Record<string, unknown>;
}

function tierFromMetadata(sub: Record<string, unknown>): string {
  const metadata = sub.metadata as Record<string, string> | undefined;
  return metadata?.tier ?? "basic";
}

function billingCycleFromMetadata(sub: Record<string, unknown>): string {
  const metadata = sub.metadata as Record<string, string> | undefined;
  return metadata?.billing_cycle ?? "monthly";
}

async function verifyStripeSignature(
  payload: string,
  header: string,
  secret: string,
): Promise<boolean> {
  const parts = header.split(",").reduce((acc, part) => {
    const [key, value] = part.split("=");
    if (key && value) acc[key.trim()] = value.trim();
    return acc;
  }, {} as Record<string, string>);

  const timestamp = parts.t;
  const signature = parts.v1;
  if (!timestamp || !signature) return false;

  const signedPayload = `${timestamp}.${payload}`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(signedPayload),
  );
  const expected = Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return timingSafeEqual(signature, expected);
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}
