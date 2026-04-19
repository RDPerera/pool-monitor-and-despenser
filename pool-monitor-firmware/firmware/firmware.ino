// ESP32 Pool Monitor Firmware
// - WiFi provisioning via WiFiManager (config portal on first boot or 5s long-press)
// - Configurable API_URL and POST_INTERVAL_MS stored in NVS (Preferences)
// - Reads PH (ADC34), Turbidity (ADC35), Temperature (DS18B20 on GPIO19)
// - Retries WiFi connection indefinitely in the background
// - 5s button hold launches the config portal at any time

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiManager.h>   // https://github.com/tzapu/WiFiManager
#include <Preferences.h>   // ESP32 NVS key-value storage
#include <OneWire.h>
#include <DallasTemperature.h>

// ─── Pin Definitions ────────────────────────────────────────────────────────
#define LED_BLUE          4
#define LED_RED           5
#define LED_GREEN         18
#define PH_SENSOR         34
#define TURBIDITY_SENSOR  35
#define TEMP_SENSOR       19   // DS18B20 data pin
#define BUTTON_PIN        22   // Active LOW with internal pull-up
#define BUZZER_PIN        32

// ─── Defaults ───────────────────────────────────────────────────────────────
#define DEFAULT_API_URL         "http://34.70.141.104:5000/pool/data"
#define DEFAULT_POST_INTERVAL   5000u   // ms
#define CONFIG_AP_NAME          "PoolMonitor"
static const char* DEVICE_ID = "PoolMonitor";

// ─── Runtime Config (loaded from NVS) ───────────────────────────────────────
char     g_apiUrl[256];
uint32_t g_postIntervalMs = DEFAULT_POST_INTERVAL;

// ─── Globals ─────────────────────────────────────────────────────────────────
Preferences       prefs;
WiFiManager       wifiManager;
OneWire           oneWire(TEMP_SENSOR);
DallasTemperature tempSensor(&oneWire);

uint32_t g_lastPostMs      = 0;
uint32_t g_pressStartMs    = 0;
bool     g_isPressing      = false;
bool     g_needSaveConfig  = false;   // set by WiFiManager save callback

// WiFiManager custom parameter buffers (must outlive the parameter objects)
char wm_apiUrlBuf[256];
char wm_intervalBuf[16];
WiFiManagerParameter* wm_paramApiUrl  = nullptr;
WiFiManagerParameter* wm_paramInterval = nullptr;

// ─── LED State Machine ───────────────────────────────────────────────────────
enum LedState {
	LED_OFF,
	LED_CONNECTING,
	LED_CONFIG_PORTAL,
	LED_CONNECTED,
	LED_POSTING,
	LED_ERROR
};
LedState g_ledState       = LED_OFF;
uint32_t g_ledToggleMs    = 0;
bool     g_ledBlinkOn     = false;

void setLEDs(bool blue, bool red, bool green) {
	digitalWrite(LED_BLUE,  blue  ? HIGH : LOW);
	digitalWrite(LED_RED,   red   ? HIGH : LOW);
	digitalWrite(LED_GREEN, green ? HIGH : LOW);
}

void setLedState(LedState s) {
	g_ledState    = s;
	g_ledToggleMs = millis();
	g_ledBlinkOn  = false;
}

void updateLEDs() {
	uint32_t now = millis();
	switch (g_ledState) {
		case LED_OFF:
			setLEDs(false, false, false);
			break;
		case LED_CONNECTING: {
			if (now - g_ledToggleMs >= 800) { g_ledBlinkOn = !g_ledBlinkOn; g_ledToggleMs = now; }
			setLEDs(g_ledBlinkOn, false, false);
			break;
		}
		case LED_CONFIG_PORTAL: {
			if (now - g_ledToggleMs >= 250) { g_ledBlinkOn = !g_ledBlinkOn; g_ledToggleMs = now; }
			setLEDs(g_ledBlinkOn, false, false);
			break;
		}
		case LED_CONNECTED:
			setLEDs(false, false, true);
			break;
		case LED_POSTING:
			setLEDs(false, false, true);
			break;
		case LED_ERROR:
			setLEDs(false, true, false);
			break;
	}
}

