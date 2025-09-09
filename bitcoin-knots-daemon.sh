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
