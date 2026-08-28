#!/usr/bin/env bash
# Build a Play-oriented Android App Bundle.
# Does not create a keystore or insert secrets.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f android/key.properties ]]; then
  echo "Missing android/key.properties." >&2
  echo "Copy android/key.properties.example, generate an upload keystore locally," >&2
  echo "and do not commit those files. MANUAL SETUP REQUIRED." >&2
  exit 1
fi

if grep -q 'REPLACE_ME' android/key.properties; then
  echo "android/key.properties still contains REPLACE_ME placeholders." >&2
  echo "Fill in real keystore values locally. Do not commit them." >&2
  exit 1
fi

export PATH="${HOME}/flutter/bin:${PATH}"
flutter build appbundle --release \
  --dart-define-from-file=tool/production.defines.json
