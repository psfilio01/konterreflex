# MVP release checklist

This checklist is the production handoff for Konterreflex. Every unchecked item
is a manual or external dependency; code completion alone does not make a store
release safe. The initial launch market assumed for the policy review is
Germany/EU. Re-run the review for every additional storefront.

## Automated gate

- [ ] Required GitHub checks are green from a clean checkout: Flutter analyze,
  Flutter tests, both web builds, Deno format/check/tests, migrations and pgTAP.
- [ ] `flutter analyze`, `flutter test`, `deno test --allow-env
  supabase/functions` and `supabase test db` pass locally.
- [ ] `./scripts/check_release_config.sh` passes in a shell populated from the
  production secret manager.
- [ ] Version/build number in `pubspec.yaml` is unique and release notes match
  the shipped behavior.
- [ ] The exact commit SHA and generated artifacts are recorded in the release.

## Ownership, market and legal

- [ ] Confirm legal entity, product owner, security contact and support contact.
- [ ] Confirm launch countries, supported age group, price, currency, VAT/tax
  handling, trial terms and cancellation/refund process.
- [ ] Publish German privacy policy, terms, imprint and support pages on stable
  HTTPS URLs; obtain legal review for GDPR, consumer and AI disclosures.
- [ ] Complete provider DPAs and document data regions/subprocessors for
  Supabase, Gemini, ElevenLabs, Stripe and any monitoring vendor.
- [ ] Define incident response, deletion-request and data-breach procedures.

## GitHub and delivery

- [ ] Protect `main`; require the CI workflow and reviewed pull requests.
- [ ] Restrict production environment access and configure deployment approval.
- [ ] Enable dependency/security update handling and repository secret scanning.
- [ ] Keep release signing keys and environment files outside Git and backups
  with documented recovery ownership.

## Supabase production project

- [ ] Create a production organization/project in the intended EU data region.
- [ ] Link the CLI project and apply every migration in order; run pgTAP against
  a disposable staging copy before production.
- [ ] Deploy all Edge Functions and verify JWT settings, especially that only
  the signed Stripe webhook is public.
- [ ] Configure production client URL, public key and server-provided service
  role values; never add the service role to Flutter.
- [ ] Allow `konterreflex://auth-callback`,
  `konterreflex://reset-password`, exact user/admin HTTPS origins and their
  reset paths. Remove localhost entries in production.
- [ ] Configure custom SMTP, confirmation/recovery templates, password policy,
  email rate limits and bot protection. Verify registration, confirmation,
  login, reset and account deletion end to end.
- [ ] Enable and test Google and Apple in Supabase using server-side provider
  credentials. Record the Apple OAuth-secret rotation owner and expiry.
- [ ] Confirm RLS is enabled for every user-owned/admin table and a normal user
  cannot access another user's sessions, recordings, cases or entitlements.
- [ ] Configure database backups/PITR, recovery test, log retention and alerting.
- [ ] Verify raw audio remains disabled by default and retention/deletion jobs
  match the selected 0/7/30/90-day preference.

## AI, speech and content

- [ ] Store production Gemini and ElevenLabs keys only as Supabase secrets;
  confirm quotas, spend alerts, regional terms and key rotation owner.
- [ ] Select and license the actor, moderator and intelligence voices; set the
  exact three production voice IDs.
- [ ] Select/configure a production STT provider. `STT_PROVIDER=unconfigured`
  is not a releasable voice-first experience.
- [ ] Test timeout, provider outage, microphone denial, recording interruption
  and retry behavior on physical iOS and Android devices.
- [ ] Human-review the seeded scenarios and knowledge sources; approve safety
  reviews and archive drafts that are not release-ready.
- [ ] Confirm qualitative feedback never becomes a numerical personality score
  and hostile examples are training material, not endorsed instructions.

## Billing policy decision — reviewed 2026-08-09

Conservative Germany/EU decision: Stripe remains web-only. iOS uses StoreKit
in-app purchase and Android uses Google Play Billing once their adapters are
implemented. Do not expose a mobile web checkout or price link by configuration
alone.

