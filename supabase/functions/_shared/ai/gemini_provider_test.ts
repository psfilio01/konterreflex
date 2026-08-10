import { GeminiProvider } from "./gemini_provider.ts";
import { ProviderError } from "./provider.ts";
import { JsonSchema } from "./schema.ts";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test("Gemini adapter requests JSON schema without leaking the key in the URL", async () => {
  let capturedUrl = "";
  let capturedInit: RequestInit | undefined;
  const fetcher: typeof fetch = (input, init) => {
    capturedUrl = String(input);
    capturedInit = init;
    return Promise.resolve(Response.json({
      modelVersion: "gemini-test",
      candidates: [{ content: { parts: [{ text: '{"reply":"Hallo"}' }] } }],
    }));
  };
  const schema: JsonSchema = {
    type: "object",
    properties: { reply: { type: "string" } },
    required: ["reply"],
    additionalProperties: false,
  };
  const provider = new GeminiProvider("server-secret", "gemini-test", fetcher);
  const result = await provider.generate({
    task: "conversation.reply",
    prompt: "Prompt",
    payload: { message: "Hallo" },
    outputSchema: schema,
  }, new AbortController().signal);

  assert(!capturedUrl.includes("server-secret"), "key must not appear in URL");
  const headers = new Headers(capturedInit?.headers);
  assert(
    headers.get("x-goog-api-key") === "server-secret",
    "expected key header",
  );
  const body = JSON.parse(String(capturedInit?.body));
  assert(
    body.generationConfig.responseMimeType === "application/json",
    "expected JSON mode",
  );
  assert(
    body.generationConfig.responseJsonSchema.required[0] === "reply",
    "expected schema",
  );
  assert(result.model === "gemini-test", "expected model metadata");
  assert(
    (result.data as { reply: string }).reply === "Hallo",
    "expected parsed JSON",
  );
});

Deno.test("Gemini adapter rejects malformed provider JSON", async () => {
  const fetcher: typeof fetch = () =>
    Promise.resolve(Response.json({
      candidates: [{ content: { parts: [{ text: "not-json" }] } }],
    }));
  const provider = new GeminiProvider("server-secret", "gemini-test", fetcher);

  let failed = false;
  try {
    await provider.generate({
      task: "conversation.reply",
      prompt: "Prompt",
      payload: {},
      outputSchema: { type: "object" },
    }, new AbortController().signal);
  } catch {
    failed = true;
  }
  assert(failed, "expected malformed JSON to fail");
});

Deno.test("Gemini adapter exposes only safe request diagnostics", async () => {
  const fetcher: typeof fetch = () =>
    Promise.resolve(Response.json({
      error: {
        status: "INVALID_ARGUMENT",
        message: "Sensitive provider diagnostic",
      },
    }, { status: 400 }));
  const provider = new GeminiProvider("server-secret", "gemini-test", fetcher);

  let caught: unknown;
  try {
    await provider.generate({
      task: "conversation.reply",
      prompt: "Prompt",
      payload: {},
      outputSchema: { type: "object" },
    }, new AbortController().signal);
  } catch (error) {
    caught = error;
  }

  assert(caught instanceof ProviderError, "expected a provider error");
  assert(caught.diagnostics.httpStatus === 400, "expected HTTP status");
  assert(
    caught.diagnostics.reason === "INVALID_ARGUMENT",
    "expected sanitized provider reason",
  );
  assert(
    !JSON.stringify(caught.diagnostics).includes("Sensitive"),
    "must not expose provider response messages",
  );
});
