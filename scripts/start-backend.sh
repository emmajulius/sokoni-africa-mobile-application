#!/usr/bin/env bash
# Start FastAPI backend development server

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🔧 Starting FastAPI backend server..."
echo "======================================"
echo ""

cd "$REPO_ROOT/africa_sokoni_app_backend"

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment not found. Please run 'bash scripts/setup.sh' first."
    exit 1
fi

# Activate virtual environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    source .venv/Scripts/activate
else
    source .venv/bin/activate
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  Warning: .env file not found. Server may not work correctly."
    echo "   Create a .env file with required configuration."
fi

# Check if uvicorn is installed
if ! python -c "import uvicorn" 2>/dev/null; then
    echo "❌ uvicorn not found. Installing dependencies..."
    pip install -r requirements.txt
fi

echo "🚀 Starting server on http://0.0.0.0:8000"
echo "📚 API docs available at http://localhost:8000/docs"
echo "📖 ReDoc available at http://localhost:8000/redoc"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start uvicorn with reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000

