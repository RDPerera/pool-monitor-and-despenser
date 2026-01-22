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

// API Configuration - Update this with your Cloudflare tunnel URL
const char* API_GET_URL = "https://desperate-conflicts-guarantees-officials.trycloudflare.com/api/dispenser/get";
const char* API_RESET_URL = "https://desperate-conflicts-guarantees-officials.trycloudflare.com/api/dispenser/reset";

// Timing Configuration
const unsigned long API_CALL_INTERVAL = 30000;  // 5 seconds
const unsigned long BUTTON_LONG_PRESS = 5000;  // 5 seconds for WiFi config
const unsigned long TEST_DURATION = 3000;      // 3 seconds test mode
const unsigned long DEBOUNCE_DELAY = 50;       // Button debounce

// State Variables
Preferences preferences;
unsigned long lastAPICall = 0;
unsigned long buttonPressStart = 0;
bool buttonPressed = false;
bool wifiConfigMode = false;
bool dispensing = false;
unsigned long dispensingStartTime[4] = {0, 0, 0, 0};
int dispensingDuration[4] = {0, 0, 0, 0};
bool relayActive[4] = {false, false, false, false};

// LED Blink States
enum LEDState {
  LED_OFF,
  LED_ON,
  LED_SLOW_BLINK,   // WiFi connecting
  LED_FAST_BLINK,   // Dispensing
  LED_PULSE         // Error/No API response
};

LEDState currentLEDState = LED_OFF;
unsigned long lastLEDBlink = 0;
bool ledOn = false;

void setup() {
  Serial.begin(115200);
  Serial.println("\n\nPool Chemical Dispenser Starting...");
  
  // Initialize pins
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(RELAY1_PIN, OUTPUT);
  pinMode(RELAY2_PIN, OUTPUT);
  pinMode(RELAY3_PIN, OUTPUT);
  pinMode(RELAY4_PIN, OUTPUT);
  
  // Turn off all relays initially (assuming active LOW)
  digitalWrite(RELAY1_PIN, LOW);
  digitalWrite(RELAY2_PIN, LOW);
  digitalWrite(RELAY3_PIN, LOW);
  digitalWrite(RELAY4_PIN, LOW);
  
  // Initialize preferences
  preferences.begin("dispenser", false);
  
  // Check if button is pressed during boot
  if (digitalRead(BUTTON_PIN) == LOW) {
    delay(100);
    if (digitalRead(BUTTON_PIN) == LOW) {
      Serial.println("Button pressed during boot - entering WiFi config mode");
      enterWiFiConfigMode();
    }
  }
  
  // Connect to WiFi
  connectWiFi();
}

void loop() {
  handleButton();
  handleLED();
  
  if (WiFi.status() == WL_CONNECTED && !wifiConfigMode && !dispensing) {
    // Check API periodically
    if (millis() - lastAPICall >= API_CALL_INTERVAL) {
      checkDispenserAPI();
      lastAPICall = millis();
    }
  }
  
  // Handle active dispensing
  handleDispensing();
}

void handleButton() {
  static unsigned long lastDebounceTime = 0;
  static bool lastButtonState = HIGH;
  bool reading = digitalRead(BUTTON_PIN);
  
  // Debounce
  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }
  
  if ((millis() - lastDebounceTime) > DEBOUNCE_DELAY) {
    // Button pressed (active LOW)
    if (reading == LOW && !buttonPressed) {
      buttonPressed = true;
      buttonPressStart = millis();
      Serial.println("Button pressed");
    }
    
    // Button released
    if (reading == HIGH && buttonPressed) {
      unsigned long pressDuration = millis() - buttonPressStart;
      buttonPressed = false;
      
      if (pressDuration >= BUTTON_LONG_PRESS) {
        // Long press - enter WiFi config mode
        Serial.println("Long press detected - entering WiFi config");
        enterWiFiConfigMode();
      } else if (pressDuration > DEBOUNCE_DELAY) {
        // Short press - test mode
        Serial.println("Short press - test mode");
        testAllRelays();
      }
    }
  }
  
  lastButtonState = reading;
}

void handleLED() {
  unsigned long currentMillis = millis();
  
  switch (currentLEDState) {
    case LED_OFF:
      digitalWrite(LED_PIN, LOW);
      break;
      
    case LED_ON:
      digitalWrite(LED_PIN, HIGH);
      break;
      
    case LED_SLOW_BLINK:  // 1 Hz - WiFi connecting
      if (currentMillis - lastLEDBlink >= 500) {
        ledOn = !ledOn;
        digitalWrite(LED_PIN, ledOn ? HIGH : LOW);
        lastLEDBlink = currentMillis;
      }
      break;
      
    case LED_FAST_BLINK:  // 5 Hz - Dispensing
      if (currentMillis - lastLEDBlink >= 100) {
        ledOn = !ledOn;
        digitalWrite(LED_PIN, ledOn ? HIGH : LOW);
        lastLEDBlink = currentMillis;
      }
      break;
      
    case LED_PULSE:  // 2 Hz - Error
      if (currentMillis - lastLEDBlink >= 250) {
        ledOn = !ledOn;
        digitalWrite(LED_PIN, ledOn ? HIGH : LOW);
        lastLEDBlink = currentMillis;
      }
      break;
  }
}

