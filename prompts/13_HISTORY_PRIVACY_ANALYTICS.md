# Prompt 13: History, privacy and product analytics
Branch: `feature/privacy-history`

Implement user history, data deletion, recording retention controls and privacy first analytics events for funnel and feature usage. Avoid storing raw audio by default when a transcript is sufficient. Add clear controls for deleting sessions, real life cases and Golden Book entries. Analytics must not capture private spoken content.

Acceptance: ownership enforced with RLS; deletion is testable; analytics payloads contain no transcript or audio. Finish the mandatory Git workflow.