// ─── Buzzer ──────────────────────────────────────────────────────────────────
void buzz(uint16_t ms = 60) {
	digitalWrite(BUZZER_PIN, HIGH);
	delay(ms);
	digitalWrite(BUZZER_PIN, LOW);
}

// ─── NVS Config ──────────────────────────────────────────────────────────────
void loadConfig() {
	prefs.begin("poolmon", true); // read-only
	String url = prefs.getString("api_url", DEFAULT_API_URL);
	url.toCharArray(g_apiUrl, sizeof(g_apiUrl));
	g_postIntervalMs = prefs.getUInt("post_interval", DEFAULT_POST_INTERVAL);
	prefs.end();

	Serial.print("[CONFIG] API URL: ");       Serial.println(g_apiUrl);
	Serial.print("[CONFIG] Post interval: "); Serial.print(g_postIntervalMs); Serial.println(" ms");
}

void saveConfig() {
	if (!wm_paramApiUrl || !wm_paramInterval) return;

	String newUrl      = String(wm_paramApiUrl->getValue());
	String newInterval = String(wm_paramInterval->getValue());
	newUrl.trim();
	newInterval.trim();

	prefs.begin("poolmon", false); // read-write

	if (newUrl.length() > 0) {
		prefs.putString("api_url", newUrl);
		newUrl.toCharArray(g_apiUrl, sizeof(g_apiUrl));
		Serial.print("[CONFIG] Saved API URL: "); Serial.println(g_apiUrl);
	}

	uint32_t interval = (uint32_t)newInterval.toInt();
	if (interval >= 1000) {   // enforce 1 s minimum
		prefs.putUInt("post_interval", interval);
		g_postIntervalMs = interval;
		Serial.print("[CONFIG] Saved interval: "); Serial.print(g_postIntervalMs); Serial.println(" ms");
	}

	prefs.end();
}

// ─── WiFiManager Setup ───────────────────────────────────────────────────────
void initWiFiManagerParams() {
	// Populate buffers with current (loaded) values so the portal pre-fills them
	strncpy(wm_apiUrlBuf, g_apiUrl, sizeof(wm_apiUrlBuf) - 1);
	snprintf(wm_intervalBuf, sizeof(wm_intervalBuf), "%u", g_postIntervalMs);

	delete wm_paramApiUrl;
	delete wm_paramInterval;
	wm_paramApiUrl  = new WiFiManagerParameter("api_url",  "API URL",           wm_apiUrlBuf,  255);
	wm_paramInterval = new WiFiManagerParameter("interval", "Post Interval (ms)", wm_intervalBuf, 10);

	wifiManager.addParameter(wm_paramApiUrl);
	wifiManager.addParameter(wm_paramInterval);
}

// ─── Config Portal (blocking) ────────────────────────────────────────────────
// Called on first boot (no credentials) or by 5-second button press.
// After the portal closes (saved or timed out), the device restarts.
void launchConfigPortal() {
	Serial.println("[PORTAL] Launching config portal...");
	setLedState(LED_CONFIG_PORTAL);
	buzz(150); delay(100); buzz(150);

	wifiManager.setConfigPortalTimeout(0); // wait indefinitely until user saves

	if (wifiManager.startConfigPortal(CONFIG_AP_NAME)) {
		Serial.println("[PORTAL] Configuration saved.");
		saveConfig();
	} else {
		Serial.println("[PORTAL] Portal closed without saving.");
	}

	Serial.println("[PORTAL] Restarting...");
	delay(500);
	ESP.restart();
}

