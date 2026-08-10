import { ElevenLabsSpeechProvider } from "./elevenlabs_provider.ts";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test("ElevenLabs TTS keeps the API key in a server header", async () => {
  let capturedUrl = "";
  let capturedHeaders = new Headers();
  const fetcher: typeof fetch = (input, init) => {
    capturedUrl = String(input);
    capturedHeaders = new Headers(init?.headers);
    return Promise.resolve(
      new Response(Uint8Array.from([1, 2]), {
        headers: { "content-type": "audio/mpeg" },
      }),
    );
  };
  const provider = new ElevenLabsSpeechProvider(
    "server-key",
    {
      moderator: "moderator_voice",
      actor: "actor_voice",
      intelligence: "intelligence_voice",
      en: {
        moderator: "english_moderator_voice",
      },
    },
    "eleven_multilingual_v2",
    "scribe_v2",
    fetcher,
  );
  const result = await provider.synthesize({
    text: "Die Szene beginnt.",
    role: "moderator",
    languageCode: "en",
  }, new AbortController().signal);
  const profile = provider.synthesisProfile({
    text: "Die Szene beginnt.",
    role: "moderator",
    languageCode: "en",
  });

  assert(
    capturedUrl.includes("english_moderator_voice"),
    "expected language-specific role voice",
  );
  assert(!capturedUrl.includes("server-key"), "key must not appear in URL");
  assert(
    capturedHeaders.get("xi-api-key") === "server-key",
    "expected key header",
  );
  assert(result.audio.length === 2, "expected audio bytes");
  assert(
    profile.voice === "english_moderator_voice",
    "cache identity must use the resolved language voice",
  );
  assert(
    profile.outputFormat === "mp3_44100_128",
    "cache identity must include the output format",
  );
});

Deno.test("ElevenLabs STT sends PCM metadata and returns a transcript", async () => {
  const capturedForms: FormData[] = [];
  const fetcher: typeof fetch = (_input, init) => {
    capturedForms.push(init?.body as FormData);
    return Promise.resolve(Response.json({ text: "Eine Antwort." }));
  };
  const provider = new ElevenLabsSpeechProvider(
    "server-key",
    {},
    "eleven_multilingual_v2",
    "scribe_v2",
    fetcher,
  );
  const result = await provider.transcribe({
    audio: Uint8Array.from([1, 2, 3]),
    mimeType: "audio/pcm;rate=16000",
    languageCode: "de",
  }, new AbortController().signal);

  const capturedForm = capturedForms[0];
  assert(capturedForm.get("model_id") === "scribe_v2", "expected STT model");
  assert(
    capturedForm.get("file_format") === "pcm_s16le_16",
    "expected PCM format",
  );
  assert(result.transcript === "Eine Antwort.", "expected transcript");
});
