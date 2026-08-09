# Voice architecture

The primary journey must work without typing.

## Roles
- Moderator: one stable neutral voice.
- Actors: one or more distinct voices per scenario.
- Intelligence: one stable product voice for feedback and conversation.
- User: microphone input.

## State machine
`idle -> introducing -> acting -> awaiting_user -> recording -> processing -> feedback -> follow_up`

The orb animation reflects state but is never required to understand the flow.

## Provider boundary
Server side speech operations use `SpeechProvider` contracts. ElevenLabs is the default TTS provider. STT is configurable. Audio files may be cached when policy and consent allow.

## Accessibility
Always provide optional captions/transcripts and visible controls even though text input is not required.
