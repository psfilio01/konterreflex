import { AiRequest, AiResponse, isAiTask } from "../_shared/contracts.ts";
import { AiProviderRegistry } from "../_shared/ai/provider_registry.ts";
import { ProviderError } from "../_shared/ai/provider.ts";
import { isRecord, validateSchema } from "../_shared/ai/schema.ts";
import { AiTaskDefinition, taskRegistry } from "../_shared/ai/task_registry.ts";

export interface AiGatewayDependencies {
  authenticate(request: Request): Promise<boolean>;
  providers: AiProviderRegistry;
  providerId: string;
  loadPrompt(definition: AiTaskDefinition): Promise<string>;
  timeoutMs?: number;
  createRequestId?: () => string;
  log?: (message: string, metadata: Record<string, unknown>) => void;
}

class GatewayError extends Error {
  constructor(
    readonly code: string,
    readonly status: number,
    readonly publicMessage: string,
  ) {
    super(code);
  }
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status: number): Response {
  return Response.json(body, {
    status,
    headers: corsHeaders,
  });
}

export function createAiGatewayHandler(
  dependencies: AiGatewayDependencies,
): (request: Request) => Promise<Response> {
  const timeoutMs = dependencies.timeoutMs ?? 20_000;
  const createRequestId = dependencies.createRequestId ??
    (() => crypto.randomUUID());
  const log = dependencies.log ?? (() => {});

  return async (request) => {
    const requestId = createRequestId();
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return errorResponse(
        requestId,
        new GatewayError(
          "method_not_allowed",
          405,
          "Diese Methode wird nicht unterstützt.",
        ),
      );
    }

    try {
      if (!await dependencies.authenticate(request)) {
        throw new GatewayError("unauthorized", 401, "Anmeldung erforderlich.");
      }

      const aiRequest = await parseRequest(request);
      const definition = taskRegistry[aiRequest.task];
      const provider = dependencies.providers.get(dependencies.providerId);
      const prompt = withResponseLanguage(
        await dependencies.loadPrompt(definition),
        aiRequest.responseLanguage,
      );

      const result = await runWithTimeout(
        (signal) =>
          provider.generate({
            task: definition.task,
            prompt,
            payload: aiRequest.payload,
            outputSchema: definition.outputSchema,
          }, signal),
        timeoutMs,
      );

      const validation = validateSchema(result.data, definition.outputSchema);
      if (!validation.valid) {
        log("ai_gateway_invalid_provider_response", {
          requestId,
          task: definition.task,
          provider: provider.id,
          issueCount: validation.issues.length,
        });
        throw new GatewayError(
          "invalid_provider_response",
          502,
          "Die KI-Antwort konnte nicht sicher verarbeitet werden.",
        );
      }

      const response: AiResponse = {
        data: result.data,
        provider: provider.id,
        model: result.model,
        promptVersion: definition.promptVersion,
        schemaVersion: "1",
        requestId,
      };
      return json(response, 200);
    } catch (error) {
      const safeError = toGatewayError(error);
      log("ai_gateway_request_failed", {
        requestId,
        code: safeError.code,
        status: safeError.status,
        ...providerDiagnostics(error),
      });
      return errorResponse(requestId, safeError);
    }
  };
}

async function parseRequest(request: Request): Promise<AiRequest> {
  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (contentLength > 65_536) {
    throw new GatewayError(
      "payload_too_large",
      413,
      "Die Anfrage ist zu groß.",
    );
  }

  const text = await request.text();
  if (text.length > 65_536) {
    throw new GatewayError(
      "payload_too_large",
      413,
      "Die Anfrage ist zu groß.",
    );
  }

  let body: unknown;
  try {
    body = JSON.parse(text);
  } catch {
    throw new GatewayError("invalid_json", 400, "Ungültige Anfrage.");
  }
  if (
    !isRecord(body) ||
    body.schemaVersion !== "1" ||
    !isAiTask(body.task) ||
    !isRecord(body.payload) ||
    (body.responseLanguage != null &&
      body.responseLanguage !== "de" &&
      body.responseLanguage !== "en")
  ) {
    throw new GatewayError("invalid_request", 400, "Ungültige Anfrage.");
  }
  return {
    ...body,
    responseLanguage: body.responseLanguage === "en" ? "en" : "de",
  } as unknown as AiRequest;
}

function withResponseLanguage(prompt: string, language: "de" | "en"): string {
  const languageName = language === "en" ? "English" : "German";
  return `${prompt}\n\n# Required response language\nWrite every user-facing text value in ${languageName}. Keep JSON keys unchanged. Do not translate quoted user input, names, or schema keys. Preserve the qualitative, non-numerical feedback and all safety rules.`;
}

async function runWithTimeout<T>(
  action: (signal: AbortSignal) => Promise<T>,
  timeoutMs: number,
): Promise<T> {
  const controller = new AbortController();
  let timeout: ReturnType<typeof setTimeout> | undefined;
  const timeoutPromise = new Promise<never>((_, reject) => {
    timeout = setTimeout(() => {
      controller.abort();
      reject(
        new GatewayError(
          "provider_timeout",
          504,
          "Die KI-Antwort hat zu lange gedauert.",
        ),
      );
    }, timeoutMs);
  });
  try {
    return await Promise.race([action(controller.signal), timeoutPromise]);
  } finally {
    if (timeout != null) clearTimeout(timeout);
  }
}

function providerDiagnostics(error: unknown): Record<string, unknown> {
  if (!(error instanceof ProviderError)) return {};
  return {
    providerCode: error.code,
    ...(error.diagnostics.httpStatus == null
      ? {}
      : { providerHttpStatus: error.diagnostics.httpStatus }),
    ...(error.diagnostics.reason == null
      ? {}
      : { providerReason: error.diagnostics.reason }),
  };
}

function toGatewayError(error: unknown): GatewayError {
  if (error instanceof GatewayError) return error;
  if (
    error instanceof ProviderError &&
    error.code === "request_failed" &&
    error.diagnostics.httpStatus === 429
  ) {
    return new GatewayError(
      "provider_capacity",
      503,
      "Das KI-Feedback ist gerade ausgelastet. Bitte versuche es später erneut.",
    );
  }
  if (error instanceof Error && error.name === "AbortError") {
    return new GatewayError(
      "provider_timeout",
      504,
      "Die KI-Antwort hat zu lange gedauert.",
    );
  }
  return new GatewayError(
    "provider_failure",
    502,
    "Die KI ist gerade nicht erreichbar. Bitte versuche es erneut.",
  );
}

function errorResponse(requestId: string, error: GatewayError): Response {
  return json({
    error: { code: error.code, message: error.publicMessage },
    requestId,
  }, error.status);
}
