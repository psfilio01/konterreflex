#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

failures=0

fail() {
  echo "ERROR: $1" >&2
  failures=$((failures + 1))
}

require_variable() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    fail "$name is not set"
  fi
}

if git grep -Eq 'sk_live_[A-Za-z0-9]{16,}|whsec_[A-Za-z0-9]{16,}' -- ':!scripts/check_release_config.sh'; then
  fail "a value resembling a live Stripe secret is tracked by Git"
fi

if git grep -q 'com\.example\.konterreflex' -- android ios; then
  fail "replace the example Android/iOS application identifier"
fi

if grep -q 'signingConfig = signingConfigs.getByName("debug")' android/app/build.gradle.kts; then
  fail "configure Android release signing instead of the debug key"
fi

require_variable APP_ENV
require_variable SUPABASE_URL
require_variable SUPABASE_ANON_KEY
require_variable GEMINI_API_KEY
require_variable ELEVENLABS_API_KEY
require_variable ELEVENLABS_VOICE_ACTOR
require_variable ELEVENLABS_VOICE_INTELLIGENCE
require_variable ELEVENLABS_VOICE_MODERATOR
require_variable STRIPE_SECRET_KEY
require_variable STRIPE_WEBHOOK_SECRET
require_variable STRIPE_PRO_PRICE_ID
require_variable BILLING_RETURN_URL

if [ "${APP_ENV:-}" != "production" ]; then
  fail "APP_ENV must be production"
fi

case "${SUPABASE_URL:-}" in
  https://localhost*|https://127.0.0.1*|http://*|"")
    fail "SUPABASE_URL must be a non-local HTTPS URL"
    ;;
esac

case "${BILLING_RETURN_URL:-}" in
  https://*) ;;
  *) fail "BILLING_RETURN_URL must use HTTPS" ;;
esac

for name in SUPABASE_ANON_KEY GEMINI_API_KEY ELEVENLABS_API_KEY \
  STRIPE_SECRET_KEY STRIPE_WEBHOOK_SECRET STRIPE_PRO_PRICE_ID; do
  value="${!name:-}"
  case "$value" in
    *replace*|*placeholder*|*change-me*) fail "$name still contains a placeholder" ;;
  esac
done

if [ "$failures" -gt 0 ]; then
  echo "Release configuration has $failures blocking issue(s)." >&2
  exit 1
fi

echo "Release configuration checks passed. No secret values were printed."
