import { SpeechProviderRegistry } from "../_shared/speech/provider_registry.ts";
import { SpeechProviderError } from "../_shared/speech/provider.ts";
import {
  SynthesizeRequest,
  SynthesizeResult,
  VoiceRole,
  voiceRoles,
} from "../_shared/speech/contracts.ts";
import {
  createSharedSpeechCacheKey,
  SharedSpeechCatalog,
  SharedSpeechReference,
  sharedSpeechResourceKinds,
  SpeechAudioCache,
  SpeechAudioCacheStatus,
} from "../_shared/speech/shared_audio_cache.ts";

export interface SpeechGatewayDependencies {
  authenticate(request: Request): Promise<boolean>;
  providers: SpeechProviderRegistry;
  ttsProviderId: string;
  sttProviderId: string;
  sharedSpeechCatalog?: SharedSpeechCatalog;
  speechAudioCache?: SpeechAudioCache;
  timeoutMs?: number;
  createRequestId?: () => string;
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
  return Response.json(body, { status, headers: corsHeaders });
}

export function createSpeechGatewayHandler(
  dependencies: SpeechGatewayDependencies,
): (request: Request) => Promise<Response> {
  const createRequestId = dependencies.createRequestId ??
    (() => crypto.randomUUID());
  const timeoutMs = dependencies.timeoutMs ?? 25_000;

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
      const body = await readJson(request);
      if (body.schemaVersion !== "1") {
        throw new GatewayError("invalid_request", 400, "Ungültige Anfrage.");
      }

      if (body.operation === "tts") {
        const text = body.text;
        const role = body.role;
        if (
          typeof text !== "string" ||
          text.trim().length === 0 ||
          text.length > 1_500 ||
          !isVoiceRole(role) ||
          (body.voiceId != null && typeof body.voiceId !== "string") ||
          (body.languageCode != null && !isLanguageCode(body.languageCode))
        ) {
          throw new GatewayError(
            "invalid_request",
            400,
            "Ungültige Sprachausgabe.",
          );
        }
        const languageCode = body.languageCode === "en" ? "en" : "de";
        const sharedReference = parseSharedReference(body.sharedReference);
        if (body.sharedReference != null && sharedReference == null) {
          throw new GatewayError(
            "invalid_request",
            400,
            "Ungültige Sprachausgabe.",
          );
        }
        let synthesisRequest: SynthesizeRequest = {
          text,
          role,
          voiceId: typeof body.voiceId === "string" ? body.voiceId : undefined,
          languageCode,
        };
        if (sharedReference != null) {
          if (
            dependencies.sharedSpeechCatalog == null ||
            dependencies.speechAudioCache == null
          ) {
            throw new GatewayError(
              "cache_unavailable",
              503,
              "Die Sprachausgabe ist gerade nicht erreichbar.",
            );
          }
          const canonical = await dependencies.sharedSpeechCatalog.resolve(
            sharedReference,
            languageCode,
          );
          if (canonical == null) {
            throw new GatewayError(
              "invalid_request",
              400,
              "Diese Sprachausgabe ist nicht freigegeben.",
            );
          }
          if (
            canonical.text.trim().length === 0 ||
            canonical.text.length > 1_500
          ) {
            throw new GatewayError(
              "invalid_request",
              400,
              "Ungültige Sprachausgabe.",
            );
          }
          synthesisRequest = canonical;
        }
        const provider = dependencies.providers.textToSpeech(
          dependencies.ttsProviderId,
        );
        const create = () =>
          withTimeout(
            (signal) => provider.synthesize(synthesisRequest, signal),
            timeoutMs,
          );
        let cacheStatus: SpeechAudioCacheStatus = "bypass";
        let result: SynthesizeResult;
        if (sharedReference != null && dependencies.speechAudioCache != null) {
          const profile = provider.synthesisProfile(synthesisRequest);
          const cacheKey = await createSharedSpeechCacheKey(
            synthesisRequest,
            profile,
          );
          try {
            const cached = await dependencies.speechAudioCache.getOrCreate(
              cacheKey,
              create,
            );
            result = cached.result;
            cacheStatus = cached.status;
          } catch (error) {
            if (
              error instanceof GatewayError ||
              error instanceof SpeechProviderError
            ) throw error;
            console.warn(JSON.stringify({
              event: "shared_speech_cache_bypassed",
              requestId,
              cacheKey: cacheKey.slice(0, 12),
            }));
            result = await create();
          }
        } else {
          result = await create();
        }
        if (sharedReference != null) {
          console.info(JSON.stringify({
            event: "shared_speech_cache_result",
            requestId,
            cacheStatus,
            provider: result.provider,
            model: result.model,
          }));
        }
        return json({
          audioBase64: encodeBase64(result.audio),
          mimeType: result.mimeType,
          provider: result.provider,
          model: result.model,
          cacheStatus,
          schemaVersion: "1",
          requestId,
        }, 200);
      }

      if (body.operation === "stt") {
        if (
          typeof body.audioBase64 !== "string" ||
          body.audioBase64.length > 8_000_000 ||
          typeof body.mimeType !== "string" ||
          (body.languageCode != null && !isLanguageCode(body.languageCode))
        ) {
          throw new GatewayError("invalid_request", 400, "Ungültige Aufnahme.");
        }
        const audio = decodeBase64(body.audioBase64);
        if (audio.length === 0) {
          throw new GatewayError(
            "invalid_request",
            400,
            "Die Aufnahme ist leer.",
          );
        }
        const provider = dependencies.providers.speechToText(
          dependencies.sttProviderId,
        );
        const result = await withTimeout(
          (signal) =>
            provider.transcribe({
              audio,
              mimeType: body.mimeType as string,
              languageCode: body.languageCode === "en" ? "en" : "de",
            }, signal),
          timeoutMs,
        );
        return json({
          transcript: result.transcript,
          provider: result.provider,
          model: result.model,
          schemaVersion: "1",
          requestId,
        }, 200);
      }

      throw new GatewayError(
        "invalid_request",
        400,
        "Unbekannte Sprachoperation.",
      );
    } catch (error) {
      const safe = safeError(error);
      console.warn(JSON.stringify({
        event: "speech_gateway_failed",
        requestId,
        code: safe.code,
        status: safe.status,
      }));
      return errorResponse(requestId, safe);
    }
  };
}

