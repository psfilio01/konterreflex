import { AiProvider, ProviderError } from "./provider.ts";

export class AiProviderRegistry {
  private readonly providers = new Map<string, AiProvider>();

  constructor(providers: AiProvider[]) {
    for (const provider of providers) this.providers.set(provider.id, provider);
  }

  get(providerId: string): AiProvider {
    const provider = this.providers.get(providerId);
    if (!provider) {
      throw new ProviderError(
        "configuration",
        `AI provider '${providerId}' is not configured`,
      );
    }
    return provider;
  }
}
