import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  static Future<bool> requestBluetoothPermissions() async {
    try {
      // Request location permission (required for Bluetooth scanning on Android)
      PermissionStatus locationStatus = await Permission.location.request();

      // Request Bluetooth permissions for Android 12+
      PermissionStatus bluetoothScanStatus = PermissionStatus.granted;
      PermissionStatus bluetoothConnectStatus = PermissionStatus.granted;

      // Check Android version and request appropriate permissions
      if (Platform.isAndroid) {
        // For Android 12+ (API 31+), request new Bluetooth permissions
        try {
          bluetoothScanStatus = await Permission.bluetoothScan.request();
          bluetoothConnectStatus = await Permission.bluetoothConnect.request();
        } catch (e) {
          // If permissions don't exist on older versions, that's okay
          print('Bluetooth permissions not available on this version: $e');
        }
      }

      return locationStatus.isGranted &&
          bluetoothScanStatus.isGranted &&
          bluetoothConnectStatus.isGranted;
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  static Future<bool> checkBluetoothPermissions() async {
    try {
      bool locationGranted = await Permission.location.isGranted;
      bool bluetoothScanGranted = true;
      bool bluetoothConnectGranted = true;

      // Check Bluetooth permissions for Android 12+
      if (Platform.isAndroid) {
        try {
          bluetoothScanGranted = await Permission.bluetoothScan.isGranted;
          bluetoothConnectGranted = await Permission.bluetoothConnect.isGranted;
        } catch (e) {
          // If permissions don't exist on older versions, that's okay
          print('Bluetooth permissions not available on this version: $e');
        }
      }

      return locationGranted && bluetoothScanGranted && bluetoothConnectGranted;
    } catch (e) {
      print('Permission check error: $e');
      return false;
    }
  }
}
