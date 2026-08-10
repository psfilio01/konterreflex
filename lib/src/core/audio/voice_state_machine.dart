enum VoiceTurnState {
  idle,
  preparing,
  introducing,
  acting,
  awaitingUser,
  recording,
  processing,
  feedback,
  followUp,
}

class VoiceStateTransitionError extends StateError {
  VoiceStateTransitionError(super.message);
}

class VoiceStateMachine {
  VoiceTurnState _state = VoiceTurnState.idle;

  VoiceTurnState get state => _state;

  static const _allowed = <VoiceTurnState, Set<VoiceTurnState>>{
    VoiceTurnState.idle: {VoiceTurnState.preparing},
    VoiceTurnState.preparing: {
      VoiceTurnState.introducing,
      VoiceTurnState.feedback,
      VoiceTurnState.awaitingUser,
    },
    VoiceTurnState.introducing: {
      VoiceTurnState.acting,
      VoiceTurnState.awaitingUser,
    },
    VoiceTurnState.acting: {
      VoiceTurnState.acting,
      VoiceTurnState.awaitingUser,
    },
    VoiceTurnState.awaitingUser: {
      VoiceTurnState.recording,
      VoiceTurnState.idle,
    },
    VoiceTurnState.recording: {
      VoiceTurnState.processing,
      VoiceTurnState.awaitingUser,
    },
    VoiceTurnState.processing: {
      VoiceTurnState.preparing,
      VoiceTurnState.feedback,
      VoiceTurnState.awaitingUser,
    },
    VoiceTurnState.feedback: {
      VoiceTurnState.followUp,
      VoiceTurnState.awaitingUser,
    },
    VoiceTurnState.followUp: {
      VoiceTurnState.awaitingUser,
      VoiceTurnState.idle,
    },
  };

  void transitionTo(VoiceTurnState next) {
    if (!(_allowed[_state]?.contains(next) ?? false)) {
      throw VoiceStateTransitionError(
          'Invalid voice transition: $_state -> $next');
    }
    _state = next;
  }

  void interrupt() {
    if (_state == VoiceTurnState.idle ||
        _state == VoiceTurnState.awaitingUser) {
      return;
    }
    _state = VoiceTurnState.awaitingUser;
  }

  void reset() => _state = VoiceTurnState.idle;
}
