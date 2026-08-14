import 'package:flutter/material.dart';
import 'package:konterreflex/src/core/audio/voice_state_machine.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

extension VoiceTurnOrbState on VoiceTurnState {
  IntelligenceOrbState get orbState => switch (this) {
        VoiceTurnState.idle ||
        VoiceTurnState.awaitingUser =>
          IntelligenceOrbState.idle,
        VoiceTurnState.preparing => IntelligenceOrbState.preparing,
        VoiceTurnState.introducing ||
        VoiceTurnState.acting ||
        VoiceTurnState.feedback =>
          IntelligenceOrbState.speaking,
        VoiceTurnState.recording => IntelligenceOrbState.listening,
        VoiceTurnState.processing => IntelligenceOrbState.processingSpeech,
        VoiceTurnState.followUp => IntelligenceOrbState.success,
      };
}

@visibleForTesting
IntelligenceOrbState resolveVoiceTurnOrbState(
  VoiceTurnSnapshot snapshot, {
  bool showProcessingSpiral = true,
}) {
  if (snapshot.state != VoiceTurnState.processing) {
    return snapshot.state.orbState;
  }
  if (!showProcessingSpiral) return IntelligenceOrbState.thinking;
  return snapshot.processingComplete
      ? IntelligenceOrbState.processingSpeechComplete
      : IntelligenceOrbState.processingSpeech;
}

class VoiceTurnOrb extends StatelessWidget {
  const VoiceTurnOrb({
    required this.controller,
    this.size = 156,
    this.showProcessingSpiral = true,
    super.key,
  });

  final VoiceTurnController controller;
  final double size;
  final bool showProcessingSpiral;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.voiceActivity,
      builder: (context, activity, child) => ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final snapshot = controller.snapshot;
          return IntelligenceOrb(
            size: size,
            state: resolveVoiceTurnOrbState(
              snapshot,
              showProcessingSpiral: showProcessingSpiral,
            ),
            activityLevel: activity,
          );
        },
      ),
    );
  }
}
