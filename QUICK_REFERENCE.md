# Quick Reference Card

## Hardware Pins
| Pin | Function |
|-----|----------|
| 16  | LED |
| 17  | Button |
| 25  | Relay 1 (Dispenser 1) |
| 33  | Relay 2 (Dispenser 2) |
| 26  | Relay 3 (Dispenser 3) |
| 27  | Relay 4 (Dispenser 4) |

## LED Status
| Pattern | Meaning |
|---------|---------|
| Solid ON | Connected & Idle |
| Slow blink (1Hz) | WiFi Connecting |
| Fast blink (5Hz) | Dispensing |
| Pulse (2Hz) | Error |

## Button Functions
- **< 5 sec**: Test mode (all relays 3s)
- **> 5 sec**: WiFi config mode

## Server Commands

### Start Server
```bash
cd server
./start_server.sh
```

### Quick Tunnel
```bash
cloudflared tunnel --url http://localhost:5000
```

### Test API
```bash
python test_api.py
```

## API Quick Commands

### Get Values
```bash
curl http://localhost:5000/api/dispenser/get
```

### Set Values
```bash
curl -X POST http://localhost:5000/api/dispenser/set \
  -H "Content-Type: application/json" \
  -d '{"dispenser1":"5","dispenser2":"3","dispenser3":"2","dispenser4":"1"}'
```

### Reset Values
```bash
curl -X POST http://localhost:5000/api/dispenser/reset
```

## Troubleshooting

### WiFi Issues
- Long press button > 5 sec
- Connect to "PoolDispenser_AP"
- Reconfigure credentials

### Server Issues
```bash
# Kill process on port 5000
lsof -ti:5000 | xargs kill -9

# Restart
./start_server.sh
```

### ESP32 Debug
- Open Serial Monitor: 115200 baud
- Check WiFi connection status
- Verify API URL is correct

## Files to Edit

### Change API URL
`dispenser/firmware.ino` lines 13-14

### Change Dispenser Values
`server/dispenser_config.json`

### Server Config
`server/.env`

## Default Values
- Polling interval: 5 seconds
- Test duration: 3 seconds
- WiFi timeout: 180 seconds
- API timeout: 5 seconds

## Safety Checklist
- [ ] All connections waterproof
- [ ] Proper power supplies
- [ ] Chemical safety gear
- [ ] Test with water first
- [ ] Calibrate flow rates
- [ ] Monitor first cycles
