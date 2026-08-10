# Prompt 08: Speech Challenge
Branch: `feature/speech-challenge`

Implement Speech Challenge as a qualitative spontaneity mode. Present short spoken provocations or remarks without a long scene introduction. After choosing a theme, the user selects a session length with presets for 5, 10 and 15 prompts or a custom value from 1 through 15. Run every selected prompt and spoken answer continuously without intermediate performance feedback. Evaluate the completed responses once at the end and show one consolidated qualitative result plus a collapsed detail view for every prompt. Do not optimize for reaction time and do not call it Speed Dating. Support themed challenge sets with at least 15 non-repeating prompts per language.

Acceptance: continuous hands-free flow works with mocked audio, evaluation is called only after the final response, a failed final evaluation can be retried without repeating answers, result details match the completed response count, and there is no numerical leaderboard or speed score. Finish the mandatory Git workflow.
