# Pool Chemical Dispenser System

Complete ESP32-based pool chemical dispenser with Python Flask server and Cloudflare tunnel support.

## Hardware Setup

### Components Required
- ESP32 Development Board
- 4-Channel Relay Module (5V)
- Push Button Switch
- LED
- 4x Water Pumps
- Resistors: 1x 10kΩ (button pull-up), 1x 220Ω (LED)
- Jumper wires

### Pin Connections

| Component | ESP32 Pin | Notes |
|-----------|-----------|-------|
| LED | GPIO 16 | Connect via 220Ω resistor |
| Button | GPIO 17 | Active LOW (grounds when pressed) |
| Relay 1 (Dispenser 1) | GPIO 25 | Controls pump for chemical 1 |
| Relay 2 (Dispenser 2) | GPIO 33 | Controls pump for chemical 2 |
| Relay 3 (Dispenser 3) | GPIO 26 | Controls pump for chemical 3 |
| Relay 4 (Dispenser 4) | GPIO 27 | Controls pump for chemical 4 |

### Wiring Diagram

```
ESP32                    4-Channel Relay Module
GPIO 25 ────────────────► IN1 (Relay 1) ──► Pump 1 (Chemical 1)
GPIO 33 ────────────────► IN2 (Relay 2) ──► Pump 2 (Chemical 2)
GPIO 26 ────────────────► IN3 (Relay 3) ──► Pump 3 (Chemical 3)
GPIO 27 ────────────────► IN4 (Relay 4) ──► Pump 4 (Chemical 4)

GPIO 16 ──[220Ω]──► LED ──► GND
GPIO 17 ──► Button ──► GND (with 10kΩ pull-up internally enabled)

5V/3.3V ────────────────► Relay Module VCC
GND ────────────────────► Relay Module GND
```

## Software Setup

### 1. ESP32 Firmware

#### Prerequisites
- Arduino IDE 1.8+ or 2.0+
- ESP32 Board Support (install via Board Manager)
- Required Libraries:
  - WiFiManager by tzapu
  - ArduinoJson by Benoit Blanchon (version 6.x)
  - HTTPClient (included with ESP32 core)

#### Installation Steps

1. **Install Arduino IDE**
   - Download from: https://www.arduino.cc/en/software

2. **Add ESP32 Board Support**
   - File → Preferences
   - Add to "Additional Board Manager URLs":
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Tools → Board → Boards Manager
   - Search "ESP32" and install "esp32 by Espressif Systems"

3. **Install Required Libraries**
   - Tools → Manage Libraries
   - Search and install:
     - "WiFiManager" by tzapu
     - "ArduinoJson" by Benoit Blanchon

4. **Configure and Upload**
   - Open `dispenser/firmware.ino`
   - Update API URLs (lines 13-14) with your Cloudflare tunnel URL:
     ```cpp
     const char* API_GET_URL = "https://your-tunnel-url.trycloudflare.com/api/dispenser/get";
     const char* API_RESET_URL = "https://your-tunnel-url.trycloudflare.com/api/dispenser/reset";
     ```
   - Select your ESP32 board: Tools → Board → ESP32 Dev Module
   - Select the correct COM port: Tools → Port
   - Click Upload

### 2. Python Server

#### Prerequisites
- Python 3.8+
- pip

#### Installation

1. **Navigate to server directory**
   ```bash
   cd server
   ```

2. **Install dependencies**
   ```bash
   pip install flask flask-cors flask-sqlalchemy python-dotenv pyjwt werkzeug
   ```

3. **Run the server**
   ```bash
   python main.py
   ```

The server will start on `http://0.0.0.0:5000`

### 3. Cloudflare Tunnel Setup

Cloudflare Tunnel provides a secure way to expose your local server without opening ports or changing your router settings.

#### Installation

1. **Install Cloudflare Tunnel (cloudflared)**

   **macOS (Homebrew):**
   ```bash
   brew install cloudflare/cloudflare/cloudflared
   ```

   **Linux:**
   ```bash
   wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
   sudo dpkg -i cloudflared-linux-amd64.deb
   ```

   **Windows:**
   Download from: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/

2. **Login to Cloudflare**
   ```bash
   cloudflared tunnel login
   ```
   This will open a browser for authentication.

3. **Create a tunnel**
   ```bash
   cloudflared tunnel create pool-dispenser
   ```
   Save the tunnel ID shown.

4. **Create config file**
   Create `~/.cloudflared/config.yml`:
   ```yaml
   tunnel: <your-tunnel-id>
   credentials-file: /Users/<your-username>/.cloudflared/<tunnel-id>.json

   ingress:
     - hostname: pool-dispenser.yourdomain.com
       service: http://localhost:5000
     - service: http_status:404
   ```

5. **Route DNS**
   ```bash
   cloudflared tunnel route dns pool-dispenser pool-dispenser.yourdomain.com
   ```

6. **Run the tunnel**
   ```bash
   cloudflared tunnel run pool-dispenser
   ```

#### Quick Test Mode (No Domain Required)

For testing without a domain:
```bash
cloudflared tunnel --url http://localhost:5000
```

This will give you a temporary URL like: `https://random-words.trycloudflare.com`

