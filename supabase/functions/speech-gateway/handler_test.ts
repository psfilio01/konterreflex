import {
  SynthesizeRequest,
  TranscribeRequest,
} from "../_shared/speech/contracts.ts";
import {
  SpeechToTextProvider,
  TextToSpeechProvider,
} from "../_shared/speech/provider.ts";
import { SpeechProviderRegistry } from "../_shared/speech/provider_registry.ts";
import { createSpeechGatewayHandler } from "./handler.ts";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

class MockSpeechProvider implements TextToSpeechProvider, SpeechToTextProvider {
  readonly id = "mock";
  synthesized: SynthesizeRequest | null = null;
  transcribed: TranscribeRequest | null = null;

  synthesize(request: SynthesizeRequest): Promise<{
    audio: Uint8Array;
    mimeType: string;
    provider: string;
    model: string;
  }> {
    this.synthesized = request;
    return Promise.resolve({
      audio: Uint8Array.from([1, 2, 3]),
      mimeType: "audio/mpeg",
      provider: this.id,
      model: "mock-tts",
    });
  }

  transcribe(request: TranscribeRequest): Promise<{
    transcript: string;
    provider: string;
    model: string;
  }> {
    this.transcribed = request;
    return Promise.resolve({
      transcript: "Das sehe ich anders.",
      provider: this.id,
      model: "mock-stt",
    });
  }
}

function handlerFor(provider: MockSpeechProvider, authenticated = true) {
  return createSpeechGatewayHandler({
    authenticate: async () => authenticated,
    providers: new SpeechProviderRegistry({ tts: [provider], stt: [provider] }),
    ttsProviderId: "mock",
    sttProviderId: "mock",
    createRequestId: () => "speech-1",
  });
}

Deno.test("routes TTS with an explicit voice role", async () => {
  const provider = new MockSpeechProvider();
  const response = await handlerFor(provider)(
    new Request("http://localhost", {
      method: "POST",
      body: JSON.stringify({
        operation: "tts",
        schemaVersion: "1",
        text: "Die Szene beginnt.",
        role: "moderator",
        languageCode: "en",
      }),
    }),
  );
  const body = await response.json();

  assert(response.status === 200, "expected success");
  assert(provider.synthesized?.role === "moderator", "expected moderator role");
  assert(provider.synthesized?.languageCode === "en", "expected language");
  assert(body.audioBase64 === "AQID", "expected encoded audio");
  assert(body.model === "mock-tts", "expected model metadata");
});

Deno.test("creates a request ID with the production default", async () => {
  const provider = new MockSpeechProvider();
  const handler = createSpeechGatewayHandler({
    authenticate: async () => true,
    providers: new SpeechProviderRegistry({ tts: [provider], stt: [provider] }),
    ttsProviderId: "mock",
    sttProviderId: "mock",
  });
  const response = await handler(
    new Request("http://localhost", {
      method: "POST",
      body: JSON.stringify({
        operation: "tts",
        schemaVersion: "1",
        text: "Die Szene beginnt.",
        role: "moderator",
      }),
    }),
  );
  const body = await response.json();

  assert(response.status === 200, "expected success");
  assert(
    typeof body.requestId === "string" &&
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
        .test(body.requestId),
    "expected a generated UUID request ID",
  );
});

Deno.test("routes short lived audio to configured STT", async () => {
  const provider = new MockSpeechProvider();
  const response = await handlerFor(provider)(
    new Request("http://localhost", {
      method: "POST",
      body: JSON.stringify({
        operation: "stt",
        schemaVersion: "1",
        audioBase64: "AQID",
        mimeType: "audio/pcm;rate=16000",
        languageCode: "de",
      }),
    }),
  );
  const body = await response.json();

  assert(response.status === 200, "expected success");
  assert(provider.transcribed?.audio.length === 3, "expected decoded audio");
  assert(provider.transcribed?.languageCode === "de", "expected language");
  assert(body.transcript === "Das sehe ich anders.", "expected transcript");
});

Deno.test("rejects unsupported speech languages", async () => {
  const provider = new MockSpeechProvider();
  const response = await handlerFor(provider)(
    new Request("http://localhost", {
      method: "POST",
      body: JSON.stringify({
        operation: "tts",
        schemaVersion: "1",
        text: "Bonjour",
        role: "moderator",
        languageCode: "fr",
      }),
    }),
  );

  assert(response.status === 400, "expected invalid request");
  assert(provider.synthesized === null, "provider must not run");
});

Deno.test("rejects unauthenticated speech before provider use", async () => {
  const provider = new MockSpeechProvider();
  const response = await handlerFor(provider, false)(
    new Request("http://localhost", {
      method: "POST",
      body: JSON.stringify({
        operation: "tts",
        schemaVersion: "1",
        text: "Nicht erlaubt",
        role: "intelligence",
      }),
    }),
  );

  assert(response.status === 401, "expected unauthorized");
  assert(provider.synthesized === null, "provider must not run");
});
