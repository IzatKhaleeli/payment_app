import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../Screens/ShareScreenOptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Custom_Widgets/CustomPopups.dart';
import '../Models/Payment.dart';
import '../Services/LocalizationService.dart'; // Adjust import if needed
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:http_parser/http_parser.dart';

import '../Services/PaymentService.dart';
import '../Services/apiConstants.dart';
import '../Services/networking.dart';

class EmailBottomSheet extends StatefulWidget {
  final Payment payment;

  const EmailBottomSheet({
    Key? key,
    required this.payment,
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
  String? _headerBase64;
  String? _footerBase64;

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
    _loadBase64Images();
  }

  Future<void> _loadSavedLanguageCode() async {
    setState(() {
      _selectedLanguage ='ar';
    });

    // Load the localized message for the saved/default language
    await _loadLocalizedEmailContent(_selectedLanguage);
  }

  Future<void> _loadLocalizedEmailContent(String languageCode) async {
    try {
      String jsonString = await rootBundle.loadString('assets/languages/$languageCode.json');
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

  Future<void> _loadBase64Images() async {
    try {
      final headerBase64 = await encodeImageToBase64('assets/images/headerEmail.jpg');
      final footerBase64 = await encodeImageToBase64('assets/images/footerEmail.jpg');
      setState(() {
        _headerBase64 = headerBase64;
        _footerBase64 = footerBase64;
      });
    } catch (e) {
      print("Error encoding images to Base64: $e");
    }
  }

  Future<String> encodeImageToBase64(String path) async {
    final ByteData data = await rootBundle.load(path);
    final List<int> bytes = data.buffer.asUint8List();
    return base64Encode(bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_emailJson == null || _headerBase64 == null || _footerBase64 == null) {
      return Center(child: CircularProgressIndicator());
    }
    DateTime transactionDate = widget.payment.transactionDate!;

// Extract year, month, day, hour, and minute
    int year = transactionDate.year;
    int month = transactionDate.month;
    int day = transactionDate.day;
    int hour = transactionDate.hour;
    int minute = transactionDate.minute;

// Format the output as a string
    String formattedDate = '${year.toString().padLeft(4, '0')}/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    //String subject = "${getLocalizedEmailContent('emailSubject')} ${formattedDate}";
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
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[700]),
                  ),
                  keyboardType: TextInputType.emailAddress,
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

                            setState(() {
                              if (_toController.text.isEmpty) {
                                _errorText = appLocalization.getLocalizedString('toFieldError');
                                return;
                              }
                              _errorText = null; // Clear error if valid
                            });
                            if(_errorText ==null) {
                              // Handle send action
                              String transactionDate = widget.payment.transactionDate.toString(); // Your original string
                              int spaceIndex = transactionDate.indexOf(' ');

                              String result; // Define the result variable
                              if (spaceIndex != -1) {
                                result = transactionDate.substring(0, spaceIndex); // Get the part before the first space
                              } else {
                                result = transactionDate; // If no space found, use the entire string
                              }

                              String fileName="اشعاردفع-${result}";
                              //String fileName="إشعاردفع-${DateFormat('yyyy-MM-dd').format(widget.payment.transactionDate!)}";
                              String toEmail = _toController.text;
                              print("To: $toEmail");
                              print("Subject: $fileName");
                              String direction = _selectedLanguage == 'en' ? 'left' : 'right';
                              print("_selectedLanguage :${_selectedLanguage}");
                              String headerImage = "/9j/4AAQSkZJRgABAQEAlgCWAAD/4QAiRXhpZgAATU0AKgAAAAgAAQESAAMAAAABAAEAAAAAAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcGBwcICQsJCAgKCAcHCg0KCgsMDAwMBwkODw0MDgsMDAz/2wBDAQICAgMDAwYDAwYMCAcIDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCACLA88DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDwPVNUuv7Qm/fSfeqv/atz/wA9mo1P/kKTf71V6/BPeP8AZSnTjyrQsf2rc/8APZqP7Vuf+ezVXopByQ7Fj+1bn/ns1H9q3P8Az2aq9FAckOxY/tW5/wCezUf2rc/89mqvRQHJDsWP7Vuf+ezUf2rc/wDPZqr0UByQ7Fj+1bn/AJ7NR/atz/z2aq9FAckOxY/tW5/57NR/atz/AM9mqvRQHJDsWP7Vuf8Ans1H9q3P/PZqr0UByQ7Fj+1bn/ns1H9q3P8Az2aq9FAckOxY/tW5/wCezUf2rc/89mqvRQHJDsWP7Vuf+ezUf2rc/wDPZqr0UByQ7Fj+1bn/AJ7NR/atz/z2aq9FAckOxY/tW5/57NR/atz/AM9mqvRQHJDsWP7Vuf8Ans1H9q3P/PZqr0UByQ7Fj+1bn/ns1H9q3P8Az2aq9FAckOxY/tW5/wCezUf2rc/89mqvRQHJDsWP7Vuf+ezUf2rc/wDPZqr0UByQ7Fj+1bn/AJ7NR/atz/z2aq9FAckOxY/tW5/57NR/atz/AM9mqvRQHJDsWP7Vuf8Ans1H9q3P/PZqr0UByQ7Fj+1bn/ns1H9q3P8Az2aq9FAckOxY/tW5/wCezUf2rc/89mqvRQHJDsWP7Vuf+ezUf2rc/wDPZqr0UByQ7Fj+1bn/AJ7NR/atz/z2aq9FAckOxY/tW5/57NR/atz/AM9mqvRQHJDsWP7Vuf8Ans1H9q3P/PZqr0UByQ7Fj+1bn/ns1H9q3P8Az2aq9FAckOxY/tW5/wCezUf2rc/89mqvRQHJDsWP7Vuf+ezUf2rc/wDPZqr0UByQ7Fj+1bn/AJ7NR/atz/z2aq9FAckOxY/tW5/57NR/atz/AM9mqvRQHJDsWP7Vuf8Ans1H9q3P/PZqr0UByQ7Fj+1bn/ns1H9q3P8Az2aq9FAckOxY/tW5/wCezUf2rc/89mqvRQHJDsWP7Vuf+ezUf2rc/wDPZqr0UFezh2LH9q3P/PZqP7Vuf+ezVXooD2cOxY/tW5/57NR/atz/AM9mqvRQHs4dix/atz/z2aj+1bn/AJ7NVeigPZw7Fj+1bn/ns1H9q3P/AD2aq9FAezh2LH9q3P8Az2aj+1bn/ns1V6KA9nDsWP7Vuf8Ans1H9q3P/PZqr0UB7OHYsf2rc/8APZqP7Vuf+ezVXooD2cOxY/tW5/57NR/atz/z2aq9FAezh2LH9q3P/PZqP7Vuf+ezVXooD2cOxY/tW5/57NR/atz/AM9mqvRQHs4dix/atz/z2aj+1bn/AJ7NVeigPZw7Fj+1bn/ns1H9q3P/AD2aq9FAezh2LH9q3P8Az2aj+1bn/ns1V6KA9nDsWP7Vuf8Ans1H9q3P/PZqr0UB7OHYsf2rc/8APZqP7Vuf+ezVXooD2cOxY/tW5/57NR/atz/z2aq9FAezh2LH9q3P/PZqP7Vuf+ezVXooD2cOxY/tW5/57NR/atz/AM9mqvRQHs4dix/atz/z2aj+1bn/AJ7NVeigPZw7Fj+1bn/ns1H9q3P/AD2aq9FAezh2LH9q3P8Az2aj+1bn/ns1V6KA9nDsWP7Vuf8Ans1H9q3P/PZqr0UB7OHYsf2rc/8APZqP7Vuf+ezVXooF7OHYsf2rc/8APZqP7Vuf+ezVXooFyQ7Fj+1bn/ns1H9q3P8Az2aq9FAckOxY/tW5/wCezUf2rc/89mqvRQHJDsWNV/5CU3+9VerGq/8AISm/3qr0BT+BBRRRQaBRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFADZJFij3OyqtNjulmbarqzelfZX/BE39nzwp+0D+0frkPizSbfWrTSdP86C2nXdFu3gbiO9fUf/AAWb/Yw+G/w0/Y9v/FXhvwvpuh6vpV1CsU1nFs3B22kH1r3MPkdWrgnjItWX6H5DnXjFl2W8VUuFalGcqlTkXPpZOW3mfktRSJ92lrwz9eCiiigAooooAKKKKACihdzMqqrO7NtRUXczFvuqtfVnwm/4Iy/G74ueBYfEEen6fo8N5F5tvb3kwSdx23DtXTh8HXxDtQhc8HPOKMpyamqua4iFFS0XO7X9D5TorqvjF8E/FH7P/jq48N+LtLm0vVbf5trf6uZf7yN/EtcrWMoyhLlkuVnrYXFUcTRjicNNThLVSWqaCiiioOgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAsar/yEpv96q9WNV/5CU3+9Vegzp/AgooooNAooooAKKKm0/TbrXNUtrCxt5Lq+vpVgt4EX5pHZtqrQtdETUqQhDnnsV5JFj2r8zMzbVRV3M3/AAGu98F/ss/Ez4j2yz6H4F8QX0EnzLKLcqrf99V+qf8AwTh/4I/eGfgn4dsfFHxAsrfX/Gl0gn8mdd0Om5+YKo9a+1tU8Q+HfAFnH9uu9H0ePGEWaVIR+GcV9tl/CMpU/a4qfL5H8pcY/ScoYXGywPD+G9vy6c7bSfolq15n85fjr9nvx/8AC6BpfEXg3X9KhX70j25Zf/Ha46OVZPmVt1f0xAeG/iboMgUaXrdjMNjbSkyN7V+cf/BUf/gj5pcHhvUPiF8K7D7Df2YNxqOjRf6q4QdWjX+FqzzDhOdKl7TDz5kjv4E+klhMzxsMtzyh9XnN2Ur3jfs76r11Py6p1nbzaleJbWdvcXl1I21YoEaSRv8AgK12X7O/wE8RftP/ABZ03wb4bgZtQv3xLI6/LZov33f/AHa/cL9jf/gmx8PP2QfCdvHaaXbar4i2f6Vq1zEHmkfHOM9BXlZPkdbHS5vhgup+heJ3jFlfB8FRmva4iesYLt3b6L8Wfirof7GHxe8SWAurP4eeIpIWGQ3k7dwri/HHw48S/DC88jxLoGraHJ6XNuyr/wB9fdr+kbV/iP4V8LXy2l5rOiafcdBDLdRRt+RNU/iJ8HfB/wAefCclhr2k6XrmnXSYIdFdWz3Br6OpwbRlDlpVfePwvB/SozCFdTzDL17GXZu/46P8D+a3cvl53fLXWaT8APiB4h0ZdS0/wX4gutPkXelxHbny2T+8K+mP+CoH/BMKf9jnxRZeKPC6zXngHU9QgR4m+ZtNdpV4P/TOv2L+B2hWcPwb8OwxWdtHC2nQ/IqAD7gryct4ZnWrVKFd8rifpHHHj9hcsynB5vktNV4Yhu93bl5bXTS66n84PhrwXrXjfXG0zRdG1TVNSV9j29vblpI29G/u16Le/sJfGfTtMa9k+HPiDyMbuI/mxX75+BPgD4H+DEmpX2i6DpOky6hO95eXIiVTI7HJZjVy0+N3gnVdQ+wQ+JfD891nb5K3kTMT6YzXr0+DaKX76pqfm+N+lNmVapzZXl96a35nJv8ADRH82WuaLf8AhfVJLLVbC80u8j+9FcxNG3/j1M0+xudY1BLWxtrrULqT5Vit4mkk/wDHa/oR/av/AGEPh/8AtfeDZtP17SbWO+ZP9H1K2QLcWrdmVqz/ANkP/gnZ8O/2PvDcdtoulwahqw5n1W7RZLic+57Vyf6l1fbW51yd/wDgH0lP6VWVf2X7eeFn9Z/5939315u3la5+I+k/sT/GHXNN+123w68RNDt3bvJ27q4fxp8P/EHw0vfs/iTQdU0O49LuAqv/AH192v6StS+J3hbw/frY3WtaLaXHQRSXUSP+RNZXxR+BXgr9oHwvJp/iLRdM1zT7tCAHjVs5HUGuqpwbTcf3NXU+dwP0qMdCupZnl6VGX8rd/wAdH+B/Np3/AL1JuWP5m+Va+sf+Cn3/AATVvP2JPFS65oXnX3w/1aUrHI4y+mv/AHHb+7/dNbX/AASx/wCCYE37Ymrf8Jd4sS4tPAljLtiiHyvqjr2/6518rHJsT9a+qW97+tfQ/o6p4ocPx4c/1m9t/s/b7XN/Jb+by/Q+T/A/w18TfE68+z+GfD2ra5J/07W7Mv8A3192uu1b9jf4uaBYtc3nw78RRwx/MzeTu21/QZ8PvhF4Q+BnhaOx0HSNL0TTbROBHGsaqB3Jq3pfxF8K+Kb02ljrOiX10DjyormKR/yBr6qnwbRjG1Wr7x/N+M+lRmFSs5YDL17GPdu9vO2iPyc/4N84J9O/ah8YW91a3Frcx6aFkinjaN0+cdjX2B/wXUfd/wAE/fEH/X1bH/yIK+n9E+DnhnQvHM3iSx0TT7TW7qLyJrqKIJJInoSK+Xv+C6I8v9gDxE2C7NdWqqo6sfM6V67y94PKqmHb5tGfmMeNYcU+I+BziFP2fNOknG97OLS3PxDaRI4tzNtWuy8A/s9ePvijbLL4d8G6/qkLfdkjtyq/+PV+jH/BLX/gj/pZ8Oab8QPipYLqF9fKLjTtGm/1NujfMHkH8TGv0YY+HPhtoybm0nRbOFdi7ikEagdua+ay3hOpWpe0xEuRfifv3HX0ksJlmNlluR0PrE4e65X92/ZW1l66L1P52fG/7LvxM+HFm1xrngbX9Pt1+9Kbcsv/AI7XCRyLJuX5lZfvArtZf+A1/TLpfiLw78Q7J/sN3pGtQ42usUiTD8cZr4n/AOCj/wDwR98N/Gjwxf8Air4e2NvoPjK1Qzm3hXy4NSx8xVh2aqx/CMoU/aYWfP5HHwb9JqhisbHA8QYb2HNpzptpeqeqXmfjnQN0kiRokkk0h2pHGrSM3/AVrc8JfDTxB42+JNr4P03TbhvEl3d/YDZsvzRy52tu/wBla/aj9gX/AIJPeCf2WPDVnqeuWNv4i8aToss95cpvW2f+5GD0Arw8pyWtjpuMfdUd2frniP4sZRwhhYVMR+9qzXuQW7/vX6Lz+4/H/wAJ/shfFfxzYrdaX8PvEd1bsu5ZPJ2q3/fVc/4++DHjT4Uj/ipvCmuaKv8Afmt22/8AfS1/R9rnjjw14Hljh1LVNH012HypNOkJP4E1HrXhfwv8W/DskN7aaTrmm3a7HBCTRuv1r6iXBtHl5YVdT+esP9KjM4VVVxOXr2L7OV/vas/uP57/ANiKPRLz9rv4er4gaNtHbU08zzPubv4c/wDAq/owtAgto1QL5e0bcdCK/In/AIKq/wDBJiH4FaZcfEr4Zw3EejwS+fqWmxHmw+bd5sPsDzivMfhH/wAFtfjL8LPAdvopbStfW1i8q3vLxGMwH8O4/wAVZ5Xilk05YbGLfXmR6viJw1W8U8Lhc/4WqqSgnCVObs4u9/v791Zo98/4OLoNDU+AmQW48RGV87ceb5Gfmz/s5xX5k113xw+Pfiz9pDx9P4m8Y6k+palNwi7v3dun9xF7LXI18rm2OjisVKtTVos/oXwz4Ur8OcO4fKMTPnnC/M+l272XkgooorzT70KKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAsar/yEpv8AeqvVjVf+QlN/vVXoM6fwIKKKKDQKKKKACvsX/giB8Brf4w/tftrF/AtxaeDrUXUauu5fNb5R/wB818dV+hf/AAbu+LbXSvjf460mRlW61DT4pYx/ew+a9jh+nCWOpqfc/MfGbGYjC8GY6thfj5LfJtJ/hc/Rf9uD9p61/ZD/AGdNd8YzKJ7mzj8qyh/57Tvwi1+B3xn/AGivG37R3i+617xd4g1K8uLx2dbdZisFurfdRU/2a/Yz/guD8LNU+JX7E+pSaVDJcSaHdR300SLuZo1PzH8K/ECC4W4gR0+YMte7xlia6xEaK+Cx+Q/Rd4fyp5LWzNwjLEObTb3jFJWS7X38z1j9lv8AbU8dfshePrHWtE1rULjSoXX7dplxKZIZ4+4UfwtX79fB34l6b8ffhFo/iKyxJp+v2STeW3JXevKn6dK/mrvI5LiPyY0aSe4byoox8zSO33VWv6GP+Cdnwy1H4Sfse+CtF1ZWjvrewWSRD95N/wA2P1ro4NxFeUp0ZfAeJ9Kbh/K6GGwmZ0oxhiJTa00co2vd97Pr5nC/sL/sGab+zJ8cfil4mhs44x4g1U/2bkf6qDrgf3fmzXGf8FkP2+tU/ZN+GOn+HvCsixeKvFRaOGc/N9jhX77/AFr648G/FDSvHesa1Y6fOktz4fuvsd4oP+rfAavy6/4OIfhdqVj8Q/BfjAJNJpDxSWUkgH7uCT+EH/er3c1/2TLJvCf1d6n4/wCGsY8S8dYZcS+9otJfa5Ye4vnZPz+Z+e3iTxhrnjDWJdQ1bXNY1K/mbe9xPdMzZr63/wCCWH/BR/xZ8BvjZovhHxFrF5rHg3xFOtoq3UrSSWUjfKhDN/DXxvXafs0/DjUvi1+0V4L0HSYZJryfVYZmEY+aNFb5n/4DX5rl2Lr08TCdN63+8/vPjThvKMfkNfDY+lFUowfRe5ZbrtY/oY+Pnwh034//AAg1bwzqEcc1nrEIA3DO0ghgR+VbXw38PP4R8BaVpszbpNPtkhY+u0Yq1pkUfh/w9bx3EqhbG3RHdvZcZq1p+pw6vpy3UDCSGRSUYfxV+zezjzc/2j/Kuriq3sPqid6UZXXq1b8UkfkH/wAFoP8AgoN4l8V/Ge8+GPhXV7jR/D+hqo1GS1dkmvJm/h3L/CtfAdvfXWn3i3Vvf6hb3Mbb1uI52WRW/vbq9Y/b1Of21PiL/wBhJ/5mvI7hWkt3X+JlZa/Hc3xVWtipyk+p/qT4b8N5dlfDmEw+EpxSlCMpaatySbb7n7kf8EWPHPjb4j/scafqfjHVpNWc3UsNjLKP3hhQ7V3N3rsP+Cjdx8aNU+FsOifBmztxq2qt5d3qEr7TZxdyn+1XH/8ABEPxTZ+JP2DvD8cDqZbC4ngmX+JWDCvXv2pP22/AX7HcWmzePL640y11dvLt51gaSPd6MR0r9OwvI8th7SdlZa3/AFP8/uII4mlx9ifqOEjVqQrS5aXLeLs3b3Vv3PyP1j/gkN+0x4k1U32oJJfahI283EupO0m7/er7E/4JjfCb9p79mnx3H4e8fQx6x4Du1/1s10ZZ9Pf1Bb+GvUD/AMFvv2fRJx4sfb/17P8A4VG3/BcP9nuI/vPFxX0Jtnrx8HhMsw9VVqeI1/xI/TOJOJvEDPMullmOyVOm10oSTj5rs0e8ftTfs96X+0/8DNd8Haqsf2fWIDGrNz5bdmFX/wBn74SWH7PfwX0DwrYrHHbaDZJCzKu0Oyr8z/ia8Asf+C2P7PuoX1pax+LG868lSFM2z/eZto7V9SNcReKPDDvayBodQtj5Ug7hxwf1r6LD1MNWqOtRak9tD8JzbL8+yrB08szSlUo0ZTc1GaaV7WbV/I/Fn/gqb/wUj8V/Hn40ax4R8M61eaP4K0CdrVjayNFJfyrwxLL/AA+1fI3h3xlrng/WI9Q0fXNW03UIX3pcQXRWTd/eaui/aO+HupfCr9obxh4f1eCSHULTUppCGXbuSR2ZWX/Z2tXGdTX5HmOLr1MTKdR63P8ATbgvhvJ8BkdDC5fSi6Tgui9+63fe5+1n/BHD9v7U/wBrP4Z6h4f8VyLN4s8L7Y5ZwMfbYv4X+tfRn7T3wFt/2h/CGn6HfBZLC31O3v5kbpJ5T7gK/OX/AIN3/hhqd3498aeMvLkXR0hWwjlx8szg7uPWv1B8V/FDR/BHiXRdL1C5W3utemeG0Bb/AFjqu4iv03JKsq+XwliT/P3xXy2hk3G9elkCsoWklH7MrXlb038ih8afifpv7P3wb1rxNeqqWHh2xefYvGdq8KK/n/8A2m/2zPHn7W3j6+1rXtc1CHT5pW+xabbzGOCCPdwMfxNtr9vv+Cj/AMLL/wCLv7GnjrRdK8yS/l055Io06ylfm21/Pfbq0MfkurRyW/7p0f7ysvysrV89xliq8ZQox0gfuP0V8hyuvhMXmdaMZ4iM0ve3jG19PV318jtvgt+0V44/Zy8WWuueEfEWpWdxZuHa3eZmguF/uulfvl+xJ+01aftc/s6aD4xhVYJ76HbeQg/6qVfldfzr+di4lW3t2d/lX1r9vv8AgiB8J9U+GH7Eeky6rFJby65K97FDIu1o0bp+dY8HYiu68qL+Cx7P0ocgyqOS0czUIxxCmkmt5Jp3T7238vma/wAMv2BNL8B/8FF/FXxSS0j+y32nRtajb8qXD/LIw/4Ditj/AIKgftqSfsVfs+TaxpqpN4i1aT7FpiN90SN/GR6LXu1h8TtL1L4j33haGdW1XT7ZLuaPPzKjnAr4N/4OGfhVq3ij4E+G/ElnHJNY+Hr5WvAi7vLRv429q+qx98Lgas8L8WrP5u4Nk+IuLsuw3EUrwtCHvdYxXur5/jc/K34h/FfxX8XdfuNY8UeItW1bUrpy7tJcNtUt821V/hWvZP2Ev+ChHjT9j/4p6Szaxfat4Pu50g1HTrqVpREjNt3pu+6Vr59jbzI1dfmVvmWptH8PXXi/xBp+j6fDJc6hq10lvbxKu5pGZq/K8LjMRCsqsJe8f6M51w3lGLyypl+Lox9hy2tZWS8u1u/Q/pamt9N+Lvw0ZWWO40zXrH7rDcrJIn/16/nU/aU+Fv8Awo79oTxj4TX5YdJ1OSOBf+mWflr+hv4BeEpvAPwR8M6PdSbrnT9NhilY+oQZr8Gf+Cj3iO38W/tzfEK8tSrQx37Qbk/iZa+44wjF4anOW5/I/wBF/EVKOf5hgaDvR5b/AHSsn802eK0UUV+dn9uBRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQBY1X/kJTf71V6sar/wAhKb/eqvQZ0/gQUUUUGgUUUUAFelfsi/tIXv7KH7Q2g+NLUNJa2UvlX8K/8tbduD/3ytea0DH8Va0KsqNSNSG8ThzPLaGPwlTA4pc0JxcZLyZ/Sh8NfiT4Y/aO+FlprOj3FprWh61b/MOHVgw+ZGHr6ivh39o3/g378K/ETxldav4J8Rz+ElvZGkms2i86BGY87B/DX59/sgft7/ED9izWS3hm+F5ocr77jSLpmML/AO7/AHW/3a+/vh3/AMHEHgm+0mNfE3hPXNNvtvz/AGdRJH+Ga/QqedZbmNFQxqtJf1oz+I8Z4W8fcE5jUxHCUpVKM/5bN26KUXpdd0df+yB/wQ78E/s9eM7fxJ4q1KTxlq+nkSWiyx+XbwuP4tndq+lf2tv2pPDn7Ivwa1LxLrl1DH9nhKWdru2vdSbflRBXxP8AFv8A4OJNAttKmj8FeDtSvdQZf3c18fLhX34r88f2lf2qvG37W3jT+2vGmqSXRh5trKP5be0HoB/7NUYjO8vwNB0sArtnTkvhDxnxhmsMy41nKFKHSTXM1/LGK0jfq9D6a/4Jdf8ABR6X4d/tdeIrnxzeeTovxNvWmkldvksLhjhCf9lvlWv1s+L3wc8K/tK/DO68P+IbK31fQ9Si9m+8OHRux96/mykjEq7W+7X1p+xl/wAFgfiJ+yjptvoeqIvjDwzCdkcN05+02yf3Uf8Ai/4FXnZLxFThB4bGaxf9an3fi14HYrHYqGd8LPkrQSXJflvyaJxfRpaefqfR/jb/AINyrW48Rs/hzx/dafpMkmVt7i2854l9N1fUv7C//BL/AMD/ALEcUuoWO7WvE10mybVLpfmA9EH8FeLaD/wcMfDG70pZL7w/4mtbrHzReUDz7V5H+0X/AMHB+p+JNHmsfhz4Ym0yaZdovtRPzRf7QUcV7FPEZHhZfWKdub5s/McZkvi/xFRWTZgpqk9G5csU/wDE1q/xPpH/AIK7/t3af+zj8IW8J6PeRyeMvFUsVrDFG/z2kTOoaVvSvqL4IxbPg54dJbcx06FiT6lBmv5wvHfxB1z4n+NZvEniLUrjWNaurhLiWe4O5m2vu2r/AHVr9Rfhj/wX6+H3hj4Z6Ppl/wCG/EX9pWNklvMI4x5YcDHB9Kzy7iOlWxNSpXfItLHZx54D5lluQ4HA5LSeIrc0pVpR7tK2/RWsv+Cfnp+3BdG7/bG+IjP97+1ZF/Vq8trqPjf8Qx8XPjN4l8VRwfZY9cvnuUhb7yAnI3Vy9fAYqXPWnKP8zP7R4fw1TD5VhqFWPLKEIKXySPuD/gif+3DZ/s5/FS78C+JroWnh3xTKGs7iVvktrnsp/uhq/Wb49fALwn+1J8Lrrw34psYdT0nUEyh/iibs6N2NfzcNH5m3+Ha25SPlZW/vCvsP9jv/AILO/EL9mfSrXQ/EEP8AwmXh23ASEzuftUCf3Qf4v+BV9VkOf0qdL6pjF7p/OHjD4K5jmOZLibhiVsRo5RvZtraUX37nu/jP/g3KDa4zeG/iE9rprSbkhurTzHjX03fxV638CP8Aggn8L/h5oN0niye88Xaldps8528lIv8AcXsay9G/4OF/hhd2SteeH/ElrNj5ozCDzXBfGP8A4OIrGSxmh8C+Db57qRWVJ9Sby41PrxXrR/sCk/arlf3v8D87nHxpzOMcuqe0gv5vdh98lZnzZ/wU8/4JnQ/sMSWOs6L4gW90PWLgpbWk20XNo6/MD7j3r9BP+CPn7denftKfAqz8LapdR2/jHwrClrNA7fPcxAYSUf3vl61+QPx7/aL8Z/tO+O5vEXjPV7jUb2T5YoQdsFqvoi1g+APiFrnwq8Z2fiDw3qdzo+sae+Y54Ttz/st/eWvncLnFLCY11sNG1OXQ/dOIPCnH8R8JUcqz7EKeOpaxqJaJ/wAr7q2jfXc/c79un/gl14H/AG3Fj1K88zRPE1smyLU7UfMV9HH8VfLngf8A4NzrWDxLHJ4k8f3OoaTG+Tb29r5LyL6bu1YH7O//AAcIal4c0y3sfiP4Xm1KSNdpvtNPzS/7RU8V6x4g/wCDhj4ZWmmM+n+H/Et3csPki8oD5vevpZ4jI8U/rFW3N8z8BweS+L/D1H+xcApypLZx5ZJf4W9V+B9ofCP4P+Ff2Z/hnb6B4fs7fR9B0uL129OrMe596/JD/gp1/wAFJpviF+2D4bvPA920+h/DO9EscsbfJfzZ/eY/2Svy1yX7Zv8AwV8+In7V2nzaLpqr4P8ADM67ZIbZz9ouV/22/hr5OjhWCPaq4WvGzriKE4Rw2C0iv0P1Dwl8DsTgMTUzzil8+ImmlC97c+kpSfVtafM/ov8A2T/2nPDv7Wvwb03xPotzDOl1CFu7bPz20u350cV80fthf8EN/BX7QnjS48S+FtSk8GatfEvdrFH5lvO/97Z2r8r/ANmf9rDxv+yR4y/tjwXqklqsjf6VYyNut7ke4/8AZq/Q/wCEv/BxD4dutIih8aeD9Usb5V2yTWX7yHP416mHzzL8dQVPHrll/W3Y+Bzrwh4z4OzaeY8FzlOlPpG10v5ZRekrdHr8ja/Zv/4IAeFvh14xs9Y8beIpvFq2LiWKzEXkwMR03j+IV9wfFD4m+G/2bvhZeazq1xbaToei2pwvCKoUcKor4V+I3/BxD4K07SWHhnwnrWoXxX939pASPPvivz//AGvP28viF+2jrol8UXv2XRYX322kWrYt0/3v73/AqqpnGW4Ci4YJXk/61Zz4Hwt4+42zKniOLpSp0YfzWvbtCK0Tfc9f+CP/AAVKvdD/AOCjupfFDWPOTwr4nl/s6eAt/wAetrnbE34fer9k7i38M/tEfDBopPseu+G/EFtyvDxTxsK/mnkVZVZWVdtfRH7GP/BTf4ifsXmOw0+VfEHhXOTpd6TiEf7DfeFeTk3EnspOlitVLU/TvFjwIeZ0qGP4atTr0IRgo3tzKHw69Jrv1Ps74x/8G7+h694rnvPBPjG58P6fcOz/AGKeD7SsW7+FT/dr2b9iD/gjp4H/AGR/EkfiXULuTxV4pg/1N1cptjt/dE/ve9eb+Dv+Dhz4d3+kL/bPhnxDp97j51SMOmfauL+OH/Bw5a3GkzWvgDwfdPeSKVS61E7I09wBXswrZDRn9Yha/wA/yPyXEZb4xZrh/wCw8Sp+zejb5Vdec92vnqfXf/BRn9tXQ/2O/gTqV7NcQy+IdShe30myVv3k0pGM49BX4Gapql14g1i81K/kaa+1Cd7idz/E7NurpvjZ8cvFf7RHjmfxJ4x1a41XUpW/dhj+5t1/uov8K1yNfI55nEsdWTjpCOx/THhB4X0uDstcKsufEVdZvpptFeS/FhRRRXhH68FFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFAFjVf+QlN/vVXqxqv/ACEpv96q9BnT+BBRRRQaBRRRQAUUUUAFFFFABRRRQAUUUUAJ2/vUtFSQaXqF/bzPY2F5efZ03uYomkWNf7zNQvImVSMFeZHRX1h8Yf2GvCPw/wD+Ccnhv4uWU143ibVnjSZWf938zFfu/hXycrfu1b/ZrqxWFnh5RjP7Sv8AeeHw7xLg85pVK2CvanOVOV1b3ob/ACFopJJBHHub7tJ5jKyb0mRZPu74mVW/76WuWzPc54p2bHUV9Wf8E2f2HfCX7Yfg34iah4mmvIZ/CcCyWggbav3Gbn/vmp/+Cc/7CPhH9rrR/iZP4kmvo28GyTrZ+S23cqBtrH8q9KjleIq+zt9u9vkfC5l4jZPgHjFXcr4WUI1NP+fnw27+Z8lY/wBmnU66j+z6hdRr9y3neJf91WZaZGzTKzJDcSKv3nSJ2X/x1a86zvY+49rHlUm9GLRSK3mfN834rtob5F3bWb6LupGnMrXFo/1ftUultbvqlmt15kdnJcItwdrKyxMy7z83+zur67n+AH7NfgTwlcaldeOo9cuPsc09rZQl2klJT90h2j7wPWuzD4KVe/K1Hl7s+bz7ijD5TKEKsJzdT4eSLl99tvmfH9FHmebufbsWRmZAf4U/hWo7yZrezkkX70a7lrjPolK5N/u02vrz43fsF+Dfht/wTi0P4vWU14fEWqSW6zK7/u/nzu+X8K+QVkYW6u8dwqSfdcxMq/8AfW2uzFYKph2lP7SufP8AD/FOAzqlUq4Ju1ObpvmVvehuOooorjPogooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKALGq/8hKb/AHqr1Y1X/kJTf71V6DOn8CCiiig0CiiigAooooAKKKKACiiigAooooA9y/4J6/si2f7avx7m8I6jqF1pdja2bXk0lucSv/sivTtN+NXhH9inwV8UPhDNo/jS41A6pJFFqVraI0kkQPALOPun/Zr57/Zr/aN8SfsqfFiz8YeF5I/t1suyWGUbknibqhr611X/AILlyeIr03epfB3wzeX0i/vZpGUvI3qxr6LLa2DjQtKXJU11tfRn4nxzlXEtfN26VB4rBSjBxhGoqbhUhK93da3Or/anjMv/AARI8E+VbXbNJdI4i8otIqtI/UV+csdndeWP+JfqX3f+fV//AImvvy8/4Lz32oaDHpc3wm0OXTYThLZpVaEfQVm/8PtbbH/JE/Cn5p/hXRmH1DFThJV7cqS2fQ8Xgr/XLIcPXw8sp5/aVZ1P40Fbmd7fI4v/AIIy/ATw/wDG79qHUP8AhLtHkv7TQrBrm3tLqBlieT+8d33q+xPhrq3gv/goz4F+LPhXXPhbH4Zt/A8sttp1+toI2fYGAZWxy3FfP3hv/gu7c+EL9rrS/hH4f065ddjSW7qj7f7uayvEP/BePx4LmIeG/Bfh/QLV5fNvYgqv9s3dc124HGZdhqCpe05lrf3d77fcfK8UcL8cZ7m1TM4YN0ZWp+zf1hfu3B3k0o78+2x2X/BDzTZNI8DfHizmjuEFknkq80Rj8wKH5qb/AIIfOR4Z+PQzjdLd/wAnrkX/AOC6OoW/hzVNP034W6LpJ1eB4riW1kVNzEbct/erxf8AYc/4KH6l+w/d+KJLHw7b68vii5a4mSSXyxHuOdtY0swwVGdCMZ3jC93bud+Y8F8UZnhM3r18IqdXEug4Q9pF39na+u3S54x4B8Ijxn8ZtL0bULfULXT9W1wWt1N9ndfLiaVlav07/bT/AGj/AA5/wTMk8HeC/CPwj07XtH1CxMs941l5gbauOu0/MeteIr/wW4tx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";
                              String footerImage ="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HNKlepVTwzilGFtVLS7vb169dtCD7dff9BG8/wC/7Ufbr3/oIXn/AH/aoqK5bs93lj2Jft17/wBBC8/7/tR9uvf+ghd/9/2qKii7Dlj2FDsrbw7LJ13g/Nn1zTmuJ5GDS3M0zr91pJCxH0PamUUDsh8k882POuJrjHTzZC2PpmmUUUBtsFFFFIYUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAV63+yv/yWS0/68p//AEGvJK9b/ZX/AOSyWn/XlP8A+g11YX+PD1R4Wff8irE/4JfkeUXP/HxJ9ajqS5/4+JPrUdcx7cdkFFFFIoKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACvW/2V/8Akslp/wBeU/8A6DXklet/sr/8lktP+vKf/wBBrqwv8eHqjws+/wCRVif8EvyPKLn/AI+JPrUdQ3V4ftEnyjr61F9sP90Vy3R78YSsi3RVT7Yf7oo+2H+6KLlcki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdFVPth/uij7Yf7oouHJIt0VU+2H+6KPth/uii4cki3RVT7Yf7oo+2H+6KLhySLdet/sr/APJZLT/ryn/9Brxn7Yf7or139lO7LfGe0G3/AJcp/wD0GunCv9/D1R4OfQayrFf4Jfkf/9k=";

                              String emailBody = "<html>\n   <body style=\"font-family: Arial, sans-serif; margin: 0; padding: 0; max-width: 975px; text-align: ${direction};\">\n"
                                  "<!-- Header Image -->\n"
                                  "<table role=\"presentation\" style=\"width: 100%; max-width: 975px; border: 0; cellpadding: 0; cellspacing: 0;\">\n"
                                  "    <tr>\n"
                                  "        <td align=\"center\" style=\"padding: 10px 0;\">\n"
                                  "            <img src=\"data:image/png;base64,${headerImage}\" alt=\"Header Image\" style=\"width: 100%; max-width: 975px; height: auto; display: block;\"/>\n"
                                  "        </td>\n"
                                  "    </tr>\n"
                                  "</table>\n\n"
                                  "<!-- Email Content -->\n"
                                  "<br> <table role=\"presentation\" style=\"width: 100%; max-width: 975px; border: 0; cellpadding: 0; cellspacing: 0; text-align: ${direction};\">\n"
                                  "    <tr>\n"
                                  "        <td style=\"padding: 20px 10px; border-bottom: 1px solid #dddddd;\">\n"
                                  "            <p style=\"font-size: 18px; color: #333333; margin: 0;\">${getLocalizedEmailContent("emailBodyLine1")},</p>\n"
                                  "            <br><p style=\"font-size: 18px; color: #333333; margin: 0;\">${getLocalizedEmailContent('emailBodyLine2')} ${formattedDate}</p>\n"
                                  "            <br><p style=\"font-size: 18px; color: #333333; margin: 0;\">${getLocalizedEmailContent("noteEmail")}</p>\n"
                                  "            <br><p style=\"font-size: 18px; color: #333333; margin: 0;\">${getLocalizedEmailContent("thankYou")}</p>\n"
                                  "        </td>\n"
                                  "    </tr>\n"
                                  "</table>\n\n"
                                  "<br>\n"
                                  "<div style=\"font-family: Arial, sans-serif; margin: 0; padding: 0; direction: rtl; width: 100%; max-width: 975px; background-color: #f0f0f0;\">\n"
                                  "    <table role=\"presentation\" style=\"width: 100%; max-width: 975px; border-collapse: collapse;\">\n"
                                  "        <tr>\n"
                                  "            <td style=\"width: 50%; padding: 10px; border-right: 1px solid #ddd; text-align: left; vertical-align: top;\">\n"
                                  "                <div style=\"font-weight: bold; margin-bottom: 2px;\">Disclaimer</div>\n"
                                  "                <p>The information in this email may contain confidential material and it is intended solely for the addresses. Access to this email by anyone else is unauthorized. If you are not the intended recipient, please delete the email instantly.</p>\n"
                                  "            </td>\n"
                                  "            <td style=\"width: 50%; padding: 10px; border-left: 1px solid #ddd; text-align: right; vertical-align: top;\" dir=\"rtl\">\n"
                                  "                <div style=\"font-weight: bold; margin-bottom: 2px;\">إخلاء المسؤوليه</div>\n"
                                  "                <p>قد يحتوي هذا البريد الإلكتروني على مواد سرية. الحصول على هذه الرسالة من قبل أي شخص آخر، هو شيء غير مصرح به. إذا لم تكن المتلقي المقصود، يرجى حذف هذا البريد الإلكتروني على الفور.</p>\n"
                                  "            </td>\n"
                                  "        </tr>\n"
                                  "    </table>\n"
                                  "</div>\n"
                                  "<table role=\"presentation\" style=\"width: 100%; max-width: 975px; border: 0; cellpadding: 0; cellspacing: 0;\">\n"
                                  "    <tr>\n"
                                  "        <td align=\"center\" style=\"padding: 10px 0;\">\n"
                                  "            <img src=\"data:image/png;base64,${footerImage}\" alt=\"Footer Image\" style=\"width: 100%; max-width: 975px; height: auto; display: block;\"/>\n"
                                  "        </td>\n"
                                  "    </tr>\n"
                                  "</table>\n"
                                  "</body>\n"
                                  "</html>";


                              final file = await ShareScreenOptions.sharePdf(
                                  context, widget.payment.id!,
                                  _selectedLanguage);
                              if (file == null) {
                                print("file is null");
                              }
                              else {
                                print("ready to send to email api");
                                await sendPdfFileViaApi(context, file, toEmail, fileName, emailBody,fileName);

                                if (await file.exists()) {
                                  await file.delete();
                                  print('File deleted successfully');
                                }
                              }

                              // Close bottom sheet if no error
                              Navigator.pop(context);
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

  Future<void> sendPdfFileViaApi(BuildContext context,File pdfFile, String toEmail, String subject, String emailBody,String fileName) async {
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
        'subject': subject,
        'body': emailBody,
      };

      NetworkHelper networkHelper = NetworkHelper(
        url: apiUrlEmail, // Replace with your API URL
        headers: headers
      );

      String emailDetailsJson = jsonEncode(emailDetails);
      print("file name before send : ${fileName}");
      dynamic response = await networkHelper.uploadFile(
        fileName: fileName,
        file: pdfFile,
        emailDetailsJson: emailDetailsJson,
      ).timeout(Duration(seconds: 4));

      if (response == 200) {
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.check_circle, color: Colors.green, size: 40),
          message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentEmailOk"),
          buttonText:  Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
          onPressButton: () {
            // Define what happens when the button is pressed
            print('Success acknowledged');
          },
        );
      }
      else if(response == 401){
        int responseNumber = await PaymentService.attemptReLogin(context);
        print("the response number from get expend the session is :${responseNumber}");
        if(responseNumber == 200 ){
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
              headers: headers
          );

          dynamic reloginResponse = await networkHelper.uploadFile(
            fileName: fileName,
            file: pdfFile,
            emailDetailsJson: emailDetailsJson,
          );
          if (reloginResponse == 200) {
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.check_circle, color: Colors.green, size: 40),
              message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentEmailOk"),
              buttonText:  Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
              onPressButton: () {
                // Define what happens when the button is pressed
                print('Success acknowledged');
              },
            );
          }
          else {
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.error, color: Colors.red, size: 40),
              message: '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentEmailFailed")}: Failed to upload file , $reloginResponse.statusCode',
              buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
              onPressButton: () {
                print('Failed to upload file. Status code: ${reloginResponse.statusCode}');
              },
            );
          }



        }
      }
      else if (response.statusCode == 408) {
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.error, color: Colors.red, size: 40),
          message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("networkTimeoutError"),
          buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
          onPressButton: () {
            print('Error timeout');
          },
        );
      }
      else {
        print(response.statusCode);
        print(response.reasonPhrase);

        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.error, color: Colors.red, size: 40),
          message: '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentEmailFailed")}: Failed to upload file , $response.statusCode',
          buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
          onPressButton: () {
            print('Failed to upload file. Status code: ${response.statusCode}');
          },
        );
      }
    }
    on SocketException catch (e) {
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: Colors.red, size: 40),
        message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("networkError"),
        buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
        onPressButton: () {
          print('Network error acknowledged');
        },
      );
    } on TimeoutException catch (e) {
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: Colors.red, size: 40),
        message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("networkTimeoutError"),
        buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
        onPressButton: () {
          print('Timeout error acknowledged');
        },
      );
    }
    catch (e) {
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: Colors.red, size: 40),
        message: '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentEmailFailed")}',
        buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
        onPressButton: () {
// Define what happens when the button is pressed
          print('Error: $e');
        },
      );
    }
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
          _selectedLanguage = languageCode;
        });
        await _loadLocalizedEmailContent(languageCode);
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

void showEmailBottomSheet(BuildContext context, Payment payment) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Enable the bottom sheet to resize based on the content
    builder: (context) => EmailBottomSheet(payment: payment),
  );
}