  import 'package:flutter/material.dart';
  import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:provider/provider.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../../Services/LocalizationService.dart';
import 'androidBluetoothFeaturesScreen.dart';
  import 'setAsDefaultBottomSheet.dart';


  class PrinterSettingScreen extends StatefulWidget {
    const PrinterSettingScreen({Key? key}) : super(key: key);

    @override
    State<PrinterSettingScreen> createState() => _PrinterSettingScreenState();
  }

  class _PrinterSettingScreenState extends State<PrinterSettingScreen> {
    BlueThermalPrinter printer = BlueThermalPrinter.instance;
    List<BluetoothDevice> pairedDevices = [];
    String? defaultDeviceLabel;
    String? defaultDeviceAddress;
    bool isLoading = false;
    bool isConnected = false;

    @override
    void initState() {
      super.initState();
      _getDefaultDevice();
      _getPairedDevices();
    }

    // Retrieve the default device address from SharedPreferences
    void _getDefaultDevice() async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        defaultDeviceLabel = prefs.getString('default_device_label');
        defaultDeviceAddress = prefs.getString('default_device_address');
      });
    }

    /// Retrieve paired Bluetooth devices and update the state.
    void _getPairedDevices() async {
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

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString("printerSettings")),
        ),
        body: Column(
          children: [
            if (isLoading) ...[
              Center(child: CircularProgressIndicator()),
              SizedBox(height: 16),
            ],
            // Make sure this ListView.builder is in the correct position inside the Column
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true, // Ensures it takes only the space it needs
                      itemCount: pairedDevices.length,
                      itemBuilder: (context, index) {
                        final device = pairedDevices[index];
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                              child: Material(
                                color: defaultDeviceAddress == device.address ? Colors.grey[100] : Colors.grey[100],
                                child: ListTile(
                                  title: Text(
                                    device.name ?? Provider.of<LocalizationService>(context, listen: false).getLocalizedString("unknown"),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: defaultDeviceAddress == device.address ? Color(0xFFC62828) : Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(device.address ?? "",
                                    style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),),
                                  trailing: ElevatedButton(
                                    onPressed: defaultDeviceAddress == device.address
                                        ? null // Disable if it's the default device
                                        : () {
                                      // Show bottom sheet when "Set as Default" is pressed
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (BuildContext context) {
                                          return SetAsDefaultBottomSheet(device: device);
                                        },
                                      ).then((_) {
                                        // Refresh the device list and check default device status
                                        _getDefaultDevice();
                                      });
                                    },
                                    child: Container(
                                      width: 90, // Set a fixed width for the button text (adjust as necessary)
                                      height:30,
                                      child: Center(
                                        child: Text(
                                          defaultDeviceAddress == device.address ? Provider.of<LocalizationService>(context, listen: false).getLocalizedString("default") : Provider.of<LocalizationService>(context, listen: false).getLocalizedString("setAsDefault"),
                                          style: TextStyle(
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center, // Ensure the text is centered inside the container
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Container wrapping the button with 1/3 screen width and specific height
                  Container(
                    width: MediaQuery.of(context).size.width / 3, // 1/3 of the screen width
                    height: 50, // Set height for the button
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _getPairedDevices,
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFFC62828), // Button background color
                        onPrimary: Colors.white, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12), // Add vertical padding for better spacing
                        elevation: 5, // Button elevation (shadow)
                      ),
                      child: Text(
                        Provider.of<LocalizationService>(context, listen: false).getLocalizedString("scan"),
                        style: TextStyle(
                          fontSize: 18, // Increase text size for better readability
                          fontWeight: FontWeight.bold, // Make the text bold
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

  }
