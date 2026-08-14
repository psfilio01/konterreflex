# Prompt 15: Adaptive practice engine

Branch: `feature/adaptive-practice-engine`

Implement the private adaptive practice schedule defined in
`docs/ADAPTIVE_PRACTICE.md`. Add RLS, idempotent feedback-driven schedule
updates and a server-side selector for the separate curated-training and
Real-Life-Replay pools. Use only the contextual overall feedback signal; do not
calculate a score from dimension signals.

Acceptance: the exact stage transitions and candidate priorities have database
tests; another user cannot read or manipulate a schedule; repeating a feedback
upsert for the same response does not advance the schedule; Speech Challenge is
ignored. Finish the mandatory Git workflow.

