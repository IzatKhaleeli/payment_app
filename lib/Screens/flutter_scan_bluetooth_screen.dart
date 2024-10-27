import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scan_bluetooth/flutter_scan_bluetooth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';

class FlutterScanBluetoothScreen extends StatefulWidget {
  const FlutterScanBluetoothScreen({Key? key}) : super(key: key);

  @override
  State<FlutterScanBluetoothScreen> createState() => _FlutterScanBluetoothScreenState();
}

class _FlutterScanBluetoothScreenState extends State<FlutterScanBluetoothScreen> {
  late FlutterScanBluetooth _scanBluetooth;
  late List<BluetoothDevice> _devices;
  BluetoothDevice? _selectedDevice;

  late File imgFile;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    _devices = [];
    _scanBluetooth = FlutterScanBluetooth();
    _startScan();
    _initImg();
  }

  _startScan() async {
    setState(() {
      isScanning = true;
    });
    await _scanBluetooth.startScan();

    _scanBluetooth.devices.listen((dev) {
      if (!_isDeviceAdded(dev)) {
        setState(() {
          _devices.add(dev);
        });
      }
    });

    await Future.delayed(const Duration(seconds: 10));
    _stopScan();
  }

  _stopScan() {
    _scanBluetooth.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  bool _isDeviceAdded(BluetoothDevice device) => _devices.contains(device);

  _initImg() async {
    try {
      ByteData byteData = await rootBundle.load("images/payment_test.png");
      Uint8List buffer = byteData.buffer.asUint8List();
      String path = (await getTemporaryDirectory()).path;
      imgFile = File("$path/img.png");
      imgFile.writeAsBytes(buffer);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Bluetooth Scanner"),
        backgroundColor: Colors.lightBlue,
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 15,
          ),
          ConditionalBuilder(
            condition: !isScanning,
            builder: (context) => FloatingActionButton(
              onPressed: () {
                _startScan();
              },
              child: const Icon(
                Icons.bluetooth_searching,
              ),
            ),
            fallback: (context) => const CircularProgressIndicator(
              color: Colors.lightBlue,
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          ConditionalBuilder(
            condition: _selectedDevice != null,
            builder: (context) => Column(
              children: [
                _buildDev(_selectedDevice!),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MaterialButton(
                      onPressed: () {
                        print("print button clicked");
                        // Your printing logic here
                      },
                      color: Colors.lightBlue,
                      child: const Text(
                        "Print",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    MaterialButton(
                      onPressed: () {
                        print("connect button clicked");
                        // Your connect logic here
                      },
                      color: Colors.lightBlue,
                      child: const Text(
                        "Connect",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              ],
            ),
            fallback: (context) => const Text("No printer selected"),
          ),
          const SizedBox(
            height: 15,
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.lightBlue,
          ),
          const SizedBox(
            height: 15,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ..._devices.map(
                        (dev) => _buildDev(dev),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDev(BluetoothDevice dev) => GestureDetector(
    onTap: () {
      setState(() {
        _selectedDevice = dev;
      });
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.125),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(dev.name,
              style: const TextStyle(
                  color: Colors.lightBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 10,
          ),
          Text(dev.address,
              style: const TextStyle(color: Colors.grey, fontSize: 14))
        ],
      ),
    ),
  );
}
