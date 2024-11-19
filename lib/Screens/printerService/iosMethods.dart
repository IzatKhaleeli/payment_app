import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:ooredoo_app/Screens/printerService/converImageToPos.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static Future<void> connectToDevice() async {
    print("connect method stated");
    final prefs = await SharedPreferences.getInstance();
    String? savedAddress = prefs.getString('default_device_address');

    print("qqq :${savedAddress}");
    if (savedAddress == null || savedAddress.isEmpty) {
      throw Exception("No saved Bluetooth address found in SharedPreferences.");
    }
    try {
      print("connect method started");
      final isConnected = await _channel.invokeMethod('connectToDevice', {'address': savedAddress});
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

  static Future<bool> checkConnection() async {
    try {
      final bool isConnected = await _channel.invokeMethod('isConnected');
      print('Device is connected: $isConnected');
      return isConnected;
    } on PlatformException catch (e) {
      print("Failed to check connection status: '${e.message}'.");
      return false;
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

  // Check if Bluetooth power is on
  static Future<bool> isBluetoothPoweredOn() async {
    try {
      final isPoweredOn = await _channel.invokeMethod('isBluetoothPoweredOn');
      return isPoweredOn ?? false;
    } catch (e) {
      print("Failed to check Bluetooth power state: $e");
      return false;
    }
  }


  // Listen for discovered Bluetooth devices
  static Stream<dynamic> listenForDevices() {
    return eventChannel.receiveBroadcastStream();
  }

  /// Convert image, connect, and print.
  static Future<void> loadImages(img.Image image) async {
    try {
      // Prepare the image data for POS printing
      final profile = await CapabilityProfile.load();
      List<int> imageData = await ConvertImageToPos.prepareImageForPrint(image, profile);
      print("Image data prepared for POS printing.");

      // Send the image data to the printer
      await printImageBytes(imageData);

    } catch (e) {
      print("Failed to load or print images: $e");
      rethrow;
    } finally {
      // Disconnect after printing
      //  await disconnect();
    }
  }
}