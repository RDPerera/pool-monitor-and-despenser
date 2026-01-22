# Cloudflare Tunnel Setup Guide

This guide will help you set up a Cloudflare Tunnel to securely expose your local server to the internet with a permanent URL.

## Why Cloudflare Tunnel?

- ✅ No port forwarding needed
- ✅ No dynamic DNS required
- ✅ Free SSL/HTTPS encryption
- ✅ DDoS protection included
- ✅ Works behind NAT/firewalls
- ✅ Static URL that won't change

## Prerequisites

- Cloudflare account (free tier works!)
- A domain name managed by Cloudflare (or willing to transfer)
- Server running on localhost:5000

## Option 1: Quick Test (No Domain Required)

Perfect for immediate testing before setting up a permanent tunnel.

### Step 1: Install cloudflared

**macOS:**
```bash
brew install cloudflare/cloudflare/cloudflared
```

**Linux:**
```bash
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared
```

**Windows:**
Download from: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/

### Step 2: Start Quick Tunnel

```bash
cloudflared tunnel --url http://localhost:5000
```

You'll see output like:
```
Your quick Tunnel has been created! Visit it at:
https://random-words-1234.trycloudflare.com
```

### Step 3: Update ESP32 Firmware

Open `dispenser/firmware.ino` and update:

```cpp
const char* API_GET_URL = "https://random-words-1234.trycloudflare.com/api/dispenser/get";
const char* API_RESET_URL = "https://random-words-1234.trycloudflare.com/api/dispenser/reset";
```

**⚠️ Important:** Quick tunnel URLs are temporary and will change each time you restart!

---

## Option 2: Permanent Tunnel (Recommended for Production)

### Step 1: Install cloudflared

Same as Option 1 above.

### Step 2: Login to Cloudflare

```bash
cloudflared tunnel login
```

This will:
1. Open your browser
2. Ask you to select a domain
3. Download a certificate to `~/.cloudflared/cert.pem`

### Step 3: Create a Tunnel

```bash
cloudflared tunnel create pool-dispenser
```

Output will show:
```
Tunnel credentials written to ~/.cloudflared/<TUNNEL-ID>.json
Created tunnel pool-dispenser with id <TUNNEL-ID>
```

**Save the TUNNEL-ID!** You'll need it.

### Step 4: Create Configuration File

Create `~/.cloudflared/config.yml`:

```yaml
tunnel: <YOUR-TUNNEL-ID>
credentials-file: ~/.cloudflared/<YOUR-TUNNEL-ID>.json

ingress:
  # Route to your Flask server
  - hostname: pool.yourdomain.com
    service: http://localhost:5000
  
  # Catch-all rule (required)
  - service: http_status:404
```

**Replace:**
- `<YOUR-TUNNEL-ID>` with your actual tunnel ID
- `pool.yourdomain.com` with your desired subdomain

### Step 5: Configure DNS

```bash
cloudflared tunnel route dns pool-dispenser pool.yourdomain.com
```

This automatically creates a CNAME record in Cloudflare DNS.

### Step 6: Run the Tunnel

```bash
cloudflared tunnel run pool-dispenser
```

Your server is now accessible at: `https://pool.yourdomain.com`

### Step 7: Update ESP32 Firmware

```cpp
const char* API_GET_URL = "https://pool.yourdomain.com/api/dispenser/get";
const char* API_RESET_URL = "https://pool.yourdomain.com/api/dispenser/reset";
```

---

## Running as a Service (Auto-start on Boot)

### macOS/Linux

Create a systemd service or use launchd:

**systemd (Linux):**

Create `/etc/systemd/system/cloudflared.service`:

```ini
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=yourusername
ExecStart=/usr/local/bin/cloudflared tunnel run pool-dispenser
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared
```

**macOS launchd:**

```bash
cloudflared service install
```

### Windows

```bash
cloudflared service install
```

---

## Testing Your Setup

### 1. Test from Command Line

```bash
# Get current values
curl https://pool.yourdomain.com/api/dispenser/get

# Set values
curl -X POST https://pool.yourdomain.com/api/dispenser/set \
  -H "Content-Type: application/json" \
  -d '{"dispenser1":"5","dispenser2":"3","dispenser3":"2","dispenser4":"1"}'

# Reset values
curl -X POST https://pool.yourdomain.com/api/dispenser/reset
```

### 2. Test from Browser

Open: `https://pool.yourdomain.com/api/dispenser/get`

You should see:
```json
{
  "dispenser1": "0",
  "dispenser2": "0",
  "dispenser3": "0",
  "dispenser4": "0"
}
```

### 3. Use Test Script

```bash
cd server
python test_api.py
```

Update `BASE_URL` in the script first!

---

## Advanced Configuration

### Multiple Services on Different Subdomains

