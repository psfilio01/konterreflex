export const voiceRoles = ["moderator", "actor", "intelligence"] as const;
export type VoiceRole = (typeof voiceRoles)[number];

export interface SynthesizeRequest {
  text: string;
  role: VoiceRole;
  voiceId?: string;
  languageCode?: "de" | "en";
}

export interface SynthesizeResult {
  audio: Uint8Array;
  mimeType: string;
  provider: string;
  model: string;
}

export interface TranscribeRequest {
  audio: Uint8Array;
  mimeType: string;
  languageCode?: "de" | "en";
}

export interface TranscribeResult {
  transcript: string;
  provider: string;
  model: string;
}
