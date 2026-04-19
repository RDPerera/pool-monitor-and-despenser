#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <WiFiManager.h>
#include <Preferences.h>

// Pin Definitions
#define LED_PIN 16
#define BUTTON_PIN 17
#define RELAY1_PIN 25  // Dispenser 1
#define RELAY2_PIN 33  // Dispenser 2
#define RELAY3_PIN 26  // Dispenser 3
#define RELAY4_PIN 27  // Dispenser 4

// Relay logic: most relay modules are active LOW (LOW = ON, HIGH = OFF)
#define RELAY_ON  LOW
#define RELAY_OFF HIGH

// API Configuration
const char* API_GET_URL = "http://34.70.141.104:5000/api/dispenser/get";
const char* API_RESET_URL = "http://34.70.141.104:5000/api/dispenser/reset";

// Timing Configuration
const unsigned long API_CALL_INTERVAL = 30000;  // 30 seconds
const unsigned long BUTTON_LONG_PRESS  = 5000;  // 5 seconds hold to reset WiFi
const unsigned long TEST_DURATION      = 3000;  // 3 seconds relay test
const unsigned long DEBOUNCE_DELAY     = 50;
const unsigned long WIFI_RETRY_INTERVAL = 30000; // retry WiFi every 30s if dropped

// State Variables
Preferences preferences;
unsigned long lastAPICall      = 0;
unsigned long lastWiFiRetry    = 0;
unsigned long buttonPressStart = 0;
bool buttonPressed   = false;
bool dispensing      = false;
unsigned long dispensingStartTime[4] = {0, 0, 0, 0};
int  dispensingDuration[4]           = {0, 0, 0, 0};
bool relayActive[4]                  = {false, false, false, false};

// LED States
enum LEDState {
  LED_OFF,
  LED_ON,
  LED_SLOW_BLINK,  // WiFi connecting / config portal active
  LED_FAST_BLINK,  // Dispensing
  LED_PULSE        // Error
};

LEDState currentLEDState = LED_OFF;
unsigned long lastLEDBlink = 0;
bool ledOn = false;

// Called by WiFiManager when AP/portal is started
void apCallback(WiFiManager* wm) {
  Serial.println("WiFiManager: Config portal started");
  Serial.print("Connect to AP: ");
  Serial.println(wm->getConfigPortalSSID());
  Serial.println("Then open 192.168.4.1 in your browser");
  currentLEDState = LED_SLOW_BLINK;
}

void setup() {
  Serial.begin(115200);
  Serial.println("\n\nPool Chemical Dispenser Starting...");

  pinMode(LED_PIN,    OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(RELAY1_PIN, OUTPUT);
  pinMode(RELAY2_PIN, OUTPUT);
  pinMode(RELAY3_PIN, OUTPUT);
  pinMode(RELAY4_PIN, OUTPUT);

  allRelaysOff();

  preferences.begin("dispenser", false);

  // Hold button at boot → force WiFi config portal
  if (digitalRead(BUTTON_PIN) == LOW) {
    delay(100);
    if (digitalRead(BUTTON_PIN) == LOW) {
      Serial.println("Boot button held - entering WiFi config mode");
      enterWiFiConfigMode();
    }
  }

  connectWiFi();
}

void loop() {
  handleButton();
  handleLED();

  // WiFi reconnection if dropped
  if (WiFi.status() != WL_CONNECTED) {
    currentLEDState = LED_PULSE;
    if (millis() - lastWiFiRetry >= WIFI_RETRY_INTERVAL) {
      Serial.println("WiFi lost - reconnecting...");
      WiFi.reconnect();
      lastWiFiRetry = millis();
    }
    return;
  }

  if (!dispensing) {
    if (millis() - lastAPICall >= API_CALL_INTERVAL) {
      checkDispenserAPI();
      lastAPICall = millis();
    }
  }

  handleDispensing();
}

// ── Button ────────────────────────────────────────────────────────────────────

void handleButton() {
  static unsigned long lastDebounceTime = 0;
  static bool lastButtonState = HIGH;
  bool reading = digitalRead(BUTTON_PIN);

  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > DEBOUNCE_DELAY) {
    if (reading == LOW && !buttonPressed) {
      buttonPressed      = true;
      buttonPressStart   = millis();
      Serial.println("Button pressed");
    }

    // Visual feedback: flash LED fast once 5s threshold is reached
    if (buttonPressed && !dispensing) {
      unsigned long held = millis() - buttonPressStart;
      if (held >= BUTTON_LONG_PRESS) {
        currentLEDState = LED_FAST_BLINK;  // signal "release now to reset WiFi"
      }
    }

    if (reading == HIGH && buttonPressed) {
      unsigned long pressDuration = millis() - buttonPressStart;
      buttonPressed = false;

      if (pressDuration >= BUTTON_LONG_PRESS) {
        Serial.println("Long press - resetting WiFi config");
        enterWiFiConfigMode();
      } else if (pressDuration > DEBOUNCE_DELAY && !dispensing) {
        Serial.println("Short press - relay test");
        testAllRelays();
      }
    }
  }

  lastButtonState = reading;
}

