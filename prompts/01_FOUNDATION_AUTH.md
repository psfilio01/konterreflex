# Prompt 01: App foundation and auth
Branch: `feature/auth-foundation`

Implement Supabase authentication, profile bootstrap, signed in and signed out routing, basic onboarding and account deletion plumbing. Use passwordless email or another low friction Supabase supported flow that is sensible for mobile. Keep core use voice first after onboarding. Add RLS tests or equivalent database checks where practical.

Acceptance: a user can sign in, receive a profile and sign out; protected screens require auth; deletion path is explicit. Finish the mandatory Git workflow.
