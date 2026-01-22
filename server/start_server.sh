#!/bin/bash

# Pool Dispenser Server Startup Script

echo "==================================="
echo "Pool Chemical Dispenser Server"
echo "==================================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed!"
    echo "Please install Python 3.8 or higher"
    exit 1
fi

echo "✓ Python $(python3 --version) found"
echo ""

# Check if we're in the server directory
if [ ! -f "main.py" ]; then
    echo "Navigating to server directory..."
    cd server
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo "✓ Virtual environment created"
    echo ""
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate
echo ""

# Install/update dependencies
echo "Installing dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt
echo "✓ Dependencies installed"
echo ""

# Create default config if it doesn't exist
if [ ! -f "dispenser_config.json" ]; then
    echo "Creating default dispenser configuration..."
    cat > dispenser_config.json << EOF
{
  "dispenser1": "0",
  "dispenser2": "0",
  "dispenser3": "0",
  "dispenser4": "0"
}
EOF
    echo "✓ Configuration file created"
    echo ""
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env configuration..."
    cat > .env << EOF
DATABASE_URL=sqlite:///pool_monitor.db
PORT=5000
DEBUG=True
JWT_SECRET_KEY=change-this-in-production-$(date +%s)
EOF
    echo "✓ .env file created"
    echo ""
fi

echo "==================================="
echo "Starting Flask Server..."
echo "==================================="
echo ""
echo "Server will be available at:"
echo "  Local:   http://localhost:5000"
echo "  Network: http://$(ipconfig getifaddr en0 2>/dev/null || hostname -I | awk '{print $1}'):5000"
echo ""
echo "Dispenser API Endpoints:"
echo "  GET  http://localhost:5000/api/dispenser/get"
echo "  POST http://localhost:5000/api/dispenser/set"
echo "  POST http://localhost:5000/api/dispenser/reset"
echo ""
echo "Press Ctrl+C to stop the server"
echo "==================================="
echo ""

# Run the server
python3 main.py
