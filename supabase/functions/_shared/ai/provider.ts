import { AiTask } from "../contracts.ts";
import { JsonSchema } from "./schema.ts";

export interface AiProviderRequest {
  task: AiTask;
  prompt: string;
  payload: Record<string, unknown>;
  outputSchema: JsonSchema;
}

export interface AiProviderResult {
  data: unknown;
  model: string;
}

export interface AiProvider {
  readonly id: string;
  generate(
    request: AiProviderRequest,
    signal: AbortSignal,
  ): Promise<AiProviderResult>;
}

export class ProviderError extends Error {
  constructor(
    readonly code: "configuration" | "request_failed" | "invalid_response",
    message: string,
  ) {
    super(message);
    this.name = "ProviderError";
  }
}
