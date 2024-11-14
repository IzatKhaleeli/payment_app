import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // PDF Viewer package
import 'package:ooredoo_app/Screens/preview_test.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import '../Services/LocalizationService.dart';
import 'printerService/androidBluetoothFeaturesScreen.dart';
import 'printerService/convertPdfToImage.dart'; // For SharedPreferences

class PrinterConfirmationBottomSheet extends StatefulWidget {
  final String pdfFilePath; // File path to the PDF to preview
  PrinterConfirmationBottomSheet({required this.pdfFilePath});

  @override
  _PrinterConfirmationBottomSheetState createState() =>
      _PrinterConfirmationBottomSheetState();
}

class _PrinterConfirmationBottomSheetState
    extends State<PrinterConfirmationBottomSheet> {
  String? printerLabel;
  String? printerAddress;
  String _selectedLanguage = 'ar';
  Map<String, dynamic>? _emailJson;

  // Function to get the default printer info from SharedPreferences
  Future<void> _getPrinterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      printerLabel = prefs.getString('default_device_label') ?? 'No Printer';
      printerAddress = prefs.getString('default_device_address') ?? 'No Address';
    });
  }

  @override
  void initState() {
    super.initState();
    _getPrinterInfo(); // Fetch the default printer info when the bottom sheet opens
    _loadSavedLanguageCode();
  }

  Future<void> _loadSavedLanguageCode() async {
    setState(() {
      _selectedLanguage ='ar';
    });

    // Load the localized message for the saved/default language
    await _loadLocalizedContent(_selectedLanguage);
  }

  Future<void> _loadLocalizedContent(String languageCode) async {
    try {
      String jsonString = await rootBundle.loadString('assets/languages/$languageCode.json');
      setState(() {
        _emailJson = jsonDecode(jsonString);
      });
    } catch (e) {
      print("Error loading localized strings for $languageCode: $e");
    }
  }

  String getLocalizedContent(String key) {
    if (_emailJson == null) {
      return '** $key not found';
    }
    return _emailJson![key] ?? '** $key not found';
  }

  // Function to simulate printing (for now just prints a test message to terminal)
  void _printTest() {
    print("Printing test... PDF Path: ${widget.pdfFilePath}");
    // You can replace this with actual printing functionality later
  }

  // Function to load and convert PDF to image using PdfConverter
  Future<void> _convertPdfToImage(String pdfPath) async {
    img.Image image = await PdfConverter.convertPdfToImage(pdfPath); // Convert the PDF to an image
    print("image returned here");
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ImageView(image: image),
    //   ),
    // );
    AndroidBluetoothFeatures.loadAndPrintImages(image);
  }

  @override
  Widget build(BuildContext context) {
    String currentLanguageCode = Localizations.localeOf(context).languageCode;

    return Directionality(
      textDirection: currentLanguageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title above the PDF preview
                Align(
                  alignment: currentLanguageCode == 'ar'
                      ? Alignment.centerRight  // Align to the right for Arabic
                      : Alignment.centerLeft,  // Align to the left for English
                  child: Text(
                    Provider.of<LocalizationService>(context, listen: false).getLocalizedString("sendToPrinter"), // Title in Arabic or English
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 16),

                // Printer info section
                Column(
                  children: [
                    // Printer info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("printer")}: ', // Title
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold, // Bold title
                          ),
                        ),
                        Text(
                          '$printerLabel', // Value
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal, // Normal value
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8), // Space between the rows

                    // MAC Address info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("mac")}: ', // Title
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold, // Bold title
                          ),
                        ),
                        Text(
                          '$printerAddress', // Value
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal, // Normal value
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Display the PDF preview
                Container(
                  height: 400, // Set a fixed height for the PDF preview
                  child: PDFView(
                    filePath: widget.pdfFilePath, // Pass the file path to the PDF viewer
                  ),
                ),
                SizedBox(height: 20),

                // Buttons Row (Print and Cancel)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // "Print" Button with padding to create space
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0), // Padding between buttons
                        child: ElevatedButton(
                          onPressed: () {
                            _printTest(); // Call the print function (currently printing to terminal)
                            _convertPdfToImage(widget.pdfFilePath); // Convert the PDF to an image on init
                            Navigator.pop(context); // Close the bottom sheet after printing
                          },
                          child: Text(
                            Provider.of<LocalizationService>(context, listen: false).getLocalizedString("print"),
                          ),
                        ),
                      ),
                    ),

                    // "Cancel" Button with padding to create space
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0), // Padding between buttons
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Simply close the bottom sheet
                          },
                          child: Text(
                            Provider.of<LocalizationService>(context, listen: false).getLocalizedString("cancel"),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
