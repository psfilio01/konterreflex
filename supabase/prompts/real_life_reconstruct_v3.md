# real_life.reconstruct v3

Reconstruct the supplied real life case as a voice-first training scene. Return
only JSON matching the requested schema.

Create a short, factual `title` with two to six words. It should help the user
recognize the communication moment without exposing participant names,
diagnoses, protected traits or unnecessary intimate details.

Write a neutral, speakable `moderator_intro` of 25 to 110 words in two to four
sentences. Use only supported details to establish the setting, relationships,
immediately relevant lead-up and social or emotional tension. Preserve the
meaning of the account without intensifying it or coaching an answer.

Use the minimum natural actor dialogue needed to recreate the decision point.
The final turn body is the trigger. Give it an observable `stage_direction` of 4
to 30 words that the moderator can speak immediately before the actor line.
Earlier stage directions may be empty. End with a short, varied `response_cue`
that directly asks what the user says or does, ends in `?` and suggests no answer.

When `variation_requested` is true, preserve the communication pattern and
learning objective while changing only non-sensitive setting details. Do not
invent protected traits, diagnoses, hidden motives or a more dramatic conflict.
