import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../Screens/ShareScreenOptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Custom_Widgets/CustomPopups.dart';
import '../Models/Payment.dart';
import '../Services/LocalizationService.dart'; // Adjust import if needed
import '../Services/PaymentService.dart';
import '../Services/apiConstants.dart';
import '../Services/networking.dart';
import '../core/constants.dart';

class EmailBottomSheet extends StatefulWidget {
  final List<Payment> payments;
  final bool isMultiple;

  const EmailBottomSheet({
    Key? key,
    required this.payments,
    this.isMultiple = false,
  }) : super(key: key);

  @override
  _EmailBottomSheetState createState() => _EmailBottomSheetState();
}

class _EmailBottomSheetState extends State<EmailBottomSheet> {
  final TextEditingController _toController = TextEditingController();
  final FocusNode _toFocusNode = FocusNode();
  String? _errorText;
  String _selectedLanguage = 'ar';
  Map<String, dynamic>? _emailJson;
  bool isBlackAndWhite = false;

  @override
  void initState() {
    super.initState();
    _toFocusNode.addListener(() {
      setState(() {
        if (_toFocusNode.hasFocus) {
          _errorText = null; // Clear error when field is focused
        }
      });
    });
    _loadSavedLanguageCode();
    _loadLocalizedEmailContent(_selectedLanguage);
  }

  Future<void> _loadSavedLanguageCode() async {
    setState(() {
      _selectedLanguage = 'ar';
    });

    // Load the localized message for the saved/default language
    await _loadLocalizedEmailContent(_selectedLanguage);
  }

