#!/usr/bin/env bash
# Setup script for Sokoni Africa App
# Installs all dependencies for both Flutter frontend and FastAPI backend

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🚀 Setting up Sokoni Africa App..."
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Flutter installation
echo -e "${BLUE}Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}⚠️  Flutter not found. Please install Flutter first:${NC}"
    echo "   https://docs.flutter.dev/get-started/install"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✓${NC} Found: $FLUTTER_VERSION"
echo ""

# Check Python installation
echo -e "${BLUE}Checking Python installation...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}⚠️  Python 3 not found. Please install Python 3.10+ first.${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
echo -e "${GREEN}✓${NC} Found: $PYTHON_VERSION"
echo ""

# Install Flutter dependencies
echo -e "${BLUE}Installing Flutter dependencies...${NC}"
cd "$REPO_ROOT"
flutter pub get
echo -e "${GREEN}✓${NC} Flutter dependencies installed"
echo ""

# Setup Python virtual environment
echo -e "${BLUE}Setting up Python virtual environment...${NC}"
cd "$REPO_ROOT/africa_sokoni_app_backend"

if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    echo -e "${GREEN}✓${NC} Virtual environment created"
else
    echo -e "${GREEN}✓${NC} Virtual environment already exists"
fi

# Activate virtual environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    source .venv/Scripts/activate
else
    source .venv/bin/activate
fi

echo -e "${GREEN}✓${NC} Virtual environment activated"
echo ""

# Upgrade pip
echo -e "${BLUE}Upgrading pip...${NC}"
pip install --upgrade pip --quiet
echo -e "${GREEN}✓${NC} pip upgraded"
echo ""

# Install Python dependencies
echo -e "${BLUE}Installing Python dependencies...${NC}"
pip install -r requirements.txt --quiet
echo -e "${GREEN}✓${NC} Python dependencies installed"
echo ""

# Check for .env file
echo -e "${BLUE}Checking environment configuration...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found.${NC}"
    echo "   Please create a .env file in africa_sokoni_app_backend/ with:"
    echo "   - DATABASE_URL"
    echo "   - SECRET_KEY"
    echo "   - FLUTTERWAVE_PUBLIC_KEY (optional)"
    echo "   - FLUTTERWAVE_SECRET_KEY (optional)"
    echo "   - CLOUDINARY_CLOUD_NAME (optional)"
    echo "   - CLOUDINARY_API_KEY (optional)"
    echo "   - CLOUDINARY_API_SECRET (optional)"
else
    echo -e "${GREEN}✓${NC} .env file found"
fi
echo ""

# Check PostgreSQL connection (if DATABASE_URL is set)
if [ -f ".env" ] && grep -q "DATABASE_URL" .env; then
    echo -e "${BLUE}Checking database connection...${NC}"
    # Extract DATABASE_URL from .env (simple extraction)
    DB_URL=$(grep "^DATABASE_URL=" .env | cut -d '=' -f2- | tr -d '"' | tr -d "'")
    if [ -n "$DB_URL" ]; then
        echo -e "${GREEN}✓${NC} DATABASE_URL configured"
        echo "   Run 'python init_db.py' to initialize the database"
    fi
fi
echo ""

echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Configure .env file in africa_sokoni_app_backend/"
echo "  2. Initialize database: cd africa_sokoni_app_backend && python init_db.py"
echo "  3. Start backend: bash scripts/start-backend.sh"
echo "  4. Start frontend: bash scripts/start-frontend.sh"
echo ""

