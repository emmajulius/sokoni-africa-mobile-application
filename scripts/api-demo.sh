#!/usr/bin/env bash
# Comprehensive API Demo Script - Demonstrates all Sokoni Africa API endpoints
# Based on actual implementation in africa_sokoni_app_backend

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# API Configuration
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
API="${API_BASE_URL}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Global variables
TOKEN=""
USER_ID=""
PRODUCT_ID=""
ORDER_ID=""

echo -e "${CYAN}🌐 Sokoni Africa API Comprehensive Demo${NC}"
echo "=============================================="
echo ""
echo "API Base URL: $API"
echo ""

# Check if jq is installed (for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq not found. Install it for better JSON output:${NC}"
    echo "   macOS: brew install jq"
    echo "   Ubuntu: sudo apt-get install jq"
    echo "   Windows: choco install jq"
    echo ""
    USE_JQ=false
else
    USE_JQ=true
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl not found. Please install curl first.${NC}"
    exit 1
fi

# Helper function to print section headers
print_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Helper function to print API call
print_api_call() {
    echo -e "${YELLOW}# $1${NC}"
    echo -e "${YELLOW}$2${NC}"
    echo ""
}

# Helper function to make API call and display response
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local headers=$4
    local description=$5
    
    print_api_call "$description" "curl -X $method \"${API}$endpoint\" $headers $data"
    
    local response
    if [ -n "$data" ] && [ "$data" != "null" ]; then
        response=$(curl -s -X "$method" "${API}${endpoint}" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            $headers \
            -d "$data" 2>&1)
    else
        response=$(curl -s -X "$method" "${API}${endpoint}" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            $headers 2>&1)
    fi
    
    if [ $USE_JQ = true ]; then
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    else
        echo "$response"
    fi
    echo ""
}

# Test API connectivity
echo -e "${BLUE}Testing API connectivity...${NC}"
if curl -s -f "${API}/docs" > /dev/null 2>&1 || curl -s -f "${API}/api/products" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API is reachable${NC}"
else
    echo -e "${YELLOW}⚠️  API may not be running. Start it with: bash scripts/start-backend.sh${NC}"
    echo ""
fi
echo ""

