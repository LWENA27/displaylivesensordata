import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import 'dart:async';
import 'services/bluetooth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soil Sensor Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
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
        if (data.containsKey('ph')) {
          _currentPHValue = (data['ph'] as num).toDouble();
        }
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
    bool isEnabled = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    setState(() {
      _isBluetoothEnabled = isEnabled;
    });

    if (!_isBluetoothEnabled) {
      await FlutterBluePlus.turnOn();
      isEnabled = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      setState(() {
        _isBluetoothEnabled = isEnabled;
      });
    }

    if (_isBluetoothEnabled) {
      await _refreshDevices();
    }
  }

  Future<void> _refreshDevices() async {
    try {
      final bondedDevices = await FlutterBluePlus.bondedDevices;
      setState(() {
        _devices = bondedDevices;
      });
    } catch (e) {
      print('Error refreshing devices: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Sensor Monitor'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
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
            // Simple status card
            Card(
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
                          color: _isBluetoothEnabled ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(_isBluetoothEnabled ? 'Enabled' : 'Disabled'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _connectionStatus == BluetoothConnectionStatus.connected 
                                ? Colors.green 
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _connectionStatus == BluetoothConnectionStatus.connected 
                                ? 'Connected' 
                                : 'Disconnected',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Device selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Device',
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connect/Disconnect buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedDevice != null &&
                        _connectionStatus == BluetoothConnectionStatus.disconnected
                        ? _connectToDevice
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.bluetooth_connected),
                    label: const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _connectionStatus == BluetoothConnectionStatus.connected
                        ? _disconnect
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // pH Display
            Card(
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
                    if (_currentPHValue != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _getPHStatusText(),
                        style: TextStyle(
                          color: _getPHStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // NPK Display
            Card(
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
                        _buildNutrientDisplay('N', _currentNValue, Colors.blue[600]!),
                        _buildNutrientDisplay('P', _currentPValue, Colors.orange[600]!),
                        _buildNutrientDisplay('K', _currentKValue, Colors.purple[600]!),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'NPK sensors will be added in future updates',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
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

  Widget _buildNutrientDisplay(String nutrient, double? value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: value != null ? color : Colors.grey[300],
            borderRadius: BorderRadius.circular(30),
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
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getNutrientName(nutrient),
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _getNutrientName(String nutrient) {
    switch (nutrient) {
      case 'N': return 'Nitrogen';
      case 'P': return 'Phosphorus';
      case 'K': return 'Potassium';
      default: return '';
    }
  }

  Color _getPHStatusColor() {
    if (_currentPHValue == null) return Colors.grey;
    if (_currentPHValue! >= 6.0 && _currentPHValue! <= 7.5) {
      return Colors.green;
    } else if (_currentPHValue! >= 5.5 && _currentPHValue! <= 8.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getPHStatusText() {
    if (_currentPHValue == null) return '';
    if (_currentPHValue! >= 6.0 && _currentPHValue! <= 7.5) {
      return 'Optimal pH Range';
    } else if (_currentPHValue! >= 5.5 && _currentPHValue! <= 8.0) {
      return 'Acceptable pH Range';
    } else {
      return 'Poor pH Level';
    }
  }
}
