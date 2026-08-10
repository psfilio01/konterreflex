import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/app.dart';
import 'package:konterreflex/src/features/auth/application/auth_providers.dart';
import 'package:konterreflex/src/features/auth/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const testUser = User(
  id: 'user-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

void main() {
  testWidgets('signed in users see the protected home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUserProvider.overrideWith((ref) => Stream.value(testUser)),
          passwordRecoveryProvider.overrideWith((ref) => Stream.value(false)),
          profileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'user-1',
              locale: 'de',
              displayName: 'Ada',
            ),
          ),
        ],
        child: const KonterreflexApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Konterreflex'), findsOneWidget);
    expect(find.byTooltip('Einstellungen'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Echte Situation'), findsOneWidget);
    expect(find.text('Speech Challenge'), findsOneWidget);
    expect(find.text('Golden Book'), findsOneWidget);
  });

  testWidgets('signed out users are redirected to sign in', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUserProvider.overrideWith((ref) => Stream.value(null)),
          passwordRecoveryProvider.overrideWith((ref) => Stream.value(false)),
          profileProvider.overrideWith((ref) async => null),
        ],
        child: const KonterreflexApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Willkommen zurück'), findsOneWidget);
    expect(find.text('Anmelden'), findsOneWidget);
    expect(find.text('Mit Google fortfahren'), findsOneWidget);
    expect(find.text('Mit Apple fortfahren'), findsOneWidget);
  });

  testWidgets('new users must complete onboarding', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUserProvider.overrideWith((ref) => Stream.value(testUser)),
          passwordRecoveryProvider.overrideWith((ref) => Stream.value(false)),
          profileProvider.overrideWith(
            (ref) async => const UserProfile(id: 'user-1', locale: 'de'),
          ),
        ],
        child: const KonterreflexApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wie dürfen wir dich ansprechen?'), findsOneWidget);
    expect(find.byTooltip('Einstellungen'), findsNothing);
  });

  testWidgets('password recovery opens the new password form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUserProvider.overrideWith((ref) => Stream.value(testUser)),
          passwordRecoveryProvider.overrideWith((ref) => Stream.value(true)),
          profileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'user-1',
              locale: 'de',
              displayName: 'Ada',
            ),
          ),
        ],
        child: const KonterreflexApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Neues Passwort'), findsWidgets);
    expect(find.text('Passwort speichern'), findsOneWidget);
  });
}
