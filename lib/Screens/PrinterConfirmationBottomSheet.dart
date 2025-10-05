import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // PDF Viewer package
import 'package:ooredoo_app/Screens/printerService/iosMethods.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import '../Custom_Widgets/CustomPopups.dart';
import '../Services/LocalizationService.dart';
import '../core/constants.dart';
import 'printerService/androidBluetoothFeaturesScreen.dart';
import 'printerService/convertPdfToImage.dart'; // For SharedPreferences
import '../Screens/printerService/iosMethods.dart' as iosPlat;

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
      printerAddress =
          prefs.getString('default_device_address') ?? 'No Address';
    });
  }

  @override
  void initState() {
    super.initState();

    _getPrinterInfo(); // Fetch the default printer info when the bottom sheet opens
    _loadSavedLanguageCode();
    _checkAndConnectToPrinter(); // Check connection and connect if not connected
  }

  Future<void> _loadSavedLanguageCode() async {
    setState(() {
      _selectedLanguage = 'ar';
    });

    // Load the localized message for the saved/default language
    await _loadLocalizedContent(_selectedLanguage);
  }

  Future<void> _loadLocalizedContent(String languageCode) async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/languages/$languageCode.json');
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

  // Function to load and convert PDF to image using PdfConverter
  Future<void> _convertPdfToImage(String pdfPath) async {
    img.Image image = await PdfConverter.convertPdfToImage(
        pdfPath); // Convert the PDF to an image
    if (image.length > 1) {
      if (Platform.isAndroid) {
        print("Sent image data to anroid started.");
        AndroidBluetoothFeatures.loadAndPrintImages(image);
      } else if (Platform.isIOS) {
        print("Sent image data to iOS started.");
        await BluetoothService.loadImages(image);
        //        Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ImageView(image: image),
        //   ),
        // );
        print("Sent image data to iOS success.");
      } else {
        print("Error: No image data to send.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentLanguageCode = Localizations.localeOf(context).languageCode;

    return Directionality(
      textDirection:
          currentLanguageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title above the PDF preview
                Align(
                  alignment: currentLanguageCode == 'ar'
                      ? Alignment.centerRight // Align to the right for Arabic
                      : Alignment.centerLeft, // Align to the left for English
                  child: Text(
                    Provider.of<LocalizationService>(context, listen: false)
                        .getLocalizedString(
                            "sendToPrinter"), // Title in Arabic or English
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
                  ],
                ),
                SizedBox(height: 10),

                // Display the PDF preview
                Container(
                  height: 480, // Set a fixed height for the PDF preview
                  child: PDFView(
                    filePath: widget
                        .pdfFilePath, // Pass the file path to the PDF viewer
                  ),
                ),
                SizedBox(height: 10),
                // Buttons Row (Print and Cancel)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // "Print" Button with padding to create space
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0), // Padding between buttons
                        child: ElevatedButton(
                          onPressed: () async {
                            if (Platform.isIOS) {
                              bool isBluetoothOn = await iosPlat
                                  .BluetoothService.isBluetoothPoweredOn();
                              bool connected =
                                  await BluetoothService.checkConnection();

                              if (!isBluetoothOn) {
                                CustomPopups.showCustomResultPopup(
                                  context: context,
                                  icon: Icon(Icons.error,
                                      color: AppColors.primaryRed, size: 40),
                                  message: Provider.of<LocalizationService>(
                                          context,
                                          listen: false)
                                      .getLocalizedString(
                                          "bluetooth_off_message"),
                                  buttonText: Provider.of<LocalizationService>(
                                          context,
                                          listen: false)
                                      .getLocalizedString("ok"),
                                  onPressButton: () {
                                    // Define what happens when the button is pressed
                                    print('bluetooth is not powered ..');
                                    return;
                                  },
                                );
                              } else if (!connected) {
                                CustomPopups.showCustomResultPopup(
                                  context: context,
                                  icon: Icon(Icons.error,
                                      color: AppColors.primaryRed, size: 40),
                                  message: Provider.of<LocalizationService>(
                                          context,
                                          listen: false)
                                      .getLocalizedString(
                                          "theDefaultDeviceNotConnected"),
                                  buttonText: Provider.of<LocalizationService>(
                                          context,
                                          listen: false)
                                      .getLocalizedString("ok"),
                                  onPressButton: () {
                                    // Define what happens when the button is pressed
                                    print('theDefaultDeviceNotConnected ..');
                                    return;
                                  },
                                );
                              } else
                                _convertPdfToImage(widget
                                    .pdfFilePath); // Convert the PDF to an image on init
                            } else if (Platform.isAndroid) {
                              bool connected =
                                  await AndroidBluetoothFeatures.isConnected();
                              if (!connected)
                                CustomPopups.showCustomResultPopup(
                                  context: context,
                                  icon: Icon(Icons.error,
                                      color: AppColors.primaryRed, size: 40),
                                  message: Provider.of<LocalizationService>(
                                          context,
                                          listen: false)
                                      .getLocalizedString(
                                          "theDefaultDeviceNotConnected"),
                                  buttonText: Provider.of<LocalizationService>(
                                          context,
                                          listen: false)
                                      .getLocalizedString("ok"),
                                  onPressButton: () {
                                    // Define what happens when the button is pressed
                                    print('theDefaultDeviceNotConnected ..');
                                    return;
                                  },
                                );
                              else
                                _convertPdfToImage(widget
                                    .pdfFilePath); // Convert the PDF to an image on init
                            }
                            Navigator.pop(
                                context); // Close the bottom sheet after printing
                          },
                          child: Text(
                            Provider.of<LocalizationService>(context,
                                    listen: false)
                                .getLocalizedString("print"),
                          ),
                        ),
                      ),
                    ),

                    // "Cancel" Button with padding to create space
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0), // Padding between buttons
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                                context); // Simply close the bottom sheet
                          },
                          child: Text(
                            Provider.of<LocalizationService>(context,
                                    listen: false)
                                .getLocalizedString("cancel"),
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

  Future<void> _checkAndConnectToPrinter() async {
    if (Platform.isIOS) {
      try {
        print("_checkAndConnectToPrinter started");
        // Check if the device is already connected
        bool connected = await BluetoothService.checkConnection();
        if (!connected) {
          print("device not connected");
          // If not connected, fetch the saved device address and attempt to connect
          final prefs = await SharedPreferences.getInstance();
          String? deviceAddress = prefs.getString('default_device_address');

          if (deviceAddress != null && deviceAddress.isNotEmpty) {
            print("Connecting to device with address: $deviceAddress");
            await BluetoothService.connectToDevice();
            print("Connected to the device successfully.");
            print("_checkAndConnectToPrinter finished");
          } else {
            print("No saved device address found.");
          }
        } else {
          print("Already connected to the device.");
          // If connected, disconnect first
          await BluetoothService.disconnectDevice();
          bool secondConnected = await BluetoothService.checkConnection();
          print(secondConnected);
          if (!secondConnected) {
            await BluetoothService.connectToDevice();
          }
          print("Disconnected from the device.");
        }
      } catch (e) {
        print("Failed to check connection or connect ios: $e");
      }
    } else if (Platform.isAndroid) {
      try {
        bool connected = await AndroidBluetoothFeatures.isConnected();
        if (!connected) {
          print("device not connected");
          // If not connected, fetch the saved device address and attempt to connect
          final prefs = await SharedPreferences.getInstance();
          String? deviceAddress = prefs.getString('default_device_address');

          if (deviceAddress != null && deviceAddress.isNotEmpty) {
            print("Connecting to device with address: $deviceAddress");
            await AndroidBluetoothFeatures.connect();
            print("Connected to the device successfully.");
            print("_checkAndConnectToPrinter finished");
          } else {
            print("No saved device address found.");
          }
        } else {
          print("Already connected to the device.");
          await AndroidBluetoothFeatures.disconnect();

          await AndroidBluetoothFeatures.connect();
          print("Disconnected from the device.");
        }
      } catch (e) {
        print("Failed to check connection or connect android: $e");
      }
    }
  }
}