// ── LED ───────────────────────────────────────────────────────────────────────

void handleLED() {
  unsigned long now = millis();
  switch (currentLEDState) {
    case LED_OFF:  digitalWrite(LED_PIN, LOW);  break;
    case LED_ON:   digitalWrite(LED_PIN, HIGH); break;
    case LED_SLOW_BLINK:
      if (now - lastLEDBlink >= 500) { ledOn = !ledOn; digitalWrite(LED_PIN, ledOn); lastLEDBlink = now; }
      break;
    case LED_FAST_BLINK:
      if (now - lastLEDBlink >= 100) { ledOn = !ledOn; digitalWrite(LED_PIN, ledOn); lastLEDBlink = now; }
      break;
    case LED_PULSE:
      if (now - lastLEDBlink >= 250) { ledOn = !ledOn; digitalWrite(LED_PIN, ledOn); lastLEDBlink = now; }
      break;
  }
}

// ── WiFi ──────────────────────────────────────────────────────────────────────

void connectWiFi() {
  currentLEDState = LED_SLOW_BLINK;
  Serial.println("Connecting to WiFi...");

  WiFiManager wifiManager;
  wifiManager.setAPCallback(apCallback);
  wifiManager.setConfigPortalTimeout(180);  // 3 min portal timeout

  if (!wifiManager.autoConnect("PoolDispenser_AP")) {
    Serial.println("WiFi connection failed - restarting");
    currentLEDState = LED_PULSE;
    delay(3000);
    ESP.restart();
  }

  Serial.print("WiFi connected! IP: ");
  Serial.println(WiFi.localIP());
  currentLEDState = LED_ON;
}

void enterWiFiConfigMode() {
  currentLEDState = LED_SLOW_BLINK;
  Serial.println("Entering WiFi config mode - clearing credentials");

  WiFiManager wifiManager;
  wifiManager.setAPCallback(apCallback);
  wifiManager.resetSettings();  // clear saved credentials

  if (!wifiManager.startConfigPortal("PoolDispenser_AP")) {
    Serial.println("Config portal failed - restarting");
  }

  Serial.println("WiFi reconfigured - restarting");
  ESP.restart();
}

// ── Dispenser API ─────────────────────────────────────────────────────────────

