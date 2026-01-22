# 🏊‍♂️ ESP32 Pool Chemical Dispenser System

A complete IoT solution for automated pool chemical dispensing using ESP32, WiFi Manager, Flask server, and Cloudflare Tunnel.

## ✨ Features

- **WiFi Manager Integration**: Easy setup via captive portal (no hardcoded credentials!)
- **4 Independent Dispensers**: Control 4 separate chemical pumps
- **Remote Control**: Control from anywhere via Cloudflare Tunnel
- **LED Status Indicators**: Visual feedback for all states
- **Test Mode**: Quick button press to test all pumps
- **Automatic Polling**: ESP32 checks for jobs every 5 seconds
- **Auto-Reset**: Automatically resets after dispensing
- **JSON Configuration**: Easy-to-modify dispenser settings
- **RESTful API**: Simple HTTP API for integration

## 📋 Table of Contents

- [Hardware Requirements](#hardware-requirements)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [API Documentation](#api-documentation)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Safety](#safety)

## 🔧 Hardware Requirements

### Components

| Component | Quantity | Notes |
|-----------|----------|-------|
| ESP32 Dev Board | 1 | Any ESP32 will work |
| 4-Channel Relay Module | 1 | 5V, optocoupler isolated |
| Water Pumps | 4 | 12V DC peristaltic pumps recommended |
| LED | 1 | Any color |
| Push Button | 1 | Momentary, normally open |
| Resistors | 2 | 220Ω (LED), 10kΩ (button) optional |
| Power Supply | 1 | 5V for ESP32, 12V for pumps |
| Jumper Wires | - | As needed |

### Pin Connections

```
ESP32          Component
------         ---------
GPIO 16   →    LED (+) via 220Ω resistor to GND
GPIO 17   →    Button → GND (internal pull-up enabled)
GPIO 25   →    Relay 1 (Dispenser 1 / Chemical 1)
GPIO 33   →    Relay 2 (Dispenser 2 / Chemical 2)
GPIO 26   →    Relay 3 (Dispenser 3 / Chemical 3)
GPIO 27   →    Relay 4 (Dispenser 4 / Chemical 4)
```

## 🚀 Quick Start

### 1. Server Setup (5 minutes)

```bash
# Navigate to server directory
cd server

# Run the startup script (it handles everything!)
./start_server.sh
```

The server will start on `http://localhost:5000`

### 2. Cloudflare Tunnel (2 minutes for testing)

```bash
# Quick tunnel (temporary URL)
cloudflared tunnel --url http://localhost:5000

# Note the URL: https://xxx-xxx-xxx.trycloudflare.com
```

For permanent setup, see [CLOUDFLARE_TUNNEL_SETUP.md](CLOUDFLARE_TUNNEL_SETUP.md)

### 3. Update ESP32 Firmware

1. Open `dispenser/firmware.ino` in Arduino IDE
2. Update lines 13-14 with your Cloudflare tunnel URL:
   ```cpp
   const char* API_GET_URL = "https://your-url.trycloudflare.com/api/dispenser/get";
   const char* API_RESET_URL = "https://your-url.trycloudflare.com/api/dispenser/reset";
   ```
3. Upload to ESP32

### 4. Configure WiFi

1. Power on ESP32
2. Long press button (>5 seconds)
3. Connect to WiFi network: `PoolDispenser_AP`
4. Enter your home WiFi credentials
5. Done! ESP32 will connect and start polling

### 5. Test It!

```bash
# In another terminal
cd server
python test_api.py

# Or manually:
curl -X POST http://localhost:5000/api/dispenser/set \
  -H "Content-Type: application/json" \
  -d '{"dispenser1":"3","dispenser2":"2","dispenser3":"1","dispenser4":"1"}'
```

Watch your ESP32! It will activate the relays for the specified durations.

## 📖 Detailed Setup

See comprehensive guides:
- **[DISPENSER_SETUP.md](DISPENSER_SETUP.md)** - Complete hardware & software setup
- **[CLOUDFLARE_TUNNEL_SETUP.md](CLOUDFLARE_TUNNEL_SETUP.md)** - Tunnel configuration

## 📡 API Documentation

### Base URL
- Local: `http://localhost:5000`
- Tunnel: `https://your-domain.trycloudflare.com`

### Endpoints

#### Get Dispenser Values
```http
GET /api/dispenser/get
```

**Response:**
```json
{
  "dispenser1": "0",
  "dispenser2": "0",
  "dispenser3": "0",
  "dispenser4": "0"
}
```

#### Set Dispenser Values
```http
POST /api/dispenser/set
Content-Type: application/json

{
  "dispenser1": "5",
  "dispenser2": "3",
  "dispenser3": "2",
  "dispenser4": "4"
}
```

**Response:**
```json
{
  "message": "Dispenser values updated successfully",
  "config": {
    "dispenser1": "5",
    "dispenser2": "3",
    "dispenser3": "2",
    "dispenser4": "4"
  }
}
```

#### Reset Dispenser Values
```http
POST /api/dispenser/reset
```

**Response:**
```json
{
  "message": "Dispenser values reset successfully",
  "config": {
    "dispenser1": "0",
    "dispenser2": "0",
    "dispenser3": "0",
    "dispenser4": "0"
  }
}
```

### Value Format
- Values are strings representing **seconds**
- Range: `"0"` to `"999"` (0 to ~16 minutes)
- `"0"` means dispenser will be skipped

## 💡 Usage

### Setting Dispensing Times

**Method 1: API Call**
```bash
curl -X POST http://localhost:5000/api/dispenser/set \
  -H "Content-Type: application/json" \
  -d '{"dispenser1":"5","dispenser2":"3","dispenser3":"0","dispenser4":"2"}'
```

**Method 2: Edit JSON File**
Edit `server/dispenser_config.json`:
```json
{
  "dispenser1": "5",
  "dispenser2": "3",
  "dispenser3": "0",
  "dispenser4": "2"
}
```

**Method 3: Test Script (Interactive)**
```bash
cd server
python test_api.py
# Follow prompts
```

### ESP32 Operation

#### LED Status

| Pattern | Meaning |
|---------|---------|
| 🟢 Solid ON | Connected, idle |
| 🔵 Slow blink | Connecting to WiFi |
| 🔴 Fast blink | Dispensing chemicals |
| 🟡 Pulse | Error / No API response |

#### Button Functions

| Press Duration | Action |
|----------------|--------|
| < 5 seconds | **Test Mode**: All relays ON for 3 seconds |
| > 5 seconds | **WiFi Config**: Enter setup mode |

### Typical Workflow

1. **Set dispenser times** via API or JSON file
2. **ESP32 polls** API every 5 seconds
3. **Detects non-zero values** and activates relays
4. **Dispenses chemicals** for specified durations
5. **Calls reset API** when complete (sets all to "0")
6. **Returns to polling** for next job

## 🧪 Testing

### Test Server API

```bash
cd server

# Run all tests
python test_api.py

# Or specific commands:
python test_api.py get              # Get current values
python test_api.py set 5 3 2 1      # Set values
python test_api.py reset            # Reset to zero
python test_api.py poll             # Simulate ESP32 polling
```

### Test ESP32 Hardware

1. **Test Mode**: Short press button → All relays ON for 3 seconds
2. **Serial Monitor**: Open at 115200 baud to see debug output
3. **LED Test**: Watch status indicators during operation

## 🔍 Troubleshooting

### ESP32 Won't Connect to WiFi

- **Solution 1**: Long press button > 5 seconds, reconfigure
- **Solution 2**: Check Serial Monitor (115200 baud) for errors
- **Solution 3**: Ensure WiFi is 2.4GHz (ESP32 doesn't support 5GHz)

### Relays Not Activating

- Check relay module power (5V)
- Verify pin connections match firmware
- Some relays are active-LOW (swap HIGH/LOW in code)
- Test with button short-press (test mode)

### API Not Responding

- Verify server is running: `curl http://localhost:5000/api/dispenser/get`
- Check firewall isn't blocking port 5000
- Ensure ESP32 has correct API URL
- Check Cloudflare tunnel is running

### ESP32 Can't Reach API

- Verify tunnel URL in firmware
- Test URL from browser first
- Check ESP32 Serial Monitor for HTTP errors
- Ensure ESP32 has internet access

### Server Won't Start

```bash
# Check if port is in use
lsof -i :5000

# Kill process if needed
kill -9 <PID>

# Restart server
./start_server.sh
```

## ⚠️ Safety

### Electrical Safety
- ⚡ Use proper power supplies (5V for ESP32, appropriate voltage for pumps)
- ⚡ Never expose electronics to water
- ⚡ Use waterproof enclosures for outdoor installation
- ⚡ Ensure proper grounding

### Chemical Safety
- 🧪 Handle pool chemicals with care (gloves, goggles)
- 🧪 Never mix different chemicals directly
- 🧪 Use appropriate tubing for chemicals
- 🧪 Store chemicals in original containers
- 🧪 Follow manufacturer safety guidelines

### Calibration
- 📏 Start with SHORT durations to test flow rates
- 📏 Measure actual chemical volumes dispensed
- 📏 Calculate proper timing for your desired doses
- 📏 Test water chemistry after dispensing

### Monitoring
- 👀 Monitor first few cycles closely
- 👀 Test pool water chemistry regularly
- 👀 Check for leaks in tubing
- 👀 Verify pumps are operating correctly

## 📁 Project Structure

```
pool-monitor-and-despenser/
├── dispenser/
│   └── firmware.ino              # ESP32 Arduino code
├── server/
│   ├── main.py                   # Flask server
│   ├── dispenser_config.json     # Configuration file
│   ├── requirements.txt          # Python dependencies
│   ├── start_server.sh          # Server startup script
│   └── test_api.py              # API testing tool
├── DISPENSER_SETUP.md           # Detailed setup guide
├── CLOUDFLARE_TUNNEL_SETUP.md   # Tunnel configuration guide
└── DISPENSER_README.md          # This file
```

## 🔄 System Architecture

```
┌─────────────┐         WiFi         ┌─────────────┐
│   ESP32     │◄────────────────────►│   Router    │
│  Dispenser  │                      └──────┬──────┘
└──────┬──────┘                             │
       │                                    │
       │ Controls                           │ Internet
       │                                    │
       ▼                           ┌────────▼─────────┐
┌─────────────┐                   │  Cloudflare      │
│   4-Relay   │                   │  Tunnel          │
│   Module    │                   └────────┬─────────┘
└──────┬──────┘                            │
       │                                   │ HTTPS
       │                          ┌────────▼─────────┐
       ▼                          │   Flask Server   │
┌─────────────┐                  │   (localhost)    │
│  Chemical   │                  │                  │
│   Pumps     │                  │ - GET /get       │
│  (1,2,3,4)  │                  │ - POST /set      │
└─────────────┘                  │ - POST /reset    │
                                 └──────────────────┘
```

## 🛠️ Advanced Configuration

### Adjust Polling Interval

Edit `firmware.ino` line 18:
```cpp
const unsigned long API_CALL_INTERVAL = 5000;  // Change to desired ms
```

### Change Test Duration

Edit `firmware.ino` line 20:
```cpp
const unsigned long TEST_DURATION = 3000;  // Change to desired ms
```

### Add More Dispensers

1. Add relay pins in firmware
2. Update API endpoints in `main.py`
3. Extend JSON config structure

## 📝 TODO / Future Enhancements

- [ ] Web dashboard for visual control
- [ ] Mobile app (Flutter app in repo could be adapted!)
- [ ] Scheduling system (dispense at specific times)
- [ ] Integration with pool sensors for automatic dosing
- [ ] Historical logging and analytics
- [ ] Email/SMS notifications
- [ ] Multi-device support
- [ ] OTA firmware updates

## 📜 License

MIT License - Free to use and modify!

## 🤝 Contributing

Contributions welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

## 📞 Support

Having issues? Check:
1. [DISPENSER_SETUP.md](DISPENSER_SETUP.md) - Setup troubleshooting
2. [CLOUDFLARE_TUNNEL_SETUP.md](CLOUDFLARE_TUNNEL_SETUP.md) - Tunnel issues
3. Serial Monitor output (115200 baud)
4. Server logs

## ⭐ Credits

Built with:
- ESP32 by Espressif
- Arduino framework
- WiFiManager by tzapu
- Flask web framework
- Cloudflare Tunnel
- ArduinoJson library

---

**Happy Pool Maintaining! 🏊‍♂️💧**

Made with ❤️ for automated pool care
