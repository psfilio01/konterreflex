import { createSharedSpeechCacheKey } from "./shared_audio_cache.ts";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

Deno.test("shared speech cache keys change with voice and content", async () => {
  const request = {
    text: "Eine Szene.",
    role: "moderator" as const,
    languageCode: "de" as const,
  };
  const profile = {
    provider: "elevenlabs",
    model: "eleven_multilingual_v2",
    voice: "voice_de_one",
    outputFormat: "mp3_44100_128",
    revision: "1",
  };
  const original = await createSharedSpeechCacheKey(request, profile);
  const same = await createSharedSpeechCacheKey(request, profile);
  const otherVoice = await createSharedSpeechCacheKey(request, {
    ...profile,
    voice: "voice_de_two",
  });
  const otherText = await createSharedSpeechCacheKey({
    ...request,
    text: "Eine andere Szene.",
  }, profile);

  assert(original.length === 64, "expected a SHA-256 cache key");
  assert(original === same, "same synthesis inputs must reuse the key");
  assert(original !== otherVoice, "voice changes must invalidate audio");
  assert(original !== otherText, "content changes must invalidate audio");
});
