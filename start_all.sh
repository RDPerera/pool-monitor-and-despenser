#!/bin/bash

# Startup script for both Flask server and Cloudflare Tunnel
# This script ensures your server is accessible via the permanent tunnel

echo "======================================"
echo "Pool Monitor - Server & Tunnel Startup"
echo "======================================"
echo ""

# Function to check if a process is running
is_running() {
    pgrep -f "$1" > /dev/null 2>&1
}

# Start Flask Server
echo "Starting Flask Server..."
echo "----------------------"

# Navigate to server directory if not already there
if [ ! -f "main.py" ]; then
    cd server 2>/dev/null || {
        echo "❌ Cannot find server directory!"
        exit 1
    }
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo "✓ Virtual environment created"
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt
echo "✓ Dependencies installed"
echo ""

# Create default config if it doesn't exist
if [ ! -f "dispenser_config.json" ]; then
    echo "Creating default dispenser configuration..."
    cat > dispenser_config.json << 'EOF'
{
  "dispenser1": "0",
  "dispenser2": "0",
  "dispenser3": "0",
  "dispenser4": "0"
}
EOF
    echo "✓ Configuration created"
fi

# Start Flask server in background
# Read port from .env file if it exists
SERVER_PORT=$(grep -E "^PORT=" .env 2>/dev/null | cut -d'=' -f2 || echo "5000")
echo "Starting Flask server on port $SERVER_PORT..."
python3 main.py > server.log 2>&1 &
SERVER_PID=$!

# Wait a bit for server to start
sleep 3

if ps -p $SERVER_PID > /dev/null 2>&1; then
    echo "✓ Flask server started (PID: $SERVER_PID)"
    echo "  Logs: server/server.log"
else
    echo "❌ Failed to start Flask server"
    echo "Check server/server.log for errors"
    exit 1
fi

echo ""

# Check for Cloudflare Tunnel
echo "Cloudflare Tunnel Status"
echo "------------------------"

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "⚠️  cloudflared is not installed"
    echo ""
    echo "To set up permanent tunnel:"
    echo "  1. Install cloudflared:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "     brew install cloudflare/cloudflare/cloudflared"
    else
        echo "     See CLOUDFLARE_TUNNEL_SETUP.md"
    fi
    echo "  2. Run: ./setup_tunnel.sh"
    echo ""
    echo "Server is running locally at http://localhost:5000"
    exit 0
fi

# Check if tunnel is configured
if [ ! -f ~/.cloudflared/config.yml ]; then
    echo "⚠️  Cloudflare tunnel not configured"
    echo ""
    echo "To set up permanent tunnel, run:"
    echo "  ./setup_tunnel.sh"
    echo ""
    echo "Server is running locally at http://localhost:$SERVER_PORT"
    exit 0
fi

# Check if tunnel is already running
if is_running "cloudflared tunnel run"; then
    echo "✓ Cloudflare tunnel already running"
    
    # Extract hostname from config
    HOSTNAME=$(grep "hostname:" ~/.cloudflared/config.yml | head -1 | awk '{print $3}')
    if [ -n "$HOSTNAME" ]; then
        echo "  URL: https://$HOSTNAME"
    fi
else
    # Get tunnel name from config
    TUNNEL_ID=$(grep "tunnel:" ~/.cloudflared/config.yml | awk '{print $2}')
    
    if [ -z "$TUNNEL_ID" ]; then
        echo "⚠️  Cannot find tunnel configuration"
        echo "Run ./setup_tunnel.sh to configure"
    else
        echo "Starting Cloudflare tunnel..."
        
        # Start tunnel in background
        cloudflared tunnel run > tunnel.log 2>&1 &
        TUNNEL_PID=$!
        
        # Wait a bit for tunnel to start
        sleep 3
        
        if is_running "cloudflared tunnel run"; then
            echo "✓ Cloudflare tunnel started (PID: $TUNNEL_PID)"
            echo "  Logs: tunnel.log"
            
            # Extract hostname from config
            HOSTNAME=$(grep "hostname:" ~/.cloudflared/config.yml | head -1 | awk '{print $3}')
            if [ -n "$HOSTNAME" ]; then
                echo ""
                echo "======================================"
                echo "✓ All Services Running!"
                echo "======================================"
                echo ""
                echo "Local URL:  http://localhost:$SERVER_PORT"
                echo "Public URL: https://$HOSTNAME"
                echo ""
                echo "API Endpoints:"
                echo "  GET  https://$HOSTNAME/api/dispenser/get"
                echo "  POST https://$HOSTNAME/api/dispenser/set"
                echo ""
                echo "To stop services:"
                echo "  kill $SERVER_PID $TUNNEL_PID"
                echo ""
            fi
        else
            echo "❌ Failed to start tunnel"
            echo "Check tunnel.log for errors"
        fi
    fi
fi

echo ""
echo "Services are running in the background"
echo "Press Ctrl+C to return to terminal (services will continue running)"
echo ""

# Keep script running to show logs (optional)
# Uncomment the following lines if you want to see live logs:
# echo "=== Live Logs (Ctrl+C to stop) ==="
# tail -f server.log tunnel.log 2>/dev/null
