import 'package:intl/intl.dart';
import '../Models/Payment.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfHelper {
  static Future<pw.Document> generatePdf({
    required Payment payment,
    required Map<String, String>? bankDetails,
    required Map<String, String> currency,
    required Map<String, String> localizedStrings,
    required pw.Font font,
    required pw.MemoryImage imageLogo,
    required pw.MemoryImage imageSignature,
    required String languageCode,
    String templateType = 'blackAndWhite',
    double header2Size = 22,
    double header3Size = 21,
    double header4Size = 19,
    String? usernameLogin,
  }) async {
    final isEnglish = languageCode == 'en';

    // Format transaction date
    DateTime transactionDate = payment.transactionDate!;
    String formattedDate =
        '${transactionDate.year.toString().padLeft(4, '0')}/${transactionDate.month.toString().padLeft(2, '0')}/${transactionDate.day.toString().padLeft(2, '0')} ${transactionDate.hour.toString().padLeft(2, '0')}:${transactionDate.minute.toString().padLeft(2, '0')}';

    // Customer details
    final List<Map<String, String>> customerDetails = [
      {
        'title': localizedStrings['customerName']!,
        'value': payment.customerName
      },
      if (payment.msisdn != null && payment.msisdn!.isNotEmpty)
        {'title': localizedStrings['mobileNumber']!, 'value': payment.msisdn!},
      {'title': localizedStrings['transactionDate']!, 'value': formattedDate},
      {
        'title': localizedStrings['voucherNumber']!,
        'value': payment.voucherSerialNumber
      },
    ];

    // Payment details
    List<Map<String, String>> paymentDetails = [];
    if (payment.paymentMethod.toLowerCase() == 'cash' ||
        payment.paymentMethod.toLowerCase() == 'كاش') {
      paymentDetails = [
        {
          'title': localizedStrings['paymentMethod']!,
          'value': localizedStrings[payment.paymentMethod.toLowerCase()]!
        },
        {
          'title': localizedStrings['currency']!,
          'value': languageCode == 'ar'
              ? currency["arabicName"] ?? ''
              : currency["englishName"] ?? ''
        },
        {
          'title': localizedStrings['amount']!,
          'value': payment.amount.toString()
        },
      ];
    } else if (payment.paymentMethod.toLowerCase() == 'check' ||
        payment.paymentMethod.toLowerCase() == 'شيك') {
      paymentDetails = [
        {
          'title': localizedStrings['paymentMethod']!,
          'value': localizedStrings[payment.paymentMethod.toLowerCase()]!
        },
        {
          'title': localizedStrings['checkNumber']!,
          'value': payment.checkNumber.toString()
        },
        {
          'title': localizedStrings['bankBranchCheck']!,
          'value': languageCode == 'ar'
              ? bankDetails!["arabicName"] ?? ''
              : bankDetails!["englishName"] ?? ''
        },
        {
          'title': localizedStrings['dueDateCheck']!,
          'value': payment.dueDateCheck != null
              ? DateFormat('yyyy-MM-dd').format(payment.dueDateCheck!)
              : ''
        },
        {
          'title': localizedStrings['amountCheck']!,
          'value': payment.amountCheck.toString()
        },
        {
          'title': localizedStrings['currency']!,
          'value': languageCode == 'ar'
              ? currency["arabicName"] ?? ''
              : currency["englishName"] ?? ''
        },
      ];
    }

    // Additional details
    final List<Map<String, String>> additionalDetail = [
      {'title': localizedStrings['userid']!, 'value': usernameLogin ?? ''},
    ];

    final pdf = pw.Document();

    // Build the PDF page
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection:
                isEnglish ? pw.TextDirection.ltr : pw.TextDirection.rtl,
            child: pw.Center(
              child: _buildTemplate(
                templateType: templateType,
                imageLogo: imageLogo,
                font: font,
                header2Size: header2Size,
                header3Size: header3Size,
                header4Size: header4Size,
                customerDetails: customerDetails,
                paymentDetails: paymentDetails,
                additionalDetail: additionalDetail,
                localizedStrings: localizedStrings,
                isEnglish: isEnglish,
              ),
            ),
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Column _buildTemplate({
    required String templateType,
    required pw.MemoryImage imageLogo,
    required pw.Font font,
    required double header2Size,
    required double header3Size,
    required double header4Size,
    required List<Map<String, String>> customerDetails,
    required List<Map<String, String>> paymentDetails,
    required List<Map<String, String>> additionalDetail,
    required Map<String, String> localizedStrings,
    required isEnglish,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Logo
        pw.Container(
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
            color: PdfColors.white,
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5),
            child: pw.Image(imageLogo, height: 50),
          ),
        ),
        // Customers Detail Header
        pw.Container(
          alignment: pw.Alignment.center,
          padding: pw.EdgeInsets.all(3),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          child: pw.Text(
            localizedStrings['customersDetail'] ?? 'Customer Details',
            style: pw.TextStyle(
                fontSize: header2Size,
                fontWeight: pw.FontWeight.bold,
                font: font),
          ),
        ),
        _buildInfoTableDynamic(
            customerDetails, font, font, isEnglish, header3Size),
        // Payment Detail Header
        pw.Container(
          alignment: pw.Alignment.center,
          padding: pw.EdgeInsets.all(3),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          child: pw.Text(
            localizedStrings['paymentDetail'] ?? 'Payment Details',
            style: pw.TextStyle(
                fontSize: header2Size,
                fontWeight: pw.FontWeight.bold,
                font: font),
          ),
        ),
        _buildInfoTableDynamic(
            paymentDetails, font, font, isEnglish, header3Size),
        // Additional Details
        pw.Container(
          alignment: pw.Alignment.center,
          padding: pw.EdgeInsets.all(3),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          child: pw.Text(
            localizedStrings['additionalDetails'] ?? 'Additional Details',
            style: pw.TextStyle(
                fontSize: header2Size,
                fontWeight: pw.FontWeight.bold,
                font: font),
          ),
        ),
        _buildInfoTableDynamic(
            additionalDetail, font, font, isEnglish, header3Size),
        // Footer
        pw.Container(
          alignment: pw.Alignment.center,
          padding: pw.EdgeInsets.all(2),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          child: pw.Text(
            localizedStrings['footerPdf'] ?? 'Footer',
            style: pw.TextStyle(
                fontSize: header4Size,
                fontWeight: pw.FontWeight.bold,
                font: font),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoTableDynamic(
      List<Map<String, String>> rowData,
      pw.Font fontEnglish,
      pw.Font fontArabic,
      bool isEnglish,
      double header3Size) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.black,
        width: 2.0,
      ),
      columnWidths: {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(2),
      },
      children: rowData
          .map((row) => _buildTableRowDynamic(row['title']!, row['value']!,
              fontEnglish, fontArabic, isEnglish, header3Size))
          .toList()
          .cast<pw.TableRow>(),
    );
  }

  static pw.TableRow _buildTableRowDynamic(
      String title,
      String value,
      pw.Font fontEnglish,
      pw.Font fontArabic,
      bool isEnglish,
      double header3Size) {
    // Function to determine if the text is Arabic
    bool isArabic(String text) {
      final arabicCharRegExp = RegExp(r'[\u0600-\u06FF]');
      return arabicCharRegExp.hasMatch(text);
    }

    // Determine the font and text direction based on the content language
    final fontForTitle = isArabic(title) ? fontArabic : fontEnglish;
    final fontForValue = isArabic(value) ? fontArabic : fontEnglish;
    final textDirectionForValue =
        isArabic(value) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    return pw.TableRow(
      children: isEnglish
          ? [
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    right: pw.BorderSide(
                        color: PdfColors.black,
                        width: 1.0), // Add a right border
                  ),
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: 4, horizontal: 8), // Add horizontal padding here
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  title,
                  style:
                      pw.TextStyle(font: fontForTitle, fontSize: header3Size),
                  textDirection: isArabic(title)
                      ? pw.TextDirection.rtl
                      : pw.TextDirection.ltr,
                ),
              ),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(
                    vertical: 4, horizontal: 8), // Add horizontal padding here
                alignment: pw.Alignment.centerRight,
                child: pw.Directionality(
                  textDirection: textDirectionForValue,
                  child: pw.Text(
                    value,
                    style:
                        pw.TextStyle(font: fontForValue, fontSize: header3Size),
                  ),
                ),
              ),
            ]
          : [
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    right: pw.BorderSide(
                        color: PdfColors.black,
                        width: 1.0), // Add a right border
                  ),
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: 4, horizontal: 8), // Add horizontal padding here
                alignment: pw.Alignment.centerLeft,
                child: pw.Directionality(
                  textDirection: textDirectionForValue,
                  child: pw.Text(
                    value,
                    style:
                        pw.TextStyle(font: fontForValue, fontSize: header3Size),
                  ),
                ),
              ),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(
                    vertical: 4, horizontal: 8), // Add horizontal padding here
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  title,
                  style:
                      pw.TextStyle(font: fontForTitle, fontSize: header3Size),
                  textDirection: isArabic(title)
                      ? pw.TextDirection.rtl
                      : pw.TextDirection.ltr,
                ),
              ),
            ],
    );
  }

  static pw.Widget buildSectionHeader({
    required String title,
    required bool isArabic,
    required pw.Font font,
    required pw.Font boldFont,
    double fontSize = 22,
    PdfColor backgroundColor = const PdfColor.fromInt(0xFFE80009),
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(8),
          topRight: pw.Radius.circular(8),
        ),
      ),
      child: pw.Align(
        alignment:
            isArabic ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
      ),
    );
  }

  static Future<pw.Document> generateColoredPdf({
    required Payment payment,
    required Map<String, String>? bankDetails,
    required Map<String, String> currency,
    required Map<String, String> localizedStrings,
    required pw.Font font,
    required pw.Font boldFont,
    required pw.MemoryImage headerLogo,
    required pw.MemoryImage headerTitle,
    required pw.MemoryImage imageSignature,
    required String languageCode,
    String templateType = 'colored',
    String? usernameLogin,
  }) async {
    final isEnglish = languageCode == 'en';

    // Format transaction date
    DateTime transactionDate = payment.transactionDate!;
    String formattedDate =
        '${transactionDate.year.toString().padLeft(4, '0')}/${transactionDate.month.toString().padLeft(2, '0')}/${transactionDate.day.toString().padLeft(2, '0')} ${transactionDate.hour.toString().padLeft(2, '0')}:${transactionDate.minute.toString().padLeft(2, '0')}';

    // Customer details
    final List<Map<String, String>> customerDetails = [
      {
        'title': localizedStrings['customerName']!,
        'value': payment.customerName
      },
      if (payment.msisdn != null && payment.msisdn!.isNotEmpty)
        {'title': localizedStrings['mobileNumber']!, 'value': payment.msisdn!},
      {'title': localizedStrings['transactionDate']!, 'value': formattedDate},
      {
        'title': localizedStrings['receiptNumber']!,
        'value': payment.voucherSerialNumber
      },
    ];

    // Payment details
    List<Map<String, String>> paymentDetails = [];
    if (payment.paymentMethod.toLowerCase() == 'cash' ||
        payment.paymentMethod.toLowerCase() == 'كاش') {
      paymentDetails = [
        {
          'title': localizedStrings['paymentMethod']!,
          'value': localizedStrings[payment.paymentMethod.toLowerCase()]!
        },
        {
          'title': localizedStrings['currency']!,
          'value': languageCode == 'ar'
              ? currency["arabicName"] ?? ''
              : currency["englishName"] ?? ''
        },
        {
          'title': localizedStrings['amount']!,
          'value': payment.amount.toString()
        },
      ];
    } else if (payment.paymentMethod.toLowerCase() == 'check' ||
        payment.paymentMethod.toLowerCase() == 'شيك') {
      paymentDetails = [
        {
          'title': localizedStrings['paymentMethod']!,
          'value': localizedStrings[payment.paymentMethod.toLowerCase()]!
        },
        {
          'title': localizedStrings['checkNumber']!,
          'value': payment.checkNumber.toString()
        },
        {
          'title': localizedStrings['bankBranchCheck']!,
          'value': languageCode == 'ar'
              ? bankDetails!["arabicName"] ?? ''
              : bankDetails!["englishName"] ?? ''
        },
        {
          'title': localizedStrings['dueDateCheck']!,
          'value': payment.dueDateCheck != null
              ? DateFormat('yyyy-MM-dd').format(payment.dueDateCheck!)
              : ''
        },
        {
          'title': localizedStrings['amountCheck']!,
          'value': payment.amountCheck.toString()
        },
        {
          'title': localizedStrings['currency']!,
          'value': languageCode == 'ar'
              ? currency["arabicName"] ?? ''
              : currency["englishName"] ?? ''
        },
      ];
    }

    // Additional details
    final List<Map<String, String>> additionalDetail = [
      {'title': localizedStrings['userid']!, 'value': usernameLogin ?? ''},
    ];

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection:
                isEnglish ? pw.TextDirection.ltr : pw.TextDirection.rtl,
            child: pw.Center(
              child: _buildColoredTemplate(
                headerLogo: headerLogo,
                headerTitle: headerTitle,
                imageSignature: imageSignature,
                font: font,
                boldFont: boldFont,
                customerDetails: customerDetails,
                paymentDetails: paymentDetails,
                additionalDetail: additionalDetail,
                localizedStrings: localizedStrings,
                languageCode: languageCode,
              ),
            ),
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget buildLabelValueRow({
    required String title,
    required String value,
    required pw.Font font,
    required pw.Font boldFont,
    double fontSize = 17,
    required bool isArabic,
    double horizontalPadding = 16,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: pw.RichText(
        textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
        text: pw.TextSpan(
          children: [
            // Bold title
            pw.TextSpan(
              text: '$title: ',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: fontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            // Normal value
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                font: font,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget buildAreaFlexible({
    required pw.Font font,
    required pw.Font boldFont,
    required bool isArabic,
    required List<Map<String, String>> fields,
    double fontSize = 17,
    double columnSpacing = 20,
    double rowSpacing = 10,
    double horizontalPadding = 16,
    double maxTextWidth = 230,
  }) {
    final leftFields = <Map<String, String>>[];
    final rightFields = <Map<String, String>>[];

    for (int i = 0; i < fields.length; i++) {
      if (i % 2 == 0) {
        leftFields.add(fields[i]);
      } else {
        rightFields.add(fields[i]);
      }
    }

    pw.Widget buildColumn(List<Map<String, String>> list, {int flex = 1}) {
      return pw.Expanded(
        flex: flex,
        child: pw.Column(
          crossAxisAlignment: isArabic
              ? pw.CrossAxisAlignment.end
              : pw.CrossAxisAlignment.start,
          children: list.map((field) {
            return pw.Padding(
              padding: pw.EdgeInsets.only(bottom: rowSpacing),
              child: buildLabelValueRow(
                title: field['title'] ?? '',
                value: field['value'] ?? '',
                font: font,
                boldFont: boldFont,
                fontSize: fontSize,
                isArabic: isArabic,
              ),
            );
          }).toList(),
        ),
      );
    }

    print("lang ${isArabic}");
    final children = isArabic
        ? [
            buildColumn(rightFields, flex: 45), // 40%
            pw.SizedBox(width: columnSpacing),
            buildColumn(leftFields, flex: 55), // 60%
          ]
        : [
            buildColumn(leftFields, flex: 50), // 60%
            pw.SizedBox(width: columnSpacing),
            buildColumn(rightFields, flex: 50), // 40%
          ];
    print("test");

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment:
          isArabic ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.start,
      children: children,
    );
  }

  static pw.Widget _buildColoredTemplate({
    required pw.MemoryImage headerLogo,
    required pw.MemoryImage headerTitle,
    required pw.MemoryImage imageSignature,
    required pw.Font font,
    required pw.Font boldFont,
    required List<Map<String, String>> customerDetails,
    required List<Map<String, String>> paymentDetails,
    required List<Map<String, String>> additionalDetail,
    required Map<String, String> localizedStrings,
    String languageCode = 'en',
  }) {
    final bool isArabic = languageCode == 'ar';
    final pw.Widget headerLogoPDF = pw.Image(headerLogo, height: 90);
    final pw.Widget headerTitlePDF = pw.Image(headerTitle, height: 75);

    // Get receipt number value
    final String receiptNumber = customerDetails.firstWhere(
      (e) => e['title'] == localizedStrings['receiptNumber'],
      orElse: () => {'value': ''},
    )['value']!;

    final String paymentMethod = paymentDetails.firstWhere(
      (e) => e['title'] == localizedStrings['paymentMethod'],
      orElse: () => {'value': ''},
    )['value']!;

    final String currency = paymentDetails.firstWhere(
      (e) => e['title'] == localizedStrings['currency'],
      orElse: () => {'value': ''},
    )['value']!;

    final String paymentAmount =
        (paymentMethod == 'كاش' || paymentMethod.toLowerCase() == 'cash')
            ? paymentDetails.firstWhere(
                (e) => e['title'] == localizedStrings['amount'],
                orElse: () => {'value': ''},
              )['value']!
            : paymentDetails.firstWhere(
                (e) => e['title'] == localizedStrings['amountCheck'],
                orElse: () => {'value': ''},
              )['value']!;
    final String? checkNumber =
        (paymentMethod != 'كاش' && paymentMethod.toLowerCase() != 'cash')
            ? paymentDetails.firstWhere(
                (e) => e['title'] == localizedStrings['checkNumber'],
                orElse: () => {'value': ''},
              )['value']!
            : null;

    final String? bankName =
        (paymentMethod != 'كاش' && paymentMethod.toLowerCase() != 'cash')
            ? paymentDetails.firstWhere(
                (e) => e['title'] == localizedStrings['bankBranchCheck'],
                orElse: () => {'value': ''},
              )['value']!
            : null;

    final String? dueDate =
        (paymentMethod != 'كاش' && paymentMethod.toLowerCase() != 'cash')
            ? paymentDetails.firstWhere(
                (e) => e['title'] == localizedStrings['dueDateCheck'],
                orElse: () => {'value': ''},
              )['value']!
            : null;

    final String userid = additionalDetail.firstWhere(
      (e) => e['title'] == localizedStrings['userid'],
      orElse: () => {'value': ''},
    )['value']!;

    final String customerName = customerDetails.firstWhere(
      (e) => e['title'] == localizedStrings['customerName'],
      orElse: () => {'value': ''},
    )['value']!;

    final String msisdnReceipt = customerDetails.firstWhere(
      (e) => e['title'] == localizedStrings['mobileNumber'],
      orElse: () => {'value': ''},
    )['value']!;

    final String transactionDate = customerDetails.firstWhere(
      (e) => e['title'] == localizedStrings['transactionDate'],
      orElse: () => {'value': ''},
    )['value']!;

    final double footer_pageWidth = 595;

// Signature container width
    final double footer_signatureWidth = 160;

    // Determine if it's check-based or cash-based
    final bool isCheckPayment =
        paymentMethod.toLowerCase() == 'check' || paymentMethod == 'شيك';

// Base fields (always shown)
    final List<Map<String, String>> paymentFields = [
      {
        'title': localizedStrings['paymentMethod'] ?? 'Payment Method',
        'value': paymentMethod,
      },
      {
        'title': localizedStrings['currency'] ?? 'Currency',
        'value': currency,
      },
      {
        'title': localizedStrings['amount'] ?? 'Payment Amount',
        'value': paymentAmount,
      },
    ];

// Add check-specific fields only if payment method is Check / شيك
    if (isCheckPayment) {
      paymentFields.addAll([
        {
          'title': localizedStrings['checkNumber'] ?? 'Check Number',
          'value': checkNumber ?? "NA",
        },
        {
          'title': localizedStrings['bankBranchCheck'] ?? 'Bank',
          'value': bankName ?? "NA",
        },
        {
          'title': localizedStrings['dueDateCheck'] ?? 'Due date',
          'value': dueDate ?? "NA",
        },
      ]);
    }

    final pw.Widget titleWithReceipt = pw.Column(
      crossAxisAlignment:
          isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
      children: [
        headerTitlePDF,
        pw.SizedBox(height: 40),
        buildLabelValueRow(
          title: localizedStrings['receiptNumber'] ?? 'Receipt Number',
          value: receiptNumber,
          font: font,
          boldFont: boldFont,
          fontSize: 17,
          isArabic: isArabic,
        ),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: isArabic
              ? [
                  pw.Padding(
                    padding: pw.EdgeInsets.only(top: 40),
                    child: headerLogoPDF,
                  ),
                  titleWithReceipt,
                ]
              : [
                  titleWithReceipt,
                  pw.Padding(
                    padding: pw.EdgeInsets.only(top: 40),
                    child: headerLogoPDF,
                  ),
                ],
        ),
        pw.SizedBox(height: 20),
        buildSectionHeader(
          title: localizedStrings['customersDetail'] ?? 'Customer Details',
          isArabic: isArabic,
          font: font,
          boldFont: boldFont,
        ),
        pw.SizedBox(height: 20),
        buildAreaFlexible(
          font: font,
          boldFont: boldFont,
          isArabic: isArabic,
          fields: [
            {
              'title': localizedStrings['customerName'] ?? 'Customer Name',
              'value': customerName
            },
            {
              'title': localizedStrings['mobileNumber'] ?? 'Mobile Number',
              'value': msisdnReceipt
            },
            {
              'title': localizedStrings['date'] ?? 'Date',
              'value': transactionDate
            },
          ],
          maxTextWidth: 250,
        ),
        pw.SizedBox(height: 20),
        buildSectionHeader(
          title: localizedStrings['paymentDetail'] ?? 'Payment Details',
          isArabic: isArabic,
          font: font,
          boldFont: boldFont,
        ),
        pw.SizedBox(height: 20),
        buildAreaFlexible(
          font: font,
          boldFont: boldFont,
          isArabic: isArabic,
          fields: paymentFields,
          maxTextWidth: 250,
        ),
        pw.SizedBox(height: 20),
        pw.Spacer(),
        buildSectionHeader(
          title: localizedStrings['additionalDetails'] ?? 'Additional Details',
          isArabic: isArabic,
          font: font,
          boldFont: boldFont,
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: isArabic
              ? [
                  // 🖋️ Signature on the right (first child in RTL)
                  pw.Container(
                    height: 80,
                    width: footer_signatureWidth,
                    child: pw.Image(imageSignature, fit: pw.BoxFit.contain),
                  ),
                  // 🧾 Text (takes remaining space)
                  pw.Expanded(
                    child: buildLabelValueRow(
                      title: localizedStrings['employeeid'] ?? 'Employee Name',
                      value: userid,
                      font: font,
                      boldFont: boldFont,
                      fontSize: 17,
                      isArabic: isArabic,
                    ),
                  ),
                ]
              : [
                  // 🧾 Text (left for English)
                  pw.Expanded(
                    child: buildLabelValueRow(
                      title: localizedStrings['employeeid'] ?? 'Employee Name',
                      value: userid,
                      font: font,
                      boldFont: boldFont,
                      fontSize: 17,
                      isArabic: isArabic,
                    ),
                  ),
                  // 🖋️ Signature (right for English)
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 16),
                    child: pw.Container(
                      height: 80,
                      width: footer_signatureWidth,
                      child: pw.Image(imageSignature, fit: pw.BoxFit.contain),
                    ),
                  ),
                ],
        ),
        pw.Container(
          alignment: pw.Alignment.center,
          padding: pw.EdgeInsets.symmetric(vertical: 16),
          child: pw.Text(
            localizedStrings['footerPdf'] ??
                'Please keep the receipt as proof of payment',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold, font: font),
          ),
        ),
      ],
    );
  }
}
