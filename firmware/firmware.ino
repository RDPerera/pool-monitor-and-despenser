#include <WiFi.h>
#include <WiFiManager.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// Pin Definitions
#define LED_BLUE 4
#define LED_RED 5
#define LED_GREEN 18
#define PH_SENSOR 34
#define TURBIDITY_SENSOR 35
#define TEMP_SENSOR 19  // D5
#define BUTTON_PIN 22
#define BUZZER_PIN 32

// API Configuration
const char* API_BASE_URL = "https://api.yourserver.com/pool"; // Replace with your API
const char* DATA_ENDPOINT = "/data";
const char* CONFIG_ENDPOINT = "/config";

// Timing
unsigned long lastSensorRead = 0;
unsigned long lastAPIPost = 0;
unsigned long lastConfigFetch = 0;
unsigned long buttonPressStart = 0;
bool buttonPressed = false;

// Configurable intervals (milliseconds)
int sensorReadInterval = 1000;    // Read sensors every 1s
int apiPostInterval = 1000;       // Post to API every 1s (configurable)
int configFetchInterval = 60000;  // Fetch config every 60s

// Temperature sensor setup
OneWire oneWire(TEMP_SENSOR);
DallasTemperature tempSensor(&oneWire);

// Preferences for persistent storage
Preferences preferences;

// Sensor calibration values (fetched from API)
float phOffset = 0.0;
float phSlope = 1.0;
float turbidityOffset = 0.0;
float turbiditySlope = 1.0;
float tempOffset = 0.0;

// Threshold structures
struct Thresholds {
  float optimal;      // Green zone
  float acceptable;   // Orange zone
  float critical;     // Red zone (alarm)
};

Thresholds phThresholds = {7.4, 7.8, 8.5};           // pH: 6.8-7.4 optimal, 7.4-7.8 acceptable, >7.8 critical
Thresholds turbidityThresholds = {5.0, 20.0, 50.0}; // NTU: <5 optimal, 5-20 acceptable, >20 critical
Thresholds tempThresholds = {26.0, 30.0, 33.0};     // °C: 24-26 optimal, 26-30 acceptable, >30 critical

// Current sensor values
float currentPh = 0.0;
float currentTurbidity = 0.0;
float currentTemp = 0.0;

// Water quality status
enum WaterQuality { OPTIMAL, ACCEPTABLE, CRITICAL };
WaterQuality currentStatus = OPTIMAL;

// Device ID (MAC address based)
String deviceId;

// Function prototypes
void setupWiFi();
void checkButton();
void readSensors();
void postDataToAPI();
void fetchConfigFromAPI();
void updateLEDStatus();
void setLEDColor(int r, int g, int b);
void blinkLED(int r, int g, int b, int times, int delayMs);
void playTone(int frequency, int duration);
void playStartupMelody();
void playResetMelody();
WaterQuality evaluateWaterQuality();

