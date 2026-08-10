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

Sensitive user recordings should be optional and deletable. Prefer derived transcript + metadata when long term raw audio storage is unnecessary.

The shared speech cache contains only approved reusable product content. It does
not retain recordings, transcripts, feedback or Real Life Replay text.
