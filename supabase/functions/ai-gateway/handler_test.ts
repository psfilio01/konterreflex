import { MockAiProvider } from "../_shared/ai/mock_provider.ts";
import { AiProvider, ProviderError } from "../_shared/ai/provider.ts";
import { AiProviderRegistry } from "../_shared/ai/provider_registry.ts";
import { createAiGatewayHandler } from "./handler.ts";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function request(
  task = "conversation.reply",
  responseLanguage: "de" | "en" = "de",
): Request {
  return new Request("http://localhost/ai-gateway", {
    method: "POST",
    headers: {
      Authorization: "Bearer test-token",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      task,
      schemaVersion: "1",
      responseLanguage,
      payload: { message: "Was könnte ich sagen?" },
    }),
  });
}

function handlerFor(provider: MockAiProvider) {
  return createAiGatewayHandler({
    authenticate: async () => true,
    providerId: "mock",
    providers: new AiProviderRegistry([provider]),
    loadPrompt: async (definition) => `Prompt ${definition.promptVersion}`,
    createRequestId: () => "request-1",
    timeoutMs: 100,
  });
}

Deno.test("routes an approved task and returns trace metadata", async () => {
  const provider = new MockAiProvider({ reply: "Das sehe ich anders." });
  const response = await handlerFor(provider)(request());
  const body = await response.json();

  assert(response.status === 200, "expected success");
  assert(
    provider.lastRequest?.task === "conversation.reply",
    "expected routed task",
  );
  assert(body.data.reply === "Das sehe ich anders.", "expected provider data");
  assert(body.provider === "mock", "expected provider metadata");
  assert(body.model === "mock-v1", "expected model metadata");
  assert(
    body.promptVersion === "conversation_reply_v1",
    "expected prompt metadata",
  );
  assert(body.schemaVersion === "1", "expected schema metadata");
  assert(body.requestId === "request-1", "expected request trace");
});

Deno.test("adds the selected response language to the trusted prompt", async () => {
  const provider = new MockAiProvider({ reply: "I see that differently." });
  const response = await handlerFor(provider)(
    request("conversation.reply", "en"),
  );

  assert(response.status === 200, "expected success");
  assert(
    provider.lastRequest?.prompt.includes("user-facing text value in English"),
    "expected English response instruction",
  );
  assert(
    !Object.hasOwn(provider.lastRequest?.payload ?? {}, "responseLanguage"),
    "language must be a trusted prompt instruction, not user payload",
  );
});

Deno.test("rejects unsupported response languages", async () => {
  const provider = new MockAiProvider({ reply: "unused" });
  const invalid = new Request("http://localhost/ai-gateway", {
    method: "POST",
    headers: {
      Authorization: "Bearer test-token",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      task: "conversation.reply",
      schemaVersion: "1",
      responseLanguage: "fr",
      payload: { message: "Bonjour" },
    }),
  });

  const response = await handlerFor(provider)(invalid);
  assert(response.status === 400, "expected invalid request");
  assert(provider.lastRequest === null, "provider must not be called");
});

Deno.test("creates a request ID with the production default", async () => {
  const provider = new MockAiProvider({ reply: "Das sehe ich anders." });
  const handler = createAiGatewayHandler({
    authenticate: async () => true,
    providerId: "mock",
    providers: new AiProviderRegistry([provider]),
    loadPrompt: async (definition) => `Prompt ${definition.promptVersion}`,
  });
  const response = await handler(request());
  const body = await response.json();

  assert(response.status === 200, "expected success");
  assert(
    typeof body.requestId === "string" &&
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
        .test(body.requestId),
    "expected a generated UUID request ID",
  );
});

Deno.test("rejects provider output that does not match the task schema", async () => {
  const provider = new MockAiProvider({ text: "wrong property" });
  const response = await handlerFor(provider)(request());
  const body = await response.json();

  assert(response.status === 502, "expected bad gateway");
  assert(
    body.error.code === "invalid_provider_response",
    "expected schema error",
  );
  assert(
    !JSON.stringify(body).includes("wrong property"),
    "must not expose raw output",
  );
});

Deno.test("maps provider failures to a safe error", async () => {
  const provider = new MockAiProvider(
    null,
    new Error("secret provider diagnostic"),
  );
  const response = await handlerFor(provider)(request());
  const body = await response.json();

  assert(response.status === 502, "expected bad gateway");
  assert(
    body.error.code === "provider_failure",
    "expected provider failure code",
  );
  assert(
    !JSON.stringify(body).includes("secret provider diagnostic"),
    "must hide provider errors",
  );
});

