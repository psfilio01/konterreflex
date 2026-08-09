import { isRecord } from "../_shared/billing/stripe_api.ts";

export interface StripeEventSync {
  eventId: string;
  eventType: string;
  eventCreated: number;
  userId?: string;
  customerId?: string;
  subscriptionId?: string;
  subscriptionStatus?: string;
  currentPeriodEnd?: string;
}

export interface StripeWebhookDependencies {
  webhookSecret: string;
  syncEvent(event: StripeEventSync): Promise<boolean>;
  now?: () => number;
}

export function createStripeWebhookHandler(
  dependencies: StripeWebhookDependencies,
) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") {
      return Response.json({ error: "method_not_allowed" }, { status: 405 });
    }
    const body = await request.text();
    const signature = request.headers.get("Stripe-Signature");
    const valid = signature != null && await verifyStripeSignature(
      body,
      signature,
      dependencies.webhookSecret,
      dependencies.now?.() ?? Date.now(),
    );
    if (!valid) {
      return Response.json({ error: "invalid_signature" }, { status: 400 });
    }

    let parsed: unknown;
    try {
      parsed = JSON.parse(body);
    } catch {
      return Response.json({ error: "invalid_payload" }, { status: 400 });
    }
    const event = stripeEvent(parsed);
    if (event == null) {
      return Response.json({ error: "invalid_payload" }, { status: 400 });
    }
    try {
      const processed = await dependencies.syncEvent(event);
      return Response.json({ received: true, duplicate: !processed });
    } catch {
      return Response.json({ error: "sync_failed" }, { status: 500 });
    }
  };
}

export async function verifyStripeSignature(
  payload: string,
  header: string,
  secret: string,
  nowMs = Date.now(),
  toleranceSeconds = 300,
): Promise<boolean> {
  const parts = header.split(",").map((part) => part.trim().split("=", 2));
  const timestamp = Number(parts.find(([key]) => key === "t")?.[1]);
  const candidates = parts.filter(([key]) => key === "v1").map(([, value]) =>
    value
  );
  if (!Number.isFinite(timestamp) || candidates.length === 0 || !secret) {
    return false;
  }
  if (Math.abs(Math.floor(nowMs / 1000) - timestamp) > toleranceSeconds) {
    return false;
  }
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${timestamp}.${payload}`),
  );
  const expected = [...new Uint8Array(digest)].map((byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
  return candidates.some((candidate) => constantTimeEqual(candidate, expected));
}

function constantTimeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index++) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}

function stripeEvent(value: unknown): StripeEventSync | null {
  if (
    !isRecord(value) || typeof value.id !== "string" ||
    typeof value.type !== "string" || typeof value.created !== "number"
  ) return null;
  const result: StripeEventSync = {
    eventId: value.id,
    eventType: value.type,
    eventCreated: value.created,
  };
  if (!value.type.startsWith("customer.subscription.")) return result;
  const data = value.data;
  if (!isRecord(data) || !isRecord(data.object)) return null;
  const object = data.object;
  if (typeof object.id !== "string" || typeof object.status !== "string") {
    return null;
  }
  const metadata = isRecord(object.metadata) ? object.metadata : {};
  const customer = typeof object.customer === "string"
    ? object.customer
    : isRecord(object.customer) && typeof object.customer.id === "string"
    ? object.customer.id
    : undefined;
  const period = typeof object.current_period_end === "number"
    ? object.current_period_end
    : firstItemPeriodEnd(object.items);
  return {
    ...result,
    ...(typeof metadata.user_id === "string" && isUuid(metadata.user_id)
      ? { userId: metadata.user_id }
      : {}),
    customerId: customer,
    subscriptionId: object.id,
    subscriptionStatus: object.status,
    ...(period == null
      ? {}
      : { currentPeriodEnd: new Date(period * 1000).toISOString() }),
  };
}

function firstItemPeriodEnd(value: unknown): number | undefined {
  if (
    !isRecord(value) || !Array.isArray(value.data) || !isRecord(value.data[0])
  ) return undefined;
  return typeof value.data[0].current_period_end === "number"
    ? value.data[0].current_period_end
    : undefined;
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}