// ─── WiFi Maintenance (non-blocking retry in loop) ──────────────────────────
void maintainWiFi() {
	if (WiFi.status() == WL_CONNECTED) return;

	static uint32_t lastAttemptMs = 0;
	uint32_t now = millis();

	if (now - lastAttemptMs < 10000) return;   // try every 10 s
	lastAttemptMs = now;

	Serial.println("[WIFI] Disconnected — attempting reconnect...");
	setLedState(LED_CONNECTING);
	WiFi.reconnect();

	// Wait up to 8 s for connection, still processing LEDs and button
	uint32_t start = millis();
	while (WiFi.status() != WL_CONNECTED && millis() - start < 8000) {
		updateLEDs();
		delay(100);
	}

	if (WiFi.status() == WL_CONNECTED) {
		Serial.print("[WIFI] Reconnected — IP: ");
		Serial.println(WiFi.localIP());
		setLedState(LED_CONNECTED);
		buzz(60);
	} else {
		Serial.println("[WIFI] Reconnect failed — will retry in 10 s...");
		setLedState(LED_ERROR);
	}
}

// ─── Button (5-second long-press → config portal) ──────────────────────────
void handleButton() {
	static int      lastReading = HIGH;
	static uint32_t debounceMs  = 0;
	uint32_t        now         = millis();

	int reading = digitalRead(BUTTON_PIN);

	if (reading != lastReading) {
		debounceMs  = now;
		lastReading = reading;
		return;
	}
	if (now - debounceMs < 50) return;   // debounce gap

	if (reading == LOW) {   // button held
		if (!g_isPressing) {
			g_isPressing   = true;
			g_pressStartMs = now;
			Serial.println("[BTN] Button pressed...");
		} else if (now - g_pressStartMs >= 5000) {
			g_isPressing = false;
			Serial.println("[BTN] 5-second hold — entering config portal.");
			launchConfigPortal();   // does not return (restarts)
		}
	} else {
		if (g_isPressing) {
			Serial.print("[BTN] Released after ");
			Serial.print(now - g_pressStartMs);
			Serial.println(" ms");
			g_isPressing = false;
		}
	}
}

// ─── Sensors ─────────────────────────────────────────────────────────────────
float readPH()          { return (float)analogRead(PH_SENSOR); }
float readTurbidity()   { return (float)analogRead(TURBIDITY_SENSOR); }
float readTemperatureC() {
	tempSensor.requestTemperatures();
	return tempSensor.getTempCByIndex(0);   // DEVICE_DISCONNECTED_C (-127) on failure
}

const char* classifyWaterQuality(float ph, float turbidity, float tempC) {
	bool phOk   = (ph   >= 300 && ph   <= 900);
	bool turbOk = (turbidity  <= 1500);
	bool tempOk = (tempC > 5  && tempC < 40);
	if (phOk && turbOk && tempOk) return "optimal";
	if ((phOk && turbOk) || (phOk && tempOk) || (turbOk && tempOk)) return "acceptable";
	return "poor";
}

void scanOneWireBus() {
	Serial.println("\n[DEBUG] Scanning OneWire bus on GPIO19...");
	byte addr[8];
	int  count = 0;
	while (oneWire.search(addr)) {
		count++;
		Serial.print("[DEBUG] Device "); Serial.print(count); Serial.print(": ");
		for (int i = 0; i < 8; i++) {
			if (addr[i] < 0x10) Serial.print("0");
			Serial.print(addr[i], HEX);
		}
		Serial.println();
	}
	oneWire.reset_search();
	if (count == 0) Serial.println("[ERROR] No OneWire devices found! Check wiring and 4.7 kΩ pull-up.");
	else { Serial.print("[DEBUG] Found "); Serial.print(count); Serial.println(" device(s)"); }
}

// ─── HTTP POST ───────────────────────────────────────────────────────────────
bool postData(float ph, float turbidity, float tempC) {
	if (WiFi.status() != WL_CONNECTED) return false;

	WiFiClient  client;
	HTTPClient  http;
	if (!http.begin(client, g_apiUrl)) return false;

	http.addHeader("Content-Type", "application/json");

	const char* quality = classifyWaterQuality(ph, turbidity, tempC);

	String payload = "{";
	payload += "\"device_id\":\"";  payload += DEVICE_ID;          payload += "\",";
	payload += "\"sensors\":{";
	payload += "\"ph\":";           payload += String(ph, 1);       payload += ",";
	payload += "\"turbidity\":";    payload += String(turbidity, 1); payload += ",";
	payload += "\"temperature\":";  payload += String(tempC, 1);    payload += "},";
	payload += "\"status\":{";
	payload += "\"water_quality\":\""; payload += quality;          payload += "\",";
	payload += "\"wifi_rssi\":";    payload += String(WiFi.RSSI()); payload += ",";
	payload += "\"uptime\":";       payload += String(millis() / 1000); payload += "}}";

	int code = http.POST(payload);
	http.end();
	return (code >= 200 && code < 300);
}

