#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${REPO_ROOT}/africa_sokoni_app_backend"

API_HOST="${API_HOST:-0.0.0.0}"
API_PORT="${API_PORT:-8000}"
WEB_DEVICE="${WEB_DEVICE:-chrome}"

cleanup() {
  if [[ -n "${BACKEND_PID:-}" ]]; then
    echo "🛑 Stopping backend (PID=${BACKEND_PID})"
    kill "${BACKEND_PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [ ! -d "${BACKEND_DIR}" ]; then
  echo "❌ Backend directory not found at ${BACKEND_DIR}" >&2
  exit 1
fi

echo "🚀 Starting FastAPI backend on ${API_HOST}:${API_PORT}..."
cd "${BACKEND_DIR}"
if [ -d ".venv" ]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi
python -m uvicorn main:app --host "${API_HOST}" --port "${API_PORT}" --reload &
BACKEND_PID=$!
echo "✅ Backend PID=${BACKEND_PID}"

cd "${REPO_ROOT}"
echo "📱 Launching Flutter app on device '${WEB_DEVICE}'..."
flutter run -d "${WEB_DEVICE}"

