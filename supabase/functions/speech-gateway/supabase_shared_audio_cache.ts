import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import {
  SynthesizeRequest,
  SynthesizeResult,
  voiceRoles,
} from "../_shared/speech/contracts.ts";
import {
  SharedSpeechCatalog,
  SharedSpeechReference,
  SpeechAudioCache,
  SpeechAudioCacheResult,
} from "../_shared/speech/shared_audio_cache.ts";

interface CacheClaim {
  cache_state: "pending" | "ready" | "failed";
  storage_path: string;
  mime_type: string | null;
  provider: string | null;
  model: string | null;
  claimed: boolean;
}

const bucket = "shared-speech-cache";

export class SupabaseSharedSpeechCatalog implements SharedSpeechCatalog {
  constructor(private readonly client: SupabaseClient) {}

  async resolve(
    reference: SharedSpeechReference,
    languageCode: "de" | "en",
  ): Promise<SynthesizeRequest | null> {
    const { data, error } = await this.client.rpc(
      "resolve_shared_speech_resource",
      {
        p_kind: reference.kind,
        p_id: reference.id,
        p_language: languageCode,
      },
    );
    if (error) throw new Error("shared_speech_catalog_failed");
    const row = Array.isArray(data) ? data[0] : null;
    if (
      !isRecord(row) ||
      typeof row.speech_text !== "string" ||
      !voiceRoles.some((role) => role === row.voice_role)
    ) {
      return null;
    }
    return {
      text: row.speech_text,
      role: row.voice_role as SynthesizeRequest["role"],
      languageCode,
      voiceId: typeof row.voice_id === "string" ? row.voice_id : undefined,
    };
  }
}

export class SupabaseSpeechAudioCache implements SpeechAudioCache {
  constructor(
    private readonly client: SupabaseClient,
    private readonly leaseSeconds = 30,
    private readonly pollIntervalMs = 200,
  ) {}

  async getOrCreate(
    cacheKey: string,
    create: () => Promise<SynthesizeResult>,
  ): Promise<SpeechAudioCacheResult> {
    const claimToken = crypto.randomUUID();
    const storagePath = `v1/${cacheKey.slice(0, 2)}/${cacheKey}`;

    while (true) {
      const claim = await this.claim(cacheKey, storagePath, claimToken);
      if (claim.cache_state === "ready") {
        const cached = await this.download(cacheKey, claim);
        if (cached != null) return { result: cached, status: "hit" };
        await this.invalidate(cacheKey);
        continue;
      }
      if (claim.claimed) {
        return await this.generateAndStore(
          cacheKey,
          claimToken,
          storagePath,
          create,
        );
      }
      await delay(this.pollIntervalMs);
    }
  }

  private async claim(
    cacheKey: string,
    storagePath: string,
    claimToken: string,
  ): Promise<CacheClaim> {
    const { data, error } = await this.client.rpc(
      "claim_shared_speech_audio",
      {
        p_cache_key: cacheKey,
        p_storage_path: storagePath,
        p_claim_token: claimToken,
        p_lease_seconds: this.leaseSeconds,
      },
    );
    const row = Array.isArray(data) ? data[0] : null;
    if (error || !isCacheClaim(row)) {
      throw new Error("shared_speech_cache_claim_failed");
    }
    return row;
  }

  private async download(
    cacheKey: string,
    claim: CacheClaim,
  ): Promise<SynthesizeResult | null> {
    if (!claim.mime_type || !claim.provider || !claim.model) return null;
    const { data, error } = await this.client.storage
      .from(bucket)
      .download(claim.storage_path);
    if (error || data == null || data.size === 0 || data.size > 5_242_880) {
      return null;
    }
    void this.client.rpc("touch_shared_speech_audio", {
      p_cache_key: cacheKey,
    });
    return {
      audio: new Uint8Array(await data.arrayBuffer()),
      mimeType: claim.mime_type,
      provider: claim.provider,
      model: claim.model,
    };
  }

  private async generateAndStore(
    cacheKey: string,
    claimToken: string,
    storagePath: string,
    create: () => Promise<SynthesizeResult>,
  ): Promise<SpeechAudioCacheResult> {
    let result: SynthesizeResult;
    try {
      result = await create();
    } catch (error) {
      await this.fail(cacheKey, claimToken);
      throw error;
    }

    try {
      const { error: uploadError } = await this.client.storage
        .from(bucket)
        .upload(
          storagePath,
          new Blob([Uint8Array.from(result.audio).buffer], {
            type: result.mimeType,
          }),
          { contentType: result.mimeType, upsert: true },
        );
      if (uploadError) throw uploadError;
      const { data, error } = await this.client.rpc(
        "complete_shared_speech_audio",
        {
          p_cache_key: cacheKey,
          p_claim_token: claimToken,
          p_mime_type: result.mimeType,
          p_provider: result.provider,
          p_model: result.model,
          p_byte_size: result.audio.length,
        },
      );
      if (error || data !== true) throw new Error("cache_complete_failed");
      return { result, status: "miss" };
    } catch (error) {
      console.warn(JSON.stringify({
        event: "shared_speech_cache_store_failed",
        cacheKey: cacheKey.slice(0, 12),
      }));
      await this.fail(cacheKey, claimToken);
      return { result, status: "bypass" };
    }
  }

  private async fail(cacheKey: string, claimToken: string): Promise<void> {
    await this.client.rpc("fail_shared_speech_audio", {
      p_cache_key: cacheKey,
      p_claim_token: claimToken,
    });
  }

  private async invalidate(cacheKey: string): Promise<void> {
    const { data, error } = await this.client.rpc(
      "invalidate_shared_speech_audio",
      {
        p_cache_key: cacheKey,
      },
    );
    if (error || data !== true) {
      throw new Error("shared_speech_cache_invalidate_failed");
    }
  }
}

function isCacheClaim(value: unknown): value is CacheClaim {
  if (!isRecord(value)) return false;
  return (value.cache_state === "pending" ||
    value.cache_state === "ready" ||
    value.cache_state === "failed") &&
    typeof value.storage_path === "string" &&
    typeof value.claimed === "boolean";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}
