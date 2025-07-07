/*
 * Soil Sensor Monitor - Arduino Code
 * 
 * This Arduino sketch reads pH sensor data and sends it via HC-05 Bluetooth
 * module to the Flutter Android app in JSON format.
 * Prepared for future NPK sensor integration.
 * 
 * Hardware connections:
 * - HC-05 VCC to 5V (or 3.3V)
 * - HC-05 GND to GND
 * - HC-05 RX to Pin 2 (through voltage divider if using 5V)
 * - HC-05 TX to Pin 3
 * - pH Sensor according to your sensor's datasheet
 * - Future NPK sensors will be added
 */

#include <SoftwareSerial.h>

// Create a SoftwareSerial object for HC-05 communication
SoftwareSerial bluetooth(2, 3); // RX, TX pins

// pH Sensor variables
const int PH_PIN = A0;        // Analog pin for pH sensor
const float VREF = 5.0;       // Reference voltage
const float PH_OFFSET = 0.0;  // pH calibration offset

// Future NPK sensor pins (uncomment when adding NPK sensors)
// const int N_PIN = A1;      // Nitrogen sensor pin
// const int P_PIN = A2;      // Phosphorus sensor pin  
// const int K_PIN = A3;      // Potassium sensor pin

// Timing variables
unsigned long lastReading = 0;
const unsigned long READING_INTERVAL = 1000; // Send data every 1 second

void setup() {
  // Initialize Serial communications
  Serial.begin(9600);
  bluetooth.begin(9600);
  
  // Initialize pins
  pinMode(PH_PIN, INPUT);
  // pinMode(N_PIN, INPUT);   // Uncomment when adding NPK sensors
  // pinMode(P_PIN, INPUT);
  // pinMode(K_PIN, INPUT);
  
  // Wait for connections to stabilize
  delay(2000);
  
  Serial.println("Soil Sensor Monitor Started");
  bluetooth.println("{\"status\":\"ready\"}");
}

void loop() {
  // Check if it's time for a new reading
  if (millis() - lastReading >= READING_INTERVAL) {
    
    // Read pH sensor value
    float phValue = readPHSensor();
    
    // Read NPK values (uncomment when sensors are added)
    // int nValue = readNSensor();
    // int pValue = readPSensor();
    // int kValue = readKSensor();
    
    // Send JSON data to Flutter app via Bluetooth
    sendSensorData(phValue);
    // sendAllSensorData(phValue, nValue, pValue, kValue); // Use this when NPK sensors are added
    
    // Also print to Serial monitor for debugging
    Serial.print("pH Value: ");
    Serial.println(phValue);
    
    lastReading = millis();
  }
}

float readPHSensor() {
  // Read multiple samples for stability
  int sampleCount = 10;
  long sum = 0;
  
  for (int i = 0; i < sampleCount; i++) {
    sum += analogRead(PH_PIN);
    delay(10);
  }
  
  // Calculate average
  float voltage = (float)(sum / sampleCount) * VREF / 1024.0;
  
  // Convert voltage to pH value (this formula depends on your specific sensor)
  // This is a simplified calculation - adjust based on your sensor's datasheet
  float phValue;
  
  // Example conversion for a typical pH sensor
  // pH = 7.0 + ((2.5 - voltage) / 0.18);
  // Adjust this formula based on your specific pH sensor calibration
  phValue = 7.0 - ((voltage - 2.5) / 0.18) + PH_OFFSET;
  
  // Ensure reasonable bounds for pH (typically 0-14)
  if (phValue < 0) phValue = 0;
  if (phValue > 14) phValue = 14;
  
  return phValue;
}

// Future NPK sensor reading functions (implement when sensors are added)
/*
int readNSensor() {
  // Implement nitrogen sensor reading
  // Return nitrogen value in mg/kg or ppm
  return 0;
}

int readPSensor() {
  // Implement phosphorus sensor reading
  // Return phosphorus value in mg/kg or ppm
  return 0;
}

int readKSensor() {
  // Implement potassium sensor reading
  // Return potassium value in mg/kg or ppm
  return 0;
}
*/

void sendSensorData(float phValue) {
  // Create JSON string with pH only and send via Bluetooth
  bluetooth.print("{\"ph\":");
  bluetooth.print(phValue, 1); // 1 decimal place for pH
  bluetooth.println("}");
}

// Function to send all sensor data (use when NPK sensors are added)
/*
void sendAllSensorData(float phValue, int nValue, int pValue, int kValue) {
  // Create JSON string with all sensor values
  bluetooth.print("{\"ph\":");
  bluetooth.print(phValue, 1);
  bluetooth.print(",\"n\":");
  bluetooth.print(nValue);
  bluetooth.print(",\"p\":");
  bluetooth.print(pValue);
  bluetooth.print(",\"k\":");
  bluetooth.print(kValue);
  bluetooth.println("}");
}
*/

// Optional: Function to send test data (useful for debugging)
void sendTestData() {
  static float testPHValue = 6.5;
  
  bluetooth.print("{\"ph\":");
  bluetooth.print(testPHValue, 1);
  bluetooth.println("}");
  
  // Increment test value for next time
  testPHValue += 0.2;
  if (testPHValue > 8.0) testPHValue = 6.0;
}

// Optional: Function to send test data with NPK values
void sendTestDataWithNPK() {
  static float testPHValue = 6.5;
  static int testNValue = 40;
  static int testPValue = 30;
  static int testKValue = 50;
  
  bluetooth.print("{\"ph\":");
  bluetooth.print(testPHValue, 1);
  bluetooth.print(",\"n\":");
  bluetooth.print(testNValue);
  bluetooth.print(",\"p\":");
  bluetooth.print(testPValue);
  bluetooth.print(",\"k\":");
  bluetooth.print(testKValue);
  bluetooth.println("}");
  
  // Increment test values for next time
  testPHValue += 0.2;
  testNValue += 5;
  testPValue += 3;
  testKValue += 4;
  
  if (testPHValue > 8.0) testPHValue = 6.0;
  if (testNValue > 80) testNValue = 20;
  if (testPValue > 60) testPValue = 20;
  if (testKValue > 90) testKValue = 30;
}

// Optional: Function to handle commands from Flutter app
void handleBluetoothCommands() {
  if (bluetooth.available()) {
    String command = bluetooth.readStringUntil('\n');
    command.trim();
    
    if (command == "ping") {
      bluetooth.println("{\"status\":\"pong\"}");
    } else if (command == "test") {
      sendTestData();
    } else if (command == "test_npk") {
      sendTestDataWithNPK();
    } else if (command == "calibrate") {
      bluetooth.println("{\"status\":\"calibration_mode\"}");
      // Add calibration logic here
    }
  }
}
