# Billing and entitlements

## Principle
Do not equate mobile subscription billing with a single Stripe checkout implementation. Store rules differ by platform and region and change over time.

## Architecture
Use a `BillingProvider` abstraction in Flutter and a server side entitlement table.

Initial adapters:

- `StripeBillingProvider`: web and platform flows where Stripe is permitted.
- `StoreBillingProvider`: placeholder for Apple / Google compliant in app subscriptions where required.

Stripe remains the first backend billing integration for eligible flows. Stripe webhooks update entitlements. Never grant access based only on a client success screen.

## Entitlements
Suggested values:

- `free`
- `pro`
- `admin`

Keep product limits in database configuration.

## Compliance gate
Before shipping store builds, recheck current Apple, Google and Stripe documentation for the intended countries. This is a release task, not a one time assumption.

The Germany/EU policy snapshot and explicit launch blockers are maintained in
`docs/RELEASE_CHECKLIST.md`. As of the 2026-08-09 review, the conservative
channel decision is Stripe on web and native store billing on iOS/Android. The
mobile store adapters must be fully implemented before either store build ships.
