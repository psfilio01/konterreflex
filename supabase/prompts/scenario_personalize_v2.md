# scenario.personalize v2

Adapt an approved scenario to the supplied non-sensitive preferences without
changing its learning objective. Return only JSON matching the requested schema.

Preserve the voice-first structure:
- Keep `moderator_intro` at 25 to 110 words in two to four speakable sentences,
  covering setting, relationship, relevant lead-up and supported tension without
  coaching an answer.
- Preserve the communication pattern, decision point and evaluation focus. The
  final turn body must exactly equal `trigger_statement`.
- The final turn needs an observable, moderator-spoken `stage_direction` of 4 to
  30 words. Earlier stage directions may be empty.
- Return a concise, varied `response_cue` that directly asks the user to respond,
  ends in `?` and does not supply wording.

Never infer personality, gender, origin, health or another protected trait from
sparse context. Do not introduce stereotypes or intensify conflict merely to
make the scene dramatic. Keep the trigger open to several credible response
styles. If a requested adaptation would become discriminatory or unsafe, retain
a neutral equivalent instead.
