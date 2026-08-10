import {
  AiProvider,
  AiProviderRequest,
  AiProviderResult,
  ProviderError,
} from "./provider.ts";
import { isRecord } from "./schema.ts";

type Fetch = typeof fetch;

export class GeminiProvider implements AiProvider {
  readonly id = "gemini";

  constructor(
    private readonly apiKey: string,
    private readonly model = "gemini-2.5-flash",
    private readonly fetcher: Fetch = fetch,
  ) {
    if (!apiKey) throw new ProviderError("configuration", "Missing Gemini key");
  }

  async generate(
    request: AiProviderRequest,
    signal: AbortSignal,
  ): Promise<AiProviderResult> {
    const url = new URL(
      `https://generativelanguage.googleapis.com/v1beta/models/${
        encodeURIComponent(this.model)
      }:generateContent`,
    );
    const response = await this.fetcher(url, {
      method: "POST",
      signal,
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": this.apiKey,
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: request.prompt }] },
        contents: [{
          role: "user",
          parts: [{
            text: JSON.stringify({
              task: request.task,
              input: request.payload,
            }),
          }],
        }],
        generationConfig: {
          responseMimeType: "application/json",
          responseJsonSchema: request.outputSchema,
          temperature: 0.35,
        },
      }),
    });

    if (!response.ok) {
      const reason = await readProviderReason(response);
      throw new ProviderError(
        "request_failed",
        `Gemini request failed with status ${response.status}`,
        {
          httpStatus: response.status,
          ...(reason == null ? {} : { reason }),
        },
      );
    }

    const responseBody: unknown = await response.json();
    const text = extractCandidateText(responseBody);
    if (text == null) {
      throw new ProviderError(
        "invalid_response",
        "Gemini returned no JSON candidate",
      );
    }

    try {
      return {
        data: JSON.parse(text),
        model: isRecord(responseBody) &&
            typeof responseBody.modelVersion === "string"
          ? responseBody.modelVersion
          : this.model,
      };
    } catch {
      throw new ProviderError(
        "invalid_response",
        "Gemini returned malformed JSON",
      );
    }
  }
}

async function readProviderReason(response: Response): Promise<string | null> {
  try {
    const body: unknown = await response.json();
    if (!isRecord(body) || !isRecord(body.error)) return null;
    const reason = body.error.status;
    return typeof reason === "string" && /^[A-Z][A-Z_]{0,63}$/.test(reason)
      ? reason
      : null;
  } catch {
    return null;
  }
}

function extractCandidateText(body: unknown): string | null {
  if (!isRecord(body) || !Array.isArray(body.candidates)) return null;
  const candidate = body.candidates[0];
  if (!isRecord(candidate) || !isRecord(candidate.content)) return null;
  const parts = candidate.content.parts;
  if (!Array.isArray(parts)) return null;
  const part = parts.find((item) =>
    isRecord(item) && typeof item.text === "string"
  );
  return isRecord(part) && typeof part.text === "string" ? part.text : null;
}
