import {
  SynthesisProfile,
  SynthesizeRequest,
  SynthesizeResult,
  TranscribeRequest,
} from "../_shared/speech/contracts.ts";
import {
  SpeechToTextProvider,
  TextToSpeechProvider,
} from "../_shared/speech/provider.ts";
import { SpeechProviderRegistry } from "../_shared/speech/provider_registry.ts";
import {
  SharedSpeechCatalog,
  SharedSpeechReference,
  SpeechAudioCache,
  SpeechAudioCacheResult,
} from "../_shared/speech/shared_audio_cache.ts";
import { createSpeechGatewayHandler } from "./handler.ts";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

class MockSpeechProvider implements TextToSpeechProvider, SpeechToTextProvider {
  readonly id = "mock";
  synthesized: SynthesizeRequest | null = null;
  synthesizeCount = 0;
  transcribed: TranscribeRequest | null = null;

  synthesisProfile(request: SynthesizeRequest): SynthesisProfile {
    return {
      provider: this.id,
      model: "mock-tts",
      voice: request.voiceId ?? `${request.languageCode}-${request.role}`,
      outputFormat: "audio/mock",
      revision: "1",
    };
  }

  synthesize(request: SynthesizeRequest): Promise<{
    audio: Uint8Array;
    mimeType: string;
    provider: string;
    model: string;
  }> {
    this.synthesized = request;
    this.synthesizeCount += 1;
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

class MemorySpeechCache implements SpeechAudioCache {
  readonly entries = new Map<string, SynthesizeResult>();

  async getOrCreate(
    cacheKey: string,
    create: () => Promise<SynthesizeResult>,
  ): Promise<SpeechAudioCacheResult> {
    const existing = this.entries.get(cacheKey);
    if (existing != null) return { result: existing, status: "hit" };
    const result = await create();
    this.entries.set(cacheKey, result);
    return { result, status: "miss" };
  }
}

class FixedSpeechCatalog implements SharedSpeechCatalog {
  constructor(private readonly request: SynthesizeRequest | null) {}

  resolve(
    _reference: SharedSpeechReference,
    _languageCode: "de" | "en",
  ): Promise<SynthesizeRequest | null> {
    return Promise.resolve(this.request);
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

Deno.test("reuses approved shared speech without a second provider call", async () => {
  const provider = new MockSpeechProvider();
  const cache = new MemorySpeechCache();
  const handler = createSpeechGatewayHandler({
    authenticate: async () => true,
    providers: new SpeechProviderRegistry({ tts: [provider], stt: [provider] }),
    ttsProviderId: "mock",
    sttProviderId: "mock",
    sharedSpeechCatalog: new FixedSpeechCatalog({
      text: "Kanonischer Szenentext.",
      role: "moderator",
      languageCode: "de",
    }),
    speechAudioCache: cache,
    createRequestId: () => "speech-cache",
  });
  const requestBody = JSON.stringify({
    operation: "tts",
    schemaVersion: "1",
    text: "Veralteter Clienttext.",
    role: "moderator",
    languageCode: "de",
    sharedReference: {
      kind: "scenario_intro",
      id: "10000000-0000-0000-0000-000000000001",
    },
  });

  const first = await handler(
    new Request("http://localhost", {
      method: "POST",
      body: requestBody,
    }),
  );
  const second = await handler(
    new Request("http://localhost", {
      method: "POST",
      body: requestBody,
    }),
  );
  const firstBody = await first.json();
  const secondBody = await second.json();

  assert(firstBody.cacheStatus === "miss", "expected a cold cache miss");
  assert(secondBody.cacheStatus === "hit", "expected a warm cache hit");
  assert(provider.synthesizeCount === 1, "provider must only run once");
  assert(
    provider.synthesized?.text === "Kanonischer Szenentext.",
    "server catalog content must win over client text",
  );
});

Deno.test("does not cache private or dynamic TTS", async () => {
  const provider = new MockSpeechProvider();
  const cache = new MemorySpeechCache();
  const handler = createSpeechGatewayHandler({
    authenticate: async () => true,
    providers: new SpeechProviderRegistry({ tts: [provider], stt: [provider] }),
    ttsProviderId: "mock",
    sttProviderId: "mock",
    sharedSpeechCatalog: new FixedSpeechCatalog(null),
    speechAudioCache: cache,
  });
  const body = JSON.stringify({
    operation: "tts",
    schemaVersion: "1",
    text: "Persönliches Feedback.",
    role: "intelligence",
    languageCode: "de",
  });

  await handler(new Request("http://localhost", { method: "POST", body }));
  await handler(new Request("http://localhost", { method: "POST", body }));

  assert(provider.synthesizeCount === 2, "dynamic speech stays uncached");
  assert(
    cache.entries.size === 0,
    "private speech must not enter shared cache",
  );
});

Deno.test("rejects an unapproved shared speech reference", async () => {
  const provider = new MockSpeechProvider();
  const response = await createSpeechGatewayHandler({
    authenticate: async () => true,
    providers: new SpeechProviderRegistry({ tts: [provider], stt: [provider] }),
    ttsProviderId: "mock",
    sttProviderId: "mock",
    sharedSpeechCatalog: new FixedSpeechCatalog(null),
    speechAudioCache: new MemorySpeechCache(),
  })(
    new Request("http://localhost", {
      method: "POST",
      body: JSON.stringify({
        operation: "tts",
        schemaVersion: "1",
        text: "Nicht freigegeben.",
        role: "moderator",
        sharedReference: {
          kind: "scenario_intro",
          id: "10000000-0000-4000-8000-000000000099",
        },
      }),
    }),
  );

  assert(response.status === 400, "expected an invalid shared reference");
  assert(provider.synthesizeCount === 0, "provider must not run");
});
