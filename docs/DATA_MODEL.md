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

Generated scenarios default to `draft`. Only admins may set them to `active`.

Sensitive user recordings should be optional and deletable. Prefer derived transcript + metadata when long term raw audio storage is unnecessary.
