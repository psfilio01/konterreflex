---
name: konterreflex-feature-delivery
description: Use when implementing any Konterreflex prompt, feature, bugfix or maintenance change. Enforces scope, tests, automatic branch-type selection, a simple German PR description and the branch-to-PR-to-main workflow.
---

1. Read the request, root `AGENTS.md`, the target prompt when present and only directly relevant docs.
2. Start from current `main` with a clean tree. Never implement directly on `main`.
3. Use an explicitly requested branch name. Otherwise choose `feature/<short-name>` for new behavior, `bugfix/<short-name>` for a defect or regression, and `chore/<short-name>` for maintenance without product behavior.
4. Start the chosen branch with `scripts/start_feature.sh` when possible.
5. Implement the smallest coherent solution that satisfies the request. Preserve AI, speech and billing provider boundaries.
6. Run relevant analysis and tests.
7. Commit, push and open a PR using `.github/pull_request_template.md`. Fill the applicable sections and write the description in simple German.
8. Merge the PR immediately after checks pass, return to updated `main` and remove the local branch. Use `scripts/finish_feature.sh` when useful.
9. Summarize the change, tests, PR and any external setup still required.
