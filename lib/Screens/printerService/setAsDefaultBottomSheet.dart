import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../Custom_Widgets/CustomPopups.dart';
import '../../Services/LocalizationService.dart';

class SetAsDefaultBottomSheet extends StatefulWidget {
  final BluetoothDevice device;

  SetAsDefaultBottomSheet({required this.device});

  @override
  State<SetAsDefaultBottomSheet> createState() => _SetAsDefaultBottomSheetState();
}

class _SetAsDefaultBottomSheetState extends State<SetAsDefaultBottomSheet> {
  String? _errorText;

  // Save the selected device as default in SharedPreferences
  void _setAsDefault(BuildContext context, BluetoothDevice device, String label) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_device_address', device.address ?? '');
    await prefs.setString('default_device_label', label);
    print("Device set as default: ${device.address}, Label: $label");

    // Fetch localized strings safely
    String successMessage = Provider.of<LocalizationService>(context, listen: false).getLocalizedString("printerSetAsDefaultSuccess");
    String okText = Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok");

    // Show success popup before closing the bottom sheet
    CustomPopups.showCustomResultPopup(
      context: context,
      icon: Icon(Icons.check_circle, color: Colors.green, size: 40),
      message: successMessage,
      buttonText: okText,
      onPressButton: () {
        // Define what happens when the button is pressed
        print('Success acknowledged');
        Navigator.pop(context); // Close the bottom sheet after the popup is shown
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController labelController = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // Adjust for keyboard
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Adjust the bottom sheet size
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Provider.of<LocalizationService>(context, listen: false).getLocalizedString("setDeviceAsDefault"),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Device Address (non-editable)
              Text(
                  "${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("mac")}: ${widget.device.address}",
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),

              // Label Field
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("label"),
                  labelStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  filled: true,
                  fillColor: Colors.white,
                  errorText: _errorText,
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Save Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (labelController.text.isNotEmpty) {
                        _setAsDefault(context, widget.device, labelController.text);
                      }
                      else {
                        setState(() {
                            _errorText = Provider.of<LocalizationService>(context, listen: false).getLocalizedString("labelValidation");
                         });
                      }
                    },
                    child: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString("setAsDefault")),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
