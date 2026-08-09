#!/usr/bin/env bash
set -euo pipefail
branch="${1:?Usage: scripts/start_feature.sh feature/name}"

git diff --quiet && git diff --cached --quiet || { echo "Working tree must be clean"; exit 1; }
git checkout main
if git remote get-url origin >/dev/null 2>&1; then git pull --ff-only origin main; fi
git checkout -b "$branch"
