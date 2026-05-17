// ESP32 Pool Monitor Firmware
// - WiFi provisioning via WiFiManager (config portal on first boot)
// - Configurable API_URL and POST_INTERVAL_MS stored in NVS (Preferences)
// - Reads PH (ADC34), Turbidity (ADC35), Temperature (NTC 10K on GPIO33)
// - Retries WiFi connection indefinitely in the background

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiManager.h>   // https://github.com/tzapu/WiFiManager
#include <Preferences.h>   // ESP32 NVS key-value storage
#include <math.h>

// ─── Pin Definitions ────────────────────────────────────────────────────────
#define LED_BLUE          4
#define LED_RED           5
#define LED_GREEN         18
#define PH_SENSOR         34
#define TURBIDITY_SENSOR  35
#define TEMP_SENSOR       33   // NTC 10K thermistor — voltage divider with 10kΩ to 3.3V
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
Preferences prefs;
WiFiManager wifiManager;

uint32_t g_lastPostMs     = 0;
bool     g_needSaveConfig = false;

// WiFiManager custom parameter buffers (must outlive the parameter objects)
char wm_apiUrlBuf[256];
char wm_intervalBuf[16];
WiFiManagerParameter* wm_paramApiUrl   = nullptr;
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
LedState g_ledState    = LED_OFF;
uint32_t g_ledToggleMs = 0;
bool     g_ledBlinkOn  = false;

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
	prefs.begin("poolmon", true);
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

	prefs.begin("poolmon", false);

	if (newUrl.length() > 0) {
		prefs.putString("api_url", newUrl);
		newUrl.toCharArray(g_apiUrl, sizeof(g_apiUrl));
		Serial.print("[CONFIG] Saved API URL: "); Serial.println(g_apiUrl);
	}

	uint32_t interval = (uint32_t)newInterval.toInt();
	if (interval >= 1000) {
		prefs.putUInt("post_interval", interval);
		g_postIntervalMs = interval;
		Serial.print("[CONFIG] Saved interval: "); Serial.print(g_postIntervalMs); Serial.println(" ms");
	}

	prefs.end();
}

// ─── WiFiManager Setup ───────────────────────────────────────────────────────
void initWiFiManagerParams() {
	strncpy(wm_apiUrlBuf, g_apiUrl, sizeof(wm_apiUrlBuf) - 1);
	snprintf(wm_intervalBuf, sizeof(wm_intervalBuf), "%u", g_postIntervalMs);

	delete wm_paramApiUrl;
	delete wm_paramInterval;
	wm_paramApiUrl   = new WiFiManagerParameter("api_url",  "API URL",            wm_apiUrlBuf,  255);
	wm_paramInterval = new WiFiManagerParameter("interval", "Post Interval (ms)", wm_intervalBuf, 10);

	wifiManager.addParameter(wm_paramApiUrl);
	wifiManager.addParameter(wm_paramInterval);
}

