#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

REMOTE="git@github.com:ruancanghui-hub/lessdo.git"
BRANCH="${1:-feature/lessdo-ios-1.0}"

if ! git ls-remote "$REMOTE" HEAD >/dev/null 2>&1; then
  cat <<'EOF'
The GitHub repository ruancanghui-hub/lessdo does not exist yet.

Create an empty public repository named "lessdo" (no README, no .gitignore),
then rerun:

  ./tool/push_lessdo_source.sh

Quick link:
  https://github.com/new?name=lessdo&description=LessDo+iOS&owner=ruancanghui-hub
EOF
  exit 1
fi

git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE"
git push -u origin "$BRANCH:main"
echo "Pushed $BRANCH to $REMOTE (main)"
