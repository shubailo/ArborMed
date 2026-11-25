#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
sdk="${FLUTTER_ROOT:-${TMPDIR:-/tmp}/arbormed-flutter-3.38.9}"
if [[ ! -x "$sdk/bin/flutter" ]]; then
  git clone --quiet --depth 1 --branch 3.38.9 https://github.com/flutter/flutter.git "$sdk"
fi
export PATH="$sdk/bin:$PATH"
cd "$root/apps/student_app"
export FLUTTER_SUPPRESS_ANALYTICS=true
flutter pub get --enforce-lockfile
if [[ "${1:-}" == "--check" ]]; then
  flutter analyze
  flutter test
fi
defines=()
for key in API_URL WEB_FIREBASE_API_KEY WEB_FIREBASE_APP_ID FIREBASE_MESSAGING_SENDER_ID FIREBASE_PROJECT_ID WEB_FIREBASE_AUTH_DOMAIN FIREBASE_STORAGE_BUCKET WEB_FIREBASE_MEASUREMENT_ID; do
  if [[ -n "${!key:-}" ]]; then defines+=("--dart-define=$key=${!key}"); fi
done
flutter build web --release "${defines[@]}"
test -s build/web/main.dart.js
test -s build/web/sqlite3.wasm
