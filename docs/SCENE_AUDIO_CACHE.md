# Shared scene audio cache

## Goal

Approved scenario and Speech Challenge lines are identical for many users. They
must be synthesized once per effective voice configuration and then reused.
Dynamic feedback, follow-up dialogue and Real Life Replay content remain private
and are never written to the shared cache.

## Eligible content

The Flutter client may attach one of these stable references to a speech line:

- `scenario_intro` with a scenario ID
- `scenario_turn` with a scenario turn ID
- `challenge_prompt` with a Speech Challenge prompt ID

The Edge Function does not trust the accompanying client text. It resolves the
reference with its service-role client and only accepts active content in the
requested app language. This prevents arbitrary or user-specific text from
being retained as globally reusable audio.

## Cache identity and invalidation

The object key is a SHA-256 digest of a canonical payload containing:

- canonical server-side text and role
- app language and an optional actor voice override
- provider, model, resolved voice ID and output format
- cache schema and provider-profile revisions

Changing content, language, model, output format or any effective ElevenLabs
voice ID creates a new key automatically. No manual cache purge is needed for a
voice change. Old, unreferenced objects remain private and can later be removed
using `last_accessed_at` as a retention signal.

## Request flow

1. The authenticated client requests TTS and optionally sends a stable shared
   reference.
2. The gateway resolves shared references to canonical approved content.
3. A ready object is downloaded from the private `shared-speech-cache` bucket.
4. On a cold miss, one request obtains a time-limited database claim. Other
   concurrent requests wait for the same object instead of calling the provider.
5. The claim owner calls the configured TTS provider, uploads the result and
   marks the metadata row ready.
6. Storage or metadata failures are logged without exposing text. Freshly
   generated audio can still be returned; provider failures keep their existing
   safe error handling.

Responses expose `cacheStatus` as `hit`, `miss` or `bypass` for operational
verification. Audio objects and cache metadata have no client RLS policies and
are only accessible to the server-side service role.

## Cost and latency characteristics

The first request for a new text/voice combination still uses ElevenLabs.
Following requests reuse the stored MP3 across users and no longer incur a TTS
generation call. The current client still downloads the cached bytes through
the authenticated gateway, which keeps the provider boundary and private bucket
simple. A future signed-URL streaming layer may reduce gateway bandwidth, but is
not required to remove repeated ElevenLabs generation costs.

## Deployment and operations

Deploy migration `0013_shared_speech_audio_cache.sql` before the updated
`speech-gateway`. Supabase supplies `SUPABASE_SERVICE_ROLE_KEY` to deployed Edge
Functions; it must never be added to Flutter configuration.

Monitor structured gateway events:

- `shared_speech_cache_result` for hit/miss/bypass behavior
- `shared_speech_cache_store_failed` for storage or metadata failures
- `shared_speech_cache_bypassed` for unavailable cache infrastructure

For storage housekeeping, remove old objects and their matching metadata only
after a reviewed retention window based on `last_accessed_at`. Deleting cache
entries is safe because the next eligible request recreates them.