# 1. Get Products (Public endpoint)
echo -e "${BLUE}# GET /api/products${NC}"
echo "curl -X GET \"${API}/api/products?limit=5\""
echo ""
RESPONSE=$(curl -s -X GET "${API}/api/products?limit=5" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" 2>&1)

if [ $USE_JQ = true ]; then
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
else
    echo "$RESPONSE"
fi
echo ""
echo "---"
echo ""

# 2. Register a new user
echo -e "${BLUE}# POST /api/auth/register${NC}"
echo "curl -X POST \"${API}/api/auth/register\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"username\":\"demo_user\",\"full_name\":\"Demo User\",\"email\":\"demo@example.com\",\"phone\":\"+255712345678\",\"password\":\"SecurePass123!\"}'"
echo ""

REGISTER_RESPONSE=$(curl -s -X POST "${API}/api/auth/register" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{
        "username": "demo_user_'$(date +%s)'",
        "full_name": "Demo User",
        "email": "demo_'$(date +%s)'@example.com",
        "phone": "+255712345678",
        "password": "SecurePass123!"
    }' 2>&1)

if [ $USE_JQ = true ]; then
    echo "$REGISTER_RESPONSE" | jq '.' 2>/dev/null || echo "$REGISTER_RESPONSE"
else
    echo "$REGISTER_RESPONSE"
fi
echo ""
echo "---"
echo ""

# 3. Login
echo -e "${BLUE}# POST /api/auth/login${NC}"
echo "curl -X POST \"${API}/api/auth/login\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"username\":\"demo_user\",\"password\":\"SecurePass123!\"}'"
echo ""

LOGIN_RESPONSE=$(curl -s -X POST "${API}/api/auth/login" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{
        "username": "demo_user",
        "password": "SecurePass123!"
    }' 2>&1)

if [ $USE_JQ = true ]; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token // empty' 2>/dev/null)
    echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"
else
    TOKEN=""
    echo "$LOGIN_RESPONSE"
fi
echo ""

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ] && [ "$TOKEN" != "" ]; then
    echo -e "${GREEN}✓ Authentication successful${NC}"
    echo "Token: ${TOKEN:0:20}..."
    echo ""
    echo "---"
    echo ""

    # 4. Get current user profile
    echo -e "${BLUE}# GET /api/users/me${NC}"
    echo "curl -X GET \"${API}/api/users/me\" \\"
    echo "  -H \"Authorization: Bearer \$TOKEN\""
    echo ""

    PROFILE_RESPONSE=$(curl -s -X GET "${API}/api/users/me" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -H "Authorization: Bearer $TOKEN" 2>&1)

    if [ $USE_JQ = true ]; then
        echo "$PROFILE_RESPONSE" | jq '.' 2>/dev/null || echo "$PROFILE_RESPONSE"
    else
        echo "$PROFILE_RESPONSE"
    fi
    echo ""
    echo "---"
    echo ""

    # 5. Create a product (requires authentication)
    echo -e "${BLUE}# POST /api/products${NC}"
    echo "curl -X POST \"${API}/api/products\" \\"
    echo "  -H \"Authorization: Bearer \$TOKEN\" \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '{\"title\":\"Demo Product\",\"description\":\"A demo product\",\"category\":\"electronics\",\"price\":99.99,\"currency\":\"USD\"}'"
    echo ""

    PRODUCT_RESPONSE=$(curl -s -X POST "${API}/api/products" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d '{
            "title": "Demo Product",
            "description": "A demo product for testing",
            "category": "electronics",
            "price": 99.99,
            "currency": "USD",
            "tags": ["demo", "test"]
        }' 2>&1)

    if [ $USE_JQ = true ]; then
        PRODUCT_ID=$(echo "$PRODUCT_RESPONSE" | jq -r '.id // empty' 2>/dev/null)
        echo "$PRODUCT_RESPONSE" | jq '.' 2>/dev/null || echo "$PRODUCT_RESPONSE"
    else
        PRODUCT_ID=""
        echo "$PRODUCT_RESPONSE"
    fi
    echo ""
    echo "---"
    echo ""

    # 6. Get wallet balance
    echo -e "${BLUE}# GET /api/wallet/balance${NC}"
    echo "curl -X GET \"${API}/api/wallet/balance\" \\"
    echo "  -H \"Authorization: Bearer \$TOKEN\""
    echo ""

    WALLET_RESPONSE=$(curl -s -X GET "${API}/api/wallet/balance" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -H "Authorization: Bearer $TOKEN" 2>&1)

    if [ $USE_JQ = true ]; then
        echo "$WALLET_RESPONSE" | jq '.' 2>/dev/null || echo "$WALLET_RESPONSE"
    else
        echo "$WALLET_RESPONSE"
    fi
    echo ""
    echo "---"
    echo ""

else
    echo -e "${YELLOW}⚠️  Login failed. Skipping authenticated endpoints.${NC}"
    echo "   Note: You may need to register a user first or use existing credentials."
    echo ""
fi

# 7. Get categories
echo -e "${BLUE}# GET /api/categories${NC}"
echo "curl -X GET \"${API}/api/categories\""
echo ""

CATEGORIES_RESPONSE=$(curl -s -X GET "${API}/api/categories" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" 2>&1)

if [ $USE_JQ = true ]; then
    echo "$CATEGORIES_RESPONSE" | jq '.' 2>/dev/null || echo "$CATEGORIES_RESPONSE"
else
    echo "$CATEGORIES_RESPONSE"
fi
echo ""
echo "---"
echo ""

echo -e "${GREEN}✅ API demo complete!${NC}"
echo ""
echo "For more API endpoints, visit:"
echo "  - Swagger UI: ${API}/docs"
echo "  - ReDoc: ${API}/redoc"
echo ""