// ─── Setup ───────────────────────────────────────────────────────────────────
void setup() {
	Serial.begin(115200);
	delay(500);
	Serial.println("\n\n[STARTUP] ESP32 Pool Monitor initializing...");

	pinMode(LED_BLUE,  OUTPUT);
	pinMode(LED_RED,   OUTPUT);
	pinMode(LED_GREEN, OUTPUT);
	pinMode(BUTTON_PIN, INPUT_PULLUP);
	pinMode(BUZZER_PIN, OUTPUT);
	setLEDs(false, false, false);

	analogReadResolution(12);
	analogSetAttenuation(ADC_11db);

	// Startup blink (3× blue)
	for (int i = 0; i < 3; i++) {
		setLEDs(true, false, false); delay(120);
		setLEDs(false, false, false); delay(120);
	}

	tempSensor.begin();
	scanOneWireBus();

	// Load persisted config (API URL, interval)
	loadConfig();

	// Build WiFiManager custom parameters pre-filled with saved values
	initWiFiManagerParams();

	// Save custom params whenever the user submits the portal form
	wifiManager.setSaveParamsCallback([]() {
		Serial.println("[PORTAL] Params callback — saving config...");
		saveConfig();
	});

	wifiManager.setConfigPortalTimeout(180);   // portal auto-closes after 3 min if no action
	wifiManager.setConnectTimeout(30);          // give WiFi 30 s to connect before opening portal

	setLedState(LED_CONNECTING);
	Serial.println("[WIFI] Starting autoConnect...");

	// autoConnect behaviour:
	//   • Credentials saved → connects silently (30 s timeout)
	//   • No credentials   → opens AP portal (180 s timeout)
	//   • Returns false    → portal timed out or connect failed; loop will retry
	if (wifiManager.autoConnect(CONFIG_AP_NAME)) {
		Serial.print("[WIFI] Connected!  SSID: "); Serial.print(WiFi.SSID());
		Serial.print("  IP: "); Serial.println(WiFi.localIP());
		setLedState(LED_CONNECTED);
		buzz(80);
	} else {
		Serial.println("[WIFI] Initial connection failed — will retry in loop.");
		setLedState(LED_ERROR);
	}

	g_lastPostMs = millis();
	Serial.println("[STARTUP] Setup complete — entering loop.");
}

// ─── Loop ────────────────────────────────────────────────────────────────────
void loop() {
	updateLEDs();
	handleButton();
	maintainWiFi();   // keeps WiFi alive; retries every 10 s if dropped

	if (WiFi.status() != WL_CONNECTED) return;   // nothing to do until connected

	uint32_t now = millis();
	if (now - g_lastPostMs < g_postIntervalMs) return;
	g_lastPostMs = now;

	float ph    = readPH();
	float turb  = readTurbidity();
	float tempC = readTemperatureC();

	Serial.print("[SENSOR] PH=");         Serial.print(ph, 1);
	Serial.print("  Turbidity=");         Serial.print(turb, 1);
	Serial.print("  Temp=");              Serial.print(tempC, 1);
	Serial.println(" °C");

	setLedState(LED_POSTING);
	bool ok = postData(ph, turb, tempC);

	if (ok) {
		setLEDs(false, false, true);
		buzz(40);
		delay(60);
		setLedState(LED_CONNECTED);
		Serial.println("[HTTP] POST successful");
	} else {
		setLedState(LED_ERROR);
		buzz(160);
		Serial.println("[ERROR] HTTP POST failed");
		delay(500);
		setLedState(WiFi.status() == WL_CONNECTED ? LED_CONNECTED : LED_CONNECTING);
	}
}
