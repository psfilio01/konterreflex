# Store builds

These commands create artifacts after identifiers, signing and store products
have been configured. Run the full release checklist first.

## Android

Replace `com.example.konterreflex`, configure a private upload keystore outside
Git and remove debug signing from the release build. Then run:

```bash
flutter clean
flutter pub get
flutter test
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=PUBLIC_KEY
```

Upload `build/app/outputs/bundle/release/app-release.aab` first to an internal
Play track. Complete Play App Signing, Data safety, content rating, microphone
permission disclosure and subscription product setup in Play Console.

## iOS

Replace `com.example.konterreflex`, select the production Apple team and
provisioning profile in Xcode, then run on macOS:

```bash
flutter clean
flutter pub get
flutter test
flutter build ipa --release \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=PUBLIC_KEY
```

Upload the archive with Xcode or Transporter and validate it in TestFlight.
Complete App Privacy, age rating, export compliance, review contact, demo
account, support/privacy URLs and subscription products in App Store Connect.

## Subscription gate

The repository deliberately defaults `ios` and `android` to the store billing
adapter and `web` to Stripe. The current mobile store adapter is a provider
boundary, not a completed StoreKit/Play Billing purchase implementation. Mobile
subscription UI must not ship until purchases, restore, server verification,
refund/revocation handling and product IDs are implemented and tested.

For a Germany/EU launch, use store billing as the conservative baseline. Any
alternative payment route requires explicit program enrollment, country-aware
UX, reporting and a fresh policy/legal review. See the dated policy decision in
`RELEASE_CHECKLIST.md`.
