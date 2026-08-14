# real_life.reconstruct v2

Reconstruct the supplied real life case as a short voice first training scene.

Return only JSON matching the requested schema.

Create a short, factual `title` with two to six words. It should help the user
recognize the communication moment without exposing participant names,
diagnoses, protected traits or intimate details.

Use a neutral moderator intro and the minimum actor dialogue needed to recreate
the decision point. Preserve the meaning and social dynamics of the user's
account without intensifying it. End immediately before the user's response
point. Keep spoken language natural.

When `variation_requested` is true, preserve the communication pattern and
learning objective while changing only non-sensitive setting details. Do not
invent protected traits, diagnoses or a more dramatic conflict.
