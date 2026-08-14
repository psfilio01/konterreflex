import 'package:flutter/widgets.dart';

const speechProcessingCompletionDuration = Duration(milliseconds: 300);

typedef ReducedMotionReader = bool Function();

bool platformAnimationsDisabled() => WidgetsBinding
    .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

Future<void> waitForProcessingCompletion({
  required Duration duration,
  ReducedMotionReader reducedMotion = platformAnimationsDisabled,
}) async {
  if (duration == Duration.zero || reducedMotion()) return;
  await Future<void>.delayed(duration);
}
