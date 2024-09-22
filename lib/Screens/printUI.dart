import 'dart:async';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PrintPage extends StatefulWidget {
  @override
  _PrintPageState createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  PrinterBluetoothManager printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _devices = [];
  bool _isLoading = false;
  bool _isPrinting = false;
  PrinterBluetooth? _selectedPrinter;


  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _startScan();

    });
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  void _startScan() {
    setState(() {
      _isLoading = true;
    });

    printerManager.startScan(Duration(seconds: 5));
    if(!mounted) return;
    printerManager.scanResults.listen((devices) {
      print('Found devices: ${devices.length}');
      for (var device in devices) {
        print('Device: ${device.name} - Address: ${device.address} - Type: ${device.type}');
      }

      if (devices.isNotEmpty) {
        // Stop scanning once devices are found
        printerManager.stopScan();

        if (mounted) {
          setState(() {
            _devices = devices;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false; // Still loading if no devices found yet
          });
        }
      }
    });
  }

  Future<void> _printReceipt(PrinterBluetooth printer) async {
    setState(() {
      _isPrinting = true;
    });

    try {
      printerManager.selectPrinter(printer);
      List<int> ticket = await testTicket();
      print("ticket :${ticket}");
      final result = await printerManager.writeBytes(ticket);
      print("Result message: ${result.msg}");

      if (result.msg == 'Success') {
        _showMessage('Printing successful');
      } else {
        _showMessage('Print failed: ${result.msg}');
      }
    } catch (e) {
      _showMessage('Error printing receipt: $e');
      print('Error during printing: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  Future<List<int>> testTicket() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytesInt = [];

    bytesInt += generator.text('                                ', styles: PosStyles(bold: true));
    bytesInt += generator.text('Ooredoo', styles: PosStyles(
        bold: true,
      height: PosTextSize.size3,
      width: PosTextSize.size3,
        align: PosAlign.center
    ));
    bytesInt += generator.feed(3);
    bytesInt += generator.cut();
    return bytesInt;
  }


  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _disconnectPrinter() {
    printerManager.stopScan();
    setState(() {
      _selectedPrinter = null;
    });
    print("Printer disconnected");
  }

  @override
  void dispose() {
    printerManager.stopScan(); // Stop scan when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Print')),
      body: _isPrinting
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _devices.isEmpty
              ? Text('No Bluetooth devices found')
              : DropdownButton<PrinterBluetooth>(
            hint: Text('Select Printer'),
            value: _selectedPrinter,
            onChanged: (PrinterBluetooth? printer) {
              setState(() {
                _selectedPrinter = printer;
              });
            },
            items: _devices
                .map((device) => DropdownMenuItem(
              child: Text(device.name ?? ''),
              value: device,
            ))
                .toList(),
          ),
          ElevatedButton(
            onPressed: _selectedPrinter != null
                ? () {
              print("Printer selected: ${_selectedPrinter!.name}");
              _printReceipt(_selectedPrinter!);
            }
                : null,
            child: Text('Test Select Printer'),
          ),
          ElevatedButton(
            onPressed: _selectedPrinter != null
                ? _disconnectPrinter
                : null,
            child: Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
