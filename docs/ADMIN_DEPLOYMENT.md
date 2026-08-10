# Admin deployment

The admin app has a separate Flutter entry point and must be deployed on a
restricted HTTPS hostname, for example `admin.example.com`. The public Supabase
key is expected in the browser; authorization is enforced by server-side role
checks and RLS, not by hiding the URL.

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release -t lib/main_admin.dart \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=PUBLIC_KEY
```

Deploy `build/web` to a static HTTPS host. Build the user web app separately;
both targets write to the same local output directory.

## External setup

1. Add the exact admin HTTPS URL and login callback to Supabase Auth redirects.
2. Grant `app_metadata.role = admin` only from trusted server-side tooling.
3. Confirm admin RLS tests and test a non-admin account before launch.
4. Configure the host to send a restrictive CSP, HSTS, `X-Content-Type-Options`
   and an appropriate `Referrer-Policy`.
5. Restrict deployment access and protect the production branch/environment.
6. Never deploy a service-role key, AI key, speech key or Stripe secret.
7. Smoke-test scenario preview, safety review, approval, rejection and archive.

Removing the admin web route from public navigation is not an authorization
control. Supabase RLS remains mandatory even on a private network.