void setup() {
  Serial.begin(115200);
  
  // Initialize pins
  pinMode(LED_RED, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(BUZZER_PIN, OUTPUT);
  
  // Turn off LEDs (common anode - HIGH = OFF)
  digitalWrite(LED_RED, HIGH);
  digitalWrite(LED_GREEN, HIGH);
  digitalWrite(LED_BLUE, HIGH);
  
  // Initialize preferences
  preferences.begin("pool-monitor", false);
  
  // Get device ID from MAC address
  deviceId = WiFi.macAddress();
  deviceId.replace(":", "");
  
  Serial.println("\n=== Pool Water Quality Monitor ===");
  Serial.println("Device ID: " + deviceId);
  
  // Play startup melody
  playStartupMelody();
  
  // Initialize temperature sensor
  tempSensor.begin();
  
  // Setup WiFi
  setupWiFi();
  
  // Fetch initial configuration from API
  if (WiFi.status() == WL_CONNECTED) {
    fetchConfigFromAPI();
  }
}

void loop() {
  unsigned long currentMillis = millis();
  
  // Check for WiFi reset button
  checkButton();
  
  // Read sensors periodically
  if (currentMillis - lastSensorRead >= sensorReadInterval) {
    lastSensorRead = currentMillis;
    readSensors();
    currentStatus = evaluateWaterQuality();
  }
  
  // Post data to API periodically
  if (WiFi.status() == WL_CONNECTED && 
      currentMillis - lastAPIPost >= apiPostInterval) {
    lastAPIPost = currentMillis;
    postDataToAPI();
  }
  
  // Fetch configuration from API periodically
  if (WiFi.status() == WL_CONNECTED && 
      currentMillis - lastConfigFetch >= configFetchInterval) {
    lastConfigFetch = currentMillis;
    fetchConfigFromAPI();
  }
  
  // Update LED status based on water quality
  updateLEDStatus();
  
  delay(50); // Small delay for stability
}

void setupWiFi() {
  WiFiManager wifiManager;
  
  // Configure LED for AP mode (Blue blinking)
  blinkLED(0, 0, 255, 3, 200);
  
  // Set custom AP name
  String apName = "PoolMonitor_" + deviceId.substring(6);
  
  // Set timeout for configuration portal
  wifiManager.setConfigPortalTimeout(180); // 3 minutes
  
  // Callback for when entering config mode
  wifiManager.setAPCallback([](WiFiManager *myWiFiManager) {
    Serial.println("Entered config mode");
    Serial.println("AP Name: " + String(myWiFiManager->getConfigPortalSSID()));
    // Blink blue LED fast
    for(int i = 0; i < 10; i++) {
      setLEDColor(0, 0, 255);
      delay(100);
      setLEDColor(0, 0, 0);
      delay(100);
    }
  });
  
  // Try to connect to saved WiFi or start config portal
  if (!wifiManager.autoConnect(apName.c_str())) {
    Serial.println("Failed to connect and timeout occurred");
    // Blink red and restart
    blinkLED(255, 0, 0, 5, 300);
    ESP.restart();
  }
  
  // Successfully connected
  Serial.println("Connected to WiFi!");
  Serial.println("IP address: " + WiFi.localIP().toString());
  
  // Success indication - Green blink with success tone
  blinkLED(0, 255, 0, 3, 500);
  playTone(1000, 200);
  delay(100);
  playTone(1500, 200);
}

void checkButton() {
  if (digitalRead(BUTTON_PIN) == LOW) {
    if (!buttonPressed) {
      buttonPressed = true;
      buttonPressStart = millis();
    } else {
      // Check if button held for 5 seconds
      if (millis() - buttonPressStart >= 5000) {
        Serial.println("Resetting WiFi settings...");
        
        // Play reset melody
        playResetMelody();
        
        // Fast red blink
        blinkLED(255, 0, 0, 10, 100);
        
        // Reset WiFi settings
        WiFiManager wifiManager;
        wifiManager.resetSettings();
        
        // Clear preferences
        preferences.clear();
        
        Serial.println("WiFi settings cleared. Restarting...");
        delay(1000);
        ESP.restart();
      }
    }
  } else {
    buttonPressed = false;
  }
}

void readSensors() {
  // Read pH sensor (0-14 range, assuming 0-4095 ADC = 0-14 pH)
  int phRaw = analogRead(PH_SENSOR);
  currentPh = (phRaw / 4095.0 * 14.0 * phSlope) + phOffset;
  
  // Read turbidity sensor (lower voltage = higher turbidity)
  int turbidityRaw = analogRead(TURBIDITY_SENSOR);
  float turbidityVoltage = turbidityRaw / 4095.0 * 3.3;
  // Convert voltage to NTU (example calibration)
  currentTurbidity = ((-1120.4 * turbidityVoltage * turbidityVoltage) + 
                      (5742.3 * turbidityVoltage) - 4352.9) + turbidityOffset;
  if (currentTurbidity < 0) currentTurbidity = 0;
  
  // Read temperature sensor (DS18B20)
  tempSensor.requestTemperatures();
  currentTemp = tempSensor.getTempCByIndex(0) + tempOffset;
  
  // Debug output
  Serial.printf("pH: %.2f | Turbidity: %.2f NTU | Temp: %.2f°C\n", 
                currentPh, currentTurbidity, currentTemp);
}

WaterQuality evaluateWaterQuality() {
  bool phCritical = (currentPh < phThresholds.optimal - 1.0) || 
                    (currentPh > phThresholds.critical);
  bool turbCritical = currentTurbidity > turbidityThresholds.critical;
  bool tempCritical = (currentTemp < tempThresholds.optimal - 4.0) || 
                      (currentTemp > tempThresholds.critical);
  
  bool phAcceptable = (currentPh >= phThresholds.optimal - 1.0 && 
                       currentPh <= phThresholds.optimal) ||
                      (currentPh > phThresholds.optimal && 
                       currentPh <= phThresholds.acceptable);
  bool turbAcceptable = (currentTurbidity > turbidityThresholds.optimal && 
                         currentTurbidity <= turbidityThresholds.acceptable);
  bool tempAcceptable = (currentTemp >= tempThresholds.optimal - 4.0 && 
                         currentTemp < tempThresholds.optimal) ||
                        (currentTemp > tempThresholds.optimal && 
                         currentTemp <= tempThresholds.acceptable);
  
  if (phCritical || turbCritical || tempCritical) {
    return CRITICAL;
  } else if (phAcceptable || turbAcceptable || tempAcceptable) {
    return ACCEPTABLE;
  } else {
    return OPTIMAL;
  }
}

void updateLEDStatus() {
  static unsigned long lastBlink = 0;
  static bool blinkState = false;
  static unsigned long lastBeep = 0;
  
  unsigned long currentMillis = millis();
  
  switch (currentStatus) {
    case OPTIMAL:
      // Solid green, slow blink
      if (currentMillis - lastBlink >= 2000) {
        lastBlink = currentMillis;
        blinkState = !blinkState;
        if (blinkState) {
          setLEDColor(0, 255, 0); // Green
        } else {
          setLEDColor(0, 0, 0);   // Off
        }
      }
      break;
      
    case ACCEPTABLE:
      // Orange/Yellow blink (medium speed)
      if (currentMillis - lastBlink >= 1000) {
        lastBlink = currentMillis;
        blinkState = !blinkState;
        if (blinkState) {
          setLEDColor(255, 128, 0); // Orange
        } else {
          setLEDColor(0, 0, 0);     // Off
        }
      }
      break;
      
    case CRITICAL:
      // Fast red blink with beep
      if (currentMillis - lastBlink >= 300) {
        lastBlink = currentMillis;
        blinkState = !blinkState;
        if (blinkState) {
          setLEDColor(255, 0, 0); // Red
        } else {
          setLEDColor(0, 0, 0);   // Off
        }
      }
      
      // Beep every 2 seconds
      if (currentMillis - lastBeep >= 2000) {
        lastBeep = currentMillis;
        playTone(2000, 200);
      }
      break;
  }
}

void setLEDColor(int r, int g, int b) {
  // Common anode: LOW = ON, HIGH = OFF
  analogWrite(LED_RED, 255 - r);
  analogWrite(LED_GREEN, 255 - g);
  analogWrite(LED_BLUE, 255 - b);
}

void blinkLED(int r, int g, int b, int times, int delayMs) {
  for (int i = 0; i < times; i++) {
    setLEDColor(r, g, b);
    delay(delayMs);
    setLEDColor(0, 0, 0);
    delay(delayMs);
  }
}

void playTone(int frequency, int duration) {
  tone(BUZZER_PIN, frequency, duration);
  delay(duration);
  noTone(BUZZER_PIN);
}

void playStartupMelody() {
  int melody[] = {523, 587, 659, 784}; // C, D, E, G
  for (int i = 0; i < 4; i++) {
    playTone(melody[i], 150);
    delay(50);
  }
}

void playResetMelody() {
  int melody[] = {784, 659, 587, 523}; // G, E, D, C (descending)
  for (int i = 0; i < 4; i++) {
    playTone(melody[i], 150);
    delay(50);
  }
  playTone(392, 400); // Long low G
}

void postDataToAPI() {
  if (WiFi.status() != WL_CONNECTED) return;
  
  HTTPClient http;
  String url = String(API_BASE_URL) + DATA_ENDPOINT;
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  // Create JSON payload
  StaticJsonDocument<512> doc;
  doc["device_id"] = deviceId;
  doc["timestamp"] = millis() / 1000; // seconds since boot
  
  JsonObject sensors = doc.createNestedObject("sensors");
  sensors["ph"] = round(currentPh * 100) / 100.0;
  sensors["turbidity"] = round(currentTurbidity * 100) / 100.0;
  sensors["temperature"] = round(currentTemp * 100) / 100.0;
  
  JsonObject status = doc.createNestedObject("status");
  status["water_quality"] = (currentStatus == OPTIMAL) ? "optimal" : 
                            (currentStatus == ACCEPTABLE) ? "acceptable" : "critical";
  status["wifi_rssi"] = WiFi.RSSI();
  status["uptime"] = millis() / 1000;
  
  String payload;
  serializeJson(doc, payload);
  
  Serial.println("Posting to API: " + payload);
  
  int httpResponseCode = http.POST(payload);
  
  if (httpResponseCode > 0) {
    Serial.printf("API Response: %d\n", httpResponseCode);
    String response = http.getString();
    Serial.println("Response: " + response);
  } else {
    Serial.printf("Error posting data: %s\n", http.errorToString(httpResponseCode).c_str());
  }
  
  http.end();
}

void fetchConfigFromAPI() {
  if (WiFi.status() != WL_CONNECTED) return;
  
  HTTPClient http;
  String url = String(API_BASE_URL) + CONFIG_ENDPOINT + "?device_id=" + deviceId;
  
  http.begin(url);
  int httpResponseCode = http.GET();
  
  if (httpResponseCode == 200) {
    String response = http.getString();
    Serial.println("Config received: " + response);
    
    StaticJsonDocument<1024> doc;
    DeserializationError error = deserializeJson(doc, response);
    
    if (!error) {
      // Update calibration values
      if (doc.containsKey("calibration")) {
        JsonObject cal = doc["calibration"];
        phOffset = cal["ph_offset"] | phOffset;
        phSlope = cal["ph_slope"] | phSlope;
        turbidityOffset = cal["turbidity_offset"] | turbidityOffset;
        turbiditySlope = cal["turbidity_slope"] | turbiditySlope;
        tempOffset = cal["temp_offset"] | tempOffset;
      }
      
      // Update thresholds
      if (doc.containsKey("thresholds")) {
        JsonObject thresh = doc["thresholds"];
        
        if (thresh.containsKey("ph")) {
          phThresholds.optimal = thresh["ph"]["optimal"] | phThresholds.optimal;
          phThresholds.acceptable = thresh["ph"]["acceptable"] | phThresholds.acceptable;
          phThresholds.critical = thresh["ph"]["critical"] | phThresholds.critical;
        }
        
        if (thresh.containsKey("turbidity")) {
          turbidityThresholds.optimal = thresh["turbidity"]["optimal"] | turbidityThresholds.optimal;
          turbidityThresholds.acceptable = thresh["turbidity"]["acceptable"] | turbidityThresholds.acceptable;
          turbidityThresholds.critical = thresh["turbidity"]["critical"] | turbidityThresholds.critical;
        }
        
        if (thresh.containsKey("temperature")) {
          tempThresholds.optimal = thresh["temperature"]["optimal"] | tempThresholds.optimal;
          tempThresholds.acceptable = thresh["temperature"]["acceptable"] | tempThresholds.acceptable;
          tempThresholds.critical = thresh["temperature"]["critical"] | tempThresholds.critical;
        }
      }
      
      // Update intervals
      if (doc.containsKey("intervals")) {
        apiPostInterval = doc["intervals"]["post_interval"] | apiPostInterval;
        configFetchInterval = doc["intervals"]["config_interval"] | configFetchInterval;
      }
      
      Serial.println("Configuration updated successfully");
    }
  } else {
    Serial.printf("Failed to fetch config: %d\n", httpResponseCode);
  }
  
  http.end();
}