import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';
import 'package:konterreflex/src/core/localization/app_language.dart';
import 'package:konterreflex/src/features/auth/domain/user_profile.dart';
import 'package:konterreflex/src/features/training/domain/qualitative_feedback.dart';

void main() {
  test('supports German and English with German as safe fallback', () {
    expect(AppLanguage.fromCode('en'), AppLanguage.english);
    expect(AppLanguage.fromCode('de'), AppLanguage.german);
    expect(AppLanguage.fromCode('fr'), AppLanguage.german);
    expect(AppLanguage.fromCode(null), AppLanguage.german);

    final profile = UserProfile.fromJson({'id': 'user-1', 'locale': 'fr'});
    expect(profile.locale, 'de');
  });

  test('spoken feedback framing follows the selected app language', () {
    const feedback = QualitativeFeedback(
      overallSignal: FeedbackSignal.strong,
      dimensionSignals: FeedbackDimensionSignals(
        posture: FeedbackSignal.strong,
        precision: FeedbackSignal.strong,
        frame: FeedbackSignal.developing,
        socialEffect: FeedbackSignal.strong,
        naturalness: FeedbackSignal.strong,
        escalationFit: FeedbackSignal.developing,
      ),
      headline: 'Clear',
      explanation: 'Your position is understandable',
      strengths: ['Calm opening'],
      improvement: 'Name the next step',
      alternatives: [],
      dimensions: FeedbackDimensions(
        posture: 'calm',
        precision: 'clear',
        frame: 'stable',
        socialEffect: 'open',
        naturalness: 'natural',
        escalationFit: 'appropriate',
      ),
      provider: 'test',
      model: 'test',
      promptVersion: 'test',
    );
    final english = lookupAppLocalizations(const Locale('en'));

    final spoken = feedback.spokenSummaryFor(english);

    expect(spoken, contains('Strength: Calm opening'));
    expect(spoken, contains('Next step: Name the next step'));
    expect(spoken, isNot(contains('Nächster Schritt')));
  });
}
