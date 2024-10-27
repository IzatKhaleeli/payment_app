import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BluetoothPrinterWidget extends StatefulWidget {
  const BluetoothPrinterWidget({Key? key}) : super(key: key);

  @override
  _BluetoothPrinterWidgetState createState() => _BluetoothPrinterWidgetState();
}

class _BluetoothPrinterWidgetState extends State<BluetoothPrinterWidget> {
  final PrinterBluetoothManager _printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _printers = [];
  PrinterBluetooth? _selectedPrinter;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    _printerManager.startScan(Duration(seconds: 5));
    _printerManager.scanResults.listen((printers) {
      setState(() {
        _printers = printers;
      });
    });
  }

  Future<ui.Image?> loadImageWithCustomCanvas(
      String path, {
        double canvasWidth = 300, // default width
        double canvasHeight = 500, // default height
      }) async {
    try {
      final ByteData data = await rootBundle.load(path);
      final Uint8List bytes = data.buffer.asUint8List();
      final img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, ui.Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));

      final ui.Image uiImage = await convertImageToUiImage(decodedImage);

      final paint = Paint();
      final imageRect = ui.Rect.fromLTWH(0, 0, canvasWidth, canvasHeight);
      canvas.drawImageRect(uiImage, ui.Rect.fromLTRB(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()), imageRect, paint);

      final picture = recorder.endRecording();
      return picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
    } catch (e) {
      print('Error loading image: ${e.toString()}');
      return null;
    }
  }

  Future<ui.Image> convertImageToUiImage(img.Image image) async {
    final Uint8List bytes = Uint8List.fromList(img.encodePng(image));
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  Future<List<int>> convertImageToEscPosCommands(img.Image image) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    List<int> bytes = [];
    bytes += generator.image(image);
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }

  Future<void> printToBluetoothPrinter(
      PrinterBluetooth printer, List<int> commands) async {
    _printerManager.selectPrinter(printer);

    final result = await _printerManager.printTicket(commands);
    if (result == PosPrintResult.success) {
      print('Print job completed');
    } else {
      print('Print job failed: $result');
    }
  }

  Future<void> printWithSelectedPrinter() async {
    if (_selectedPrinter != null) {
      final ui.Image? canvasImage = await loadImageWithCustomCanvas(
        'assets/images/Ooredoo_Logo_noBG.png',
        canvasWidth: 100,
        canvasHeight: 150,
      );
      if (canvasImage == null) return;

      img.Image? imageForPrint = await uiImageToImgImage(canvasImage);
      List<int> escPosCommands = await convertImageToEscPosCommands(imageForPrint!);
      await printToBluetoothPrinter(_selectedPrinter!, escPosCommands);
    }
  }

  Future<img.Image> uiImageToImgImage(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();
    return img.decodeImage(buffer)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Printer'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _printers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_printers[index].name ?? 'Unknown'),
                  subtitle: Text(_printers[index].address!),
                  onTap: () {
                    setState(() {
                      _selectedPrinter = _printers[index];
                    });
                  },
                  selected: _selectedPrinter == _printers[index],
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _selectedPrinter != null ? printWithSelectedPrinter : null,
            child: const Text('Print with Selected Printer'),
          ),
        ],
      ),
    );
  }
}
