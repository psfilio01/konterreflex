# Prompt 05: Scenario engine
Branch: `feature/scenario-engine`

Implement retrieval and playback of approved scenarios. A session plays moderator intro, actor turns, waits for the user's spoken response, transcribes it and persists the training session and response. Use the voice state machine and keep playback logic independent of widgets. Include one to one and group scenarios.

Acceptance: only active scenarios are available to users; a mocked complete session persists correctly; retries do not duplicate records. Finish the mandatory Git workflow.

Follow-up: `prompts/15_ADAPTIVE_PRACTICE.md` and
`prompts/16_RANDOM_TRAINING.md` replace the public catalogue with adaptive
direct selection.
