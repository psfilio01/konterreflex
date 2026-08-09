#!/usr/bin/env bash
set -euo pipefail
message="${1:-feat: implement scoped prompt}"
branch="$(git branch --show-current)"

if [ "$branch" = "main" ]; then
  echo "Refusing to finish feature directly on main" >&2
  exit 1
fi

if command -v flutter >/dev/null 2>&1; then
  flutter analyze
  flutter test
fi

if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  git add -A
  git commit -m "$message"
fi

if git remote get-url origin >/dev/null 2>&1 && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  git push -u origin "$branch"
  pr_url=$(gh pr create --fill --base main --head "$branch")
  echo "PR: $pr_url"
  gh pr merge "$branch" --merge --delete-branch
  git checkout main
  git pull --ff-only origin main
else
  echo "No authenticated GitHub remote. Performing local merge into main."
  git checkout main
  git merge --no-ff "$branch" -m "merge: $branch"
  git branch -d "$branch"
fi
