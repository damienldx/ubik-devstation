#!/bin/bash
set -e

UBIK_DIR="$HOME/workspace/UBIK"
WWW_DIR="/var/www/ubik"

echo "--- Setting up UBIK Frontend ---"

if [ ! -d "$UBIK_DIR" ]; then
    echo "Error: $UBIK_DIR not found. Run setup_ubik.sh first."
    exit 1
fi

cd "$UBIK_DIR"

# 1. Install dependencies
echo "Installing npm dependencies..."
npm ci

# 2. Build
echo "Building frontend..."
export VITE_RELAY_URL="http://34.163.57.243:8091/relay"
export VITE_API_URL="http://34.163.57.243:8091/api"
export VITE_PTY_URL="ws://34.163.57.243:8091/pty"

npm run build

# 3. Deploy
echo "Deploying to $WWW_DIR..."
sudo mkdir -p "$WWW_DIR"
sudo cp -r dist/. "$WWW_DIR/"
sudo chown -R caddy:caddy "$WWW_DIR" || true

# 4. Patch Caddy
echo "Patching Caddy configuration..."
python3 "$(dirname "$0")/patch_caddy_8091.py"

echo "--- UBIK Frontend Setup Complete ---"
