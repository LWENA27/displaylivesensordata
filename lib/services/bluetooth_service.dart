import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

enum BluetoothConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _writeCharacteristic;
  // ignore: unused_field
  fbp.BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<List<int>>? _dataSubscription;
  
  final StreamController<BluetoothConnectionStatus> _statusController =
      StreamController<BluetoothConnectionStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _dataController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<BluetoothConnectionStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  
  BluetoothConnectionStatus _currentStatus = BluetoothConnectionStatus.disconnected;
  BluetoothConnectionStatus get currentStatus => _currentStatus;

  String _buffer = '';

  void _updateStatus(BluetoothConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  Future<List<fbp.BluetoothDevice>> getAvailableDevices() async {
    try {
      // Get bonded (paired) devices
      List<fbp.BluetoothDevice> bondedDevices = await fbp.FlutterBluePlus.bondedDevices;
      
      // Filter for devices that might be HC-05 modules
      List<fbp.BluetoothDevice> hc05Devices = bondedDevices.where((device) {
        String name = device.platformName.toLowerCase();
        return name.contains('hc-05') || 
               name.contains('hc05') || 
               name.contains('bluetooth') ||
               name.isEmpty; // Include unnamed devices as they might be HC-05
      }).toList();
      
      return hc05Devices.isNotEmpty ? hc05Devices : bondedDevices;
    } catch (e) {
      print('Error getting devices: $e');
      return [];
    }
  }

  Future<bool> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      _updateStatus(BluetoothConnectionStatus.connecting);
      
      // Connect to the device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      
      // Discover services
      List<fbp.BluetoothService> services = await device.discoverServices();
      
      // Look for Serial Port Profile (SPP) service or any service with write/notify characteristics
      for (fbp.BluetoothService service in services) {
        for (fbp.BluetoothCharacteristic characteristic in service.characteristics) {
          // Look for write characteristic
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
          }
          
          // Look for notify characteristic
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            _notifyCharacteristic = characteristic;
            
            // Subscribe to notifications
            await characteristic.setNotifyValue(true);
            _dataSubscription = characteristic.onValueReceived.listen(
              _onDataReceived,
              onError: (error) {
                print('Notification error: $error');
                _updateStatus(BluetoothConnectionStatus.error);
              },
            );
          }
        }
      }
      
      _updateStatus(BluetoothConnectionStatus.connected);
      return true;
    } catch (e) {
      print('Connection failed: $e');
      _updateStatus(BluetoothConnectionStatus.error);
      return false;
    }
  }

  void _onDataReceived(List<int> data) {
    try {
      // Convert bytes to string and add to buffer
      String received = String.fromCharCodes(data);
      _buffer += received;
      
      // Process complete JSON messages
      _processBuffer();
    } catch (e) {
      print('Error processing data: $e');
    }
  }

  void _processBuffer() {
    // Look for complete JSON objects in the buffer
    while (_buffer.contains('{') && _buffer.contains('}')) {
      int startIndex = _buffer.indexOf('{');
      int endIndex = _buffer.indexOf('}', startIndex) + 1;
      
      if (startIndex != -1 && endIndex > startIndex) {
        String jsonString = _buffer.substring(startIndex, endIndex);
        _buffer = _buffer.substring(endIndex);
        
        try {
          Map<String, dynamic> data = jsonDecode(jsonString);
          _dataController.add(data);
        } catch (e) {
          print('JSON parsing error: $e');
        }
      } else {
        break;
      }
    }
    
    // Keep buffer size manageable
    if (_buffer.length > 1000) {
      _buffer = _buffer.substring(_buffer.length - 500);
    }
  }

  Future<void> disconnect() async {
    try {
      await _dataSubscription?.cancel();
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      _connectedDevice = null;
      _writeCharacteristic = null;
      _notifyCharacteristic = null;
      _dataSubscription = null;
      _buffer = '';
      _updateStatus(BluetoothConnectionStatus.disconnected);
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  bool get isConnected => _connectedDevice != null && _connectedDevice!.isConnected;

  // Method to send data to the device (for future use)
  Future<void> sendData(String data) async {
    if (_writeCharacteristic != null && isConnected) {
      try {
        await _writeCharacteristic!.write(data.codeUnits);
      } catch (e) {
        print('Error sending data: $e');
      }
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _dataController.close();
  }
}
