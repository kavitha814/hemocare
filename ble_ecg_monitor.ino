#include <WiFi.h>

// WiFi Credentials
const char* ssid = "STIC";
const char* password = "stic@123";

// TCP Server on port 8080
WiFiServer server(8080);
WiFiClient client;

// Pins
const int ECG_PIN = 32;
const int LO_PLUS = 14; 
const int LO_MINUS = 27;

// BPM Logic
unsigned long lastBeatTime = 0;
int bpm = 0;

// Filter Logic (Medical Grade Smoothing)
const int FILTER_SIZE = 20; // Increased from 5 for much smoother signal
int filterBuffer[FILTER_SIZE];
int filterIdx = 0;

void setup() {
  Serial.begin(115200);

  pinMode(LO_PLUS, INPUT); 
  pinMode(LO_MINUS, INPUT);

  // Connect to WiFi
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  server.begin();
  Serial.println("TCP Server started on port 8080");
}

void loop() {
  // Check for new client if not connected
  if (!client || !client.connected()) {
    client = server.available();
    if (client) {
      Serial.println(">>> Client Connected via WiFi");
    }
  }

  if (client && client.connected()) {
    int ecgValue = 0;
    int raw = analogRead(ECG_PIN);
    bool hardwareLeadsOff = (digitalRead(LO_PLUS) == 1 || digitalRead(LO_MINUS) == 1);
    
    // Software Leads-Off: If signal is at 4095 (max) or 0 (min) constantly, it's floating
    bool softwareLeadsOff = (raw >= 4090 || raw <= 5);

    if (hardwareLeadsOff || softwareLeadsOff) {
      ecgValue = -5000; // Sentinel value for "Leads Off"
      bpm = 0;
      if (millis() % 1000 < 50) Serial.println(">>> [LEADS OFF] Ensure electrodes are attached.");
    } else {
      // 1. Digital Filtering (Strong Moving Average)
      filterBuffer[filterIdx] = raw;
      filterIdx = (filterIdx + 1) % FILTER_SIZE;
      
      long sum = 0;
      for(int i=0; i<FILTER_SIZE; i++) sum += filterBuffer[i];
      int filteredRaw = sum / FILTER_SIZE;

      // 2. Center the signal at 0 by subtracting the baseline (approx 1950)
      ecgValue = filteredRaw - 1950;
      
      // 3. BPM Calculation (Threshold based)
      if (ecgValue > 250) { 
        unsigned long now = millis();
        if (now - lastBeatTime > 400) { // Max 150 BPM
          bpm = 60000 / (now - lastBeatTime);
          lastBeatTime = now;
        }
      }

      // 4. BPM Timeout: Reset to 0 if no beat detected for 2 seconds
      if (millis() - lastBeatTime > 2000) {
        bpm = 0;
        
        // 5. AUTO-MUTE (NOISE GATE):
        // If no heartbeats are detected for 2.5s and the signal is near baseline,
        // force it to exactly 0 to show a perfectly flat professional line.
        if (millis() - lastBeatTime > 2500 && abs(ecgValue) < 150) {
          ecgValue = 0;
        }
      }
    }

    // Send data as "BPM,RAW_VALUE\n" string
    String data = String(bpm) + "," + String(ecgValue) + "\n";
    client.print(data);
    
    // Also print to Serial for debugging
    Serial.print(data);
    
    delay(10); // 100Hz sampling
  }
}
