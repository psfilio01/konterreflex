# Prompt 18: Rich scenario context and response handoff

Branch: `feature/richer-scenario-context`

Make curated Training and Real Life Replay scenes easier to enter and easier to
answer. The moderator gives a concise but substantial introduction with setting,
relationship, relevant lead-up and supported social tension. Non-empty stage
directions are spoken by the moderator before the associated actor line. Every
scene ends with a short, varied and explicit moderator `response_cue` before the
app waits for the user's voice.

Add the versioned external JSON format documented in
`docs/SCENARIO_FORMAT.md`. Admins can paste one to fifty strictly validated
scenarios into the Scenario Studio. Validate the complete batch before saving,
persist every import as a draft, record an import audit and retain the existing
safety review requirement before activation.

Update scenario generation, personalization and Real Life reconstruction prompts
and schemas so new content follows the richer structure. Preserve old stored
scenes through a localized response-cue migration. Keep private Real Life content
out of the shared speech cache.

Acceptance: Training and Real Life playback both speak context, available stage
directions, actor turns and a final moderator response cue in that order; generated
and reconstructed scenes require the new cue; a valid external batch is imported
as reviewed drafts with its locale; malformed or incomplete batches create no
drafts; relevant Flutter, Edge Function and database tests pass. Finish the
mandatory Git workflow.
