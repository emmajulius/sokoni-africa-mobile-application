#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${REPO_ROOT}/africa_sokoni_app_backend"

command -v flutter >/dev/null 2>&1 || {
  echo "❌ Flutter is not installed or not on PATH" >&2
  exit 1
}

command -v python >/dev/null 2>&1 || {
  echo "❌ Python is not installed or not on PATH" >&2
  exit 1
}

command -v pip >/dev/null 2>&1 || {
  echo "❌ pip is not installed or not on PATH" >&2
  exit 1
}

echo "📦 Resolving Flutter dependencies..."
cd "${REPO_ROOT}"
flutter pub get

if [ -d "${BACKEND_DIR}" ]; then
  echo "📦 Resolving backend Python dependencies..."
  cd "${BACKEND_DIR}"
  python -m venv .venv >/dev/null 2>&1 || true
  # shellcheck disable=SC1091
  source .venv/bin/activate
  pip install --upgrade pip
  pip install -r requirements.txt
  deactivate
else
  echo "⚠️ Backend directory not found at ${BACKEND_DIR}, skipping backend setup"
fi

echo "✅ Bootstrap complete."

