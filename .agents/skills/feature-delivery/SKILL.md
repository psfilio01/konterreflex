---
name: konterreflex-feature-delivery
description: Use when implementing a Konterreflex prompt or feature from prompts/. Enforces scoped implementation, tests and the branch-to-PR-to-main workflow.
---

1. Read the target prompt, root `AGENTS.md` and only directly relevant docs.
2. Start the branch named by the prompt with `scripts/start_feature.sh` when possible.
3. Implement the smallest coherent solution that satisfies acceptance criteria.
4. Preserve AI, speech and billing provider boundaries.
5. Run relevant analysis and tests.
6. Finish with `scripts/finish_feature.sh` or perform the equivalent workflow manually.
7. Summarize what changed, tests run and any external setup still required.
