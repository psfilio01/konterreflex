import {
  SynthesisProfile,
  SynthesizeRequest,
  SynthesizeResult,
  TranscribeRequest,
  TranscribeResult,
} from "./contracts.ts";

export interface TextToSpeechProvider {
  readonly id: string;
  synthesisProfile(request: SynthesizeRequest): SynthesisProfile;
  synthesize(
    request: SynthesizeRequest,
    signal: AbortSignal,
  ): Promise<SynthesizeResult>;
}

export interface SpeechToTextProvider {
  readonly id: string;
  transcribe(
    request: TranscribeRequest,
    signal: AbortSignal,
  ): Promise<TranscribeResult>;
}

export class SpeechProviderError extends Error {
  constructor(
    readonly code: "configuration" | "request_failed" | "invalid_response",
  ) {
    super(code);
    this.name = "SpeechProviderError";
  }
}
