import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Custom_Widgets/CustomPopups.dart';
import '../Models/Payment.dart';
import '../Services/LocalizationService.dart';
import '../Services/database.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../Utils/Enum.dart';
import '../Utils/pdf_builder.dart';
import '../core/constants.dart';
import 'EmailBottomSheet.dart';
import 'PDFviewScreen.dart';
import 'PrinterConfirmationBottomSheet.dart';
import 'SMSBottomSheet.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;

class ShareScreenOptions {
  static String? _selectedLanguageCode = 'ar';
  static bool isBlackAndWhiteFlag = false;

  static void showLanguageSelectionAndShare(
      BuildContext context, dynamic idOrIds, ShareOption option,
      {bool multiPaymentFlag = false}) {
    // normalize to list and single id
    List<int> ids;
    if (idOrIds is int) {
      ids = [idOrIds];
    } else if (idOrIds is List<int>) {
      ids = idOrIds;
    } else {
      return; // unsupported param
    }

    if (ids.isEmpty) return;

    switch (option) {
      case ShareOption.sendEmail:
        _shareViaEmail(context, ids, isMultiple: ids.length > 1);
        break;
      case ShareOption.sendSms:
        _shareViaSms(context, ids.first);
        break;
      case ShareOption.print:
        _showBottomDialog(
          context,
          (String languageCode, bool isBlackAndWhite) async {
            isBlackAndWhiteFlag = true;
            final file = await sharePdf(context, ids.first, languageCode,
                header2Size: 24, header3Size: 20, header4Size: 18);

            if (file != null && await file.exists()) {
              _shareViaPrint(context, file.path);
            } else {
              CustomPopups.showCustomResultPopup(
                context: context,
                icon: const Icon(Icons.error,
                    color: AppColors.primaryRed, size: 40),
                message:
                    '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("printFailed")}: Failed to load PDF',
                buttonText:
                    Provider.of<LocalizationService>(context, listen: false)
                        .getLocalizedString("ok"),
                onPressButton: () {
                  print('Failed to load PDF for printing');
                },
              );
            }
          },
          showTemplateOption: false,
        );
        break;
      case ShareOption.OpenPDF:
        _showBottomDialog(
          context,
          (String languageCode, bool isBlackAndWhite) async {
            await _openPdfForIds(context, ids, languageCode,
                isBlackAndWhite: isBlackAndWhite);
          },
          multiPaymentFlag: multiPaymentFlag,
        );
        break;
      case ShareOption.sendWhats:
        _showBottomDialog(context,
            (String languageCode, bool isBlackAndWhite) async {
          await _shareWhatsForIds(context, ids, languageCode,
              isBlackAndWhite: isBlackAndWhite, isMultiple: ids.length > 1);
        }, multiPaymentFlag: ids.length > 1);
        break;
      default:
        break;
    }
  }

