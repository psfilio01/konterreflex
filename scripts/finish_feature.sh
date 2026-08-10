#!/usr/bin/env bash
set -euo pipefail
message="${1:?Usage: scripts/finish_feature.sh 'type: commit message' 'Einfache deutsche Beschreibung' ['Testbeschreibung']}"
description="${2:?Eine einfache deutsche PR-Beschreibung ist erforderlich.}"
test_description="${3:-flutter analyze und flutter test}"
branch="$(git branch --show-current)"

if [ "$branch" = "main" ]; then
  echo "Refusing to finish a change directly on main" >&2
  exit 1
fi

case "$branch" in
  feature/*) change_type="Feature" ;;
  bugfix/*) change_type="Bugfix" ;;
  chore/*) change_type="Wartung" ;;
  *)
    echo "Branch must start with feature/, bugfix/ or chore/" >&2
    exit 1
    ;;
esac

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
  pr_body="$(mktemp)"
  trap 'rm -f "$pr_body"' EXIT
  {
    printf '%s\n\n' '## Beschreibung in einfachen Worten'
    printf '%s\n\n' "$description"
    printf '%s\n\n' '## Art der Änderung'
    printf '%s\n\n' "- $change_type"
    printf '%s\n\n' '## Änderungen'
    printf '%s\n\n' "- $message"
    printf '%s\n\n' '## Tests'
    printf '%s\n\n' "- $test_description"
    printf '%s\n\n' '## Hinweise für Review und Betrieb'
    printf '%s\n' '- Keine zusätzlichen Hinweise, sofern oben nicht beschrieben.'
  } > "$pr_body"
  pr_url=$(gh pr create --title "$message" --body-file "$pr_body" --base main --head "$branch")
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
