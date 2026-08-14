# Prompt 17: Real Life Replay library

Branch: `feature/real-life-library`

Persist confirmed Real Life Replay reconstructions and show a private library
once the user owns at least one case. Support manual selection, adaptive random
selection and creating another case. Cache one schema-validated reconstruction
per supported app language; lazily upgrade existing cases without snapshots.
Keep private content out of the shared audio cache.

Acceptance: no cases still opens the existing capture flow directly; abandoned
drafts do not appear; manual and adaptive selections start playback once;
language snapshots are generated once and reused; RLS and deletion cascades are
tested. Similar variations remain temporary. Finish the mandatory Git workflow.