// ─── Config Portal (blocking) ────────────────────────────────────────────────
void launchConfigPortal() {
	Serial.println("[PORTAL] Launching config portal...");
	setLedState(LED_CONFIG_PORTAL);
	buzz(150); delay(100); buzz(150);

	wifiManager.setConfigPortalTimeout(0);   // wait indefinitely

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
	if (now - lastAttemptMs < 10000) return;
	lastAttemptMs = now;

	Serial.println("[WIFI] Disconnected — attempting reconnect...");
	setLedState(LED_CONNECTING);
	WiFi.reconnect();

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

// ─── Sensors ─────────────────────────────────────────────────────────────────
float readPH() {
	// Calibration points (ADC decreases as pH increases):
	//   ADC 4000 → pH 5.0
	//   ADC 3500 → pH 7.5
	//   ADC 3230 → pH 9.0
	float adc = (float)analogRead(PH_SENSOR);
	float ph;
	if (adc >= 3500.0f) {
		ph = 5.0f + (4000.0f - adc) * (2.5f / 500.0f);
	} else {
		ph = 7.5f + (3500.0f - adc) * (1.5f / 270.0f);
	}
	return constrain(ph, 0.0f, 14.0f);
}

float readTurbidity() {
	// Calibration: ADC 1940 → 0.1 NTU (clear), ADC 1200 → 1.0 NTU
	// Higher turbidity = lower ADC (inverse relationship)
	float adc = (float)analogRead(TURBIDITY_SENSOR);
	float ntu = 0.1f + (1940.0f - adc) * (0.9f / 740.0f);
	return max(0.0f, ntu);   // clamp to 0 — can't be negative
}

float readTemperatureC() {
	// NTC 10K — Beta equation
	// Wiring: 5V ──[NTC 10K]──┬── GPIO33
	//                          ├──[10kΩ fixed]── GND
	const float SERIES_R  = 10000.0f;
	const float NOMINAL_R = 10000.0f;  // NTC resistance at 25°C
	const float NOMINAL_T = 25.0f;
	const float BETA      = 3950.0f;
	const float VCC       = 5.0f;      // divider powered from 5V rail
	const float VREF      = 3.3f;      // ESP32 ADC reference

	float adc = 0;
	for (int i = 0; i < 10; i++) { adc += analogRead(TEMP_SENSOR); delay(5); }
	adc /= 10.0f;

	if (adc <= 0 || adc >= 4095) {
		Serial.println("[TEMP] ERROR: ADC out of range — check wiring on GPIO33");
		return -127.0f;
	}

	// NTC on high side: R_ntc = R_fixed * (VCC_counts/adc - 1)
	float vcc_counts = VCC / VREF * 4095.0f;
	float resistance = SERIES_R * (vcc_counts / adc - 1.0f);
	float t = 1.0f / (logf(resistance / NOMINAL_R) / BETA + 1.0f / (NOMINAL_T + 273.15f)) - 273.15f;

	Serial.print("[TEMP] ADC="); Serial.print((int)adc);
	Serial.print("  R=");        Serial.print(resistance, 0);
	Serial.print(" Ω  T=");      Serial.print(t, 2);
	Serial.println(" °C");

	return t;
}

const char* classifyWaterQuality(float ph, float turbidity, float tempC) {
	bool phOk   = (ph >= 7.2f && ph <= 7.8f);
	bool turbOk = (turbidity <= 1.0f);
	bool tempOk = (tempC > 5.0f && tempC < 40.0f);
	if (phOk && turbOk && tempOk) return "optimal";
	if ((phOk && turbOk) || (phOk && tempOk) || (turbOk && tempOk)) return "acceptable";
	return "poor";
}

// ─── HTTP POST ───────────────────────────────────────────────────────────────
bool postData(float ph, float turbidity, float tempC) {
	if (WiFi.status() != WL_CONNECTED) return false;

	WiFiClient client;
	HTTPClient http;
	if (!http.begin(client, g_apiUrl)) return false;

	http.addHeader("Content-Type", "application/json");

	const char* quality = classifyWaterQuality(ph, turbidity, tempC);

	String payload = "{";
	payload += "\"device_id\":\"";   payload += DEVICE_ID;           payload += "\",";
	payload += "\"sensors\":{";
	payload += "\"ph\":";            payload += String(ph, 1);        payload += ",";
	payload += "\"turbidity\":";     payload += String(turbidity, 1); payload += ",";
	payload += "\"temperature\":";   payload += String(tempC, 1);     payload += "},";
	payload += "\"status\":{";
	payload += "\"water_quality\":\""; payload += quality;            payload += "\",";
	payload += "\"wifi_rssi\":";     payload += String(WiFi.RSSI());  payload += ",";
	payload += "\"uptime\":";        payload += String(millis() / 1000); payload += "}}";

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
	pinMode(BUZZER_PIN, OUTPUT);
	setLEDs(false, false, false);

	analogReadResolution(12);
	analogSetAttenuation(ADC_11db);

	// Startup blink (3× blue)
	for (int i = 0; i < 3; i++) {
		setLEDs(true, false, false); delay(120);
		setLEDs(false, false, false); delay(120);
	}

	loadConfig();
	initWiFiManagerParams();

	wifiManager.setSaveParamsCallback([]() {
		Serial.println("[PORTAL] Params callback — saving config...");
		saveConfig();
	});

	wifiManager.setConfigPortalTimeout(0);   // wait forever until configured
	wifiManager.setConnectTimeout(30);

	setLedState(LED_CONNECTING);
	Serial.println("[WIFI] Starting autoConnect...");

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
	maintainWiFi();

	if (WiFi.status() != WL_CONNECTED) return;

	uint32_t now = millis();
	if (now - g_lastPostMs < g_postIntervalMs) return;
	g_lastPostMs = now;

	float ph    = readPH();
	float turb  = readTurbidity();
	float tempC = readTemperatureC();

	Serial.print("[SENSOR] PH=");        Serial.print(ph, 1);
	Serial.print("  Turbidity=");        Serial.print(turb, 2); Serial.print(" NTU");
	Serial.print("  Temp=");             Serial.print(tempC, 1);
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
