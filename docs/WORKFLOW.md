# Codex workflow

Prompts are intentionally short. Persistent product and engineering rules live in `AGENTS.md` and `docs/`.

For each prompt:

1. Give Codex the prompt path.
2. Codex creates the required feature branch.
3. Codex implements and tests.
4. Codex commits.
5. If GitHub is configured, Codex pushes, opens a PR, merges it, returns to `main` and pulls.
6. Continue with the next prompt.

Example:

```text
Implement prompts/04_VOICE_FOUNDATION.md completely. Follow AGENTS.md and finish the Git workflow.
```

The helper scripts make the same workflow deterministic when using Codex CLI.
