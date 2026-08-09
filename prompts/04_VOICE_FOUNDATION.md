# Prompt 04: Voice foundation
Branch: `feature/voice-foundation`

Implement the voice state machine from `docs/VOICE.md`, microphone permission flow, recording abstraction, audio playback queue and server side speech provider contracts. ElevenLabs is the default TTS provider. Keep STT configurable. Support moderator, actor and intelligence voice roles. Add optional transcript display, but no text input is required for the core flow.

Acceptance: a mocked end to end audio turn works in tests; provider keys remain server side; interruptions and permission denial fail gracefully. Finish the mandatory Git workflow.