Deno.test("logs safe provider diagnostics without returning them", async () => {
  const provider: AiProvider = {
    id: "diagnostic",
    generate: () =>
      Promise.reject(
        new ProviderError(
          "request_failed",
          "Sensitive diagnostic",
          { httpStatus: 400, reason: "INVALID_ARGUMENT" },
        ),
      ),
  };
  const logs: Record<string, unknown>[] = [];
  const handler = createAiGatewayHandler({
    authenticate: async () => true,
    providerId: provider.id,
    providers: new AiProviderRegistry([provider]),
    loadPrompt: async () => "Prompt",
    createRequestId: () => "request-1",
    log: (_message, metadata) => logs.push(metadata),
  });

  const response = await handler(request());
  const body = await response.json();

  assert(response.status === 502, "expected bad gateway");
  assert(logs[0].providerCode === "request_failed", "expected error code");
  assert(logs[0].providerHttpStatus === 400, "expected provider status");
  assert(
    logs[0].providerReason === "INVALID_ARGUMENT",
    "expected provider reason",
  );
  assert(
    !JSON.stringify(body).includes("INVALID_ARGUMENT") &&
      !JSON.stringify(body).includes("Sensitive"),
    "must keep provider diagnostics out of the response",
  );
});

Deno.test("maps exhausted provider quota to temporary capacity", async () => {
  const provider: AiProvider = {
    id: "limited",
    generate: () =>
      Promise.reject(
        new ProviderError(
          "request_failed",
          "Quota details",
          { httpStatus: 429, reason: "RESOURCE_EXHAUSTED" },
        ),
      ),
  };
  const handler = createAiGatewayHandler({
    authenticate: async () => true,
    providerId: provider.id,
    providers: new AiProviderRegistry([provider]),
    loadPrompt: async () => "Prompt",
    createRequestId: () => "request-1",
  });

  const response = await handler(request());
  const body = await response.json();

  assert(response.status === 503, "expected temporary unavailability");
  assert(
    body.error.code === "provider_capacity",
    "expected capacity error code",
  );
  assert(
    !JSON.stringify(body).includes("RESOURCE_EXHAUSTED") &&
      !JSON.stringify(body).includes("Quota details"),
    "must keep provider details private",
  );
});

Deno.test("does not expose unregistered generic tasks", async () => {
  const provider = new MockAiProvider({ reply: "unused" });
  const response = await handlerFor(provider)(request("model.raw"));
  const body = await response.json();

  assert(response.status === 400, "expected invalid request");
  assert(
    body.error.code === "invalid_request",
    "expected allow-list rejection",
  );
  assert(provider.lastRequest === null, "provider must not be called");
});

Deno.test("requires authentication before routing", async () => {
  const provider = new MockAiProvider({ reply: "unused" });
  const handler = createAiGatewayHandler({
    authenticate: async () => false,
    providerId: "mock",
    providers: new AiProviderRegistry([provider]),
    loadPrompt: async () => "unused",
    createRequestId: () => "request-1",
  });
  const response = await handler(request());

  assert(response.status === 401, "expected unauthorized");
  assert(provider.lastRequest === null, "provider must not be called");
});

Deno.test("aborts provider work at the configured timeout", async () => {
  const provider: AiProvider = {
    id: "slow",
    generate: () => new Promise(() => {}),
  };
  const handler = createAiGatewayHandler({
    authenticate: async () => true,
    providerId: "slow",
    providers: new AiProviderRegistry([provider]),
    loadPrompt: async () => "Prompt",
    createRequestId: () => "request-1",
    timeoutMs: 5,
  });
  const response = await handler(request());
  const body = await response.json();

  assert(response.status === 504, "expected gateway timeout");
  assert(body.error.code === "provider_timeout", "expected timeout code");
});

