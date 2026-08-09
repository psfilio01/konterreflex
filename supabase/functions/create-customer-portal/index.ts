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
const returnUrl = Deno.env.get("BILLING_RETURN_URL");
if (!supabaseUrl || !serviceKey || !stripeKey || !returnUrl) {
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
  const { data: subscription } = await admin.from("subscriptions").select(
    "provider_customer_id",
  )
    .eq("user_id", auth.user.id).eq("provider", "stripe").not(
      "provider_customer_id",
      "is",
      null,
    )
    .order("updated_at", { ascending: false }).limit(1).maybeSingle();
  if (!subscription?.provider_customer_id) {
    return billingJson({ error: "stripe_customer_missing" }, 409);
  }
  const session = await stripe.post("billing_portal/sessions", {
    customer: subscription.provider_customer_id,
    return_url: returnUrl,
  });
  return typeof session.url === "string"
    ? billingJson({ url: session.url })
    : billingJson({ error: "invalid_stripe_response" }, 502);
});
