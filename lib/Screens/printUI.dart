import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../Services/bitmap.dart';
import 'dart:async';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Services/print_utils.dart';
import 'package:image/image.dart' as img;


class PrintPage extends StatefulWidget {
  @override
  _PrintPageState createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  final PrinterBluetoothManager printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _devices = [];
  bool _isLoading = false;
  bool _isPrinting = false;
  PrinterBluetooth? _selectedPrinter;
  StreamSubscription<List<PrinterBluetooth>>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _startScan();
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

    printerManager.startScan(Duration(seconds: 2));
    _subscription = printerManager.scanResults.listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices.toSet().toList();
          _isLoading = false;
        });
      }
    });
    print("Devices found: ${_devices.length}");
    for (var device in _devices) {
      print("Device info: ${device}");
    }
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
    _subscription?.cancel();
    printerManager.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Printer Setup'),
        centerTitle: true,
        backgroundColor: Color(0xFFC62828),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isPrinting
            ? Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select a Bluetooth Printer:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Center(
                  child: FloatingActionButton(
                    onPressed: _startScan,
                    backgroundColor: Color(0xFFC62828),
                    child: Icon(Icons.refresh,color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _devices.isEmpty
                ? Center(child: Text('No Bluetooth devices found'))
                :
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  PrinterBluetooth device = _devices[index];
                  return ListTile(
                    title: Text(device.name ?? 'Unknown device'),
                    subtitle: Text(device.address ?? 'Unknown address'),
                    leading: Icon(
                      _selectedPrinter == device
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _selectedPrinter == device
                          ? Colors.green
                          : Colors.grey,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedPrinter = device;
                      });
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:_selectedPrinter != null && !_isPrinting
                        ? () => _printReceiptJavaImage(_selectedPrinter!)
                        : null,
                    icon: Icon(Icons.print),
                    label: Text('Print Test Image'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      primary: Colors.green,
                    ),
                  ),
                ),

                SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedPrinter != null && !_isPrinting
                        ? () => _printReceipt(_selectedPrinter!)
                        : null,
                    icon: Icon(Icons.print),
                    label: Text('Print Test Receipt'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      primary: Colors.green,
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedPrinter != null ? _disconnectPrinter : null,
                    icon: Icon(Icons.cancel),
                    label: Text('Disconnect Printer'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      primary: Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printReceipt(PrinterBluetooth printer) async {
    setState(() {
      _isPrinting = true;
    });

    try {
      // Check if the printer is connected
      if (_selectedPrinter == null) {
        _showMessage('Printer is not connected. Please connect the printer and try again.');
        return;
      }

      print("Connecting to the printer...");
      printerManager.selectPrinter(printer);
      print("Printer connected");

      // Generate the receipt data
      List<int> receiptData = await _generateTestTicket();

      // Send receipt data to printer
      await printerManager.writeBytes(receiptData);
      await Future.delayed(Duration(seconds: 1)); // Adjust delay as necessary
      _showMessage('Printing successful');
    } catch (e) {
      print("Error during printing status: ${e.toString()}");
      // Improved error handling
      if (e.toString().contains('bt socket closed')) {
        _showMessage('Bluetooth connection lost. Please reconnect and try again.');
      } else {
        _showMessage('Error printing receipt: $e');
      }
    } finally {
      setState(() {
        _isPrinting = false;
      });
      print("Finished printing process");
    }
  }

  Future<List<int>> _generateTestTicket() async {
    List<int> bytesInt = [];

    bytesInt += PrintUtils.initialization();

    // Print bold left-aligned text
    bytesInt += PrintUtils.printBoldAlignedTextLeft('Ooredoo Left\n');

    // Print bold center-aligned text
    bytesInt += PrintUtils.printBoldAlignedTextCenter('Ooredoo Center\n');

    // Print bold right-aligned text
    bytesInt += PrintUtils.printBoldAlignedTextRight('Ooredoo Right\n');

    // Feed 3 lines
    bytesInt += [0x1B, 0x64, 0x03]; // ESC d 3 (Feed 3 lines)

    // Cut the paper
    bytesInt += [0x1D, 0x56, 0x00]; // ESC i (Full cut)

    return bytesInt;
  }

  List<int> _createTextCommand(String text) {
    // Convert text to bytes using the specified encoding (e.g., UTF-8)
    List<int> textBytes = utf8.encode(text);
    List<int> textCommand = [];

    // LF and CR commands
    List<int> LFCR = [
      0x0A,  // LF
      0x0D   // CR
    ];

    // Cut command in hexadecimal
    List<int> cutCommand = [
      0x1D, 0x53, 0x0D,  // ESC GS (29 83) + 13
      0x1D, 0x56, 0x42, 0x00, // ESC V (29 86 66 0)
      0x1D, 0x54, 0x00  // ESC T (29 84 0)
    ];

    // Add text bytes to command
    textCommand.addAll(textBytes);

    // Add LF and CR to the command (three lines)
    textCommand.addAll(LFCR);
    textCommand.addAll(LFCR);
    textCommand.addAll(LFCR);
    textCommand.addAll(LFCR);

    // Add cut command to the command
    textCommand.addAll(cutCommand);

    return textCommand;
  }

  Future<void> _printReceiptJavaImage(PrinterBluetooth printer) async {
    setState(() {
      _isPrinting = true;
    });
    print("Connecting to the printer...");

    try {
      // Step 1: Select the printer
      printerManager.selectPrinter(printer);
      print("Printer connected");

      // Step 2: Define ESC/POS commands (hexadecimal)
      List<int> headerCmd = [0x1B, 0x40]; // ESC @ to initialize printer
      List<int> rastercmd = [0x1D, 0x76, 0x30, 0x00]; // ESC @ to initialize printer
      List<int> lineSpacingCmd = [0x1B, 0x33, 50]; // Adjust line spacing
      List<int> alignLeftCmd = [0x1B, 0x61, 0x00]; // Left align
      List<int> alignCenterCmd = [0x1B, 0x61, 0x01]; // Center align
      List<int> textCommand1 = _createTextCommand("test text to printer1");
      List<int> LFCR = [0x0A, 0x0D]; // Line Feed and Carriage Return

      // Step 3: Image handling
      print("Loading and processing image...");
      Uint8List escPosCommands = Uint8List(0); // Initialize with empty command
      List<List<int>> commandChunks=[];
      // Load the image from assets
      img.Image? image = await ImageToEscPosConverter.loadImageFromAssets('assets/images/payment_test.png');

      if (image == null) {
        print('Image loading failed.');
      } else {
        // Convert the image to ESC/POS commands
        escPosCommands = await ImageToEscPosConverter.convertImageToEscPosCommands(context, image, 350 ); // Example width
        commandChunks = await chunkCommands(escPosCommands, 4096 ); // Adjust chunk size based on printer limits
        print('ESC/POS Commands for image generated: ${escPosCommands.length} bytes');
      }
      List<int> fullCommand = [];
      for (List<int> commandChunk in commandChunks) {
      // Step 4: Combine all commands

      fullCommand.addAll(headerCmd);          // Initialize printer
      fullCommand.addAll(alignLeftCmd);     // Center align for the image
      fullCommand.addAll(commandChunk);       // Add image data
      fullCommand.addAll(LFCR);             // Line feed after text
      fullCommand.addAll(textCommand1);     // Add text to print
      fullCommand.addAll(LFCR);             // Line feed after text

      // Step 5: Send the full command to the printer
      print("Sending print commands to the printer...");
      final result = await printerManager.writeBytes(fullCommand);

      await Future.delayed(Duration(seconds: 5)); // Adjust delay to ensure the printer processes the image fully

      // Step 6: Handle the result
        if (result.value == PosPrintResult.success.value) {
          _showMessage('Printing successful');
        } else {
          print('Error Code: ${result.value}, Message: ${result.msg}');
          _showMessage('Printing failed: ${result.msg}');
        }
      // Wait before sending the next chunk
      await Future.delayed(Duration(seconds: 7)); // Adjust delay
      }
    } catch (e) {
      print("Error during printing: $e");
      _showMessage('Error during printing: $e');
    }
    finally {
      setState(() {
        _isPrinting = false; // Reset the printing state
      });
    }

  }

  Future<List<List<int>>> chunkCommands(List<int> commands, int chunkSize) async {
    List<List<int>> chunks = [];
    for (int i = 0; i < commands.length; i += chunkSize) {
      chunks.add(commands.sublist(i, min(i + chunkSize, commands.length)));
    }
    return chunks;
  }
}
