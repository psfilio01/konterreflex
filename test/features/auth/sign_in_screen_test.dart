import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/features/auth/presentation/sign_in_screen.dart';

void main() {
  testWidgets('offers password, Google and Apple sign-in', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignInScreen())),
    );

    expect(find.text('Willkommen zurück'), findsOneWidget);
    expect(find.text('Anmelden'), findsOneWidget);
    expect(find.text('Passwort vergessen?'), findsOneWidget);
    expect(find.text('Mit Google fortfahren'), findsOneWidget);
    expect(find.text('Mit Apple fortfahren'), findsOneWidget);
    expect(find.textContaining('Anmeldelink'), findsNothing);
  });

  testWidgets('switches to password registration', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignInScreen())),
    );

    final registrationLink = find.text('Noch kein Konto? Jetzt registrieren');
    await tester.ensureVisible(registrationLink);
    await tester.tap(registrationLink);
    await tester.pump();

    expect(find.text('Konto erstellen'), findsNWidgets(2));
    expect(find.text('Passwort wiederholen'), findsOneWidget);
  });
}
