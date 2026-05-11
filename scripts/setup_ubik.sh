#!/bin/bash
set -e

UBIK_DIR="$HOME/workspace/UBIK"
BACKEND_DIR="$UBIK_DIR/backend"

echo "--- Setting up UBIK Backend ---"

# 1. Handle existing non-git directory
if [ -d "$UBIK_DIR" ] && [ ! -d "$UBIK_DIR/.git" ]; then
    echo "Renaming existing non-git directory $UBIK_DIR to $UBIK_DIR.old"
    mv "$UBIK_DIR" "$UBIK_DIR.old"
fi

# 2. Clone repo
if [ ! -d "$UBIK_DIR" ]; then
    echo "Cloning damienldx/ubik..."
    mkdir -p "$(dirname "$UBIK_DIR")"
    gh repo clone damienldx/ubik "$UBIK_DIR"
else
    echo "Repo already exists at $UBIK_DIR"
fi

# 3. Setup venv
if [ ! -d "$BACKEND_DIR/.venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$BACKEND_DIR/.venv"
fi

# 4. Install dependencies
echo "Installing dependencies..."
"$BACKEND_DIR/.venv/bin/pip" install fastapi "uvicorn[standard]" websockets python-dotenv

# 5. Create .env
echo "Creating .env file..."
cat <<EOF > "$BACKEND_DIR/.env"
UBIK_URL=http://localhost:8801
UBIK_API_KEY=ubik
EOF

# 6. Create systemd user service
SERVICE_DIR="$HOME/.config/systemd/user"
mkdir -p "$SERVICE_DIR"

echo "Creating systemd service..."
cat <<EOF > "$SERVICE_DIR/ubik-backend.service"
[Unit]
Description=UBIK Backend Service
After=network.target

[Service]
ExecStart=$BACKEND_DIR/.venv/bin/uvicorn server:app --host 127.0.0.1 --port 8765
WorkingDirectory=$BACKEND_DIR
Restart=always
Environment=PYTHONPATH=$BACKEND_DIR

[Install]
WantedBy=default.target
EOF

# 7. Enable and start
echo "Reloading systemd and starting service..."
systemctl --user daemon-reload
systemctl --user enable ubik-backend
systemctl --user restart ubik-backend

# 8. Status
echo "--- UBIK Backend Status ---"
systemctl --user status ubik-backend --no-pager
