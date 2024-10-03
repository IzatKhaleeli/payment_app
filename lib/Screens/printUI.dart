import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../Services/bitmap.dart';
import '../Utils/Alignments.dart';
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
  Uint8List? _imageData;
  double paperWidthMM = 80.0; // 80mm paper width
  double dpi = 203.0; // 203 DPI



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

    printerManager.startScan(Duration(seconds: 3));
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
      print("Device Name: ${device.name}, Address: ${device.address}");
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
        _imageData != null
            ? Expanded(child: Image.memory(_imageData!)) // Display the image
            : CircularProgressIndicator(),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedPrinter != null && !_isPrinting
                        ? () async => await _loadImage()
                    : null,
                    icon: Icon(Icons.print),
                    label: Text('Preview Image'),
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
      await Future.delayed(Duration(seconds: 2)); // Adjust delay as necessary

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

    // ESC @ (Initialize printer)
    bytesInt += [0x1B, 0x40];

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


  Future<void> _loadImage() async {
    try {
      // Load the image from assets as ByteData
      ByteData bytesData = await rootBundle.load('assets/images/payment_test.png');
      // Convert ByteData to Uint8List
      Uint8List imageData = bytesData.buffer.asUint8List();

      setState(() {
        _imageData = imageData;
      });
    } catch (e) {
      print("Error loading image: $e");
    }
  }

  Future<List<int>> _printReceiptImage(PrinterBluetooth printer) async {
    setState(() {
      _isPrinting = true;
    });
      print("Connecting to the printer...");
      printerManager.selectPrinter(printer);
      print("Printer connected");


      // Step 1: Load image from assets
      ByteData byteData = await rootBundle.load('assets/images/test_payment.jpg');

      // Step 2: Convert ByteData to Uint8List
      Uint8List imageData = byteData.buffer.asUint8List();

      // Step 3: Get temporary directory
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;

      // Step 4: Create a File in the temporary directory
      File imageFile = File('$tempPath/test_payment.jpg');

      // Step 6: Load the image for processing (e.g., resizing, printing)
      img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;

      // Calculate width in pixels
      double paperWidthInches = paperWidthMM / 25.4; // Convert mm to inches
      int printWidthPixels = (paperWidthInches * dpi).round(); // Width in pixels
      // Resize image to fit the printer width (50mm width, 203px at 203 dpi)

    print("width in pixeles : ${printWidthPixels}");
      img.Image resizedImage = img.copyResize(image, width: printWidthPixels);

      // Convert the image to a monochrome bitmap suitable for the printer
      List<int> bitmapData = [];
      int widthBytes = (printWidthPixels + 7) ~/ 8; // Calculate number of bytes required for the width



      // Add the image height to the bitmapData
      bitmapData.add(0x1B); // ESC
      bitmapData.add(0x2A); // *
      bitmapData.add(widthBytes); // number of bytes per line
      bitmapData.add(resizedImage.height); // height of the image in dots


      for (int y = 0; y < resizedImage.height; y++) {
        int byte = 0;
        for (int x = 0; x < resizedImage.width; x++) {
          // Get the pixel color (ARGB)
          int pixel = resizedImage.getPixel(x, y);
          // Convert it to monochrome (black or white)
          int luminance = img.getLuminance(pixel);
          if (luminance < 128) {
            byte |= (1 << (7 - (x % 8))); // Set bit for black pixel
          }

          // If the width is reached, add the byte to the bitmapData
          if ((x + 1) % 8 == 0 || x == resizedImage.width - 1) {
            bitmapData.add(byte);
            byte = 0; // Reset byte for the next set of pixels
          }
        }
      }
    setState(() {
      _isPrinting = false;
    });
      return bitmapData;

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
    printerManager.selectPrinter(printer);
    print("Printer connected");

    // Step 1: Create ESC/POS commands (hexadecimal)
    List<int> headerCmd = [0x1B, 0x40]; // ESC @ command to initialize printer
    List<int> alignLeftCmd = [0x1B, 0x61, 0x00]; // Left align
    List<int> alignCenterCmd = [0x1B, 0x61, 0x01]; // Center align
    List<int> alignRightCmd = [0x1B, 0x61, 0x02]; // Right align
    List<int> textCommand1 = _createTextCommand("test text to printer1");
    List<int> textCommand2 = _createTextCommand("test text to printer2");
    List<int> LFCR = [0x0A,0x0D ];   // LFCR

    print("image part started");

    // Load the image from assets
    img.Image? image = await ImageToEscPosConverter.loadImageFromAssets('assets/images/test_payment.jpg');
    // Declare escPosCommands outside the if block
    Uint8List escPosCommands = Uint8List(0); // Initialize to an empty Uint8List
    if (image != null) {
      // Convert the image to ESC/POS commands
      escPosCommands = ImageToEscPosConverter.convertImageToEscPosCommands(context,image, 320); // Example width
      // Here you can send the escPosCommands to your printer
      print('ESC/POS Commands generated: ${escPosCommands.length} bytes');
    } else {
      print('Image loading failed.');
    }
    print("image part finished");


    // Step 4: Combine commands to be sent to the printer
    List<int> fullCommand = [];
    fullCommand.addAll(headerCmd); // Initialize printer
   // fullCommand.addAll(alignCenterCmd); // Set alignment to center
    //fullCommand.addAll(textCommand1); // Add the text command
    //fullCommand.addAll(textCommand2); // Add the text command
   // fullCommand.addAll(escPosCommands); // Add the image data
    fullCommand.addAll(LFCR); // Add the LFCR



    // Step 3: Send the combined command to the printer
      final result = await printerManager.writeBytes(fullCommand);
    // Create a Completer for the synchronous operation
      // Check if result is an instance of PosPrintResult
      if (result is PosPrintResult) {
        // Directly check for success
        if (result.value == PosPrintResult.success.value) {
          _showMessage('Printing successful');
        } else {
          // Handle error cases
          print('Error Code: ${result.value}');
          print('Error Message: ${result.msg}');
          _showMessage('Printing failed: ${result.msg}');

        }
      } else {
        // Handle unexpected results
        print('Unexpected result type: $result');
        _showMessage('Unexpected result: $result');
      }
    } catch (e) {
      print("^Error during printing: $e");
      _showMessage('Error during printing: $e');
    }
    finally {
      setState(() {
        _isPrinting = false; // Ensure the printing state is reset
      });
    }
  }

}
