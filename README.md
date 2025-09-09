# Bitcoin Knots Daemon Flatpak

Flatpak package for Bitcoin Knots daemon (bitcoind).

## Features

- Sandboxed Bitcoin Knots daemon
- Automatic dependency management
- Easy installation and updates
- Configurable data directory

## Installation

### From Source

```bash
git clone https://github.com/Rsync25/bitcoin-knots-flatpak.git
cd bitcoin-knots-daemon-flatpak
./build.sh
flatpak install bitcoin-knots-daemon.flatpak

## 2. Flatpak Manifest (`org.bitcoinknots.Daemon.json`)

```json
{
  "app-id": "org.bitcoinknots.Daemon",
  "runtime": "org.freedesktop.Platform",
  "runtime-version": "22.08",
  "sdk": "org.freedesktop.Sdk",
  "command": "bitcoin-knots-daemon",
  "finish-args": [
    "--share=network",
    "--socket=network",
    "--filesystem=home:ro",
    "--filesystem=xdg-data/bitcoin-knots:create",
    "--talk-name=org.freedesktop.DBus",
    "--env=BITCOIN_DATA_DIR=/home/user/.bitcoin",
    "--allow=devel"
  ],
  "modules": [
    {
      "name": "boost",
      "buildsystem": "cmake-ninja",
      "config-opts": [
        "-DBUILD_SHARED_LIBS=ON",
        "-DCMAKE_BUILD_TYPE=Release",
        "-DBOOST_CONTEXT_BUILD_EXAMPLES=OFF",
        "-DBOOST_CONTEXT_BUILD_TESTS=OFF"
      ],
      "sources": [
        {
          "type": "archive",
          "url": "https://boostorg.jfrog.io/artifactory/main/release/1.78.0/source/boost_1_78_0.tar.bz2",
          "sha256": "8681f175d4bdb26c52222665793eef08490d7758529330f98d3b29dd0735bccc"
        }
      ]
    },
    {
      "name": "libevent",
      "buildsystem": "autotools",
      "config-opts": [
        "--disable-libevent-regress",
        "--disable-samples",
        "--disable-openssl"
      ],
      "sources": [
        {
          "type": "archive",
          "url": "https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz",
          "sha256": "92e6de1be9ec176428fd2367677e61ceffc2ee1dc119e037e4b4d2e7c2c2ad4c"
        }
      ]
    },
    {
      "name": "berkeley-db",
      "buildsystem": "autotools",
      "config-opts": [
        "--disable-shared",
        "--enable-cxx",
        "--disable-replication",
        "--with-pic"
      ],
      "sources": [
        {
          "type": "archive",
          "url": "https://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz",
          "sha256": "12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef"
        }
      ]
    },
    {
      "name": "bitcoin-knots",
      "buildsystem": "autotools",
      "build-options": {
        "env": {
          "CPPFLAGS": "-I/app/include -I/app/include/db4.8",
          "LDFLAGS": "-L/app/lib -L/app/lib/db4.8",
          "BDB_CFLAGS": "-I/app/include/db4.8",
          "BDB_LIBS": "-L/app/lib/db4.8 -ldb_cxx-4.8"
        }
      },
      "config-opts": [
        "--disable-gui",
        "--disable-wallet",
        "--disable-bench",
        "--disable-tests",
        "--disable-man",
        "--with-boost=/app",
        "--with-boost-libdir=/app/lib",
        "--with-libevent=/app"
      ],
      "sources": [
        {
          "type": "git",
          "url": "https://github.com/bitcoinknots/bitcoin.git",
          "branch": "knots",
          "commit": "latest"
        },
        {
          "type": "script",
          "dest-filename": "fix-permissions.sh",
          "commands": ["chmod -R a+rX ."]
        }
      ]
    },
    {
      "name": "bitcoin-knots-wrapper",
      "buildsystem": "simple",
      "build-commands": [
        "install -Dm755 bitcoin-knots-daemon.sh /app/bin/bitcoin-knots-daemon"
      ],
      "sources": [
        {
          "type": "file",
          "path": "bitcoin-knots-daemon.sh"
        }
      ]
    }
  ]
}
```

## 3. Wrapper Script (`bitcoin-knots-daemon.sh`)

```bash
#!/bin/sh
# Bitcoin Knots daemon wrapper for Flatpak

# Set default data directory if not specified
if [ -z "$BITCOIN_DATA_DIR" ]; then
    export BITCOIN_DATA_DIR="$HOME/.bitcoin"
fi

# Create data directory if it doesn't exist
mkdir -p "$BITCOIN_DATA_DIR"

# Run Bitcoin Knots daemon with proper arguments
exec /app/bin/bitcoind \
    -datadir="$BITCOIN_DATA_DIR" \
    -conf="$BITCOIN_DATA_DIR/bitcoin.conf" \
    "$@"
```

Make it executable:
```bash
chmod +x bitcoin-knots-daemon.sh
```

## 4. Build Script (`build.sh`)

```bash
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
```

## 5. GitHub Actions Workflow (`.github/workflows/build-flatpak.yml`)

```yaml
name: Build Bitcoin Knots Daemon Flatpak

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  release:
    types: [ created ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Install Flatpak
      run: |
        sudo apt update
        sudo apt install -y flatpak flatpak-builder

    - name: Add Flathub repository
      run: |
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        flatpak install -y flathub org.freedesktop.Platform//22.08
        flatpak install -y flathub org.freedesktop.Sdk//22.08

    - name: Make build script executable
      run: chmod +x build.sh

    - name: Build Flatpak
      run: ./build.sh

    - name: Upload artifact
      uses: actions/upload-artifact@v4
      with:
        name: bitcoin-knots-daemon-flatpak
        path: bitcoin-knots-daemon.flatpak

    - name: Create Release
      if: github.event_name == 'release'
      uses: softprops/action-gh-release@v1
      with:
        files: bitcoin-knots-daemon.flatpak
```