**Update your ESP32 firmware with this URL!**

## Usage

### Initial Setup (ESP32)

1. **Power on the ESP32**
2. **Long press button (>5 seconds)** to enter WiFi configuration mode
3. **Connect to WiFi network** "PoolDispenser_AP" from your phone/computer
4. **Configure WiFi**:
   - Browser will auto-open to configuration page
   - Enter your home WiFi SSID and password
   - Click Save
5. **ESP32 will restart** and connect to your WiFi

### LED Status Indicators

| LED Pattern | Meaning |
|-------------|---------|
| Solid ON | Connected and idle |
| Slow blink (1 Hz) | Connecting to WiFi |
| Fast blink (5 Hz) | Dispensing chemicals |
| Pulse (2 Hz) | Error / No API response |

### Setting Dispenser Times

#### Option 1: Using API (Python/curl)

```bash
# Set dispenser times (in seconds)
curl -X POST http://localhost:5000/api/dispenser/set \
  -H "Content-Type: application/json" \
  -d '{
    "dispenser1": "5",
    "dispenser2": "3",
    "dispenser3": "2",
    "dispenser4": "4"
  }'
```

#### Option 2: Edit JSON file directly

Edit `server/dispenser_config.json`:
```json
{
  "dispenser1": "5",
  "dispenser2": "3",
  "dispenser3": "2",
  "dispenser4": "4"
}
```

### Operation Flow

1. **ESP32 polls API** every 5 seconds
2. **Server responds** with dispenser times from JSON file
3. **If any time > 0**: ESP32 activates corresponding relays
4. **After dispensing**: ESP32 calls reset API (sets all to "0")
5. **Repeat**: ESP32 continues polling for next job

### Test Mode

**Press button briefly** (< 5 seconds):
- All relays turn ON for 3 seconds
- Useful for testing pump operation

### Reconfigure WiFi

**Long press button** (> 5 seconds) at any time:
- ESP32 enters WiFi configuration mode
- Connect to "PoolDispenser_AP" and reconfigure

## API Endpoints

### Get Dispenser Values
```
GET /api/dispenser/get
Response: {
  "dispenser1": "3",
  "dispenser2": "2",
  "dispenser3": "1",
  "dispenser4": "0"
}
```

### Set Dispenser Values
```
POST /api/dispenser/set
Body: {
  "dispenser1": "5",
  "dispenser2": "3",
  "dispenser3": "2",
  "dispenser4": "4"
}
```

### Reset Dispenser Values
```
POST /api/dispenser/reset
Response: {
  "message": "Dispenser values reset successfully",
  "config": {
    "dispenser1": "0",
    "dispenser2": "0",
    "dispenser3": "0",
    "dispenser4": "0"
  }
}
```

## Troubleshooting

### ESP32 Issues

**Won't connect to WiFi:**
- Long press button to reconfigure
- Check WiFi credentials
- Ensure 2.4GHz WiFi (ESP32 doesn't support 5GHz)

**Can't upload firmware:**
- Hold BOOT button while clicking Upload
- Check correct COM port selected
- Install CP210x or CH340 drivers if needed

**Relays not working:**
- Check relay module power supply (5V)
- Verify pin connections
- Some relay modules are active LOW (reverse logic)

### Server Issues

**Port already in use:**
```bash
# Find and kill process on port 5000
lsof -ti:5000 | xargs kill -9
```

**Dependencies missing:**
```bash
pip install -r requirements.txt
```

### Cloudflare Tunnel Issues

**Tunnel disconnects:**
- Run as service (see Cloudflare docs)
- Check network connectivity

**DNS not resolving:**
```bash
cloudflared tunnel route dns pool-dispenser pool-dispenser.yourdomain.com
```

## Safety Notes

⚠️ **IMPORTANT SAFETY WARNINGS**

1. **Electrical Safety**:
   - Never connect mains voltage (110V/220V) directly to ESP32
   - Use appropriate relay ratings for your pumps
   - Ensure proper grounding

2. **Chemical Safety**:
   - Handle pool chemicals with care
   - Ensure proper ventilation
   - Keep chemicals in approved containers
   - Never mix chemicals

3. **Water Safety**:
   - Test water quality after dispensing
   - Start with small amounts to calibrate
   - Monitor pool chemistry regularly

4. **Testing**:
   - Test with water before connecting chemicals
   - Verify pump directions and flow rates
   - Check for leaks in tubing

## File Structure

```
pool-monitor-and-despenser/
├── dispenser/
│   └── firmware.ino          # ESP32 firmware
├── server/
│   ├── main.py                # Flask server with dispenser API
│   └── dispenser_config.json  # Dispenser configuration
└── DISPENSER_SETUP.md         # This file
```

## License

MIT License - Feel free to modify and use for your projects!

## Support

For issues or questions:
1. Check troubleshooting section above
2. Verify all connections and configurations
3. Check serial monitor output (115200 baud) for debugging

## Future Enhancements

- [ ] Web dashboard for remote control
- [ ] Historical dispensing logs
- [ ] Automated scheduling
- [ ] Integration with pool sensor readings
- [ ] Mobile app control
- [ ] Email/SMS notifications
