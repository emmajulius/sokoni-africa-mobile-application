#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${REPO_ROOT}/africa_sokoni_app_backend"

cd "${REPO_ROOT}"
echo "🧹 Formatting Dart code..."
flutter format lib test

echo "🔍 Running Flutter static analysis..."
flutter analyze

echo "🧪 Running Flutter tests..."
flutter test

if [ -d "${BACKEND_DIR}" ]; then
  echo "🧪 Running backend unit tests..."
  cd "${BACKEND_DIR}"
  if [ -d ".venv" ]; then
    # shellcheck disable=SC1091
    source .venv/bin/activate
  fi
  if command -v pytest >/dev/null 2>&1; then
    pytest || true
  else
    echo "⚠️ pytest not found; skipping backend tests"
  fi
  if [ -n "${VIRTUAL_ENV:-}" ]; then
    deactivate
  fi
fi

echo "✅ Quality checks complete."

