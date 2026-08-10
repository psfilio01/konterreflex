import {
  SynthesisProfile,
  SynthesizeRequest,
  SynthesizeResult,
} from "./contracts.ts";

export const sharedSpeechResourceKinds = [
  "scenario_intro",
  "scenario_turn",
  "challenge_prompt",
] as const;

export type SharedSpeechResourceKind =
  (typeof sharedSpeechResourceKinds)[number];

export interface SharedSpeechReference {
  kind: SharedSpeechResourceKind;
  id: string;
}

export interface SharedSpeechCatalog {
  resolve(
    reference: SharedSpeechReference,
    languageCode: "de" | "en",
  ): Promise<SynthesizeRequest | null>;
}

export type SpeechAudioCacheStatus = "hit" | "miss" | "bypass";

export interface SpeechAudioCacheResult {
  result: SynthesizeResult;
  status: SpeechAudioCacheStatus;
}

export interface SpeechAudioCache {
  getOrCreate(
    cacheKey: string,
    create: () => Promise<SynthesizeResult>,
  ): Promise<SpeechAudioCacheResult>;
}

export async function createSharedSpeechCacheKey(
  request: SynthesizeRequest,
  profile: SynthesisProfile,
): Promise<string> {
  const canonical = JSON.stringify({
    schema: "shared-speech-v1",
    text: request.text,
    role: request.role,
    languageCode: request.languageCode ?? "de",
    voiceId: request.voiceId ?? null,
    provider: profile.provider,
    model: profile.model,
    voice: profile.voice,
    outputFormat: profile.outputFormat,
    revision: profile.revision,
  });
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(canonical),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}
