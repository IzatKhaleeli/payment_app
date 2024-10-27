import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class PrintScreen extends StatefulWidget {
  @override
  _PrintScreenState createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  PrinterBluetoothManager _printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _devices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request Bluetooth permissions
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  // Load image from assets and resize it
  Future<img.Image?> _loadImageFromAssets(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      final Uint8List bytes = data.buffer.asUint8List();
      final img.Image? logo = img.decodeImage(bytes);
      return logo;
    } catch (e) {
      print('Error loading image: ${e.toString()}');
      return null;
    }
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
    });

    _printerManager.startScan(Duration(seconds: 4));

    _printerManager.scanResults.listen((devices) {
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
    });
  }

  // Convert Flutter image to ESC/POS commands for Bluetooth
  Future<List<int>> _convertImageToEscPosCommands(img.Image image) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];
    bytes += generator.image(image);
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  Future<void> _printImage(PrinterBluetooth printer) async {
    _printerManager.selectPrinter(printer);

    // Load image
    img.Image? image = await _loadImageFromAssets('assets/images/Ooredoo_Logo_noBG.png.png');
    if (image == null) return;

    // Convert image to ESC/POS commands
    List<int> bytes = await _convertImageToEscPosCommands(image);

    // Send the bytes to the printer
    final result = await _printerManager.printTicket(bytes);
    if (result == PosPrintResult.success) {
      print("Printed successfully");
    } else {
      print("Failed to print: ${result.msg}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Printer'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _isScanning ? null : _startScan,
            child: Text(_isScanning ? 'Scanning...' : 'Scan for Printers'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.print),
                  title: Text(_devices[index].name ?? 'Unknown device'),
                  subtitle: Text(_devices[index].address!),
                  onTap: () => _printImage(_devices[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
