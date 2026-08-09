import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/shared/widgets/optional_transcript.dart';

void main() {
  testWidgets('transcript is optional and can be revealed without input', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OptionalTranscript(transcript: 'Eine gesprochene Antwort.'),
        ),
      ),
    );

    expect(find.text('Eine gesprochene Antwort.'), findsNothing);
    await tester.tap(find.text('Transkript anzeigen'));
    await tester.pump();
    expect(find.text('Eine gesprochene Antwort.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
