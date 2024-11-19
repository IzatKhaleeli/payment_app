import 'dart:io';

import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Custom_Widgets/CustomPopups.dart';
import '../../Services/LocalizationService.dart';
import 'androidBluetoothFeaturesScreen.dart';
import 'setAsDefaultBottomSheet.dart';
import 'iosMethods.dart' as iosPlat;
import 'package:flutter/services.dart';


class PrinterSettingScreen extends StatefulWidget {
  const PrinterSettingScreen({Key? key}) : super(key: key);

  @override
  State<PrinterSettingScreen> createState() => _PrinterSettingScreenState();
}

class _PrinterSettingScreenState extends State<PrinterSettingScreen> {
  String? defaultDeviceLabel;
  String? defaultDeviceAddress;
  bool isLoading = true;
  bool isConnected = false;

  //for android
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  List<BluetoothDevice> pairedDevices = [];

  //for ios
  List<Map<String, String>> discoveredDevices = []; // List to store discovered devices
  bool isScanning = false; // To track the scanning state

  // Retrieve the default device address from SharedPreferences
  void _getDefaultDevice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultDeviceLabel = prefs.getString('default_device_label');
      defaultDeviceAddress = prefs.getString('default_device_address');
    });
  }

  // Show loading for 2 seconds
  Future<void> _showLoadingTwiceScreen() async {
    // Wait for scanning to complete
    await scanDevices();
    if(Platform.isIOS)
      await scanDevices();
    setState(() {
      isLoading = false; // Stop loading after scan completes
    });
  }

  // Show loading for 2 seconds
  Future<void> _showLoadingScreen() async {
    // Wait for scanning to complete
    await scanDevices();
    setState(() {
      isLoading = false; // Stop loading after scan completes
    });
  }

  Future<void> scanDevices() async {
    setState(() {
      isLoading = true;
    });

    if (Platform.isIOS) {
      // Perform iOS scan with await to ensure it completes before moving to the next scan
      await ios_startScan();
    } else if (Platform.isAndroid) {
      // Perform Android paired device retrieval
      android_getPairedDevices();
    }

    // No need to call setState here as it is already done when the scanning is complete.
    setState(() {
      isLoading = false; // Stop loading after scanning is done
    });
  }

  @override
  void initState() {
    super.initState();
    _getDefaultDevice();
    _showLoadingTwiceScreen(); // Show loading for 2 seconds
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString("printerSettings")),
      ),
      body: isLoading ?
      Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC62828)), // Color of the spinner
        ),
      ) :
      ((Platform.isAndroid && pairedDevices.isEmpty) ||
          (Platform.isIOS && discoveredDevices.isEmpty)) ?
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Text(
                Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString("noBluetoothDevicesFound"),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(child: SizedBox.shrink()), // Push the button to the bottom
            customButton(
                context,
                isLoading,
                _showLoadingScreen,
                Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString("scan")
            ),
          ],
        ),
      ):
      Column(
        children: [

          // Make sure this ListView.builder is in the correct position inside the Column
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                  children: [
                    if (Platform.isAndroid)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if(defaultDeviceLabel != null && defaultDeviceAddress != null)
                          ...[Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10, left: 10, top: 20),
                              child: Text(
                                Provider.of<LocalizationService>(context, listen: false)
                                    .getLocalizedString("defaultPrinter"),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                              child: Card(
                                elevation: 3.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0), // Rounded corners for the Card
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: ListTile(
                                    title: Text(
                                      defaultDeviceLabel?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFC62828), // Highlight default device
                                      ),
                                    ),
                                    subtitle: Text(
                                      defaultDeviceAddress ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: null, // Default device button is disabled
                                      child: Container(
                                        width: 90, // Fixed width for button
                                        height: 30,
                                        child: Center(
                                          child: Text(
                                            Provider.of<LocalizationService>(context, listen: false)
                                                .getLocalizedString("default"),
                                            style: TextStyle(fontSize: 12),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Divider(
                              color: Colors.grey,
                              thickness: 1.0,
                              indent: 12.0,
                              endIndent: 12.0,
                            ),],

                          ListView.builder(
                            shrinkWrap: true, // Ensures it takes only the space it needs
                            physics: NeverScrollableScrollPhysics(), // Avoid nested scrolling issues
                            itemCount: pairedDevices.length,
                            itemBuilder: (context, index) {
                              final device = pairedDevices[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                                child: Card(
                                  elevation: 3.0,
                                  child: ListTile(
                                    title: Text(
                                      device.name ??
                                          Provider.of<LocalizationService>(context, listen: false)
                                              .getLocalizedString("unknown"),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      device.address ?? "",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (BuildContext context) {
                                            return SetAsDefaultBottomSheet(deviceAddress: device.address! ,deviceName: device.name!);
                                          },
                                        ).then((_) {
                                          // Refresh default device status
                                          _getDefaultDevice();
                                        });
                                      },
                                      child: Container(
                                        width: 90, // Fixed width for button
                                        height: 30,
                                        child: Center(
                                          child: Text(
                                            defaultDeviceAddress == device.address
                                                ? Provider.of<LocalizationService>(context, listen: false)
                                                .getLocalizedString("default")
                                                : Provider.of<LocalizationService>(context, listen: false)
                                                .getLocalizedString("setAsDefault"),
                                            style: TextStyle(fontSize: 13),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    else if (Platform.isIOS) ...[
                      // If there is a default device, display it first with "Default Printer:" title.
                      if (defaultDeviceAddress != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10,left: 10,top:10),
                                child: Text(
                                  Provider.of<LocalizationService>(context, listen: false)
                                      .getLocalizedString("defaultPrinter"),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                              child: Card(
                                elevation: 3.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0), // Rounded corners for the Card
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: ListTile(
                                    title: Text(
                                      discoveredDevices.firstWhere(
                                            (device) => device['address'] == defaultDeviceAddress,
                                        orElse: () => {'name': 'Unknown Device'},
                                      )['name'] ??
                                          Provider.of<LocalizationService>(context, listen: false)
                                              .getLocalizedString("unknown"),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFC62828), // Highlight default device
                                      ),
                                    ),
                                    subtitle: Text(
                                      defaultDeviceAddress ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: null, // Default device button is disabled
                                      child: Container(
                                        width: 90, // Fixed width for button
                                        height: 30,
                                        child: Center(
                                          child: Text(
                                            Provider.of<LocalizationService>(context, listen: false)
                                                .getLocalizedString("default"),
                                            style: TextStyle(fontSize: 12),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Divider(
                              color: Colors.grey,
                              thickness: 1.0,
                              indent: 12.0,
                              endIndent: 12.0,
                            ),
                          ],
                        ),

                    ],

                    ...discoveredDevices.map((device) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                        child: Card(
                          elevation: 3.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0), // Rounded corners for the Card
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: ListTile(
                              title: Text(
                                device['name'] ?? Provider.of<LocalizationService>(context, listen: false)
                                    .getLocalizedString("unknown"),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: (isConnected && defaultDeviceAddress == device['address'])
                                      ? Color(0xFFC62828)
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                device['address'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: (isConnected && defaultDeviceAddress == device['address'])
                                    ? null : () async {

                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (BuildContext context) {
                                      return SetAsDefaultBottomSheet(deviceAddress: device['address']! ,deviceName: device["name"]!);
                                    },
                                  ).then((_) {
                                    // Refresh default device status
                                    _getDefaultDevice();
                                  });
                                },
                                child: Container(
                                  width: 90, // Fixed width for button
                                  height: 30,
                                  child: Center(
                                    child: Text(
                                      defaultDeviceAddress == device['address']
                                          ? Provider.of<LocalizationService>(context, listen: false)
                                          .getLocalizedString("default")
                                          : Provider.of<LocalizationService>(context, listen: false)
                                          .getLocalizedString("setAsDefault"),
                                      style: TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ]
              ),
            ),
          ),


          customButton(context, isLoading, _showLoadingScreen, Provider.of<LocalizationService>(context, listen: false).getLocalizedString("scan")),
        ],
      ),
    );
  }

  Widget customButton(BuildContext context, bool isLoading, VoidCallback onPressed, String buttonText) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Container wrapping the button with 1/3 screen width and specific height
          Container(
            width: MediaQuery.of(context).size.width / 3, // 1/3 of the screen width
            height: 50, // Set height for the button
            margin: EdgeInsets.only(bottom: 20), // Add bottom margin (adjust the value as needed)
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed, // Use the passed in callback function
              style: ElevatedButton.styleFrom(
                primary: Color(0xFFC62828), // Button background color
                onPrimary: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                padding: EdgeInsets.symmetric(vertical: 12), // Add vertical padding for better spacing
                elevation: 4, // Button elevation (shadow)
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 18, // Increase text size for better readability
                  fontWeight: FontWeight.bold, // Make the text bold
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }




  Future<bool> ios_checkBluetoothStatus() async {
    bool isBluetoothOn = await iosPlat.BluetoothService.isBluetoothPoweredOn();
    if (isBluetoothOn) {
      print("Bluetooth is powered on.");
      return true;
    } else {
      print("Bluetooth is not powered on.");
      return false;
    }
  }

  // Stop scanning for Bluetooth devices
  void ios_stopScan() async {
    setState(() {
      isScanning = false;
    });

    await iosPlat.BluetoothService.stopScan();

    // Here, ensure that the scanning is stopped after a predefined period (e.g., 2 seconds).
    // You can use Timer to stop scanning after 2 seconds.
    Future.delayed(Duration(seconds: 2), () {
      iosPlat.BluetoothService.stopScan(); // Ensure scan stops after timeout
      setState(() {
        isScanning = false;
      });
    });
  }

  Future<void> ios_startScan() async {
    bool bluetoothStatus = await ios_checkBluetoothStatus();
    if(!bluetoothStatus){
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: Color(0xFFC62828), size: 40),
        message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("bluetooth_off_message"),
        buttonText:  Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
        onPressButton: () {
          // Define what happens when the button is pressed
          print('bluetooth is not powered ..');
          return ;
        },
      );
    }
    setState(() {
      isScanning = true;
      discoveredDevices.clear(); // Clear previously discovered devices
    });

    // Stop any ongoing scan to avoid conflicts
    await iosPlat.BluetoothService.stopScan();

    // Start the scan
    await iosPlat.BluetoothService.startScan();
    setState(() {
      // Listen for discovered devices
      iosPlat.BluetoothService.listenForDevices().listen((device) {
        // Add each discovered device to the list if it is not already in the list
        // Check if the device is already in the list
        if (device['name']?.toLowerCase() != 'unknown' &&
            !discoveredDevices.any((d) => d['address'] == device['address'])) {
          discoveredDevices.add({
            'name': device['name'],
            'address': device['address'],
          });
        }
      });

    });

    print(discoveredDevices);

  }

  /// Retrieve paired Bluetooth devices and update the state.
  void android_getPairedDevices() async {
    bool bluetoothStatus = await android_checkBluetoothStatus();
    if(!bluetoothStatus){
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: Color(0xFFC62828), size: 40),
        message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("bluetooth_off_message"),
        buttonText:  Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
        onPressButton: () {
          // Define what happens when the button is pressed
          print('bluetooth is not powered ..');
          return ;
        },
      );
    }
    setState(() {
      isLoading = true;
      pairedDevices.clear();  // Clear the device list before new scan
    });
    try {
      List<BluetoothDevice> devices = await AndroidBluetoothFeatures.startScan();
      setState(() {
        pairedDevices = devices;
      });
    } catch (e) {
      print("Error fetching paired devices: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> android_checkBluetoothStatus() async {
    bool isBluetoothOn = await AndroidBluetoothFeatures.isBluetoothOn();
    if (isBluetoothOn) {
      print("Bluetooth is powered on.");
      return true;
    } else {
      print("Bluetooth is not powered on.");
      return false;
    }
  }

}