  static void _shareViaPrint(BuildContext context, String path) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return PrinterConfirmationBottomSheet(pdfFilePath: path);
      },
    );
  }

  static Future<void> _openPdfForIds(
      BuildContext context, List<int> ids, String languageCode,
      {bool isBlackAndWhite = true}) async {
    File? file;
    if (isBlackAndWhite) {
      file = await sharePdf(context, ids.first, languageCode,
          header2Size: 24, header3Size: 20, header4Size: 18);
    } else {
      file = await sharePdfForIds(
        context,
        ids,
        languageCode,
      );
    }

    if (file != null && await file.exists()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(filePath: file!.path),
        ),
      );
    }
  }

  static Future<void> _shareWhatsForIds(
      BuildContext context, List<int> ids, String languageCode,
      {bool isBlackAndWhite = true, bool isMultiple = false}) async {
    File? file;

    String WhatsappText = " ";
    file = await sharePdfForIds(
      context,
      ids,
      languageCode,
    );
    if (isMultiple) {
    } else {
      final paymentMap = await DatabaseProvider.getPaymentById(ids.first);
      if (paymentMap == null) {
        print('No payment details found for ID $ids.first');
      } else {
        final payment = Payment.fromMap(paymentMap);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? storedUsername = prefs.getString('usernameLogin');

        Map<String, dynamic>? translatedCurrency =
            await DatabaseProvider.getCurrencyById(payment.currency!);
        String appearedCurrency = languageCode == 'ar'
            ? translatedCurrency!["arabicName"]
            : translatedCurrency!["englishName"];

        double amount = payment.paymentMethod.toLowerCase() == 'cash'
            ? payment.amount!
            : payment.amountCheck!;
        WhatsappText = languageCode == "en"
            ? '${amount} ${appearedCurrency} ${payment.paymentMethod.toLowerCase()} payment has been recieved by account manager ${storedUsername}\nTransaction reference: ${payment.voucherSerialNumber}'
            : 'تم استلام دفعه ${Provider.of<LocalizationService>(context, listen: false).getLocalizedString(payment.paymentMethod.toLowerCase())} بقيمة ${amount} ${appearedCurrency} من مدير حسابكم ${storedUsername}\nرقم الحركة: ${payment.voucherSerialNumber}';
      }
    }

    if (file != null && await file.exists()) {
      print("print stmt before send whats");
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: WhatsappText,
      );
    } else {
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: const Icon(Icons.error, color: AppColors.primaryRed, size: 40),
        message:
            '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentWhatsFailed")}: Failed to upload file',
        buttonText: Provider.of<LocalizationService>(context, listen: false)
            .getLocalizedString("ok"),
        onPressButton: () {
          print('Failed to upload file.');
        },
      );
    }
  }

  static Future<void> _shareViaEmail(BuildContext context, List<int> ids,
      {isMultiple = false}) async {
    final List<Payment> payments = [];
    for (final id in ids) {
      final paymentMap = await DatabaseProvider.getPaymentById(id);
      if (paymentMap == null) {
        print('No payment details found for ID $id');
        continue;
      }

      final payment = Payment.fromMap(paymentMap);
      payments.add(payment);
    }

    if (payments.isNotEmpty) {
      // Pass the whole list to the bottom sheet so it can handle multiple payments
      showEmailBottomSheet(context, payments, isMultiple: isMultiple);
    }
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
    showSmsBottomSheet(context, payment);
  }

  static void _showBottomDialog(BuildContext context,
      Function(String languageCode, bool isBlackAndWhite) onLanguageSelected,
      {bool showTemplateOption = true, bool multiPaymentFlag = false}) {
    //String systemLanguageCode = Localizations.localeOf(context).languageCode; // Get system's default language
    String _selectedLanguageCode = 'ar';
    isBlackAndWhiteFlag = false;

    String appLanguage =
        Provider.of<LocalizationService>(context, listen: false)
            .selectedLanguageCode;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
      ),
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(12.0),
              decoration: const BoxDecoration(
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
                crossAxisAlignment: appLanguage == 'ar'
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: appLanguage == 'ar'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Text(
                      Provider.of<LocalizationService>(context, listen: false)
                          .getLocalizedString("selectPreferredLanguage"),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLanguageCard(
                          context,
                          Provider.of<LocalizationService>(context,
                                  listen: false)
                              .getLocalizedString("english"),
                          'en',
                          Icons.language,
                          _selectedLanguageCode ==
                              'en', // Check if English is selected
                          () {
                            setState(() {
                              _selectedLanguageCode =
                                  'en'; // Update selected language to English
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildLanguageCard(
                          context,
                          Provider.of<LocalizationService>(context,
                                  listen: false)
                              .getLocalizedString("arabic"),
                          'ar',
                          Icons.language,
                          _selectedLanguageCode ==
                              'ar', // Check if Arabic is selected
                          () {
                            setState(() {
                              _selectedLanguageCode =
                                  'ar'; // Update selected language to Arabic
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  // Template Selection Section
                  if (showTemplateOption) ...[
                    const SizedBox(height: 30),
                    Align(
                      alignment: appLanguage == 'ar'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Text(
                        Provider.of<LocalizationService>(context, listen: false)
                            .getLocalizedString("selectTemplate"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (multiPaymentFlag == false) ...[
                          Expanded(
                            child: _buildSelectionCard(
                              context: context,
                              title: Provider.of<LocalizationService>(context,
                                      listen: false)
                                  .getLocalizedString("b_and_w"),
                              icon: Icons.receipt_long_outlined,
                              isSelected: isBlackAndWhiteFlag,
                              onTap: () {
                                setState(() {
                                  isBlackAndWhiteFlag = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: _buildSelectionCard(
                            context: context,
                            title: Provider.of<LocalizationService>(context,
                                    listen: false)
                                .getLocalizedString("colored"),
                            icon: Icons.receipt_long_outlined,
                            isSelected: !isBlackAndWhiteFlag,
                            onTap: () {
                              setState(() {
                                isBlackAndWhiteFlag = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Align(
                    alignment: appLanguage == 'en'
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        print(
                            "Selected template: ${isBlackAndWhiteFlag ? 'Black & White' : 'Colored'}"); // Print template choice
                        onLanguageSelected(
                            _selectedLanguageCode, isBlackAndWhiteFlag);
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                      child: Text(
                        Provider.of<LocalizationService>(context, listen: false)
                            .getLocalizedString("next"),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            const BoxShadow(
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
                  const SizedBox(width: 10),
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
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryRed,
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLanguageCard(
    BuildContext context,
    String language,
    String code,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : const Color(0xFFFFFFFF),
            width: 1.5,
          ),
          boxShadow: [
            const BoxShadow(
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
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      language,
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
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryRed,
              ),
          ],
        ),
      ),
    );
  }

  static Future<File?> sharePdf(
      BuildContext context, int id, String languageCode,
      {double header2Size = 22,
      double header3Size = 21,
      double header4Size = 19,
      bool isBlackAndWhite = true}) async {
    try {
      // Get the current localization service without changing the app's locale
      final localizationService =
          Provider.of<LocalizationService>(context, listen: false);

      // Fetch localized strings for the specified language code
      final localizedStringsDynamic = await localizationService
          .getLocalizedStringsForLanguage(languageCode);

      // Convert to Map<String, String>
      final localizedStrings = localizedStringsDynamic.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      // Load images from assets
      final pw.MemoryImage imageLogo = isBlackAndWhite
          ? await getBlackAndWhiteImage()
          : await getColoredImage();
      final pw.MemoryImage imageSignature = await getSignture();

      // Fetch payment details
      final paymentMap = await DatabaseProvider.getPaymentById(id);
      if (paymentMap == null) {
        print('No payment details found for ID $id');
        return null;
      }
      final payment = Payment.fromMap(paymentMap);

      // Fetch currency
      final currencyDynamic =
          await DatabaseProvider.getCurrencyById(payment.currency!) ?? {};
      final currency = currencyDynamic.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      // Fetch bank details if not cash
      Map<String, String>? bankDetails;
      if (!(payment.paymentMethod.toLowerCase() == 'cash' ||
          payment.paymentMethod.toLowerCase() == 'كاش')) {
        try {
          final dynamicFetchedBank =
              await DatabaseProvider.getBankById(payment.bankBranch!);
          if (dynamicFetchedBank != null) {
            bankDetails = Map<String, String>.from(
                dynamicFetchedBank.map((k, v) => MapEntry(k, v.toString())));
          }
        } catch (e) {
          print('Failed to retrieve bank details: $e');
        }
      }

      // Load fonts
      final notoSansFont = pw.Font.ttf(
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
      final amiriFont =
          pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf'));

      final notoSansBoldFont =
          pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
      final amiriBoldFont =
          pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
      final isEnglish = languageCode == 'en';
      final font = amiriFont;
      final boldFont = amiriBoldFont;

      // Get logged-in username
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? usernameLogin = prefs.getString('usernameLogin');

      pw.Document pdf;

      if (isBlackAndWhite) {
        // Generate default (black & white) PDF
        pdf = await PdfHelper.generatePdf(
          payment: payment,
          bankDetails: bankDetails,
          currency: currency,
          localizedStrings: localizedStrings,
          font: font,
          imageLogo: imageLogo, // black & white logo
          imageSignature: imageSignature,
          languageCode: languageCode,
          header2Size: header2Size,
          header3Size: header3Size,
          header4Size: header4Size,
          usernameLogin: usernameLogin,
        );
      } else {
        // Generate colored PDF
        final pw.MemoryImage headerLogo =
            await getColoredHeaderLogo(languageCode);
        final pw.MemoryImage headerTitle =
            await getColoredHeaderTitle(languageCode);

        pdf = await PdfHelper.generateColoredPdf(
          payment: payment,
          bankDetails: bankDetails,
          currency: currency,
          localizedStrings: localizedStrings,
          font: font,
          boldFont: boldFont,
          headerLogo: headerLogo,
          headerTitle: headerTitle,
          imageSignature: imageSignature,
          languageCode: languageCode,
          usernameLogin: usernameLogin,
        );
      }

      // Save PDF to temporary directory
      final directory = await getTemporaryDirectory();

      // Clean old PDFs
      for (var file in Directory(directory.path).listSync()) {
        if (file is File && file.path.endsWith('.pdf')) {
          await file.delete();
        }
      }

      // Create file
      String fileName =
          'إشعاردفع-${DateFormat('yyyy-MM-dd').format(payment.transactionDate!)}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      print("File saved at: ${file.path}");
      return file;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }

  static Future<File?> sharePdfForIds(
      BuildContext context, List<int> ids, String languageCode) async {
    final List<Payment> result = [];
    if (ids.isEmpty) return null;

    // Get the current localization service without changing the app's locale
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);

    // Fetch localized strings for the specified language code
    final localizedStringsDynamic =
        await localizationService.getLocalizedStringsForLanguage(languageCode);

    // Convert to Map<String, String>
    final localizedStrings = localizedStringsDynamic.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    // Prepare Payment objects
    for (final id in ids) {
      try {
        final paymentMap = await DatabaseProvider.getPaymentById(id);
        if (paymentMap == null) continue;

        Payment payment = Payment.fromMap(paymentMap);

        if (payment.currency != null) {
          final currencyDynamic =
              await DatabaseProvider.getCurrencyById(payment.currency!);
          if (currencyDynamic != null) {
            payment.currency = languageCode == 'ar'
                ? (currencyDynamic['arabicName']?.toString() ?? '')
                : (currencyDynamic['englishName']?.toString() ?? '');
          }
        }

        if (payment.bankBranch != null) {
          final bankDynamic =
              await DatabaseProvider.getBankById(payment.bankBranch!);
          if (bankDynamic != null) {
            payment.bankBranch = languageCode == 'ar'
                ? (bankDynamic['arabicName']?.toString() ?? '')
                : (bankDynamic['englishName']?.toString() ?? '');
          }
        }

        result.add(payment);
      } catch (e) {
        print('Failed to build payment object for id $id: $e');
        continue;
      }
    }

    final pw.MemoryImage imageSignature = await getSignture();

    final amiriFont =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf'));

    final amiriBoldFont =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
    final font = amiriFont;
    final boldFont = amiriBoldFont;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usernameLogin = prefs.getString('usernameLogin');

    pw.Document pdf = pw.Document();

    final pw.MemoryImage headerLogo = await getColoredHeaderLogo(languageCode);
    final pw.MemoryImage headerTitle =
        await getColoredHeaderTitle(languageCode);

    pdf = await PdfHelper.generateColoredPdfMultiPayment(
      payments: result,
      localizedStrings: localizedStrings,
      font: font,
      boldFont: boldFont,
      headerLogo: headerLogo,
      headerTitle: headerTitle,
      imageSignature: imageSignature,
      languageCode: languageCode,
      usernameLogin: usernameLogin,
    );
    final directory = await getTemporaryDirectory();

    for (var file in Directory(directory.path).listSync()) {
      if (file is File && file.path.endsWith('.pdf')) {
        await file.delete();
      }
    }

    String fileName =
        'إشعاردفع-${DateFormat('yyyy-MM-dd').format(result[0].transactionDate!)}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    print("File saved at: ${file.path}");
    return file;
  }

  static Future<pw.MemoryImage> getBlackAndWhiteImage() async {
    // Load the image from assets
    final ByteData imageData =
        await rootBundle.load('assets/images/Ooredoo_Logo_noBG.png');

    // Convert the image to a usable format
    final img.Image originalImage =
        img.decodeImage(imageData.buffer.asUint8List())!;

    // Convert the image to grayscale (black and white)
    final img.Image grayscaleImage = img.grayscale(originalImage);

    // Apply a threshold to convert grayscale to black and white
    final img.Image blackAndWhiteImage =
        img.Image(grayscaleImage.width, grayscaleImage.height);
    const int threshold =
        128; // You can adjust the threshold (0-255) for your desired result
    for (int y = 0; y < grayscaleImage.height; y++) {
      for (int x = 0; x < grayscaleImage.width; x++) {
        final int pixel = grayscaleImage.getPixel(x, y);
        final int luma = img.getLuminance(pixel);
        blackAndWhiteImage.setPixel(
            x,
            y,
            luma < threshold
                ? img.getColor(0, 0, 0)
                : img.getColor(255, 255, 255));
      }
    }

    // Convert the black-and-white image back to Uint8List
    final Uint8List blackAndWhiteBytes =
        Uint8List.fromList(img.encodePng(blackAndWhiteImage));

    // Return a pdf-compatible MemoryImage
    return pw.MemoryImage(blackAndWhiteBytes);
  }

  static Future<pw.MemoryImage> getColoredImage() async {
    // Load the colored image directly from assets
    final ByteData imageData =
        await rootBundle.load('assets/images/Ooredoo_Logo_noBG.png');

    // Return a pdf-compatible MemoryImage without converting to black/white
    return pw.MemoryImage(imageData.buffer.asUint8List());
  }

  static Future<pw.MemoryImage> getColoredHeaderTitle(String langCode) async {
    ByteData imageData;
    if (langCode == 'ar') {
      imageData = await rootBundle.load('assets/images/receiptVoucher_ar.png');
    } else {
      imageData = await rootBundle.load('assets/images/receiptVoucher_en.png');
    }
    return pw.MemoryImage(imageData.buffer.asUint8List());
  }

  static Future<pw.MemoryImage> getColoredHeaderLogo(String langCode) async {
    ByteData imageData;
    if (langCode == 'ar') {
      imageData = await rootBundle.load('assets/images/coloredHeader_ar.png');
    } else {
      imageData = await rootBundle.load('assets/images/coloredHeader_en.png');
    }
    return pw.MemoryImage(imageData.buffer.asUint8List());
  }

  static Future<pw.MemoryImage> getSignture() async {
    // Load the colored image directly from assets
    final ByteData imageData =
        await rootBundle.load('assets/images/signture_nobg.png');

    // Return a pdf-compatible MemoryImage without converting to black/white
    return pw.MemoryImage(imageData.buffer.asUint8List());
  }
}
