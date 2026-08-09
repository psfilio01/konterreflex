import {
  SpeechProviderError,
  SpeechToTextProvider,
  TextToSpeechProvider,
} from "./provider.ts";

export class SpeechProviderRegistry {
  private readonly tts = new Map<string, TextToSpeechProvider>();
  private readonly stt = new Map<string, SpeechToTextProvider>();

  constructor(options: {
    tts?: TextToSpeechProvider[];
    stt?: SpeechToTextProvider[];
  }) {
    for (const provider of options.tts ?? []) {
      this.tts.set(provider.id, provider);
    }
    for (const provider of options.stt ?? []) {
      this.stt.set(provider.id, provider);
    }
  }

  textToSpeech(id: string): TextToSpeechProvider {
    const provider = this.tts.get(id);
    if (!provider) throw new SpeechProviderError("configuration");
    return provider;
  }

  speechToText(id: string): SpeechToTextProvider {
    const provider = this.stt.get(id);
    if (!provider) throw new SpeechProviderError("configuration");
    return provider;
  }
}
