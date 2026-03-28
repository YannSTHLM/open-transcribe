#!/bin/bash
# Open Transcribe - macOS First-Run Installer
# Checks and installs all required dependencies

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║    Open Transcribe - First Run Setup ║"
echo "╚══════════════════════════════════════╝"
echo ""

# -------------------------------------------------------
# Helper functions
# -------------------------------------------------------
command_exists() {
    command -v "$1" &> /dev/null
}

version_ge() {
    # Returns 0 (true) if $1 >= $2
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# -------------------------------------------------------
# 1. Check for Homebrew
# -------------------------------------------------------
if ! command_exists brew; then
    echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add brew to PATH for Apple Silicon
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    echo -e "${GREEN}✓ Homebrew installed${NC}"
else
    echo -e "${GREEN}✓ Homebrew found${NC}"
fi

# -------------------------------------------------------
# 2. Check for Python 3.10+
# -------------------------------------------------------
PYTHON_OK=false
if command_exists python3; then
    PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    if version_ge "$PYTHON_VERSION" "3.10"; then
        PYTHON_OK=true
        echo -e "${GREEN}✓ Python $PYTHON_VERSION found${NC}"
    fi
fi

if [ "$PYTHON_OK" = false ]; then
    echo -e "${YELLOW}Python 3.10+ not found. Installing...${NC}"
    brew install python@3.12
    echo -e "${GREEN}✓ Python installed${NC}"
fi

# -------------------------------------------------------
# 3. Check for Node.js 18+
# -------------------------------------------------------
NODE_OK=false
if command_exists node; then
    NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VERSION" -ge 18 ]; then
        NODE_OK=true
        echo -e "${GREEN}✓ Node.js $(node -v) found${NC}"
    fi
fi

if [ "$NODE_OK" = false ]; then
    echo -e "${YELLOW}Node.js 18+ not found. Installing...${NC}"
    brew install node@20
    echo -e "${GREEN}✓ Node.js installed${NC}"
fi

# -------------------------------------------------------
# 4. Check for FFmpeg
# -------------------------------------------------------
if ! command_exists ffmpeg; then
    echo -e "${YELLOW}FFmpeg not found. Installing...${NC}"
    brew install ffmpeg
    echo -e "${GREEN}✓ FFmpeg installed${NC}"
else
    echo -e "${GREEN}✓ FFmpeg found${NC}"
fi

echo ""
echo "Setting up backend..."

# -------------------------------------------------------
# 5. Create virtual environment
# -------------------------------------------------------
cd "$APP_DIR/backend"

if [ ! -d "venv" ]; then
    echo -e "${BLUE}Creating Python virtual environment...${NC}"
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${GREEN}✓ Virtual environment exists${NC}"
fi

# -------------------------------------------------------
# 6. Install Python dependencies
# -------------------------------------------------------
echo -e "${BLUE}Installing Python dependencies (this may take a minute)...${NC}"
source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo -e "${GREEN}✓ Python dependencies installed${NC}"

# -------------------------------------------------------
# 7. Copy .env if needed
# -------------------------------------------------------
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo -e "${GREEN}✓ Created .env from .env.example${NC}"
fi

# -------------------------------------------------------
# 8. Create data directories
# -------------------------------------------------------
mkdir -p data/uploads data/transcriptions

echo ""
echo "Setting up frontend..."

# -------------------------------------------------------
# 9. Install Node.js dependencies
# -------------------------------------------------------
cd "$APP_DIR/frontend"

if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}Installing Node.js dependencies (this may take a minute)...${NC}"
    npm install
    echo -e "${GREEN}✓ Node.js dependencies installed${NC}"
else
    echo -e "${GREEN}✓ Node.js dependencies exist${NC}"
fi

# -------------------------------------------------------
# 10. Build frontend for production
# -------------------------------------------------------
if [ ! -d "dist" ]; then
    echo -e "${BLUE}Building frontend for production...${NC}"
    npm run build
    echo -e "${GREEN}✓ Frontend built${NC}"
else
    echo -e "${GREEN}✓ Frontend build exists${NC}"
fi

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       Setup Complete! 🎉             ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "You can now launch Open Transcribe."
echo ""