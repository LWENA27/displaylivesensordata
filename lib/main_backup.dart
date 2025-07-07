import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import 'dart:async';
import 'services/bluetooth_service.dart';
import 'services/permission_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soil Sensor Monitor',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SoilSensorHomePage(),
    );
  }
}

class SoilSensorHomePage extends StatefulWidget {
  const SoilSensorHomePage({super.key});

  @override
  State<SoilSensorHomePage> createState() => _SoilSensorHomePageState();
}

class _SoilSensorHomePageState extends State<SoilSensorHomePage> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  
  // Sensor values
  double? _currentPHValue;
  double? _currentNValue;
  double? _currentPValue;
  double? _currentKValue;
  
  BluetoothConnectionStatus _connectionStatus =
      BluetoothConnectionStatus.disconnected;
  bool _isBluetoothEnabled = false;
  DateTime? _lastDataReceived;

  StreamSubscription<BluetoothConnectionStatus>? _statusSubscription;
  StreamSubscription<Map<String, dynamic>>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
    _setupListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _dataSubscription?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }

  void _setupListeners() {
    _statusSubscription = _bluetoothService.statusStream.listen((status) {
      setState(() {
        _connectionStatus = status;
      });
    });

    _dataSubscription = _bluetoothService.dataStream.listen((data) {
      setState(() {
        // Handle pH sensor data
        if (data.containsKey('ph')) {
          _currentPHValue = (data['ph'] as num).toDouble();
          _lastDataReceived = DateTime.now();
        }
        
        // Handle NPK sensor data (for future use)
        if (data.containsKey('n')) {
          _currentNValue = (data['n'] as num).toDouble();
        }
        if (data.containsKey('p')) {
          _currentPValue = (data['p'] as num).toDouble();
        }
        if (data.containsKey('k')) {
          _currentKValue = (data['k'] as num).toDouble();
        }
      });
    });
  }

  Future<void> _initializeBluetooth() async {
    // Check if Bluetooth is enabled
    bool isEnabled = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    setState(() {
      _isBluetoothEnabled = isEnabled;
    });

    if (!_isBluetoothEnabled) {
      // Request to enable Bluetooth
      await FlutterBluePlus.turnOn();
      isEnabled = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      setState(() {
        _isBluetoothEnabled = isEnabled;
      });
    }

    if (_isBluetoothEnabled) {
      await _requestPermissions();
      await _refreshDevices();
    }
  }

  Future<void> _requestPermissions() async {
    bool permissionsGranted =
        await PermissionService.requestBluetoothPermissions();
    if (!permissionsGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bluetooth permissions are required for this app to work',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshDevices() async {
    if (!_isBluetoothEnabled) return;

    List<BluetoothDevice> devices = await _bluetoothService
        .getAvailableDevices();
    setState(() {
      _devices = devices;
    });
  }

  Future<void> _connectToDevice() async {
    if (_selectedDevice == null) return;

    bool success = await _bluetoothService.connectToDevice(_selectedDevice!);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to connect to device'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    await _bluetoothService.disconnect();
  }

  Color _getStatusColor() {
    switch (_connectionStatus) {
      case BluetoothConnectionStatus.connected:
        return Colors.green;
      case BluetoothConnectionStatus.connecting:
        return Colors.orange;
      case BluetoothConnectionStatus.error:
        return Colors.red;
      case BluetoothConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_connectionStatus) {
      case BluetoothConnectionStatus.connected:
        return 'Connected';
      case BluetoothConnectionStatus.connecting:
        return 'Connecting...';
      case BluetoothConnectionStatus.error:
        return 'Error';
      case BluetoothConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  Color _getPHStatusColor() {
    if (_currentPHValue == null) return Colors.grey;
    
    if (_currentPHValue! >= 6.0 && _currentPHValue! <= 7.5) {
      return Colors.green; // Optimal pH range for most plants
    } else if (_currentPHValue! >= 5.5 && _currentPHValue! <= 8.0) {
      return Colors.orange; // Acceptable pH range
    } else {
      return Colors.red; // Poor pH range
    }
  }

  String _getPHStatusText() {
    if (_currentPHValue == null) return '';
    
    if (_currentPHValue! >= 6.0 && _currentPHValue! <= 7.5) {
      return 'Optimal';
    } else if (_currentPHValue! >= 5.5 && _currentPHValue! <= 8.0) {
      return 'Acceptable';
    } else if (_currentPHValue! < 5.5) {
      return 'Too Acidic';
    } else {
      return 'Too Alkaline';
    }
  }

  Widget _buildNPKValue(String nutrient, double? value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: value != null ? color : Colors.grey[300],
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nutrient,
                style: TextStyle(
                  color: value != null ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value != null ? '${value.toInt()}' : '--',
                style: TextStyle(
                  color: value != null ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getNutrientName(nutrient),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getNutrientName(String nutrient) {
    switch (nutrient) {
      case 'N':
        return 'Nitrogen';
      case 'P':
        return 'Phosphorus';
      case 'K':
        return 'Potassium';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Sensor Monitor'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDevices,
            tooltip: 'Refresh Devices',
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bluetooth Status Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bluetooth Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.bluetooth,
                          color: _isBluetoothEnabled
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(_isBluetoothEnabled ? 'Enabled' : 'Disabled'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Device Selection Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Arduino Nano Device',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BluetoothDevice>(
                      value: _selectedDevice,
                      hint: const Text('Choose a paired device'),
                      items: _devices.map((device) {
                        return DropdownMenuItem(
                          value: device,
                          child: Text(
                            '${device.platformName.isNotEmpty ? device.platformName : 'Unknown'} (${device.remoteId})',
                          ),
                        );
                      }).toList(),
                      onChanged: (device) {
                        setState(() {
                          _selectedDevice = device;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connection Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _selectedDevice != null &&
                            _connectionStatus ==
                                BluetoothConnectionStatus.disconnected
                        ? _connectToDevice
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.bluetooth_connected),
                    label: const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _connectionStatus == BluetoothConnectionStatus.connected
                        ? _disconnect
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sensor Values Display
            // pH Sensor Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, color: Colors.green[700], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'pH Level',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentPHValue != null
                          ? '${_currentPHValue!.toStringAsFixed(1)} pH'
                          : '-- pH',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: _currentPHValue != null ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentPHValue != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPHStatusColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPHStatusText(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // NPK Sensors Card (for future implementation)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.grass, color: Colors.brown[600], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'NPK Nutrients',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.brown[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNPKValue('N', _currentNValue, Colors.blue[600]!),
                        _buildNPKValue('P', _currentPValue, Colors.orange[600]!),
                        _buildNPKValue('K', _currentKValue, Colors.purple[600]!),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentNValue != null || _currentPValue != null || _currentKValue != null
                          ? ''
                          : 'NPK sensors will be added in future updates',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Last Updated Info
            if (_lastDataReceived != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Last updated: ${_lastDataReceived!.toLocal().toString().split('.')[0]}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Instructions
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Make sure your Arduino Nano with HC-05 is paired with this device\n'
                      '2. Select the HC-05 device from the dropdown\n'
                      '3. Tap Connect to establish Bluetooth connection\n'
                      '4. pH sensor data will appear automatically\n'
                      '5. Current JSON format: {"ph": 6.7}\n'
                      '6. Future NPK format: {"ph": 6.7, "n": 50, "p": 40, "k": 60}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
