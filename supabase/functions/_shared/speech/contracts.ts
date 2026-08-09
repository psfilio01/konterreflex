export const voiceRoles = ["moderator", "actor", "intelligence"] as const;
export type VoiceRole = (typeof voiceRoles)[number];

export interface SynthesizeRequest {
  text: string;
  role: VoiceRole;
  voiceId?: string;
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
  languageCode?: string;
}

export interface TranscribeResult {
  transcript: string;
  provider: string;
  model: string;
}
