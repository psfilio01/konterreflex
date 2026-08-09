# Prompt 11: Billing and Stripe
Branch: `feature/billing`

Implement commercial entitlements. Add Stripe Checkout and Customer Portal through Supabase Edge Functions for eligible flows, verify webhook signatures and update server side subscriptions and entitlements idempotently. In Flutter, use a BillingProvider abstraction with Stripe and store billing adapters so iOS and Android policy specific purchase paths can differ without changing feature access logic. Never hard code a claim that Stripe direct checkout is allowed on every mobile storefront or region.

Acceptance: webhook tests cover replay and invalid signature; premium gates read server entitlement; restore/refresh path exists. Finish the mandatory Git workflow.
