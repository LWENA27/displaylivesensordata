# Soil Sensor Monitor - Flutter Android App

A Flutter Android application that connects to an HC-05 Bluetooth module to receive pH and NPK sensor data from an Arduino Nano in real-time.

## Features

- 🔵 **Bluetooth Connectivity**: Connect to HC-05 Bluetooth modules
- 🌱 **pH Monitoring**: Real-time pH level display with status indicators
- 📊 **NPK Ready**: Prepared for future Nitrogen, Phosphorus, Potassium sensors
- 🔄 **Automatic JSON Parsing**: Processes JSON messages like `{"ph": 6.7}` and `{"ph": 6.7, "n": 50, "p": 40, "k": 60}`
- 📱 **Modern UI**: Clean, Material Design 3 interface with soil-themed colors
- 🔐 **Permission Management**: Automatic Bluetooth permission handling
- 🔄 **Connection Status**: Visual indicators for connection state
- 🎯 **Arduino Compatible**: Ready for Arduino Nano with soil sensors

## Screenshots

The app provides:
- Bluetooth status monitoring
- Device selection dropdown
- Connect/Disconnect controls
- pH level display with optimal/acceptable/poor indicators
- NPK nutrient display (ready for future implementation)
- Clear instructions for users

## Prerequisites

### Hardware Requirements
- Android device with Bluetooth capability
- Arduino Nano with pH sensor
- HC-05 Bluetooth module
- Properly wired pH sensor circuit
- Future: NPK sensors (Nitrogen, Phosphorus, Potassium)

### Software Requirements
- Flutter SDK (3.8.1 or higher)
- Android SDK
- Android device with API level 16+ (Android 4.1+)

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd athanas
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## Arduino Setup

### Hardware Connections
Connect your pH sensor to the Arduino Nano and HC-05 module:

```
HC-05 Module:
- VCC → 5V (or 3.3V)
- GND → GND
- RX → Pin 2 (SoftwareSerial)
- TX → Pin 3 (SoftwareSerial)

pH Sensor:
- Follow your specific pH sensor wiring diagram
- Typically connects to analog pin A0
- VCC → 5V, GND → GND, Signal → A0

Future NPK Sensors:
- Nitrogen sensor → A1
- Phosphorus sensor → A2  
- Potassium sensor → A3
```

### Arduino Code Example
```cpp
#include <SoftwareSerial.h>

SoftwareSerial bluetooth(2, 3); // RX, TX
const int PH_PIN = A0;

void setup() {
  Serial.begin(9600);
  bluetooth.begin(9600);
  pinMode(PH_PIN, INPUT);
}

void loop() {
  // Read pH sensor value
  float phValue = readPHSensor();
  
  // Create and send JSON message
  bluetooth.print("{\"ph\":");
  bluetooth.print(phValue, 1);
  bluetooth.println("}");
  
  delay(1000); // Send data every second
}

float readPHSensor() {
  // Read analog value and convert to pH
  int analogValue = analogRead(PH_PIN);
  float voltage = analogValue * 5.0 / 1024.0;
  
  // Convert voltage to pH (adjust formula for your sensor)
  float phValue = 7.0 - ((voltage - 2.5) / 0.18);
  
  // Ensure valid pH range
  if (phValue < 0) phValue = 0;
  if (phValue > 14) phValue = 14;
  
  return phValue;
}

// Future NPK implementation example:
/*
void sendAllSensorData() {
  float ph = readPHSensor();
  int n = readNitrogenSensor();
  int p = readPhosphorusSensor();
  int k = readPotassiumSensor();
  
  bluetooth.print("{\"ph\":");
  bluetooth.print(ph, 1);
  bluetooth.print(",\"n\":");
  bluetooth.print(n);
  bluetooth.print(",\"p\":");
  bluetooth.print(p);
  bluetooth.print(",\"k\":");
  bluetooth.print(k);
  bluetooth.println("}");
}
*/
```

## App Usage

1. **Enable Bluetooth**: Ensure Bluetooth is enabled on your Android device
2. **Pair HC-05**: Pair your HC-05 module with your Android device first
3. **Open App**: Launch the EC Sensor Monitor app
4. **Grant Permissions**: Allow the app to access Bluetooth and location services
5. **Select Device**: Choose your HC-05 device from the dropdown
6. **Connect**: Tap the Connect button
7. **Monitor Data**: EC values will appear automatically as JSON data is received

## Permissions

The app requires the following permissions:
- `BLUETOOTH` - Basic Bluetooth functionality
- `BLUETOOTH_ADMIN` - Bluetooth administration
- `ACCESS_COARSE_LOCATION` - Required for Bluetooth device discovery
- `ACCESS_FINE_LOCATION` - Enhanced location access
- `BLUETOOTH_SCAN` - Android 12+ Bluetooth scanning
- `BLUETOOTH_CONNECT` - Android 12+ Bluetooth connection

## Project Structure

```
lib/
├── main.dart                 # Main app entry point and UI
├── services/
│   ├── bluetooth_service.dart # Bluetooth connection and data handling
│   └── permission_service.dart # Permission management
└── ...
```

## Dependencies

- `flutter_bluetooth_serial: ^0.4.0` - Bluetooth Serial communication
- `permission_handler: ^11.3.1` - Permission management

## Troubleshooting

### Common Issues

1. **No devices found**:
   - Ensure HC-05 is paired with your Android device
   - Check if Bluetooth is enabled
   - Try refreshing the device list

2. **Connection failed**:
   - Verify HC-05 is not connected to another device
   - Check if the device is within range
   - Restart Bluetooth on your phone

3. **No data received**:
   - Verify Arduino code is sending JSON in correct format: `{"ec": value}`
   - Check serial baud rates match (9600)
   - Ensure HC-05 TX/RX pins are connected correctly

4. **Permission errors**:
   - Grant all requested permissions in Android settings
   - For Android 12+, ensure precise location is enabled

## Future Enhancements

- 📈 Data logging and export functionality
- 📊 Real-time graphs and charts
- 🔔 Alert notifications for threshold values
- 💾 Local database storage
- 🌐 Remote data synchronization
- 📋 Multiple sensor support

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue in the GitHub repository
- Check the troubleshooting section above
- Verify your hardware connections and Arduino code

## Acknowledgments

- Flutter team for the excellent framework
- flutter_bluetooth_serial package maintainers
- Arduino community for sensor integration examples
# displaylivesensordata
