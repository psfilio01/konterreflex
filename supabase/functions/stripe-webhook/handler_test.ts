import { assertEquals } from "jsr:@std/assert";
import { createStripeWebhookHandler } from "./handler.ts";

const secret = "whsec_test_secret";
const now = 1_800_000_000_000;
const userId = "11111111-1111-4111-8111-111111111111";
const payload = JSON.stringify({
  id: "evt_subscription_update",
  type: "customer.subscription.updated",
  created: now / 1000,
  data: { object: {
    id: "sub_123", customer: "cus_123", status: "active",
    metadata: { user_id: userId }, current_period_end: now / 1000 + 3600,
  } },
});

Deno.test("rejects an invalid Stripe signature before syncing", async () => {
  let calls = 0;
  const handler = createStripeWebhookHandler({ webhookSecret: secret, now: () => now, syncEvent: async () => { calls += 1; return true; } });
  const response = await handler(new Request("http://local/webhook", { method: "POST", body: payload, headers: { "Stripe-Signature": `t=${now / 1000},v1=invalid` } }));
  assertEquals(response.status, 400);
  assertEquals(calls, 0);
});

Deno.test("a replay is acknowledged without applying entitlement twice", async () => {
  const events = new Set<string>();
  let applied = 0;
  const handler = createStripeWebhookHandler({
    webhookSecret: secret,
    now: () => now,
    syncEvent: async (event) => {
      if (events.has(event.eventId)) return false;
      events.add(event.eventId);
      applied += 1;
      assertEquals(event.userId, userId);
      assertEquals(event.subscriptionStatus, "active");
      return true;
    },
  });
  const signature = await sign(payload, now / 1000, secret);
  const request = () => new Request("http://local/webhook", { method: "POST", body: payload, headers: { "Stripe-Signature": signature } });
  const first = await handler(request());
  const second = await handler(request());
  assertEquals(first.status, 200);
  assertEquals(await second.json(), { received: true, duplicate: true });
  assertEquals(applied, 1);
});

async function sign(body: string, timestamp: number, keyValue: string): Promise<string> {
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(keyValue), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const digest = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${timestamp}.${body}`));
  const value = [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
  return `t=${timestamp},v1=${value}`;
}
