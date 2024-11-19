import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'converImageToPos.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_blue/flutter_blue.dart' as blue;

class AndroidBluetoothFeatures {
  static final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  /// Check if Bluetooth is on using `flutter_blue`
  static Future<bool> isBluetoothOn() async {
    try {
      // Get the current Bluetooth state
      blue.BluetoothState state = await blue.FlutterBlue.instance.state.first;

      // Check if the state is `on`
      print("Bluetooth state: $state");
      return state == blue.BluetoothState.on;
    } catch (e) {
      print("Failed to check Bluetooth state: $e");
      return false;
    }
  }

  /// Start scanning for available Bluetooth devices.
  static Future<List<BluetoothDevice>> startScan() async {
    return await _printer.getBondedDevices();
  }

  /// Connect to the saved Bluetooth device by address.
  static Future<void> connect() async {
    try {
      print("connect method stated");
      final prefs = await SharedPreferences.getInstance();
      String? savedAddress = prefs.getString('default_device_address');

      print("qqq :${savedAddress}");
      if (savedAddress == null || savedAddress.isEmpty) {
        throw Exception("No saved Bluetooth address found in SharedPreferences.");
      }

      List<BluetoothDevice> devices = await _printer.getBondedDevices();
      print("before get paired");
      BluetoothDevice? targetDevice = devices.firstWhere(
            (device) => device.address == savedAddress,
        orElse: () => throw Exception("Device with address $savedAddress not found"),
      );
      print("after get paired");

      await _printer.connect(targetDevice);
      print("Connected to device: $savedAddress");
    } catch (e) {
      print("Failed to connect: $e");
      rethrow;
    }
  }

  /// Disconnect from the current connected device if connected.
  static Future<void> disconnect() async {
    try {
      if (await isConnected()) {  // Call the method directly instead of using a local variable
        await _printer.disconnect();
        print("Disconnected from printer.");
      } else {
        print("Printer was not connected.");
      }
    } catch (e) {
      print("Failed to disconnect: $e");
    }
  }

  /// Convert image, connect, and print.
  static Future<void> loadAndPrintImages(img.Image image) async {
    try {
      final con=await isConnected();
      print("the connection state is : ${con}");
     // Ensure the printer is connected
      if (!await isConnected()) {
        await connect();
      }

      final profile = await CapabilityProfile.load();
      List<int> imageData = await ConvertImageToPos.prepareImageForPrint(image, profile);
      print("Image data prepared for POS printing.");

      // Send the image data to the printer
      await sendData(imageData);

      // // Clear the buffer or reset the printer if needed
      // await _printer.writeBytes(Uint8List.fromList([0x1B, 0x40])); // ESC @

    } catch (e) {
      print("Failed to load or print images: $e");
      rethrow;
    } finally {
     // Disconnect after printing
     //  await disconnect();
    }
  }

  /// Send data to the printer, ensuring connection before sending.
  static Future<void> sendData(List<int> data) async {
    try {
      print("sendData started :${await isConnected()}");
      if (!await isConnected()) {
        await connect();
      }
      print("after !await isConnected");
      final result = await _printer.writeBytes(Uint8List.fromList(data));
      print("the result is :${result}");
      print("Data sent to printer.");
    } catch (e) {
      print("Failed to send data: $e");
      rethrow;
    }
  }

  /// Check if the printer is connected.
  static Future<bool> isConnected() async {
    return await _printer.isConnected ?? false;
  }
}
