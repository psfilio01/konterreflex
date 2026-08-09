import 'package:flutter/material.dart';
import 'package:konterreflex/src/core/audio/voice_state_machine.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';

extension VoiceTurnOrbState on VoiceTurnState {
  IntelligenceOrbState get orbState => switch (this) {
        VoiceTurnState.idle ||
        VoiceTurnState.awaitingUser =>
          IntelligenceOrbState.idle,
        VoiceTurnState.introducing ||
        VoiceTurnState.acting ||
        VoiceTurnState.feedback =>
          IntelligenceOrbState.speaking,
        VoiceTurnState.recording => IntelligenceOrbState.listening,
        VoiceTurnState.processing => IntelligenceOrbState.thinking,
        VoiceTurnState.followUp => IntelligenceOrbState.success,
      };
}

class VoiceTurnOrb extends StatelessWidget {
  const VoiceTurnOrb({
    required this.controller,
    this.size = 156,
    super.key,
  });

  final VoiceTurnController controller;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => IntelligenceOrb(
        size: size,
        state: controller.snapshot.state.orbState,
      ),
    );
  }
}
