import 'package:flutter/services.dart';

class BluetoothService {
  static const MethodChannel _channel = MethodChannel('bluetooth_channel');
  static const EventChannel eventChannel = EventChannel('bluetooth_scan_events');

  // Start scanning for devices
  static Future<void> startScan() async {
    try {
      await _channel.invokeMethod('startScan');
    } catch (e) {
      print("Failed to start scan: $e");
    }
  }

  // Stop scanning for devices
  static Future<void> stopScan() async {
    try {
      await _channel.invokeMethod('stopScan');
    } catch (e) {
      print("Failed to stop scan: $e");
    }
  }

  // Connect to a device using its address
  static Future<void> connectToDevice(String address) async {
    try {
      print("connect method started");
      final isConnected = await _channel.invokeMethod('connectToDevice', {'address': address});
      print("Connected: $isConnected");
    } catch (e) {
      print("Failed to connect: $e");
    }
  }

  // Disconnect from the current device
  static Future<void> disconnectDevice() async {
    try {
      final isDisconnected = await _channel.invokeMethod('disconnectDevice');
      print("Disconnected: $isDisconnected");
    } catch (e) {
      print("Failed to disconnect: $e");
    }
  }

  // Print image bytes to the connected device
  static Future<void> printImageBytes(List<int> imageBytes) async {
    print("printImageBytes");
    try {
      // Convert List<int> to Uint8List to ensure compatibility
      Uint8List bytes = Uint8List.fromList(imageBytes);

      // Invoke method with the correctly formatted bytes
      await _channel.invokeMethod('printImageBytes', {'bytes': bytes});
      print("Image printed successfully.");
    } catch (e) {
      print("Failed to print image: $e");
    }
  }

  // Listen for discovered Bluetooth devices
  static Stream<dynamic> listenForDevices() {
    return eventChannel.receiveBroadcastStream();
  }
}