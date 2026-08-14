# Data model

Core tables:

- `profiles`
- `user_roles`
- `scenarios`
- `scenario_characters`
- `scenario_turns`
- `training_sessions`
- `user_responses`
- `feedback`
- `real_life_cases`
- `real_life_reconstructions`
- `practice_schedules`
- `golden_book_entries`
- `subscriptions`
- `entitlements`
- `app_config`
- `prompt_versions`
- `communication_knowledge`
- `scenario_safety_reviews`
- `shared_speech_audio_cache` (server-only metadata; audio lives in private Storage)

Generated scenarios default to `draft`. Only admins may set them to `active`.

`feedback` stores one categorical `overall_signal` and six categorical
`dimension_signals` alongside the explanatory qualitative text. Allowed values
are `strong`, `developing` and `focus`; numerical scoring remains unsupported.

`speech_challenge_results` stores one schema-validated consolidated result per
user-owned challenge session. It contains the overall qualitative result,
ordered response details and provider metadata. Individual transcripts remain
in `user_responses`; challenge results reference their response and prompt IDs
instead of duplicating transcript content.

`practice_schedules` stores a private per-user and per-language repetition
stage for either one curated scenario or one Real Life Replay case. A saved
feedback response may update its schedule only once. The stage controls timing
but is never presented as a performance score.

`real_life_reconstructions` stores one private, schema-validated scene snapshot
per case and supported language. It contains a short display title, scene data
and model traceability metadata. Deleting the case cascades to all localized
snapshots and its schedule.

Sensitive user recordings should be optional and deletable. Prefer derived transcript + metadata when long term raw audio storage is unnecessary.

The shared speech cache contains only approved reusable product content. It does
not retain recordings, transcripts, feedback or Real Life Replay text.