Edit `~/.cloudflared/config.yml`:

```yaml
tunnel: <YOUR-TUNNEL-ID>
credentials-file: ~/.cloudflared/<YOUR-TUNNEL-ID>.json

ingress:
  # API subdomain
  - hostname: api.yourdomain.com
    service: http://localhost:5000
  
  # Web dashboard subdomain (if you build one)
  - hostname: dashboard.yourdomain.com
    service: http://localhost:3000
  
  # Catch-all
  - service: http_status:404
```

Route both:
```bash
cloudflared tunnel route dns pool-dispenser api.yourdomain.com
cloudflared tunnel route dns pool-dispenser dashboard.yourdomain.com
```

### Path-Based Routing

```yaml
ingress:
  - hostname: pool.yourdomain.com
    path: ^/api/.*
    service: http://localhost:5000
  
  - hostname: pool.yourdomain.com
    service: http://localhost:3000  # Serve web app on /
  
  - service: http_status:404
```

---

## Troubleshooting

### Tunnel won't start

**Check tunnel status:**
```bash
cloudflared tunnel info pool-dispenser
```

**Check logs:**
```bash
cloudflared tunnel run pool-dispenser --loglevel debug
```

### DNS not resolving

**Verify DNS record exists:**
```bash
nslookup pool.yourdomain.com
```

Should return a CNAME to `<tunnel-id>.cfargotunnel.com`

**Manually add DNS if needed:**
1. Go to Cloudflare Dashboard
2. Select your domain
3. DNS → Add Record
4. Type: CNAME
5. Name: pool
6. Target: `<tunnel-id>.cfargotunnel.com`
7. Proxy status: Proxied (orange cloud)

### 502 Bad Gateway

- Ensure Flask server is running on localhost:5000
- Check `config.yml` has correct service URL
- Verify firewall isn't blocking localhost connections

### Connection Refused

- Check if tunnel is running: `ps aux | grep cloudflared`
- Restart tunnel: `cloudflared tunnel run pool-dispenser`
- Check server is running: `curl http://localhost:5000`

---

## Security Best Practices

1. **Use HTTPS Only** (automatic with Cloudflare)

2. **Add Authentication** (optional but recommended):
   
   Update Flask to require API keys:
   ```python
   API_KEY = os.getenv('API_KEY', 'your-secret-key')
   
   @app.before_request
   def check_auth():
       if request.path.startswith('/api/dispenser'):
           auth = request.headers.get('X-API-Key')
           if auth != API_KEY:
               return jsonify({'error': 'Unauthorized'}), 401
   ```
   
   Update ESP32:
   ```cpp
   http.addHeader("X-API-Key", "your-secret-key");
   ```

3. **Rate Limiting**:
   
   Add to Flask:
   ```python
   from flask_limiter import Limiter
   limiter = Limiter(app, key_func=lambda: request.remote_addr)
   
   @app.route('/api/dispenser/set', methods=['POST'])
   @limiter.limit("10 per minute")
   def set_values():
       # ...
   ```

4. **IP Allowlist** (Cloudflare Dashboard):
   - Go to Security → WAF
   - Create rule to allow only your home IP

---

## Monitoring

### View Tunnel Logs

```bash
cloudflared tunnel run pool-dispenser --loglevel debug
```

### Cloudflare Dashboard

1. Zero Trust → Access → Tunnels
2. View tunnel status and traffic
3. Monitor requests and errors

### Server Logs

Add to Flask:
```python
import logging
logging.basicConfig(level=logging.INFO)

@app.route('/api/dispenser/get')
def get_values():
    app.logger.info(f"GET request from {request.remote_addr}")
    # ...
```

---

## Cost

**Cloudflare Tunnel: FREE** ✨

No bandwidth limits, no usage fees. Works on free Cloudflare plan!

---

## Alternative: ngrok

If Cloudflare Tunnel doesn't work for you, try ngrok:

```bash
# Install ngrok
brew install ngrok  # macOS
# or download from https://ngrok.com/download

# Run
ngrok http 5000

# You'll get a URL like: https://abc123.ngrok.io
```

**Note:** Free ngrok URLs change on each restart (like quick Cloudflare tunnels).

---

## Summary Checklist

- [ ] Install cloudflared
- [ ] Login to Cloudflare account
- [ ] Create tunnel
- [ ] Configure `~/.cloudflared/config.yml`
- [ ] Route DNS
- [ ] Test tunnel
- [ ] Update ESP32 firmware with tunnel URL
- [ ] (Optional) Set up as service
- [ ] (Optional) Add authentication
- [ ] Test end-to-end with ESP32

---

## Need Help?

- Cloudflare Docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- Tunnel troubleshooting: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/
- Community Forum: https://community.cloudflare.com/

---

Happy Dispensing! 💧🏊‍♂️