void checkDispenserAPI() {
  HTTPClient http;
  http.begin(API_GET_URL);
  http.setTimeout(5000);

  int httpCode = http.GET();

  if (httpCode == HTTP_CODE_OK) {
    String payload = http.getString();
    Serial.println("API Response: " + payload);

    StaticJsonDocument<512> doc;
    if (deserializeJson(doc, payload) == DeserializationError::Ok) {
      // Server returns string values e.g. "10", so parse via const char*
      int disp1 = atoi(doc["dispenser1"] | "0");
      int disp2 = atoi(doc["dispenser2"] | "0");
      int disp3 = atoi(doc["dispenser3"] | "0");
      int disp4 = atoi(doc["dispenser4"] | "0");

      if (disp1 > 0 || disp2 > 0 || disp3 > 0 || disp4 > 0) {
        Serial.printf("Dispensing: D1=%ds D2=%ds D3=%ds D4=%ds\n", disp1, disp2, disp3, disp4);
        startDispensing(disp1, disp2, disp3, disp4);
      } else {
        currentLEDState = LED_ON;
      }
    } else {
      Serial.println("JSON parse error");
      currentLEDState = LED_PULSE;
    }
  } else {
    Serial.printf("API call failed: %d\n", httpCode);
    currentLEDState = LED_PULSE;
  }

  http.end();
}

void startDispensing(int d1, int d2, int d3, int d4) {
  dispensing = true;
  currentLEDState = LED_FAST_BLINK;

  dispensingDuration[0] = d1 * 1000;
  dispensingDuration[1] = d2 * 1000;
  dispensingDuration[2] = d3 * 1000;
  dispensingDuration[3] = d4 * 1000;

  unsigned long now = millis();
  const int relayPins[4] = {RELAY1_PIN, RELAY2_PIN, RELAY3_PIN, RELAY4_PIN};
  int durations[4] = {d1, d2, d3, d4};

  for (int i = 0; i < 4; i++) {
    if (durations[i] > 0) {
      digitalWrite(relayPins[i], RELAY_ON);
      relayActive[i]        = true;
      dispensingStartTime[i] = now;
      Serial.printf("Relay %d ON\n", i + 1);
    }
  }
}

void handleDispensing() {
  if (!dispensing) return;

  unsigned long now = millis();
  bool anyActive = false;
  const int relayPins[4] = {RELAY1_PIN, RELAY2_PIN, RELAY3_PIN, RELAY4_PIN};

  for (int i = 0; i < 4; i++) {
    if (relayActive[i]) {
      if (now - dispensingStartTime[i] >= (unsigned long)dispensingDuration[i]) {
        digitalWrite(relayPins[i], RELAY_OFF);
        relayActive[i] = false;
        Serial.printf("Relay %d OFF\n", i + 1);
      } else {
        anyActive = true;
      }
    }
  }

  if (!anyActive) {
    Serial.println("Dispensing complete - calling reset API");
    dispensing = false;
    callResetAPI();
    currentLEDState = LED_ON;
  }
}

void callResetAPI() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected - skipping reset API");
    return;
  }

  HTTPClient http;
  http.begin(API_RESET_URL);
  http.setTimeout(5000);

  int httpCode = http.POST("");

  if (httpCode == HTTP_CODE_OK) {
    Serial.println("Reset API: success");
  } else {
    Serial.printf("Reset API failed: %d\n", httpCode);
  }

  http.end();
}

// ── Relay Helpers ─────────────────────────────────────────────────────────────

void allRelaysOff() {
  digitalWrite(RELAY1_PIN, RELAY_OFF);
  digitalWrite(RELAY2_PIN, RELAY_OFF);
  digitalWrite(RELAY3_PIN, RELAY_OFF);
  digitalWrite(RELAY4_PIN, RELAY_OFF);
}

void testAllRelays() {
  Serial.println("Test mode - all relays ON for 3 seconds");
  currentLEDState = LED_FAST_BLINK;

  digitalWrite(RELAY1_PIN, RELAY_ON);
  digitalWrite(RELAY2_PIN, RELAY_ON);
  digitalWrite(RELAY3_PIN, RELAY_ON);
  digitalWrite(RELAY4_PIN, RELAY_ON);

  delay(TEST_DURATION);
  allRelaysOff();

  Serial.println("Test mode complete");
  currentLEDState = LED_ON;
}
