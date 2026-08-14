import 'package:flutter_test/flutter_test.dart';
import 'package:konterreflex/src/core/audio/voice_state_machine.dart';
import 'package:konterreflex/src/core/audio/voice_turn_controller.dart';
import 'package:konterreflex/src/shared/widgets/intelligence_orb.dart';
import 'package:konterreflex/src/shared/widgets/voice_turn_orb.dart';

void main() {
  test('voice phases map to understandable orb states', () {
    expect(VoiceTurnState.idle.orbState, IntelligenceOrbState.idle);
    expect(
      VoiceTurnState.preparing.orbState,
      IntelligenceOrbState.preparing,
    );
    expect(VoiceTurnState.introducing.orbState, IntelligenceOrbState.speaking);
    expect(VoiceTurnState.acting.orbState, IntelligenceOrbState.speaking);
    expect(VoiceTurnState.awaitingUser.orbState, IntelligenceOrbState.idle);
    expect(VoiceTurnState.recording.orbState, IntelligenceOrbState.listening);
    expect(
      VoiceTurnState.processing.orbState,
      IntelligenceOrbState.processingSpeech,
    );
    expect(VoiceTurnState.feedback.orbState, IntelligenceOrbState.speaking);
    expect(VoiceTurnState.followUp.orbState, IntelligenceOrbState.success);
  });

  test('completed voice processing closes the spiral', () {
    expect(
      resolveVoiceTurnOrbState(
        const VoiceTurnSnapshot(
          state: VoiceTurnState.processing,
          processingComplete: true,
        ),
      ),
      IntelligenceOrbState.processingSpeechComplete,
    );
  });

  test('Speech Challenge can keep intermediate processing neutral', () {
    expect(
      resolveVoiceTurnOrbState(
        const VoiceTurnSnapshot(state: VoiceTurnState.processing),
        showProcessingSpiral: false,
      ),
      IntelligenceOrbState.thinking,
    );
  });
}
