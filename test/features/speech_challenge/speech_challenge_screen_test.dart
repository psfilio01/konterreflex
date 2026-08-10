import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/theme/app_tokens.dart';
import 'package:konterreflex/src/features/speech_challenge/application/speech_challenge_providers.dart';
import 'package:konterreflex/src/features/speech_challenge/domain/speech_challenge.dart';
import 'package:konterreflex/src/features/speech_challenge/presentation/speech_challenge_screen.dart';

void main() {
  testWidgets('challenge cards use the same spacing as training cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          challengeSetsProvider.overrideWith((ref) async => challengeSets),
        ],
        child: const MaterialApp(home: SpeechChallengeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(Card);
    expect(cards, findsNWidgets(2));
    final firstCard = tester.getRect(cards.at(0));
    final secondCard = tester.getRect(cards.at(1));

    expect(secondCard.top - firstCard.bottom, AppSpacing.md);
  });
}

const challengeSets = [
  ChallengeSet(
    id: 'position',
    title: 'Präzise Position',
    description: 'Eine Haltung kurz und anschlussfähig ausdrücken.',
    prompts: [],
  ),
  ChallengeSet(
    id: 'boundaries',
    title: 'Klare Grenzen',
    description: 'Spontan Grenzen setzen, ohne unnötig zu verschärfen.',
    prompts: [],
  ),
];
