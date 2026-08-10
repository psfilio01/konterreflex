# Konterreflex repository instructions

## Mission
Build a commercial, voice first training app for spontaneous communication. Keep UX calm, light, minimal and fast. The AI is an abstract conversational intelligence, never a human coach avatar.

## Working style
- Read the requested prompt plus only the relevant docs before coding.
- Prefer simple architecture and small dependencies.
- Preserve provider boundaries for AI, speech and billing.
- Never expose provider API keys in Flutter clients.
- Use Supabase RLS for all user owned data.
- Add tests for business logic and critical Edge Functions.
- Do not invent product behavior that conflicts with `docs/PRODUCT.md`.
- You may improve implementation details when a cleaner solution fits the architecture.
- Avoid large speculative refactors.

## Git workflow, mandatory for every change
1. Start from current `main` and a clean tree. Never commit directly to `main`, including for small fixes.
2. Choose the branch type from the actual scope unless the prompt explicitly names a branch:
   - `feature/<short-name>` for new product behavior or a meaningful enhancement.
   - `bugfix/<short-name>` for a defect, regression or unintended behavior.
   - `chore/<short-name>` for documentation, tooling, dependencies or maintenance without new product behavior.
3. Implement and test only the scoped task.
4. Commit with a concise conventional commit.
5. Push and always open a pull request when `origin` and authenticated `gh` are available. Use `.github/pull_request_template.md` and fill every section that applies.
6. Write the PR description in simple German. Explain in user-friendly words what changes, why it is useful and how it was tested.
7. Merge the pull request immediately after checks pass.
8. Return to `main`, pull with `--ff-only`, and delete the local branch.
9. If no remote or GitHub authentication exists, merge locally into `main` and report that no remote PR could be created. Never leave finished work stranded on a change branch.

Use `scripts/start_feature.sh` and `scripts/finish_feature.sh` when useful. Despite their legacy names, they support `feature/`, `bugfix/` and `chore/` branches.

## Quality gate
Before finishing a task, run what exists and is relevant:

```bash
flutter analyze
flutter test
supabase functions serve --env-file .env.local
```

Do not fail a task merely because a tool is not installed. Report the missing prerequisite clearly.

## Security
- Secrets only server side or local untracked env files.
- Validate auth server side.
- Verify Stripe webhook signatures.
- Treat user recordings and transcripts as private data.
- Store only what is necessary and support deletion.

## Product language
Default product copy is German. Code, identifiers and technical documentation are English.

## Code review rules
Flag: leaked secrets, missing RLS, provider coupling, hidden paid access bypass, raw model output used without schema validation, discriminatory scenario generation, numerical scoring replacing qualitative feedback, or UI that requires typing for a core flow.
