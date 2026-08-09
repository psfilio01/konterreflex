# Konterreflex

Voice first training for spontaneous, confident communication.

## Local setup

Install Flutter and the Supabase CLI, then run:

```bash
./scripts/bootstrap.sh
supabase start
cp .env.local.example .env.local
supabase status
```

Copy the local API URL and anon key printed by `supabase status` into
`.env.local`. The file contains public Flutter client configuration only and is
ignored by Git. Provider and billing secrets belong in local server environment
files or Supabase secrets; never pass them to Flutter.

Start the mobile app or web app with:

```bash
flutter run --dart-define-from-file=.env.local
flutter run -d chrome --dart-define-from-file=.env.local
```

For an Android emulator, use `http://10.0.2.2:54321` as `SUPABASE_URL`. The
iOS simulator and web use `http://127.0.0.1:54321`.

Run the web admin entry point with:

```bash
flutter run -d chrome -t lib/main_admin.dart \
  --dart-define-from-file=.env.local
```

Validate the project with:

```bash
flutter analyze
flutter test
```

Stop local services with `supabase stop`.

## Codex workflow

Work through `prompts/00_BOOTSTRAP.md` to `prompts/14_RELEASE_READINESS.md` in
order.

For Codex, simply open the repository and give it one prompt file at a time, for example:

```text
Implement prompts/00_BOOTSTRAP.md completely. Follow AGENTS.md.
```

Codex automatically reads `AGENTS.md`. Repository skills live in `.agents/skills`.

## Product

Core modes:

1. Training simulations
2. Replay of a real life situation
3. Speech Challenge
4. Golden Book

The app is voice first. Text is optional support, not the primary interaction.

## Architecture

Flutter client + Flutter web admin + Supabase + provider abstractions for AI, speech and billing.

Default providers:

- LLM: Gemini through a server side AI gateway
- TTS: ElevenLabs
- STT: provider adapter, default configurable
- Billing: Stripe for eligible flows, with a store billing abstraction for mobile compliance

See `docs/ARCHITECTURE.md`.
