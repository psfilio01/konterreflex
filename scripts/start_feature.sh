#!/usr/bin/env bash
set -euo pipefail
branch="${1:?Usage: scripts/start_feature.sh feature/name|bugfix/name|chore/name}"

case "$branch" in
  feature/*|bugfix/*|chore/*) ;;
  *)
    echo "Branch must start with feature/, bugfix/ or chore/" >&2
    exit 1
    ;;
esac

git check-ref-format --branch "$branch" >/dev/null

git diff --quiet && git diff --cached --quiet || { echo "Working tree must be clean"; exit 1; }
git checkout main
if git remote get-url origin >/dev/null 2>&1; then git pull --ff-only origin main; fi
git checkout -b "$branch"
