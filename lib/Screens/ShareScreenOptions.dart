import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ooredoo_app/Screens/printerService/PrinterSettingScreen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Custom_Widgets/CustomPopups.dart';
import '../Models/Payment.dart';
import '../Services/LocalizationService.dart';
import '../Services/database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../Utils/Enum.dart';
import 'EmailBottomSheet.dart';
import 'PDFviewScreen.dart';
import 'PrinterConfirmationBottomSheet.dart';
import 'SMSBottomSheet.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

class ShareScreenOptions {
  static String? _selectedLanguageCode='ar';

  static void showLanguageSelectionAndShare(BuildContext context, int id, ShareOption option) {
    switch (option) {
      case ShareOption.sendEmail:
        _shareViaEmail(context, id);
        break;
      case ShareOption.sendSms:
        _shareViaSms(context, id);
        break;
      case ShareOption.print:
        _showLanguageSelectionDialog(context, (String languageCode) async {
          final file = await sharePdf(context, id, languageCode,header2Size:24 ,header3Size:20 ,header4Size: 18);
          if (file != null && await file.exists()) {
            // _openPrintPreview(file.path);
            _shareViaPrint(context, file.path);

          } else {
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.error, color: Colors.red, size: 40),
              message: '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("printFailed")}: Failed to load PDF',
              buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
              onPressButton: () {
                print('Failed to load PDF for printing');
              },
            );
          }
        });
        break;
      case ShareOption.OpenPDF:
        _showLanguageSelectionDialog(context, (String languageCode) async {
          final file = await sharePdf(context, id, languageCode);
          if (file != null) {

            if (file != null && await file.exists()) {
              // Open PDF preview
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfPreviewScreen(filePath: file.path),
                ),
              );
            }
          } else {

            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.error, color: Colors.red, size: 40),
              message: '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentWhatsFailed")}: Failed to upload file',
              buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
              onPressButton: () {
                print('Failed to upload file. Status code');
              },
            );
          }
        });
        break;
      case ShareOption.sendWhats:
        _showLanguageSelectionDialog(context, (String languageCode) async {
          final file = await sharePdf(context, id, languageCode);
          if (file != null && await file.exists()) {
            final paymentMap = await DatabaseProvider.getPaymentById(id);
            if (paymentMap == null) {
              print('No payment details found for ID $id');
              return null;
            }
            // Create a Payment instance from the fetched map
            final payment = Payment.fromMap(paymentMap);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? storedUsername = prefs.getString('usernameLogin');

            Map<String, dynamic>? translatedCurrency = await DatabaseProvider.getCurrencyById(payment.currency!);
            String appearedCurrency = languageCode == 'ar'
                ? translatedCurrency!["arabicName"]
                : translatedCurrency!["englishName"];

            double amount= payment.paymentMethod.toLowerCase() == 'cash' ? payment.amount! :payment.amountCheck!;
            String WhatsappText = languageCode == "en"
                ? '${amount} ${appearedCurrency} ${payment.paymentMethod.toLowerCase()} payment has been recieved by account manager ${storedUsername}\nTransaction reference: ${payment.voucherSerialNumber}'
                : 'تم استلام دفعه ${Provider.of<LocalizationService>(context, listen: false).getLocalizedString(payment.paymentMethod.toLowerCase())} بقيمة ${amount} ${appearedCurrency} من مدير حسابكم ${storedUsername}\nرقم الحركة: ${payment.voucherSerialNumber}';
            print("print stmt before send whats");
            await Share.shareFiles(
              [file.path],
              mimeTypes: ['application/pdf'],
              text: WhatsappText,
            );
          } else {
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.error, color: Colors.red, size: 40),
              message: '${Provider.of<LocalizationService>(
                  context, listen: false).getLocalizedString(
                  "paymentSentWhatsFailed")}: Failed to upload file',
              buttonText: Provider.of<LocalizationService>(
                  context, listen: false).getLocalizedString("ok"),
              onPressButton: () {
                print('Failed to upload file.');
              },
            );
          }}
        );
        break;
      default:
      // Optionally handle unexpected values
        break;
    }

  }
  static void _shareViaPrint(BuildContext context, String path) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return PrinterConfirmationBottomSheet(pdfFilePath: path); // Pass the file path
      },
    );

  }
  static Future<void> _shareViaEmail(BuildContext context, int id) async {
    // Fetch payment details from the database
    final paymentMap = await DatabaseProvider.getPaymentById(id);
    if (paymentMap == null) {
      print('No payment details found for ID $id');
      return null;
    }

    // Create a Payment instance from the fetched map
    final payment = Payment.fromMap(paymentMap);

    showEmailBottomSheet(context,payment);
  }

  static Future<void> _shareViaSms(BuildContext context, int id) async {
    // Fetch payment details from the database
    final paymentMap = await DatabaseProvider.getPaymentById(id);
    if (paymentMap == null) {
      print('No payment details found for ID $id');
      return null;
    }

    // Create a Payment instance from the fetched map
    final payment = Payment.fromMap(paymentMap);
    print("smssss");
    showSmsBottomSheet(context,payment);
  }


  static void _showLanguageSelectionDialog(BuildContext context, Function(String) onLanguageSelected) {
    //String systemLanguageCode = Localizations.localeOf(context).languageCode; // Get system's default language
    String _selectedLanguageCode = 'ar';
    String appLanguage = Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
      ),
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12.0,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Provider.of<LocalizationService>(context, listen: false)
                        .getLocalizedString("selectPreferredLanguage"),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLanguageCard(
                          context,
                          Provider.of<LocalizationService>(context, listen: false)
                              .getLocalizedString("english"),
                          'en',
                          Icons.language,
                          _selectedLanguageCode == 'en', // Check if English is selected
                              () {
                            setState(() {
                              _selectedLanguageCode = 'en'; // Update selected language to English
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildLanguageCard(
                          context,
                          Provider.of<LocalizationService>(context, listen: false)
                              .getLocalizedString("arabic"),
                          'ar',
                          Icons.language,
                          _selectedLanguageCode == 'ar', // Check if Arabic is selected
                              () {
                            setState(() {
                              _selectedLanguageCode = 'ar'; // Update selected language to Arabic
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: appLanguage == 'en' ? Alignment.centerRight : Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        onLanguageSelected(_selectedLanguageCode); // Return the selected language
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFC62828),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: Text(
                        Provider.of<LocalizationService>(context, listen: false).getLocalizedString("next"),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),

                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildLanguageCard(
      BuildContext context,
      String language,
      String code,
      IconData icon,
      bool isSelected, // Whether this language is selected
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? Color(0xFFC62828) : Color(0xFFFFFFFF),
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
                  language,
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


  static Future<File?> sharePdf(BuildContext context, int id, String languageCode ,{double header2Size = 22, double header3Size = 21, double header4Size = 19}) async {
    try {
      // Get the current localization service without changing the app's locale
      final localizationService = Provider.of<LocalizationService>(context, listen: false);
      // Fetch localized strings for the specified language code
      final localizedStrings = await localizationService.getLocalizedStringsForLanguage(languageCode);

      // Load the image from assets
      final pw.MemoryImage imageLogo = await getBlackAndWhiteImage();

      // Fetch payment details from the database
      final paymentMap = await DatabaseProvider.getPaymentById(id);
      if (paymentMap == null) {
        print('No payment details found for ID $id');
        return null;
      }

      // Create a Payment instance from the fetched map
      final payment = Payment.fromMap(paymentMap);
      final currency = await DatabaseProvider.getCurrencyById(payment.currency!); // Implement this method
      Map<String, String>? bankDetails;

      if (payment.paymentMethod.toLowerCase() == 'cash') {
        // Handle cash payment case
        print('Payment is made in cash. No need to fetch bank details.');
      } else {
        try {
          final dynamicFetchedBank = await DatabaseProvider.getBankById(payment.bankBranch!);
          if (dynamicFetchedBank != null) {
            // Convert the fetched map from Map<String, dynamic>? to Map<String, String>
            bankDetails = Map<String, String>.from(dynamicFetchedBank.map(
                  (key, value) => MapEntry(key, value.toString()), // Ensure all values are strings
            ));
            print('Bank details retrieved: $bankDetails');
          } else {
            print('No bank details found.');
          }
        } catch (e) {
          print('Failed to retrieve bank details: $e');
        }
      }      // Load fonts
      final notoSansFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
      final amiriFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf'));

      final isEnglish = languageCode == 'en';
      final font = isEnglish ? notoSansFont : amiriFont;


      // Generate PDF content with payment details
      final pdf = pw.Document();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? usernameLogin = prefs.getString('usernameLogin');
      DateTime transactionDate = payment.transactionDate!;

// Extract year, month, day, hour, and minute
      int year = transactionDate.year;
      int month = transactionDate.month;
      int day = transactionDate.day;
      int hour = transactionDate.hour;
      int minute = transactionDate.minute;

// Format the output as a string
      String formattedDate = '${year.toString().padLeft(4, '0')}/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      final List<Map<String, String>> customerDetails = [
        {'title': localizedStrings['customerName'], 'value': payment.customerName},
        if (payment.msisdn != null && payment.msisdn.toString().length>0)
          {'title': localizedStrings['mobileNumber'], 'value': payment.msisdn.toString()},
        {'title': localizedStrings['transactionDate'], 'value': formattedDate},
        {'title': localizedStrings['voucherNumber'], 'value': payment.voucherSerialNumber},
      ];

      String receiptVoucher = localizedStrings['receiptVoucher'];
      String customersDetail = localizedStrings['customersDetail'];
      String additionalDetails = localizedStrings['additionalDetails'];

      List<Map<String, String>> paymentDetails=[];
      if(payment.paymentMethod.toLowerCase() == 'cash' || payment.paymentMethod.toLowerCase() == 'كاش')
        paymentDetails = [
          {'title': localizedStrings['paymentMethod'], 'value': localizedStrings[payment.paymentMethod.toLowerCase()] },
          {'title': localizedStrings['currency'], 'value': languageCode =='ar' ? currency!["arabicName"] ?? '' : currency!["englishName"]},
          {'title': localizedStrings['amount'], 'value': payment.amount.toString()},
        ];
      else if(payment.paymentMethod.toLowerCase() == 'check' || payment.paymentMethod.toLowerCase() == 'شيك')
        paymentDetails = [
          {'title': localizedStrings['paymentMethod'], 'value': localizedStrings[payment.paymentMethod.toLowerCase()]},
          {'title': localizedStrings['checkNumber'], 'value': payment.checkNumber.toString()},
          {'title': localizedStrings['bankBranchCheck'], 'value': languageCode =='ar' ? bankDetails!["arabicName"] ??'' : bankDetails!["englishName"] ?? ''},
          {'title': localizedStrings['dueDateCheck'], 'value': payment.dueDateCheck != null
              ? DateFormat('yyyy-MM-dd').format(payment.dueDateCheck!)
              : ''},
          {'title': localizedStrings['amountCheck'], 'value': payment.amountCheck.toString()},
          {'title': localizedStrings['currency'], 'value': languageCode =='ar' ? currency!["arabicName"] ?? '' : currency!["englishName"]},

        ];
      final List<Map<String, String>> additionalDetail= [
        {'title': localizedStrings['userid'], 'value': usernameLogin!},
      ];

      String paymentDetail = localizedStrings['paymentDetail'];
      String footerPdf = localizedStrings['footerPdf'];

      pdf.addPage(
        pw.Page(
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Directionality(
              textDirection: isEnglish ? pw.TextDirection.ltr : pw.TextDirection.rtl,
              child: pw.Center(
                child: pw.Container(

                  color: PdfColors.white,
                  padding: pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black, // Set the border color to black
                            width: 2,              // Set the border width to 2
                          ),                          color: PdfColors.white,
                        ),

                        child:pw.Padding(
                          padding: const pw.EdgeInsets.only(top:5), // Example padding
                          child: pw.Image(imageLogo, height: 50),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: pw.EdgeInsets.all(3), // Add padding here
                        decoration: pw.BoxDecoration(
                          color: PdfColors.black,
                          border: pw.Border.all(
                            color: PdfColors.black, // Set the border color to black
                            width: 2,              // Set the border width to 2
                          ),                        ),
                        child: pw.Text(
                          receiptVoucher,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: header2Size,
                            fontWeight: pw.FontWeight.bold,
                            font: font,
                          ),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: pw.EdgeInsets.all(3), // Add padding here
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey300,
                          border: pw.Border.all(
                            color: PdfColors.black, // Set the border color to black
                            width: 2,              // Set the border width to 2
                          ),                        ),
                        child: pw.Text(
                          customersDetail,
                          style: pw.TextStyle(
                            fontSize: header2Size,
                            fontWeight: pw.FontWeight.bold,
                            font: font,
                          ),
                        ),
                      ),
                      _buildInfoTableDynamic(customerDetails, notoSansFont, amiriFont, isEnglish,header3Size),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: pw.EdgeInsets.all(3), // Add padding here
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey300,
                          border: pw.Border.all(
                            color: PdfColors.black, // Set the border color to black
                            width: 2,              // Set the border width to 2
                          ),                        ),
                        child: pw.Text(
                          paymentDetail,
                          style: pw.TextStyle(
                            fontSize: header2Size,
                            fontWeight: pw.FontWeight.bold,
                            font: font,
                          ),
                        ),
                      ),
                      _buildInfoTableDynamic(paymentDetails, notoSansFont, amiriFont, isEnglish,header3Size),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: pw.EdgeInsets.all(3), // Add padding here
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey300,
                          border: pw.Border.all(
                            color: PdfColors.black, // Set the border color to black
                            width: 2,              // Set the border width to 2
                          ),                        ),
                        child: pw.Text(
                          additionalDetails,
                          style: pw.TextStyle(
                            fontSize: header2Size,
                            fontWeight: pw.FontWeight.bold,
                            font: font,
                          ),
                        ),
                      ),
                      _buildInfoTableDynamic(additionalDetail, notoSansFont, amiriFont, isEnglish,header3Size),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: pw.EdgeInsets.all(2), // Add padding here
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(
                            color: PdfColors.black, // Set the border color to black
                            width: 2,              // Set the border width to 2
                          ),                        ),
                        child: pw.Text(
                          footerPdf,
                          style: pw.TextStyle(
                            fontSize: header4Size,
                            fontWeight: pw.FontWeight.bold,
                            font: font,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final tempDirPath = directory.path;
      // List and delete existing PDF files
      final tempDirContents = Directory(tempDirPath).listSync();
      for (var file in tempDirContents) {
        print('gg:${file}');
        if (file is File && file.path.endsWith('.pdf')) {
          await file.delete();
          print('Deleted old file: ${file.path}');
        }
      }

      //String fileName=languageCode=='en'? 'Payment Notice-${DateFormat('yyyy-MM-dd').format(payment.transactionDate!)}' : 'إشعار_دفع_${DateFormat('yyyy-MM-dd').format(payment.transactionDate!)}';
      String fileName='إشعاردفع-${DateFormat('yyyy-MM-dd').format(payment.transactionDate!)}';
      final path = '${directory.path}/$fileName.pdf';
      final file = File(path);
      print("file saved in:${file}");
      // Write the PDF file
      await file.writeAsBytes(await pdf.save());
      return file;

    } catch (e) {
      print('Error: $e');
      return null;
      // Handle the error (e.g., show a snackbar or dialog in the UI)
    }
  }
  // Build info table with dynamic localization
  static pw.Widget _buildInfoTableDynamic(List<Map<String, String>> rowData, pw.Font fontEnglish, pw.Font fontArabic, bool isEnglish,double header3Size) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.black, // Ensure the color is black or any visible color
        width: 2.0,             // Increase the width (e.g., 1.0 or higher)
      ),      columnWidths: {
      0: pw.FlexColumnWidth(2), // Adjust as needed
      1: pw.FlexColumnWidth(2), // Adjust as needed
    },
      children: rowData.map((row) => _buildTableRowDynamic(row['title']!, row['value']!, fontEnglish, fontArabic, isEnglish,header3Size)).toList().cast<pw.TableRow>(),
    );
  }

  static pw.TableRow _buildTableRowDynamic(String title, String value, pw.Font fontEnglish, pw.Font fontArabic, bool isEnglish,double header3Size) {
    // Function to determine if the text is Arabic
    bool isArabic(String text) {
      final arabicCharRegExp = RegExp(r'[\u0600-\u06FF]');
      return arabicCharRegExp.hasMatch(text);
    }

    // Determine the font and text direction based on the content language
    final fontForTitle = isArabic(title) ? fontArabic : fontEnglish;
    final fontForValue = isArabic(value) ? fontArabic : fontEnglish;
    final textDirectionForValue = isArabic(value) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    return pw.TableRow(
      children: isEnglish
          ? [
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              right: pw.BorderSide(color: PdfColors.black, width: 1.0), // Add a right border
            ),
          ),
          padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Add horizontal padding here
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            title,
            style: pw.TextStyle(font: fontForTitle, fontSize: header3Size),
            textDirection: isArabic(title) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
        ),
        pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Add horizontal padding here
          alignment: pw.Alignment.centerRight,
          child: pw.Directionality(
            textDirection: textDirectionForValue,
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fontForValue, fontSize: header3Size),
            ),
          ),
        ),
      ]
          : [
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              right: pw.BorderSide(color: PdfColors.black, width: 1.0), // Add a right border
            ),
          ),
          padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Add horizontal padding here
          alignment: pw.Alignment.centerLeft,
          child: pw.Directionality(
            textDirection: textDirectionForValue,
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fontForValue, fontSize: header3Size),
            ),
          ),
        ),
        pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Add horizontal padding here
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            title,
            style: pw.TextStyle(font: fontForTitle, fontSize: header3Size),
            textDirection: isArabic(title) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
        ),
      ],
    );
  }

  static Future<pw.MemoryImage> getBlackAndWhiteImage() async {
    // Load the image from assets
    final ByteData imageData = await rootBundle.load('assets/images/Ooredoo_Logo_noBG.png');

    // Convert the image to a usable format
    final img.Image originalImage = img.decodeImage(imageData.buffer.asUint8List())!;

    // Convert the image to grayscale (black and white)
    final img.Image grayscaleImage = img.grayscale(originalImage);

    // Apply a threshold to convert grayscale to black and white
    final img.Image blackAndWhiteImage = img.Image(grayscaleImage.width, grayscaleImage.height);
    const int threshold = 128; // You can adjust the threshold (0-255) for your desired result
    for (int y = 0; y < grayscaleImage.height; y++) {
      for (int x = 0; x < grayscaleImage.width; x++) {
        final int pixel = grayscaleImage.getPixel(x, y);
        final int luma = img.getLuminance(pixel);
        blackAndWhiteImage.setPixel(x, y, luma < threshold ? img.getColor(0, 0, 0) : img.getColor(255, 255, 255));
      }
    }

    // Convert the black-and-white image back to Uint8List
    final Uint8List blackAndWhiteBytes = Uint8List.fromList(img.encodePng(blackAndWhiteImage));

    // Return a pdf-compatible MemoryImage
    return pw.MemoryImage(blackAndWhiteBytes);
  }


}