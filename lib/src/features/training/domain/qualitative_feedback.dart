import 'package:flutter/widgets.dart';
import 'package:konterreflex/l10n/generated/app_localizations.dart';

class FeedbackDimensions {
  const FeedbackDimensions({
    required this.posture,
    required this.precision,
    required this.frame,
    required this.socialEffect,
    required this.naturalness,
    required this.escalationFit,
  });

  factory FeedbackDimensions.fromJson(Map<String, dynamic> json) {
    const requiredKeys = {
      'posture',
      'precision',
      'frame',
      'social_effect',
      'naturalness',
      'escalation_fit',
    };
    _requireExactKeys(json, requiredKeys);
    return FeedbackDimensions(
      posture: _requiredText(json, 'posture'),
      precision: _requiredText(json, 'precision'),
      frame: _requiredText(json, 'frame'),
      socialEffect: _requiredText(json, 'social_effect'),
      naturalness: _requiredText(json, 'naturalness'),
      escalationFit: _requiredText(json, 'escalation_fit'),
    );
  }

  final String posture;
  final String precision;
  final String frame;
  final String socialEffect;
  final String naturalness;
  final String escalationFit;

  Map<String, dynamic> toJson() => {
        'posture': posture,
        'precision': precision,
        'frame': frame,
        'social_effect': socialEffect,
        'naturalness': naturalness,
        'escalation_fit': escalationFit,
      };
}

class QualitativeFeedback {
  const QualitativeFeedback({
    required this.headline,
    required this.explanation,
    required this.strengths,
    required this.improvement,
    required this.alternatives,
    required this.dimensions,
    required this.provider,
    required this.model,
    required this.promptVersion,
  });

  factory QualitativeFeedback.fromGateway({
    required Map<String, dynamic> data,
    required String provider,
    required String model,
    required String promptVersion,
  }) {
    const requiredKeys = {
      'headline',
      'explanation',
      'strengths',
      'improvement',
      'alternatives',
      'dimensions',
    };
    _requireExactKeys(data, requiredKeys);
    final strengths = _textList(data, 'strengths', maxLength: 3);
    final alternatives = _textList(data, 'alternatives', maxLength: 3);
    final dimensions = data['dimensions'];
    if (dimensions is! Map) {
      throw const FormatException('Feedback dimensions must be an object.');
    }
    return QualitativeFeedback(
      headline: _requiredText(data, 'headline'),
      explanation: _requiredText(data, 'explanation'),
      strengths: strengths,
      improvement: _requiredText(data, 'improvement'),
      alternatives: alternatives,
      dimensions: FeedbackDimensions.fromJson(
        Map<String, dynamic>.from(dimensions),
      ),
      provider: provider,
      model: model,
      promptVersion: promptVersion,
    );
  }

  final String headline;
  final String explanation;
  final List<String> strengths;
  final String improvement;
  final List<String> alternatives;
  final FeedbackDimensions dimensions;
  final String provider;
  final String model;
  final String promptVersion;

  String get spokenSummary => spokenSummaryFor(
        lookupAppLocalizations(const Locale('de')),
      );

  String spokenSummaryFor(AppLocalizations strings) {
    final strength =
        strengths.isEmpty ? '' : strings.spokenStrength(strengths.first);
    return '$headline. $explanation.$strength '
        '${strings.feedbackNextStep}: $improvement';
  }
}

void _requireExactKeys(Map<String, dynamic> json, Set<String> expected) {
  final actual = json.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw const FormatException(
      'Feedback contains missing or unsupported fields. Numeric scoring is not allowed.',
    );
  }
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be non-empty text.');
  }
  return value.trim();
}

List<String> _textList(
  Map<String, dynamic> json,
  String key, {
  required int maxLength,
}) {
  final value = json[key];
  if (value is! List ||
      value.length > maxLength ||
      value.any((item) => item is! String)) {
    throw FormatException('$key must be a short text list.');
  }
  return value
      .cast<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
