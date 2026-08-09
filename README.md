# Konterreflex

Voice first training for spontaneous, confident communication.

## Start here

1. Create a new GitHub repository and push this folder.
2. Install Flutter, Supabase CLI, GitHub CLI and Codex.
3. Copy `.env.example` to `.env` and configure local secrets. Never commit `.env`.
4. Run `./scripts/bootstrap.sh` once.
5. Work through `prompts/00_BOOTSTRAP.md` to `prompts/14_RELEASE_READINESS.md` in order.

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
