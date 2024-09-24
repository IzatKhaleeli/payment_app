import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/Payment.dart';
import '../Services/LocalizationService.dart';
import '../Services/database.dart';
import 'SMS_Service.dart';

class SmsBottomSheet extends StatefulWidget {
  final Payment payment;

  const SmsBottomSheet({
    Key? key,
    required this.payment,
  }) : super(key: key);

  @override
  _SmsBottomSheetState createState() => _SmsBottomSheetState();
}

class _SmsBottomSheetState extends State<SmsBottomSheet> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  String? _errorText;
  String _selectedMessageLanguage = 'ar'; // Default message language is English
  Map<String, dynamic>? _messageJson;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguageCode();
    if(widget.payment.msisdn != null)
    _phoneController.text=widget.payment.msisdn!;
    _phoneFocusNode.addListener(() {
      setState(() {
        if (_phoneFocusNode.hasFocus) {
          _errorText = null; // Clear error when field is focused
        }
      });
    });
  }

  Future<void> _loadSavedLanguageCode() async {
    setState(() {
      // If a language code is saved, use it as the default, otherwise keep 'en' as default
      _selectedMessageLanguage = 'ar';
    });
    // Load the localized message for the saved/default language
    await _loadLocalizedMessage(_selectedMessageLanguage);
  }

  Future<void> _loadLocalizedMessage(String languageCode) async {
    // Load the correct language JSON file
    String jsonString = await rootBundle.loadString('assets/languages/$languageCode.json');
    setState(() {
      _messageJson = jsonDecode(jsonString);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fetching localized strings for the app's UI
    var appLocalization = Provider.of<LocalizationService>(context, listen: false);
    String currentLanguageCode = Localizations.localeOf(context).languageCode;

    return Directionality(
      textDirection: currentLanguageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        // Adjust bottom padding dynamically based on keyboard visibility
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Adjust the bottom sheet size
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalization.getLocalizedString('sendSms'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  decoration: InputDecoration(
                    labelText: appLocalization.getLocalizedString('phoneNumber'),
                    labelStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    errorText: _errorText,
                    errorStyle: TextStyle(color: Colors.red, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
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
                    prefixIcon: Icon(Icons.phone, color: Colors.grey[700]),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 24),
                // Language Switcher for Message
                Text(appLocalization.getLocalizedString('selectLanguageForMessage')),
                SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildLanguageButton(
                        context,
                        'en',
                        'English',
                        Icons.language,
                        _selectedMessageLanguage == 'en',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildLanguageButton(
                        context,
                        'ar',
                        'Arabic',
                        Icons.language,
                        _selectedMessageLanguage == 'ar',
                      ),
                    ),


                  ],
                ),
                SizedBox(height: 24),

                // Send Button
                Row(
                  mainAxisAlignment: currentLanguageCode == 'ar' ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: currentLanguageCode == 'ar' ? Alignment.centerLeft : Alignment.centerRight,
                        child: ElevatedButton.icon(
                            onPressed: () async {
                              final msisdnRegex = RegExp(r'^05\d{8}$');
                              setState(() {
                                if (_phoneController.text.isEmpty) {
                                  _errorText = appLocalization.getLocalizedString('phoneNumberFieldError');
                                  return;
                                }
                                else if(!RegExp(r'^[0-9]*$').hasMatch(_phoneController.text)) {
                                  _errorText='${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('MSISDN')} ${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('mustContainOnlyNumber')}';
                                }
                                else if (_phoneController.text.length != 10){
                                  _errorText= Provider.of<LocalizationService>(context, listen: false).getLocalizedString('maxLengthExceeded');
                                }
                                else if (!msisdnRegex.hasMatch(_phoneController.text)) {
                                  _errorText = Provider.of<LocalizationService>(context, listen: false).getLocalizedString('invalidMSISDN');
                                  return ;
                                }
                                else {
                                  _errorText = null;
                                }
                              });

                              await _loadLocalizedMessage(_selectedMessageLanguage);

                              if (_messageJson != null && _errorText == null) {
                                print("message sent now");
                                String amount = widget.payment.amount?.toString() ?? widget.payment.amountCheck.toString();

                                  // await SmsService.sendSmsRequest(
                                  //     context,
                                  //     _phoneController.text,
                                  //     _selectedMessageLanguage,
                                  //     amount,
                                  //     widget.payment.currency!,
                                  //     widget.payment.voucherSerialNumber,
                                  //     _messageJson![widget.payment.paymentMethod.toLowerCase()]
                                  // );



                                // Close bottom sheet if no error
                                if (_errorText == null) Navigator.pop(context);
                              }
                            },
                            icon: Icon(Icons.send),
                          label: Text(appLocalization.getLocalizedString('send')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFC62828),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
  Widget _buildLanguageButton(
      BuildContext context,
      String languageCode,
      String languageName,
      IconData icon,
      bool isSelected) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedMessageLanguage = languageCode;
        });
        await _loadLocalizedMessage(languageCode);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? Color(0xFFC62828) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Color(0xFFC62828) : Colors.grey[700],
                ),
                SizedBox(width: 12),
                Text(
                  languageName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Color(0xFFC62828) : Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Color(0xFFC62828),
              ),
          ],
        ),
      ),
    );
  }

}

void showSmsBottomSheet(BuildContext context, Payment payment) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Enable the bottom sheet to resize based on the content
    builder: (context) => SmsBottomSheet(payment: payment),
  );
}
