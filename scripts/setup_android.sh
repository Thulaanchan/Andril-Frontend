#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get --enforce-lockfile
flutter gen-l10n
