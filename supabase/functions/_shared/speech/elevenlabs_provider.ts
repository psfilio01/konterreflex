import {
  SynthesisProfile,
  SynthesizeRequest,
  SynthesizeResult,
  TranscribeRequest,
  TranscribeResult,
  VoiceRole,
} from "./contracts.ts";
import {
  SpeechProviderError,
  SpeechToTextProvider,
  TextToSpeechProvider,
} from "./provider.ts";

type Fetch = typeof fetch;

export interface ElevenLabsRoleVoices {
  moderator?: string;
  actor?: string;
  intelligence?: string;
}

export interface ElevenLabsVoiceConfig extends ElevenLabsRoleVoices {
  de?: ElevenLabsRoleVoices;
  en?: ElevenLabsRoleVoices;
}

export class ElevenLabsSpeechProvider
  implements TextToSpeechProvider, SpeechToTextProvider {
  readonly id = "elevenlabs";
  private readonly outputFormat = "mp3_44100_128";

  constructor(
    private readonly apiKey: string,
    private readonly voices: ElevenLabsVoiceConfig,
    private readonly ttsModel = "eleven_multilingual_v2",
    private readonly sttModel = "scribe_v2",
    private readonly fetcher: Fetch = fetch,
  ) {
    if (!apiKey) throw new SpeechProviderError("configuration");
  }

  async synthesize(
    request: SynthesizeRequest,
    signal: AbortSignal,
  ): Promise<SynthesizeResult> {
    const voiceId = this.voiceFor(
      request.role,
      request.languageCode ?? "de",
      request.voiceId,
    );
    const url = new URL(
      `https://api.elevenlabs.io/v1/text-to-speech/${
        encodeURIComponent(voiceId)
      }`,
    );
    url.searchParams.set("output_format", this.outputFormat);
    const response = await this.fetcher(url, {
      method: "POST",
      signal,
      headers: {
        "Content-Type": "application/json",
        "xi-api-key": this.apiKey,
      },
      body: JSON.stringify({ text: request.text, model_id: this.ttsModel }),
    });
    if (!response.ok) throw new SpeechProviderError("request_failed");
    return {
      audio: new Uint8Array(await response.arrayBuffer()),
      mimeType: response.headers.get("content-type")?.split(";")[0] ??
        "audio/mpeg",
      provider: this.id,
      model: this.ttsModel,
    };
  }

  synthesisProfile(request: SynthesizeRequest): SynthesisProfile {
    return {
      provider: this.id,
      model: this.ttsModel,
      voice: this.voiceFor(
        request.role,
        request.languageCode ?? "de",
        request.voiceId,
      ),
      outputFormat: this.outputFormat,
      revision: "1",
    };
  }

  async transcribe(
    request: TranscribeRequest,
    signal: AbortSignal,
  ): Promise<TranscribeResult> {
    const form = new FormData();
    form.set("model_id", this.sttModel);
    form.set("tag_audio_events", "false");
    if (request.languageCode) form.set("language_code", request.languageCode);
    if (request.mimeType.startsWith("audio/pcm")) {
      form.set("file_format", "pcm_s16le_16");
    }
    form.set(
      "file",
      new Blob([Uint8Array.from(request.audio).buffer], {
        type: request.mimeType,
      }),
      request.mimeType.startsWith("audio/pcm")
        ? "response.pcm"
        : "response.audio",
    );
    const response = await this.fetcher(
      "https://api.elevenlabs.io/v1/speech-to-text",
      {
        method: "POST",
        signal,
        headers: { "xi-api-key": this.apiKey },
        body: form,
      },
    );
    if (!response.ok) throw new SpeechProviderError("request_failed");
    const body: unknown = await response.json();
    if (!isRecord(body) || typeof body.text !== "string") {
      throw new SpeechProviderError("invalid_response");
    }
    return {
      transcript: body.text,
      provider: this.id,
      model: this.sttModel,
    };
  }

  private voiceFor(
    role: VoiceRole,
    languageCode: "de" | "en",
    actorOverride?: string,
  ): string {
    const voice = role === "actor" && actorOverride
      ? actorOverride
      : this.voices[languageCode]?.[role] ?? this.voices[role];
    if (!voice || !/^[A-Za-z0-9_-]{8,64}$/.test(voice)) {
      throw new SpeechProviderError("configuration");
    }
    return voice;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
