# Authentication setup

Konterreflex supports email/password accounts, password recovery, Google and
Apple sign-in through Supabase Auth. Magic-link and email-OTP sign-in are not
part of the product flow.

Provider credentials are server-side configuration. Never add a Google client
secret, Apple signing key, Apple-generated OAuth secret or Supabase service-role
key to Flutter configuration, source control or a mobile build.

## Redirect URLs

Add these exact mobile URLs under Supabase Dashboard → Authentication → URL
Configuration → Redirect URLs:

- `konterreflex://auth-callback`
- `konterreflex://reset-password`

Also add the exact production user and admin HTTPS origins, including their
`/reset-password` paths. Keep localhost URLs only in development. Set the hosted
project Site URL to the canonical production web origin.

The iOS URL scheme and Android intent filters are checked into the app. Replace
the example bundle/application identifiers before configuring production OAuth
clients.

## Email and password

In Supabase Dashboard → Authentication → Providers → Email:

1. Keep email/password sign-up enabled.
2. Require email confirmation for production.
3. Set the minimum password length to at least 8 characters and enable the
   strongest practical character policy. Enable leaked-password protection when
   the project plan supports it.
4. Configure custom SMTP for production delivery, sender reputation and usable
   rate limits.
5. Configure the confirmation and recovery templates. The local equivalents are
   `supabase/templates/confirmation.html` and
   `supabase/templates/recovery.html`.

The app deliberately returns a neutral password-reset confirmation so that it
does not reveal whether an email address has an account. Existing
passwordless-only users can use “Passwort vergessen?” once to establish a
password.

## Google

1. Create or select a Google Cloud project and configure its OAuth consent
   screen with only `openid`, email and profile scopes.
2. Create a Web application OAuth client.
3. Add the Supabase callback shown on the Dashboard Google provider page. It is
   normally `https://PROJECT_REF.supabase.co/auth/v1/callback`.
4. Enter the Web client ID and client secret in Supabase Dashboard →
   Authentication → Providers → Google and enable the provider.
5. Add development and production web origins in Google and verify the final
   consent-screen branding before release.

The client starts the OAuth flow through Supabase and receives only a Supabase
session. It does not request or persist Google API access tokens.

## Apple

Konterreflex uses the Supabase OAuth flow so the same implementation works on
iOS, Android and web.

1. In Apple Developer, enable Sign in with Apple for the production app and
   create a Services ID for the web OAuth flow.
2. Configure the Supabase project domain and callback URL from the Apple
   provider page, normally
   `https://PROJECT_REF.supabase.co/auth/v1/callback`.
3. Create a Sign in with Apple key and securely retain its `.p8` file, Key ID and
   Team ID.
4. Generate the Apple client secret and configure the Services ID and secret in
   Supabase Dashboard → Authentication → Providers → Apple.
5. Rotate the Apple OAuth secret before its six-month expiry and test the new
   secret before revoking the old one.

Apple may only provide a person's name on the first authorization. Konterreflex
therefore continues to collect its own display name during onboarding.

## Local development

Email/password and recovery work with the local Supabase stack and Mailpit. The
Google and Apple sections in `supabase/config.toml` intentionally remain
disabled with empty credentials. To test social login locally, enable a provider
only in an uncommitted local configuration and supply its secret through an
ignored environment file.

Restart the local stack after Auth config changes:

```bash
supabase stop
supabase start
supabase status
```

Open the Mailpit URL shown by `supabase status` to test confirmation and reset
emails.

## Verification

Before release, test each flow on a fresh account and an existing account:

- password registration, confirmation, login, wrong password and logout;
- password reset from a terminated mobile app and from each web origin;
- Google and Apple consent, cancellation, repeat login and account matching;
- account deletion followed by an attempted login;
- provider outages, expired links and email rate limits.