- Apple guideline 3.1.1 says unlocking app functionality/subscriptions normally
  uses in-app purchase. EU offer steering exists only under Apple's current EU
  terms, eligibility, StoreKit APIs, disclosures, reporting and fees. Recheck
  [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/#business)
  and [Apple's EU distribution/payment update](https://developer.apple.com/support/dma-and-apps-in-the-eu/).
- Google Play requires its billing system for Play-distributed digital features
  unless a policy exception/program applies. EEA alternative billing requires
  enrollment and program/API compliance. Recheck the
  [Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en)
  and [user-choice billing requirements](https://support.google.com/googleplay/android-developer/answer/13821247?hl=en).
- Stripe's current mobile digital-goods page describes direct iOS/Android Stripe
  routes as US-only. Recheck [Stripe mobile digital goods](https://docs.stripe.com/mobile/digital-goods).

- [ ] Revalidate all three official sources immediately before UI freeze and
  store submission; record reviewer, date, countries and chosen program terms.
- [ ] Implement StoreKit and Play Billing adapters, purchase/restore UI, server
  receipt verification, renewal, grace period, refund and revocation handling.
- [ ] Create matching subscription products/IDs in App Store Connect and Play
  Console; test sandbox, upgrade/downgrade, cancellation and restore.
- [ ] Keep `billing_channels` set to `ios=store`, `android=store`, `web=stripe`.
  Changing it is a policy and engineering change, not an operations toggle.

## Stripe web billing

- [ ] Activate the production Stripe account and complete identity, tax,
  statement descriptor, support and payout settings.
- [ ] Create the production recurring price and set `STRIPE_PRO_PRICE_ID`.
- [ ] Configure the hosted customer portal, cancellation and refund policy.
- [ ] Register the production webhook URL and the required subscription/checkout
  events; set the signing secret and test signature/replay/out-of-order handling.
- [ ] Set an allow-listed HTTPS `BILLING_RETURN_URL`; verify checkout, portal,
  failed payment, renewal, cancellation and entitlement removal in live mode
  with a controlled low-price product before public launch.

## Apple external setup

- [ ] Enroll the legal entity in Apple Developer Program and accept current
  agreements, banking and tax terms.
- [ ] Choose and replace the immutable example bundle ID; configure team,
  certificates, provisioning and App Store Connect app record.
- [ ] Complete App Privacy, age rating, export compliance, support/privacy URLs,
  screenshots, description and accurate review notes for AI and voice behavior.
- [ ] Provide a working review demo account and keep production backend/providers
  available during review.
- [ ] Verify microphone purpose text and deletion/subscription management routes.
- [ ] Verify Sign in with Apple and Google cancellation/retry on a physical
  device; confirm Apple login remains available wherever another social login
  is offered.
- [ ] Pass TestFlight testing on supported iPhone/iPad and App Review validation.

## Google external setup

- [ ] Enroll the legal entity in Play Console and accept current agreements,
  merchant, tax and payout terms.
- [ ] Choose and replace the immutable example application ID; create the app,
  enable Play App Signing and protect the upload key.
- [ ] Complete Data safety, content rating, target audience, ads declaration,
  account deletion URL, privacy/support URLs and microphone disclosure.
- [ ] Test the browser-based Google and Apple callbacks from an installed build.
- [ ] Pass internal/closed track testing on supported Android versions and form
  factors, including fresh install and update.

## Web and admin hosting

- [ ] Configure user/admin DNS, TLS, HSTS, CSP and security headers; deploy each
  entry point separately and invalidate old assets safely.
- [ ] Verify Supabase redirects, deep links, password reset and billing return
  URLs use only controlled production domains.
- [ ] Grant admin roles only from trusted server tooling and test that a
  non-admin cannot load or mutate admin data.
- [ ] Follow `ADMIN_DEPLOYMENT.md`; keep service-role/provider keys out of both
  web bundles.

## Privacy-safe operations and monitoring

- [ ] Select a monitoring provider and implement the existing `ErrorReporter`
  adapter using only fixed error code, area, fatal flag and environment.
- [ ] Prohibit transcripts, audio, prompts, user text, arbitrary exception
  messages, request bodies and stack traces from remote error events.
- [ ] Configure alerts for crash rate, Function error codes, provider outages,
  webhook failures and database capacity without private payload logging.
- [ ] Verify analytics is opt-in, contains only the fixed event schema and is
  absent before consent; test consent withdrawal.
- [ ] Review operator access/audit logs and run account/session/case deletion
  tests on staging with representative data.

## Product and visual QA

- [ ] Replace or explicitly approve `assets/branding/app_icon_placeholder.png`;
  confirm rights, contrast and every Android/iOS/web rendition. The generated
  placeholder is not a final trademark decision.
- [ ] Produce real store screenshots from fictional accounts; never use private
  transcripts or recordings in marketing/review assets.
- [ ] Test screen readers, text scaling, contrast, reduced motion, keyboard/web
  navigation and the complete core flow without typing.
- [ ] Test low bandwidth, offline transitions, background/resume, permission
  changes and interrupted audio on physical devices.
- [ ] Complete a staging smoke test: auth, all four modes, qualitative feedback,
  Golden Book, history/deletion, privacy preferences, admin review and billing.

## Go/no-go

- [ ] Product, engineering, privacy/legal, content safety and operations owners
  sign off on the same commit and market list.
- [ ] No open release blocker, high-severity security finding, paid-access bypass
  or unsupported billing path remains.
- [ ] Rollback owner, support coverage and first-24-hours monitoring are active.