async function readJson(request: Request): Promise<Record<string, unknown>> {
  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (contentLength > 8_100_000) {
    throw new GatewayError(
      "payload_too_large",
      413,
      "Die Aufnahme ist zu groß.",
    );
  }
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    throw new GatewayError("invalid_json", 400, "Ungültige Anfrage.");
  }
  if (!isRecord(body)) {
    throw new GatewayError("invalid_request", 400, "Ungültige Anfrage.");
  }
  return body;
}

function isVoiceRole(value: unknown): value is VoiceRole {
  return typeof value === "string" && voiceRoles.some((role) => role === value);
}

function isLanguageCode(value: unknown): value is "de" | "en" {
  return value === "de" || value === "en";
}

function parseSharedReference(value: unknown): SharedSpeechReference | null {
  if (!isRecord(value)) return null;
  if (
    typeof value.kind !== "string" ||
    !sharedSpeechResourceKinds.some((kind) => kind === value.kind) ||
    typeof value.id !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
      .test(value.id)
  ) {
    return null;
  }
  return {
    kind: value.kind as SharedSpeechReference["kind"],
    id: value.id,
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function decodeBase64(value: string): Uint8Array {
  try {
    const binary = atob(value);
    return Uint8Array.from(binary, (character) => character.charCodeAt(0));
  } catch {
    throw new GatewayError("invalid_request", 400, "Ungültige Aufnahme.");
  }
}

function encodeBase64(bytes: Uint8Array): string {
  let binary = "";
  const chunkSize = 32_768;
  for (let index = 0; index < bytes.length; index += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(index, index + chunkSize));
  }
  return btoa(binary);
}

async function withTimeout<T>(
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
          "Die Sprachverarbeitung hat zu lange gedauert.",
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

function safeError(error: unknown): GatewayError {
  if (error instanceof GatewayError) return error;
  return new GatewayError(
    "provider_failure",
    502,
    "Die Sprachverarbeitung ist gerade nicht erreichbar.",
  );
}

function errorResponse(requestId: string, error: GatewayError): Response {
  return json({
    error: { code: error.code, message: error.publicMessage },
    requestId,
  }, error.status);
}
