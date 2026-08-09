export class StripeApi {
  constructor(
    private readonly secretKey: string,
    private readonly fetcher: typeof fetch = fetch,
  ) {
    if (!secretKey) throw new Error("Missing Stripe secret key.");
  }

  async post(
    path: string,
    fields: Record<string, string>,
  ): Promise<Record<string, unknown>> {
    const response = await this.fetcher(`https://api.stripe.com/v1/${path}`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams(fields),
    });
    const body: unknown = await response.json();
    if (!response.ok || !isRecord(body)) {
      throw new Error("Stripe request failed.");
    }
    return body;
  }
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
