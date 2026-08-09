import { createClient } from "npm:@supabase/supabase-js@2";
import {
  bearerToken,
  billingCorsHeaders,
  billingJson,
} from "../_shared/billing/auth.ts";
import { StripeApi } from "../_shared/billing/stripe_api.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
const priceId = Deno.env.get("STRIPE_PRO_PRICE_ID");
const returnUrl = Deno.env.get("BILLING_RETURN_URL");
if (!supabaseUrl || !serviceKey || !stripeKey || !priceId || !returnUrl) {
  throw new Error("Missing billing server configuration.");
}
const admin = createClient(supabaseUrl, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const stripe = new StripeApi(stripeKey);

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: billingCorsHeaders });
  }
  if (request.method !== "POST") {
    return billingJson({ error: "method_not_allowed" }, 405);
  }
  const token = bearerToken(request);
  if (!token) return billingJson({ error: "unauthorized" }, 401);
  const { data: auth, error } = await admin.auth.getUser(token);
  if (error || !auth.user) return billingJson({ error: "unauthorized" }, 401);

  const { data: existing } = await admin.from("subscriptions")
    .select("provider_customer_id").eq("user_id", auth.user.id).eq(
      "provider",
      "stripe",
    )
    .not("provider_customer_id", "is", null).limit(1).maybeSingle();
  const customerId = existing?.provider_customer_id as string | undefined;
  const session = await stripe.post("checkout/sessions", {
    mode: "subscription",
    "line_items[0][price]": priceId,
    "line_items[0][quantity]": "1",
    client_reference_id: auth.user.id,
    "subscription_data[metadata][user_id]": auth.user.id,
    ...(customerId
      ? { customer: customerId }
      : { customer_email: auth.user.email ?? "" }),
    success_url: `${returnUrl}?billing=success`,
    cancel_url: `${returnUrl}?billing=cancelled`,
  });
  return typeof session.url === "string"
    ? billingJson({ url: session.url })
    : billingJson({ error: "invalid_stripe_response" }, 502);
});
