#!/bin/bash

# Cloudflare Tunnel Setup Script
# This script helps you create and configure a permanent Cloudflare Tunnel

set -e

echo "======================================"
echo "Cloudflare Tunnel Setup"
echo "======================================"
echo ""

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "❌ cloudflared is not installed!"
    echo ""
    echo "Please install it first:"
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  brew install cloudflare/cloudflare/cloudflared"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "  wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
        echo "  sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared"
        echo "  sudo chmod +x /usr/local/bin/cloudflared"
    fi
    echo ""
    exit 1
fi

echo "✓ cloudflared is installed: $(cloudflared --version | head -n1)"
echo ""

# Check if already logged in
if [ ! -f ~/.cloudflared/cert.pem ]; then
    echo "Step 1: Login to Cloudflare"
    echo "============================="
    echo "This will open your browser to authenticate..."
    echo ""
    cloudflared tunnel login
    echo ""
    echo "✓ Login successful!"
    echo ""
else
    echo "✓ Already logged in to Cloudflare"
    echo ""
fi

# Get tunnel name
read -p "Enter a name for your tunnel (e.g., pool-dispenser): " TUNNEL_NAME
if [ -z "$TUNNEL_NAME" ]; then
    TUNNEL_NAME="pool-dispenser"
fi

# Check if tunnel already exists
EXISTING_TUNNEL=$(cloudflared tunnel list | grep -w "$TUNNEL_NAME" || true)

if [ -n "$EXISTING_TUNNEL" ]; then
    echo ""
    echo "⚠️  Tunnel '$TUNNEL_NAME' already exists!"
    echo "$EXISTING_TUNNEL"
    read -p "Do you want to use the existing tunnel? (y/n): " USE_EXISTING
    
    if [[ "$USE_EXISTING" =~ ^[Yy]$ ]]; then
        TUNNEL_ID=$(echo "$EXISTING_TUNNEL" | awk '{print $1}')
        echo "Using existing tunnel ID: $TUNNEL_ID"
    else
        read -p "Enter a different tunnel name: " TUNNEL_NAME
        echo ""
        echo "Step 2: Creating Tunnel"
        echo "======================="
        TUNNEL_OUTPUT=$(cloudflared tunnel create "$TUNNEL_NAME")
        echo "$TUNNEL_OUTPUT"
        TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -oP 'with id \K[^\s]+')
        echo ""
        echo "✓ Tunnel created with ID: $TUNNEL_ID"
    fi
else
    echo ""
    echo "Step 2: Creating Tunnel"
    echo "======================="
    TUNNEL_OUTPUT=$(cloudflared tunnel create "$TUNNEL_NAME")
    echo "$TUNNEL_OUTPUT"
    TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -oP 'with id \K[^\s]+' || echo "$TUNNEL_OUTPUT" | awk '/with id/{print $NF}')
    echo ""
    echo "✓ Tunnel created with ID: $TUNNEL_ID"
fi

echo ""
echo "Step 3: Configure DNS"
echo "====================="
read -p "Enter your domain/subdomain (e.g., pool.yourdomain.com): " HOSTNAME

if [ -z "$HOSTNAME" ]; then
    echo "❌ Hostname is required!"
    exit 1
fi

echo ""
echo "Creating DNS record..."
cloudflared tunnel route dns "$TUNNEL_NAME" "$HOSTNAME"
echo "✓ DNS configured for $HOSTNAME"
echo ""

# Create config file
echo "Step 4: Creating Configuration"
echo "=============================="

CONFIG_DIR=~/.cloudflared
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/config.yml" << EOF
tunnel: $TUNNEL_ID
credentials-file: $CONFIG_DIR/$TUNNEL_ID.json

ingress:
  # Route to your Flask server
  - hostname: $HOSTNAME
    service: http://localhost:5000
  
  # Catch-all rule (required)
  - service: http_status:404
EOF

echo "✓ Configuration saved to $CONFIG_DIR/config.yml"
echo ""

# Save config info to project
cat > "$(dirname "$0")/tunnel_info.txt" << EOF
Tunnel Name: $TUNNEL_NAME
Tunnel ID: $TUNNEL_ID
Hostname: $HOSTNAME
Created: $(date)

Configuration file: $CONFIG_DIR/config.yml
Credentials file: $CONFIG_DIR/$TUNNEL_ID.json

To start the tunnel manually:
  cloudflared tunnel run $TUNNEL_NAME

To install as a service:
  sudo cloudflared service install

Your API will be available at:
  https://$HOSTNAME/api/dispenser/get
  https://$HOSTNAME/api/dispenser/set
EOF

echo "✓ Tunnel information saved to tunnel_info.txt"
echo ""

echo "Step 5: Install as System Service (Optional)"
echo "============================================"
read -p "Do you want to install the tunnel as a system service (auto-start on boot)? (y/n): " INSTALL_SERVICE

if [[ "$INSTALL_SERVICE" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Installing service..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sudo cloudflared service install
        echo "✓ Service installed (macOS launchd)"
        echo ""
        echo "Service commands:"
        echo "  Start:   sudo launchctl start com.cloudflare.cloudflared"
        echo "  Stop:    sudo launchctl stop com.cloudflare.cloudflared"
        echo "  Status:  sudo launchctl list | grep cloudflared"
    else
        # Linux
        sudo cloudflared service install
        sudo systemctl enable cloudflared
        sudo systemctl start cloudflared
        echo "✓ Service installed and started (systemd)"
        echo ""
        echo "Service commands:"
        echo "  Start:   sudo systemctl start cloudflared"
        echo "  Stop:    sudo systemctl stop cloudflared"
        echo "  Status:  sudo systemctl status cloudflared"
        echo "  Logs:    sudo journalctl -u cloudflared -f"
    fi
else
    echo ""
    echo "Skipped service installation."
    echo "You can install it later with: sudo cloudflared service install"
fi

echo ""
echo "======================================"
echo "✓ Setup Complete!"
echo "======================================"
echo ""
echo "Your tunnel is ready!"
echo "URL: https://$HOSTNAME"
echo ""
echo "Next steps:"
echo "1. Make sure your Flask server is running (./start_server.sh)"
echo "2. Start the tunnel:"
echo "   cloudflared tunnel run $TUNNEL_NAME"
echo ""
echo "3. Test your API:"
echo "   curl https://$HOSTNAME/api/dispenser/get"
echo ""
echo "4. Update your ESP32 firmware with the new URL:"
echo "   https://$HOSTNAME/api/dispenser/get"
echo "   https://$HOSTNAME/api/dispenser/set"
echo ""
echo "Configuration saved in:"
echo "  - ~/.cloudflared/config.yml"
echo "  - ./tunnel_info.txt"
echo ""
