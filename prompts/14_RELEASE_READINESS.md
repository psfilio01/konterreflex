# Prompt 14: Release readiness
Branch: `feature/release-readiness`

Perform an MVP release hardening pass. Add CI for Flutter analyze/tests and Supabase function tests, environment documentation, error reporting hooks without private transcript leakage, production configuration checks, app icons/placeholders, admin deployment notes and store build instructions. Recheck current Apple, Google and Stripe rules for digital subscriptions in intended launch markets before finalizing billing UI. Produce a concise `docs/RELEASE_CHECKLIST.md`.

Acceptance: CI is green from a clean checkout; secrets are documented but not committed; release checklist identifies every manual external setup item. Finish the mandatory Git workflow.
