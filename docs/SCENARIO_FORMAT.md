# Scenario format

Konterreflex uses one voice-first scene structure for curated Training scenarios,
AI-generated drafts and Real Life Replay reconstructions. The external batch
format below is the supported hand-off from another AI or content tool into the
Admin Scenario Studio.

## Playback contract

A scene is spoken in this order:

1. `moderator_intro`: two to four spoken sentences that establish the setting,
   relationship, immediately relevant lead-up and supported social tension.
2. For every turn, a non-empty `stage_direction` is spoken by the moderator,
   followed by the actor's `body` in the selected actor voice.
3. `response_cue`: one direct moderator question that makes the hand-off clear.
4. Konterreflex waits for the user's spoken response.

The introduction creates presence but does not coach an answer. Stage directions
describe only observable behavior and the immediate speaking moment. The response
cue may vary naturally, for example `Was antwortest du?`, `Wie reagierst du?` or
`Was sagst du jetzt?`, but it must never suggest a preferred answer.

## External JSON batch

Paste the complete JSON object into **Szenario-Studio > JSON-Import**. One batch
contains one language and between one and fifty scenarios.

```json
{
  "schema_version": "konterreflex.scenarios.v1",
  "locale": "de",
  "scenarios": [
    {
      "title": "Vor der Gruppe angezweifelt",
      "category": "Freundschaft · Gruppe",
      "moderator_intro": "Du bist mit zwei Freunden auf einem Boot und unterhältst dich mit einer neuen Bekanntschaft. Du hast gerade erzählt, dass ein Teil deiner Familie aus Italien kommt und dass du selbst nur etwas Italienisch sprichst. Einer deiner Freunde mischt sich ein und stellt deine Aussage vor der Gruppe infrage.",
      "trigger_statement": "Du bist doch gar kein richtiger Italiener.",
      "underlying_intent": "Die Bemerkung kann deine Glaubwürdigkeit vor der Gruppe infrage stellen; die genaue Absicht der Person bleibt offen.",
      "evaluation_focus": [
        "ruhige Präsenz",
        "klare Selbstpositionierung",
        "passende Intensität"
      ],
      "response_cue": "Du bist dran. Was antwortest du?",
      "characters": [
        {
          "name": "Freund",
          "description": "Ein Freund, der sich vor der Gruppe einmischt"
        }
      ],
      "turns": [
        {
          "character_name": "Freund",
          "body": "Du bist doch gar kein richtiger Italiener.",
          "stage_direction": "Dein Freund schaut dich direkt an und sagt vor der Gruppe:"
        }
      ]
    }
  ]
}
```

The importer rejects unknown or missing fields. Every imported scenario is saved
with source `imported` and status `draft`; prior review in another tool does not
bypass the Konterreflex safety review and admin activation step.

## Field rules

### Batch

- `schema_version` must be exactly `konterreflex.scenarios.v1`.
- `locale` must be `de` or `en` and applies to the complete batch.
- `scenarios` must contain 1 to 50 objects. Use a separate batch per language.

### Scenario

- Use exactly these fields: `title`, `category`, `moderator_intro`,
  `trigger_statement`, `underlying_intent`, `evaluation_focus`, `response_cue`,
  `characters` and `turns`.
- `title` contains 2 to 8 words and at most 80 characters. It identifies the
  communication moment without private names or intimate details.
- `category` is a short navigation label such as `Arbeit · 1:1`,
  `Freundschaft · Gruppe` or `Familie · 1:1`.
- `moderator_intro` contains 25 to 110 words in two to four speakable sentences.
  Include setting, relationship, relevant lead-up and stakes or tension. Exclude
  analysis, answer advice and irrelevant biography.
- `trigger_statement` is the exact decisive actor line. It must equal the `body`
  of the final turn after trimming whitespace.
- `underlying_intent` describes the possible social function as a contextual
  hypothesis, never as a diagnosis or certain hidden motive.
- `evaluation_focus` contains 1 to 6 qualitative aspects. Do not use points,
  percentages or numerical scoring.
- `response_cue` contains 2 to 16 words, ends with a question mark and clearly
  asks the user to respond without supplying wording.
- `characters` contains 1 to 4 unique names. Use role-like, non-stereotyped
  descriptions and no voice-provider identifiers; voices are assigned in Admin.
- `turns` contains 1 to 8 entries in playback order. Every `character_name` must
  match a declared character exactly. Keep `body` concise and naturally spoken.
- The final `stage_direction` is required and contains 4 to 30 words. Earlier
  stage directions may be empty. Describe observable gaze, pause, gesture, tone
  or group reaction without claiming thoughts or motives.

## Content and safety rules

- Create realistic friction without assigning hostility, competence or status to
  gender, ethnicity, sexuality, disability, religion, age or another protected
  trait.
- A prejudiced or insulting line is allowed when it is clearly the object of the
  exercise. The introduction, intent and evaluation focus must not endorse it.
- Keep facts, observations and contextual hypotheses separate. Do not diagnose a
  participant or present an uncertain motive as fact.
- Allow several credible response styles. Do not embed one scripted correct
  answer in the scene.
- Prefer short actor lines that a person could plausibly say aloud. More context
  belongs in the moderator introduction, not in artificial dialogue.
- Curated imports should use fictional or role-based character names. Personal
  names and private details belong only in the user's protected Real Life Replay
  data.

## Prompt for another AI

The following starter prompt can be combined with the JSON example and field
rules above:

```text
Erstelle genau 20 unterschiedliche deutsche Trainingsszenarien für spontane
Kommunikation. Gib ausschließlich einen JSON-Batch im Format
konterreflex.scenarios.v1 zurück. Halte alle Feldregeln exakt ein. Variiere Ort,
Beziehung, Gruppengröße, Machtgefälle und Kommunikationsmuster. Jede Einführung
setzt den User mit 25 bis 110 Wörtern konkret in die Lage. Der letzte Satz ist
der entscheidende Trigger, hat eine beobachtbare Moderator-Regie und entspricht
trigger_statement exakt. Beende jedes Szenario mit einer kurzen, variierenden
response_cue-Frage. Erzeuge realistische Reibung ohne Stereotype, Diagnose oder
eine vorgegebene richtige Antwort. Alle Szenarien verwenden locale de.
```