Deno.test("rejects numeric scoring fields in response evaluation", async () => {
  const provider = new MockAiProvider({
    headline: "Klar",
    explanation: "Die Aussage ist verständlich.",
    strengths: ["Ruhiger Einstieg"],
    improvement: "Nenne den nächsten Schritt.",
    alternatives: ["Ich sehe das anders."],
    dimensions: {
      posture: "ruhig",
      precision: "klar",
      frame: "neu gesetzt",
      social_effect: "anschlussfähig",
      naturalness: "sprechbar",
      escalation_fit: "passend",
    },
    score: 8,
  });
  const response = await handlerFor(provider)(request("response.evaluate"));
  const body = await response.json();

  assert(response.status === 502, "expected schema rejection");
  assert(
    body.error.code === "invalid_provider_response",
    "expected validation error",
  );
});

Deno.test("accepts categorical visual feedback without a score", async () => {
  const provider = new MockAiProvider(visualFeedback());
  const response = await handlerFor(provider)(
    request("response.evaluate_visual"),
  );
  const body = await response.json();

  assert(response.status === 200, "expected valid visual feedback");
  assert(body.data.overall_signal === "strong", "expected overall signal");
  assert(
    body.promptVersion === "response_evaluate_visual_v3",
    "expected visual prompt version",
  );
});

Deno.test("rejects numeric values as visual feedback signals", async () => {
  const provider = new MockAiProvider({
    ...visualFeedback(),
    overall_signal: "8",
  });
  const response = await handlerFor(provider)(
    request("response.evaluate_visual"),
  );
  const body = await response.json();

  assert(response.status === 502, "expected schema rejection");
  assert(
    body.error.code === "invalid_provider_response",
    "expected validation error",
  );
});

Deno.test("accepts one consolidated Speech Challenge result", async () => {
  const provider = new MockAiProvider(challengeSessionFeedback());
  const response = await handlerFor(provider)(
    request("response.evaluate_challenge_session"),
  );
  const body = await response.json();

  assert(response.status === 200, "expected valid challenge result");
  assert(body.data.details.length === 2, "expected ordered response details");
  assert(
    body.promptVersion === "response_challenge_session_v1",
    "expected challenge prompt version",
  );
});

Deno.test("rejects numeric Speech Challenge detail signals", async () => {
  const result = challengeSessionFeedback();
  const details = result.details as Array<Record<string, unknown>>;
  details[0].signal = "9";
  const provider = new MockAiProvider(result);
  const response = await handlerFor(provider)(
    request("response.evaluate_challenge_session"),
  );
  const body = await response.json();

  assert(response.status === 502, "expected schema rejection");
  assert(
    body.error.code === "invalid_provider_response",
    "expected validation error",
  );
});

Deno.test("safety review keeps hostile training context separate from discrimination", async () => {
  const provider = new MockAiProvider({
    decision: "pass",
    findings: ["Hostile remark is the explicit training object."],
    rationale: "The scenario does not endorse the remark.",
    hostile_content_as_training: true,
    protected_trait_linkage: false,
    stereotype_risk: false,
  });
  const response = await handlerFor(provider)(
    request("scenario.safety_review"),
  );
  const body = await response.json();
  assert(response.status === 200, "expected valid safety review");
  assert(
    body.data.hostile_content_as_training === true,
    "expected explicit training context",
  );
  assert(
    body.data.protected_trait_linkage === false,
    "expected no trait linkage",
  );
});

function visualFeedback(): Record<string, unknown> {
  return {
    overall_signal: "strong",
    dimension_signals: {
      posture: "strong",
      precision: "strong",
      frame: "developing",
      social_effect: "strong",
      naturalness: "strong",
      escalation_fit: "developing",
    },
    headline: "Klar",
    explanation: "Die Aussage ist verständlich.",
    strengths: ["Ruhiger Einstieg"],
    improvement: "Nenne den nächsten Schritt.",
    alternatives: ["Ich sehe das anders."],
    dimensions: {
      posture: "ruhig",
      precision: "klar",
      frame: "neu gesetzt",
      social_effect: "anschlussfähig",
      naturalness: "sprechbar",
      escalation_fit: "passend",
    },
  };
}

function challengeSessionFeedback(): Record<string, unknown> {
  return {
    summary: visualFeedback(),
    details: [
      {
        signal: "strong",
        headline: "Clear boundary",
        strength: "The response is direct.",
        improvement: "Name the next step.",
        alternative: "I want to finish this thought first.",
      },
      {
        signal: "developing",
        headline: "Useful foundation",
        strength: "The position is understandable.",
        improvement: "Make the request more concrete.",
        alternative: "Please let me finish, then I will respond.",
      },
    ],
  };
}
