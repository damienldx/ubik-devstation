#!/bin/bash
set -e

echo "--- Setup UBIK Fleet on dev-station-02 ---"

# 1. Clone or Update ubik-fleet
mkdir -p ~/workspace
if [ ! -d "$HOME/workspace/ubik-fleet" ]; then
    echo "Cloning ubik-fleet..."
    gh repo clone damienldx/ubik-fleet ~/workspace/ubik-fleet
else
    echo "Updating ubik-fleet..."
    git -C ~/workspace/ubik-fleet pull
fi

# 2. Dependencies
echo "Installing dependencies..."
pip3 install --user requests --break-system-packages 2>/dev/null || python3 -c "import requests" 2>/dev/null || true

# 3. Systemd User Directory
mkdir -p ~/.config/systemd/user/

# 4. Create ubik-relay.service
echo "Creating ubik-relay.service..."
cat <<EOF > ~/.config/systemd/user/ubik-relay.service
[Unit]
Description=UBIK Relay
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/damienldx/workspace/ubik-fleet/fleet/mcp_relay.py
WorkingDirectory=/home/damienldx/workspace/ubik-fleet/fleet
Environment=RELAY_PORT=7894
Restart=always

[Install]
WantedBy=default.target
EOF

# 5. Create ubik-fleet-worker.service
echo "Creating ubik-fleet-worker.service..."
cat <<EOF > ~/.config/systemd/user/ubik-fleet-worker.service
[Unit]
Description=UBIK Fleet Worker
After=ubik-relay.service

[Service]
ExecStart=/usr/bin/python3 /home/damienldx/workspace/ubik-fleet/fleet/agent_worker.py dev-station-02
WorkingDirectory=/home/damienldx/workspace/ubik-fleet/fleet
Environment=RELAY_URL=http://127.0.0.1:7894
Restart=always

[Install]
WantedBy=default.target
EOF

# 6. Enable and Start Services
echo "Reloading systemd and starting services..."
systemctl --user daemon-reload
systemctl --user enable --now ubik-relay ubik-fleet-worker

# 7. Status
echo "Checking status..."
systemctl --user status ubik-relay ubik-fleet-worker --no-pager
