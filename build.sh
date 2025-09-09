#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables
APP_ID="org.bitcoinknots.Daemon"
MANIFEST="org.bitcoinknots.Daemon.json"
REPO_DIR="./repo"
BUILD_DIR="./build"
BUNDLE_NAME="bitcoin-knots-daemon.flatpak"

echo -e "${GREEN}Building Bitcoin Knots Daemon Flatpak...${NC}"

# Check if Flatpak is installed
if ! command -v flatpak &> /dev/null; then
    echo -e "${RED}Flatpak is not installed. Please install it first.${NC}"
    exit 1
fi

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR" "$REPO_DIR" "$BUNDLE_NAME"

# Build the application
echo -e "${YELLOW}Building application...${NC}"
flatpak-builder \
    --force-clean \
    --ccache \
    --repo="$REPO_DIR" \
    "$BUILD_DIR" \
    "$MANIFEST"

# Create bundle
echo -e "${YELLOW}Creating bundle...${NC}"
flatpak build-bundle "$REPO_DIR" "$BUNDLE_NAME" "$APP_ID"

# Verify bundle
if [ -f "$BUNDLE_NAME" ]; then
    echo -e "${GREEN}Build successful! Bundle created: $BUNDLE_NAME${NC}"
    echo -e "${YELLOW}To install:${NC} flatpak install $BUNDLE_NAME"
    echo -e "${YELLOW}To run:${NC} flatpak run $APP_ID"
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi
