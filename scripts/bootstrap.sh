#!/usr/bin/env bash
set -euo pipefail

command -v git >/dev/null || { echo "git is required"; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init -b main

if command -v flutter >/dev/null 2>&1; then
  if [ ! -d android ] || [ ! -d ios ]; then
    flutter create --platforms=ios,android,web --project-name konterreflex .
  fi
  flutter pub get
else
  echo "Flutter is not installed. Scaffold files are ready; Prompt 00 will finish platform generation once Flutter is available."
fi

echo "Bootstrap complete."
