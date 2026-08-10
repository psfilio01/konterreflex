# Architecture

## Shape

```text
Flutter mobile app + Flutter web admin
        |
        v
Supabase Auth / Postgres / Storage / Edge Functions
        |
        +--> AI gateway --> Gemini default / OpenAI / Claude / compatible providers
        +--> Speech gateway --> ElevenLabs default / alternate providers
        |       +--> private shared scene audio cache
        +--> Billing gateway --> Stripe + mobile store adapters
```

## Rules

1. Flutter never holds provider secret keys.
2. Edge Functions own AI, TTS, STT and billing calls.
3. Provider interfaces prevent direct coupling.
4. Structured model outputs are JSON validated before use.
5. User content is protected by RLS and ownership checks.
6. Scenario generation is draft first. Admin approval is required before a generated scenario becomes globally active.
7. Paid access is checked against server side entitlements.
8. Shared audio is limited to canonical approved content resolved by the server;
   user-specific speech is never globally cached.

## Flutter feature folders

```text
lib/src/
  core/
    ai/
    audio/
    billing/
    config/
    data/
    routing/
    theme/
  features/
    auth/
    onboarding/
    home/
    training/
    real_life/
    speech_challenge/
    golden_book/
    history/
    subscription/
    settings/
  shared/
  admin/
```

Keep domain logic independent of widgets where practical.
