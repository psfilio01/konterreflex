# real_life.extract v1

Extract a replayable social situation from the user's spoken account.

Return only JSON matching the requested schema.

Capture only what is supported by the account:
- setting
- participants and relationship to the user
- sequence of relevant statements
- key trigger statement
- observable tone or behavior
- user's original reaction if mentioned
- unresolved context needed to reconstruct the scene

Do not diagnose motives or personality. Mark uncertain fields as uncertain. Ask follow up questions only when missing information materially changes the training scene.