void connectWiFi() {
  currentLEDState = LED_SLOW_BLINK;
  Serial.println("Connecting to WiFi...");
  
  WiFiManager wifiManager;
  wifiManager.setConfigPortalTimeout(180);  // 3 minutes timeout
  
  if (!wifiManager.autoConnect("PoolDispenser_AP")) {
    Serial.println("Failed to connect to WiFi");
    currentLEDState = LED_PULSE;
    delay(3000);
    ESP.restart();
  }
  
  Serial.println("Connected to WiFi!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
  currentLEDState = LED_ON;
}

void enterWiFiConfigMode() {
  wifiConfigMode = true;
  currentLEDState = LED_SLOW_BLINK;
  Serial.println("Entering WiFi configuration mode...");
  
  WiFiManager wifiManager;
  wifiManager.resetSettings();  // Clear saved credentials
  
  if (!wifiManager.startConfigPortal("PoolDispenser_AP")) {
    Serial.println("Failed to start config portal");
    ESP.restart();
  }
  
  Serial.println("WiFi reconfigured, restarting...");
  ESP.restart();
}

void checkDispenserAPI() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected");
    currentLEDState = LED_PULSE;
    return;
  }
  
  HTTPClient http;
  http.begin(API_GET_URL);
  http.setTimeout(5000);
  
  int httpCode = http.GET();
  
  if (httpCode == HTTP_CODE_OK) {
    String payload = http.getString();
    Serial.println("API Response: " + payload);
    
    StaticJsonDocument<512> doc;
    DeserializationError error = deserializeJson(doc, payload);
    
    if (!error) {
      int disp1 = doc["dispenser1"] | 0;
      int disp2 = doc["dispenser2"] | 0;
      int disp3 = doc["dispenser3"] | 0;
      int disp4 = doc["dispenser4"] | 0;
      
      // Check if any dispenser has non-zero value
      if (disp1 > 0 || disp2 > 0 || disp3 > 0 || disp4 > 0) {
        Serial.printf("Dispensing: D1=%ds, D2=%ds, D3=%ds, D4=%ds\n", disp1, disp2, disp3, disp4);
        startDispensing(disp1, disp2, disp3, disp4);
      } else {
        currentLEDState = LED_ON;  // Idle state
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
  
  // Set durations (convert seconds to milliseconds)
  dispensingDuration[0] = d1 * 1000;
  dispensingDuration[1] = d2 * 1000;
  dispensingDuration[2] = d3 * 1000;
  dispensingDuration[3] = d4 * 1000;
  
  // Turn on relays that have non-zero duration
  unsigned long currentTime = millis();
  
  if (d1 > 0) {
    digitalWrite(RELAY1_PIN, HIGH);
    relayActive[0] = true;
    dispensingStartTime[0] = currentTime;
    Serial.println("Relay 1 ON");
  }
  
  if (d2 > 0) {
    digitalWrite(RELAY2_PIN, HIGH);
    relayActive[1] = true;
    dispensingStartTime[1] = currentTime;
    Serial.println("Relay 2 ON");
  }
  
  if (d3 > 0) {
    digitalWrite(RELAY3_PIN, HIGH);
    relayActive[2] = true;
    dispensingStartTime[2] = currentTime;
    Serial.println("Relay 3 ON");
  }
  
  if (d4 > 0) {
    digitalWrite(RELAY4_PIN, HIGH);
    relayActive[3] = true;
    dispensingStartTime[3] = currentTime;
    Serial.println("Relay 4 ON");
  }
}

void handleDispensing() {
  if (!dispensing) return;
  
  unsigned long currentTime = millis();
  bool anyActive = false;
  
  // Check each relay
  for (int i = 0; i < 4; i++) {
    if (relayActive[i]) {
      if (currentTime - dispensingStartTime[i] >= dispensingDuration[i]) {
        // Turn off this relay
        switch (i) {
          case 0: digitalWrite(RELAY1_PIN, LOW); Serial.println("Relay 1 OFF"); break;
          case 1: digitalWrite(RELAY2_PIN, LOW); Serial.println("Relay 2 OFF"); break;
          case 2: digitalWrite(RELAY3_PIN, LOW); Serial.println("Relay 3 OFF"); break;
          case 3: digitalWrite(RELAY4_PIN, LOW); Serial.println("Relay 4 OFF"); break;
        }
        relayActive[i] = false;
      } else {
        anyActive = true;
      }
    }
  }
  
  // If all relays are done, call reset API
  if (!anyActive) {
    Serial.println("Dispensing complete, calling reset API");
    dispensing = false;
    callResetAPI();
    currentLEDState = LED_ON;
  }
}

void callResetAPI() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected for reset");
    return;
  }
  
  HTTPClient http;
  http.begin(API_RESET_URL);
  http.setTimeout(5000);
  
  int httpCode = http.POST("");  // Empty POST body
  
  if (httpCode == HTTP_CODE_OK) {
    Serial.println("Reset API called successfully");
  } else {
    Serial.printf("Reset API failed: %d\n", httpCode);
  }
  
  http.end();
}

void testAllRelays() {
  Serial.println("Test mode - All relays ON for 3 seconds");
  currentLEDState = LED_FAST_BLINK;
  
  // Turn on all relays
  digitalWrite(RELAY1_PIN, HIGH);
  digitalWrite(RELAY2_PIN, HIGH);
  digitalWrite(RELAY3_PIN, HIGH);
  digitalWrite(RELAY4_PIN, HIGH);
  
  delay(TEST_DURATION);
  
  // Turn off all relays
  digitalWrite(RELAY1_PIN, LOW);
  digitalWrite(RELAY2_PIN, LOW);
  digitalWrite(RELAY3_PIN, LOW);
  digitalWrite(RELAY4_PIN, LOW);
  
  Serial.println("Test mode complete");
  currentLEDState = LED_ON;
}
