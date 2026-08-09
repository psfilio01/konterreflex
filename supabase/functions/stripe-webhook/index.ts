import { createClient } from "npm:@supabase/supabase-js@2";
import { createStripeWebhookHandler } from "./handler.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
if (!supabaseUrl || !serviceKey || !webhookSecret) throw new Error("Missing Stripe webhook configuration.");
const admin = createClient(supabaseUrl, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } });

Deno.serve(createStripeWebhookHandler({
  webhookSecret,
  async syncEvent(event) {
    const { data, error } = await admin.rpc("sync_stripe_subscription_event", {
      p_event_id: event.eventId,
      p_event_type: event.eventType,
      p_event_created: new Date(event.eventCreated * 1000).toISOString(),
      p_user_id: event.userId ?? null,
      p_customer_id: event.customerId ?? null,
      p_subscription_id: event.subscriptionId ?? null,
      p_status: event.subscriptionStatus ?? null,
      p_current_period_end: event.currentPeriodEnd ?? null,
    });
    if (error) throw error;
    return data === true;
  },
}));