  Future<void> _loadLocalizedEmailContent(String languageCode) async {
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

  String getLocalizedEmailContent(String key) {
    if (_emailJson == null) {
      return '** $key not found';
    }
    return _emailJson![key] ?? '** $key not found';
  }

  Future<void> sendPdfFileViaApi(
    BuildContext context,
    File pdfFile,
    String toEmail,
    String subject,
    String fileName,
    String languageCode,
    String transactionDate,
  ) async {
    // Cache localization service and avoid calling Provider.of after awaits
    final loc = Provider.of<LocalizationService>(context, listen: false);

    try {
      // Add headers
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? tokenID = prefs.getString('token');
      if (tokenID == null) {
        print('Token not found');
        return;
      }
      String fullToken = "Barer ${tokenID}";
      print(fullToken);
      Map<String, String> headers = {
        'tokenID': fullToken,
      };
      Map<String, String> emailDetails = {
        'to': toEmail,
        'transactionDate': transactionDate,
        'languageCode': _selectedLanguage,
      };

      NetworkHelper networkHelper = NetworkHelper(
          url: apiUrlEmail, // Replace with your API URL
          headers: headers);

      print("emailDetails :${emailDetails}");
      String emailDetailsJson = jsonEncode(emailDetails);
      print("file name before send : ${fileName}");
      dynamic response = await networkHelper
          .uploadFile(
            fileName: fileName,
            file: pdfFile,
            emailDetailsJson: emailDetailsJson,
          )
          .timeout(Duration(seconds: 7));

      if (response == 200) {
        if (!mounted) return;
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.check_circle, color: Colors.green, size: 40),
          message: loc.getLocalizedString("paymentSentEmailOk"),
          buttonText: loc.getLocalizedString("ok"),
          onPressButton: () {
            // Define what happens when the button is pressed
            print('Success acknowledged');
          },
        );
      } else if (response.statusCode == 429) {
        if (!mounted) return;
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.error, color: AppColors.primaryRed, size: 40),
          message: loc.getLocalizedString("exceedNumberOfRequest"),
          buttonText: loc.getLocalizedString("ok"),
          onPressButton: () {
            print('Exceed number of request');
          },
        );
      } else if (response == 401) {
        int responseNumber = await PaymentService.attemptReLogin(context);
        print(
            "the response number from get expend the session is :${responseNumber}");
        if (responseNumber == 200) {
          print("relogin successfully");
          tokenID = prefs.getString('token');
          if (tokenID == null) {
            print('Token not found');
            return;
          }
          fullToken = "Barer ${tokenID}";
          headers = {
            'tokenID': fullToken,
          };
          networkHelper = NetworkHelper(
              url: apiUrlEmail, // Replace with your API URL
              headers: headers);

          dynamic reloginResponse = await networkHelper.uploadFile(
            fileName: fileName,
            file: pdfFile,
            emailDetailsJson: emailDetailsJson,
          );
          if (reloginResponse == 200) {
            if (!mounted) return;
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.check_circle, color: Colors.green, size: 40),
              message: loc.getLocalizedString("paymentSentEmailOk"),
              buttonText: loc.getLocalizedString("ok"),
              onPressButton: () {
                // Define what happens when the button is pressed
                print('Success acknowledged');
              },
            );
          } else if (response.statusCode == 429) {
            if (!mounted) return;
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.error, color: AppColors.primaryRed, size: 40),
              message: loc.getLocalizedString("exceedNumberOfRequest"),
              buttonText: loc.getLocalizedString("ok"),
              onPressButton: () {
                print('Exceed number of request');
              },
            );
          } else {
            if (!mounted) return;
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.error, color: AppColors.primaryRed, size: 40),
              message:
                  '${loc.getLocalizedString("paymentSentEmailFailed")}: Failed to upload file , $reloginResponse.statusCode',
              buttonText: loc.getLocalizedString("ok"),
              onPressButton: () {
                print(
                    'Failed to upload file. Status code: ${reloginResponse.statusCode}');
              },
            );
          }
        }
      } else if (response.statusCode == 408) {
        if (!mounted) return;
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.error, color: AppColors.primaryRed, size: 40),
          message: loc.getLocalizedString("networkTimeoutError"),
          buttonText: loc.getLocalizedString("ok"),
          onPressButton: () {
            print('Error timeout');
          },
        );
      } else {
        print(response.statusCode);
        print(response.reasonPhrase);
        if (!mounted) return;
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.error, color: AppColors.primaryRed, size: 40),
          message:
              '${loc.getLocalizedString("paymentSentEmailFailed")}: Failed to upload file , $response.statusCode',
          buttonText: loc.getLocalizedString("ok"),
          onPressButton: () {
            print('Failed to upload file. Status code: ${response.statusCode}');
          },
        );
      }
    } on SocketException {
      if (!mounted) return;
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: AppColors.primaryRed, size: 40),
        message: loc.getLocalizedString("networkError"),
        buttonText: loc.getLocalizedString("ok"),
        onPressButton: () {
          print('Network error acknowledged');
        },
      );
    } on TimeoutException {
      if (!mounted) return;
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: AppColors.primaryRed, size: 40),
        message: loc.getLocalizedString("networkTimeoutError"),
        buttonText: loc.getLocalizedString("ok"),
        onPressButton: () {
          print('Timeout error acknowledged');
        },
      );
    } catch (e) {
      if (!mounted) return;
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: AppColors.primaryRed, size: 40),
        message: '${loc.getLocalizedString("paymentSentEmailFailed")}',
        buttonText: loc.getLocalizedString("ok"),
        onPressButton: () {
// Define what happens when the button is pressed
          print('Error: $e');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emailJson == null) {
      return Center(child: CircularProgressIndicator());
    }
    DateTime transactionDate = widget.payments.first.transactionDate!;

// Extract year, month, day, hour, and minute
    int year = transactionDate.year;
    int month = transactionDate.month;
    int day = transactionDate.day;
    int hour = transactionDate.hour;
    int minute = transactionDate.minute;

