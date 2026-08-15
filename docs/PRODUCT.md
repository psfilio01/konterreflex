# Product contract

Konterreflex is a voice first training system for spontaneous communication.

## Core promise
The user experiences realistic social situations, responds aloud, receives qualitative feedback and can repeat the situation until the response feels natural.

## Main cases

### Real life replay
The user tells Konterreflex what happened. The intelligence extracts context,
people, intent and tension, reconstructs the situation with voices, lets the
user answer again and then reflects on alternatives. Confirmed reconstructions
become a private library. Users may choose a case directly or start an adaptive
random replay. Reconstructions are generated once per selected app language and
then reused.

### Training simulation
Curated or approved scenarios cover one to one, group, work, family, friendship,
dating and public situations. Opening Training selects an adaptive random scene
without exposing the catalogue in the normal user flow. A neutral moderator
voice introduces setting, relationships, relevant lead-up and supported tension.
The moderator also speaks observable stage directions, one or more actor voices
perform the scene, and a final moderator cue clearly hands the turn to the user.

### Speech Challenge
Short prompts without long scene introductions. The user chooses 1 to 15
prompts before starting. Prompts and spoken responses run continuously without
intermediate evaluation; one consolidated qualitative result with expandable
response details appears at the end. The goal is spontaneous, high quality
communication, not a speed score.

### Golden Book
Users save useful phrases, words, rhetorical patterns and personal favorites by voice or simple direct interaction.

## Feedback
Never reduce performance to a numerical score. Use concise qualitative language. Evaluate contextually across posture, precision, frame, social effect, naturalness and escalation fit.

Results may use the categorical visual signals `strong`, `developing` and
`focus` for rapid orientation. They must stay contextual, non-numeric,
accessible without color and accompanied by explanatory qualitative feedback.

The overall signal may schedule a future repetition according to
`docs/ADAPTIVE_PRACTICE.md`. This scheduling state is not a score. Dimension
signals must not be counted or averaged for selection.

The signed-in user chooses one app language in Settings. That one choice
controls labels, curated training content, speech recognition, spoken voices
and all user-facing AI output. German is the default; German and English are
currently supported.

## AI persona
Do not portray a human coach. The product is an abstract conversational intelligence represented by a responsive orb or bubble.

## Content principles
- Gender neutral where possible.
- Realistic without stereotyping.
- No discriminatory generation or evaluation.
- Provocative situations may be simulated when training requires them, but the system must not endorse prejudice.
- Distinguish evidence based communication concepts from historical or speculative theories.

## Commercial model
Freemium ready. Entitlements are server controlled. Exact free limits and prices remain configurable rather than hard coded in product logic.
