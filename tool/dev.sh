#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/flutter/bin:$PATH"
cd "$ROOT"

if ! command -v firebase >/dev/null 2>&1; then
  npm install -g firebase-tools
fi

firebase emulators:start --project family-brain-dev &
EMU_PID=$!
trap 'kill $EMU_PID' EXIT
sleep 6

flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5173 \
  --dart-define=USE_EMULATOR=true \
  --dart-define=EMULATOR_HOST=127.0.0.1