// Format the output as a string
    String formattedDate =
        '${year.toString().padLeft(4, '0')}/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    var appLocalization =
        Provider.of<LocalizationService>(context, listen: false);
    String currentLanguageCode = Localizations.localeOf(context).languageCode;

    return Directionality(
      textDirection:
          currentLanguageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        // Adjust bottom padding dynamically based on keyboard visibility
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Adjust the bottom sheet size
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalization.getLocalizedString('sendEmail'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // To Field (editable)
                TextField(
                  controller: _toController,
                  focusNode: _toFocusNode,
                  decoration: InputDecoration(
                    labelText: appLocalization.getLocalizedString('to'),
                    labelStyle:
                        TextStyle(fontSize: 14, color: Colors.grey[700]),
                    errorText: _errorText,
                    errorStyle:
                        TextStyle(color: AppColors.primaryRed, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                    prefixIcon:
                        Icon(Icons.email_outlined, color: Colors.grey[700]),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 24),
                // Language Switcher for Message
                Text(
                  appLocalization
                      .getLocalizedString('selectLanguageForMessage'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildLanguageButton(
                        context,
                        'en',
                        'English',
                        Icons.language,
                        _selectedLanguage == 'en',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildLanguageButton(
                        context,
                        'ar',
                        'Arabic',
                        Icons.language,
                        _selectedLanguage == 'ar',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                Text(
                  Provider.of<LocalizationService>(context, listen: false)
                      .getLocalizedString("selectTemplate"),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectionCard(
                        context: context,
                        title: Provider.of<LocalizationService>(context,
                                listen: false)
                            .getLocalizedString("colored"),
                        icon: Icons.receipt_long_outlined,
                        isSelected: !isBlackAndWhite,
                        onTap: () {
                          setState(() {
                            isBlackAndWhite = false;
                          });
                        },
                      ),
                    ),
                    if (widget.isMultiple != true) ...[
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildSelectionCard(
                          context: context,
                          title: Provider.of<LocalizationService>(context,
                                  listen: false)
                              .getLocalizedString("b_and_w"),
                          icon: Icons.receipt_long_outlined,
                          isSelected: isBlackAndWhite,
                          onTap: () {
                            setState(() {
                              isBlackAndWhite = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 20),

                // Send Button
                Row(
                  mainAxisAlignment: currentLanguageCode == 'ar'
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: currentLanguageCode == 'ar'
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            setState(() {
                              if (_toController.text.isEmpty) {
                                _errorText = appLocalization
                                    .getLocalizedString('toFieldError');
                                return;
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                  .hasMatch(_toController.text)) {
                                _errorText = appLocalization
                                    .getLocalizedString('invalidEmailError');
                                return;
                              }
                              _errorText = null;
                            });
                            if (_errorText == null) {
                              final firstPayment = widget.payments.first;
                              String transactionDate =
                                  firstPayment.transactionDate.toString();
                              int spaceIndex = transactionDate.indexOf(' ');

                              String result;
                              if (spaceIndex != -1) {
                                result =
                                    transactionDate.substring(0, spaceIndex);
                              } else {
                                result = transactionDate;
                              }

                              String fileName = "اشعاردفع-${result}";
                              String toEmail = _toController.text;
                              print("To: $toEmail");
                              print("Subject: $fileName");

                              File? file;

                              if (!isBlackAndWhite) {
                                file = await ShareScreenOptions.sharePdfForIds(
                                  context,
                                  widget.payments
                                      .map((payment) => payment.id!)
                                      .toList(),
                                  _selectedLanguage,
                                );
                              } else {
                                file = await ShareScreenOptions.sharePdf(
                                    context,
                                    firstPayment.id!,
                                    _selectedLanguage,
                                    isBlackAndWhite: isBlackAndWhite);
                              }

                              if (file == null) {
                                print("file is null");
                              } else {
                                print("ready to send to email api");
                                await sendPdfFileViaApi(
                                    context,
                                    file,
                                    toEmail,
                                    fileName,
                                    fileName,
                                    currentLanguageCode,
                                    formattedDate);
                              }
                              // Close bottom sheet if no error
                              Navigator.pop(context);
                            }
                          },
                          icon: Icon(Icons.send),
                          label:
                              Text(appLocalization.getLocalizedString('send')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
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

  static Widget _buildSelectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : Colors.white,
            width: 1.5,
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
            Flexible(
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? AppColors.primaryRed : Colors.grey[700],
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      title,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryRed
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryRed,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, String languageCode,
      String languageName, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedLanguage = languageCode;
        });
        await _loadLocalizedEmailContent(languageCode);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : Colors.transparent,
            width: 1.5,
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
                  color: isSelected ? AppColors.primaryRed : Colors.grey[700],
                ),
                SizedBox(width: 10),
                Text(
                  languageName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.primaryRed : Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryRed,
              ),
          ],
        ),
      ),
    );
  }
}

void showEmailBottomSheet(BuildContext context, List<Payment> payments,
    {bool isMultiple = false}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        EmailBottomSheet(payments: payments, isMultiple: isMultiple),
  );
}
