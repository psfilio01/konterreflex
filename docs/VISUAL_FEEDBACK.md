# Qualitative visual feedback

## Goal

Users should understand the direction of their result within a moment, before
reading the detailed reflection. The visualization complements the qualitative
feedback; it does not replace or reduce it to a score.

## Visual hierarchy

The result card starts with two layers:

1. One prominent overall signal with shape, icon, color and localized label.
2. Six compact dimension signals for presence, precision, frame, likely social
   effect, naturalness and escalation fit.

The detailed headline, explanation, strengths, next step and alternatives remain
below this overview and explain the context behind the visual signal.

When a training result is ready, the overview replaces the large active voice
orb as the primary content. It appears directly below the result heading, ahead
of follow-up actions and the optional transcript. Active playback, recording and
processing states keep the voice orb and their existing interaction hierarchy.

## Signal vocabulary

The API uses three stable, language-independent categories:

- `strong`: the response supports the communication goal; remaining changes are
  refinements.
- `developing`: the response has a useful basis, but one material adjustment
  would improve it.
- `focus`: the response currently misses an important part of the goal or fit;
  another attempt is useful.

These categories are not points and must never be converted to numbers, averaged
or counted into a hidden score. Gemini sets the overall category contextually
and evaluates every dimension independently.

## Visual and accessibility rules

- Strong uses a check-circle and calm sage/green treatment.
- Developing uses an upward path and sand treatment.
- Focus uses a replay symbol and lavender treatment, not an alarming failure
  red.
- Color is never the only signal. Every state has a distinct icon, localized
  label and screen-reader semantics.
- No stars, progress rings, percentages, rankings or pass/fail language.
- The overview appears immediately and does not require animation to be clear.

## AI and compatibility

New clients call `response.evaluate_visual`, backed by
`response_evaluate_v3.md`. The previous `response.evaluate` task remains on its
v2 schema so already installed clients continue to parse their feedback. The
new schema adds `overall_signal` and six exact `dimension_signals`; raw model
output remains schema-validated before reaching Flutter.

Signals are persisted with provider, model and prompt version for traceability.
The detailed qualitative dimension texts remain the source of explanation and
must be consistent with their corresponding visual categories.
