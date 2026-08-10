# Voice architecture

The primary journey must work without typing.

## Roles
- Moderator: one stable neutral voice.
- Actors: one or more distinct voices per scenario.
- Intelligence: one stable product voice for feedback and conversation.
- User: microphone input.

## State machine
`idle -> preparing -> introducing -> acting -> awaiting_user -> recording -> processing -> preparing -> feedback -> follow_up`

The preparation state covers speech generation and buffering. The speaking state
starts only when playback is ready. The orb animation reflects state and voice
activity but is never required to understand the flow.

Microphone activity uses the RMS level of the local PCM stream. Playback starts
its visual cadence only when the device audio player starts; it does not delay
playback to decode or analyze provider audio a second time.

## Provider boundary
Server side speech operations use `SpeechProvider` contracts. ElevenLabs is the default TTS provider. STT is configurable. Audio files may be cached when policy and consent allow.

## Accessibility
Always provide optional captions/transcripts and visible controls even though text input is not required.
