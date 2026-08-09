import { AiProvider, AiProviderRequest, AiProviderResult } from "./provider.ts";

export class MockAiProvider implements AiProvider {
  readonly id = "mock";
  lastRequest: AiProviderRequest | null = null;

  constructor(
    private readonly result: unknown,
    private readonly failure?: Error,
  ) {}

  generate(
    request: AiProviderRequest,
    _signal: AbortSignal,
  ): Promise<AiProviderResult> {
    this.lastRequest = request;
    if (this.failure) return Promise.reject(this.failure);
    return Promise.resolve({ data: this.result, model: "mock-v1" });
  }
}
