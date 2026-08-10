# Environment configuration

Konterreflex uses compile-time public Flutter configuration and server-side
Supabase Function secrets. Never put provider or service-role secrets in a
Flutter `--dart-define` or a web build.

## Flutter client values

| Variable | Environments | Purpose |
| --- | --- | --- |
| `APP_ENV` | all | `development`, `staging`, or `production` |
| `SUPABASE_URL` | all | Public project API URL |
| `SUPABASE_PUBLISHABLE_KEY` | all | Public publishable client key (`sb_publishable_...`) |

Production startup rejects HTTP, local Supabase URLs and obvious placeholder
keys. `.env.local.example` is safe to copy for local work; the resulting
`.env.local` is ignored by Git.

```bash
flutter run --dart-define-from-file=.env.local
flutter build web --release \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=PUBLIC_KEY
```

Values passed to a web build are public by definition. CI uses non-secret dummy
values because compilation must not depend on a live backend.

Authentication uses email/password plus Google and Apple. The Flutter client
contains no social-provider secret. Configure providers and SMTP in Supabase,
and allow both `konterreflex://auth-callback` and
`konterreflex://reset-password`. Exact web and admin HTTPS callback URLs must
also be allow-listed. See `docs/AUTH.md` for the complete setup and verification
steps.

## Edge Function values

`supabase/.env.example` is the complete local template. Supabase provides
`SUPABASE_URL`, the public key and `SUPABASE_SERVICE_ROLE_KEY` to deployed
Functions. Configure the remaining provider values with the dashboard or CLI:

```bash
supabase secrets set --env-file supabase/.env.production
```

`supabase/.env.production` must remain untracked. Required production groups:

- AI: `GEMINI_API_KEY`; optional model/provider/timeout settings.
- Speech: `ELEVENLABS_API_KEY` and the three fallback IDs
  `ELEVENLABS_VOICE_MODERATOR`, `ELEVENLABS_VOICE_ACTOR` and
  `ELEVENLABS_VOICE_INTELLIGENCE`.
- Billing: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`,
  `STRIPE_PRO_PRICE_ID`, and an HTTPS `BILLING_RETURN_URL`.

The mobile client never receives these values. Rotate a leaked key immediately,
then redeploy the affected Functions.

### Voices per app language

The app language stored in `profiles.locale` controls UI copy, Gemini output,
speech recognition and voice selection together. Configure a different voice
for each role and language with:

```text
ELEVENLABS_VOICE_MODERATOR_DE
ELEVENLABS_VOICE_ACTOR_DE
ELEVENLABS_VOICE_INTELLIGENCE_DE
ELEVENLABS_VOICE_MODERATOR_EN
ELEVENLABS_VOICE_ACTOR_EN
ELEVENLABS_VOICE_INTELLIGENCE_EN
```

Language-specific values take precedence. A missing `_DE` or `_EN` value falls
back to the corresponding unqualified ID, so existing deployments continue to
work while the six voice variants are configured. After changing a Supabase
secret, redeploy `speech-gateway`; no provider key or voice ID belongs in the
Flutter environment.

The Google project behind `GEMINI_API_KEY` must have available Gemini API
quota. The gateway maps exhausted quota to a temporary capacity error. Speech
Challenges keep the saved answers and continue without inventing qualitative
feedback; normal feedback resumes automatically when quota is available again.

## Environments and checks

Use separate Supabase and Stripe resources for development, staging and
production. Do not reuse user recordings, transcripts or production accounts in
non-production environments.

Before a production build, load values into the current shell from a secure
secret manager and run:

```bash
./scripts/check_release_config.sh
```

The check only reports variable names and configuration problems; it never
prints values. It also blocks the generated example bundle IDs, Android debug
signing, obvious placeholders and tracked live Stripe secret patterns.
