import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ooredoo_app/Screens/printerService/PrinterSettingScreen.dart';
import 'package:ooredoo_app/Screens/record_diconnected_payment/record_diconnected_payment.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/LocalizationService.dart';
import 'package:intl/intl.dart';
import 'package:number_to_word_arabic/number_to_word_arabic.dart';
import 'package:number_to_words_english/number_to_words_english.dart';
import '../Services/PaymentService.dart';
import '../Services/database.dart';
import '../Utils/Enum.dart';
import '../core/constants.dart';
import 'PaymentCancellationScreen.dart';
import 'payment_history/PaymentHistoryScreen.dart';
import '../Custom_Widgets/CustomPopups.dart';
import 'recordPayment/RecordPaymentScreen.dart';
import '../Screens/ShareScreenOptions.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../Screens/printerService/iosMethods.dart' as iosPlat;
import '../Custom_Widgets/ImageGalleryPreview.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final int paymentId;
  PaymentConfirmationScreen({required this.paymentId});

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  int hasDisconnectedPermission = 0;

  Map<String, dynamic>? _paymentDetails;
  String voucherNumber = "";
  String paymentInvoiceFor = "";
  String amountCheck = "";
  String checkNumber = "";
  String bankBranch = "";
  String dueDateCheck = "";
  String amount = "";
  String currency = "";
  String deposit = "";
  String notifyFinance = "";
  String checkApproval = "";
  String viewPayment = '';
  String confirmPayment = '';
  String savePayment = '';
  String confirmTitle = '';
  String paymentSummary = '';
  String customerName = '';
  String transactionDate = '';
  String transactionTime = '';
  String cancellationDate = '';
  String paymentMethod = '';
  String confirm = '';
  String cancel = '';
  String paymentSuccessful = '';
  String paymentSuccessfulBody = '';
  String ok = '';
  String prNumber = '';
  String msisdn = '';
  String msisdnPayment = '';
  String msisdnReceipt = '';
  String status = '';
  String theSumOf = '';
  String numberConvertBody = '';
  String languageCode = "";
  String cancelReason = "";
  String isDisconnected = "";
  String cancellationStatus = "";
  String checkImages = "";

  String saved = "";
  String synced = "";
  String confirmed = "";
  String cancelled = "";
  String cancelPending = "";

  late StreamSubscription _syncSubscription;
  String? AppearedCurrency;
  String? AppearedBank;

  @override
  void initState() {
    super.initState();
    _loadPermission();
    _fetchPaymentDetails();
    _syncSubscription = PaymentService.syncStream.listen((_) {
      _fetchPaymentDetails();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeLocalizationStrings();
  }

  @override
  void dispose() {
    _syncSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchPaymentDetails() async {
    try {
      // widget.paymentId is non-nullable
      _paymentDetails = await DatabaseProvider.getPaymentById(widget.paymentId);
      if (_paymentDetails != null) {
        String currencyId = (_paymentDetails!['currency'] ?? '').toString();
        Map<String, dynamic>? currency =
            await DatabaseProvider.getCurrencyById(currencyId);
        if (!mounted) return;
        setState(() {
          AppearedCurrency =
              Provider.of<LocalizationService>(context, listen: false)
                          .selectedLanguageCode ==
                      'ar'
                  ? currency!['arabicName']
                  : currency!['englishName'];
        });

        String bankId = (_paymentDetails!['bankBranch'] ?? '').toString();
        Map<String, dynamic>? bank = await DatabaseProvider.getBankById(bankId);
        if (!mounted) return;
        setState(() {
          if (bank != null) {
            AppearedBank =
                Provider.of<LocalizationService>(context, listen: false)
                            .selectedLanguageCode ==
                        'ar'
                    ? bank['arabicName'] ?? 'Unknown Bank'
                    : bank['englishName'] ?? 'Unknown Bank';
          } else {
            AppearedBank = 'Unknown Bank';
          }
        });
      } else {
        print('No payment details found for ID ${widget.paymentId}');
      }
    } catch (e) {
      print('Error fetching payment details: $e');
    }

    // print("payment detailsss ${_paymentDetails}");
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690));
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 375).clamp(0.8, 1.3);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          viewPayment,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22 * scale,
            fontFamily: 'NotoSansUI',
          ),
        ),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PaymentHistoryScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 30 * scale),
              child: _buildPaymentDetailCard(scale),
            ),
          ],
        ),
      ),
      floatingActionButton: _paymentDetails?["isDisconnected"] == 0 ||
              (hasDisconnectedPermission == _paymentDetails?["isDisconnected"])
          ? Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: FloatingActionButton(
                  onPressed: () {
                    // print("payment detail to pass to record screen :");
                    // print(_paymentDetails);
                    if (_paymentDetails == null) return;
                    (_paymentDetails?['msisdnReceipt'] != null)
                        ? Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecordPaymentDisconnectedScreen(
                                paymentParams: _paymentDetails!,
                              ),
                            ),
                          )
                        : Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecordPaymentScreen(
                                paymentParams: _paymentDetails!,
                              ),
                            ),
                          );
                  },
                  backgroundColor: AppColors.primaryRed,
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
            )
          : SizedBox.shrink(),
    );
  }

  Future<void> _loadPermission() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hasDisconnectedPermission = prefs.getInt('disconnectedPermission') ?? 0;
    });
    // print("Loaded hasDisconnectedPermission: $hasDisconnectedPermission");
  }

  void _initializeLocalizationStrings() {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    languageCode = localizationService.selectedLanguageCode;
    voucherNumber = localizationService.getLocalizedString('voucherNumber');
    paymentInvoiceFor =
        localizationService.getLocalizedString('paymentInvoiceFor');
    amountCheck = localizationService.getLocalizedString('amountCheck');
    checkNumber = localizationService.getLocalizedString('checkNumber');
    bankBranch = localizationService.getLocalizedString('bankBranchCheck');
    dueDateCheck = localizationService.getLocalizedString('dueDateCheck');
    amount = localizationService.getLocalizedString('amount');
    currency = localizationService.getLocalizedString('currency');
    deposit = localizationService.getLocalizedString('deposit');
    checkApproval = localizationService.getLocalizedString('checkApproval');
    notifyFinance = localizationService.getLocalizedString('notifyFinance');
    cancellationDate =
        localizationService.getLocalizedString('cancellationDate');

    ok = localizationService.getLocalizedString('ok');
    status = localizationService.getLocalizedString('status');
    prNumber = localizationService.getLocalizedString('PR');
    msisdn = localizationService.getLocalizedString('MSISDN');
    msisdnReceipt = localizationService.getLocalizedString('msisdn_receipt');
    msisdnPayment = localizationService.getLocalizedString('msisdn_payment');
    theSumOf = localizationService.getLocalizedString('theSumOf');
    viewPayment = localizationService.getLocalizedString('viewPayment');
    savePayment = localizationService.getLocalizedString('savePayment');
    confirmPayment = localizationService.getLocalizedString('confirmPayment');
    paymentSummary = localizationService.getLocalizedString('paymentSummary');
    customerName = localizationService.getLocalizedString('customerName');
    paymentMethod = localizationService.getLocalizedString('paymentMethod');
    confirm = localizationService.getLocalizedString('confirm');
    paymentSuccessful =
        localizationService.getLocalizedString('paymentSuccessful');
    paymentSuccessfulBody =
        localizationService.getLocalizedString('paymentSuccessfulBody');
    cancel = localizationService.getLocalizedString('cancel');
    cancelReason = localizationService.getLocalizedString('cancelReason');
    isDisconnected = localizationService.getLocalizedString('isDisconnected');
    transactionDate = localizationService.getLocalizedString('transactionDate');
    transactionTime = localizationService.getLocalizedString('transactionTime');
    saved = localizationService.getLocalizedString('saved');
    synced = localizationService.getLocalizedString('synced');
    confirmed = localizationService.getLocalizedString('confirmed');
    cancelled = localizationService.getLocalizedString('Cancelled');
    cancelPending = localizationService.getLocalizedString('cancelpending');
    cancellationStatus =
        localizationService.getLocalizedString('cancellationStatus');
    checkImages = localizationService.getLocalizedString('checkImages');
  }

  Widget _buildPaymentDetailCard(double scale) {
    if (_paymentDetails == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final paymentDetails = _paymentDetails!;

    return Container(
      padding: EdgeInsets.all(16 * scale),
      margin: EdgeInsets.only(bottom: 20 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryHeader(scale, paymentDetails['status'].toLowerCase(),
              paymentDetails['cancellationStatus']),
          Divider(
              color: AppColors.primaryRed, thickness: 2, height: 15 * scale),
          if ((paymentDetails['status']?.toLowerCase() == "synced") ||
              (paymentDetails['status']?.toLowerCase() == "cancelled") ||
              (paymentDetails['status']?.toLowerCase() ==
                  "canceldpending")) ...[
            _detailItem(scale, voucherNumber,
                paymentDetails['voucherSerialNumber'] ?? ''),
            _divider(scale),
          ],
          _detailItem(
              scale,
              transactionDate,
              paymentDetails['status']?.toLowerCase() == "saved"
                  ? (paymentDetails['lastUpdatedDate'] != null
                      ? DateFormat('yyyy-MM-dd').format(
                          DateTime.parse(paymentDetails['lastUpdatedDate']))
                      : '')
                  : (paymentDetails['transactionDate'] != null
                      ? DateFormat('yyyy-MM-dd').format(
                          DateTime.parse(paymentDetails['transactionDate']))
                      : '')),
          _divider(scale),
          _detailItem(
              scale,
              transactionTime,
              paymentDetails['status']?.toLowerCase() == "saved"
                  ? (paymentDetails['lastUpdatedDate'] != null
                      ? DateFormat('HH:mm:ss').format(
                          DateTime.parse(paymentDetails['lastUpdatedDate']))
                      : '')
                  : (paymentDetails['transactionDate'] != null
                      ? DateFormat('HH:mm:ss').format(
                          DateTime.parse(paymentDetails['transactionDate']))
                      : '')),
          _divider(scale),
          if ((paymentDetails['status']?.toLowerCase() == "cancelled") ||
              (paymentDetails['status']?.toLowerCase() ==
                  "canceldpending")) ...[
            _detailItem(scale, cancellationDate,
                paymentDetails['cancellationDate']?.toString() ?? ''),
            _divider(scale),
            _detailItem(scale, cancelReason,
                paymentDetails['cancelReason']?.toString() ?? ''),
            _divider(scale),
          ],
          _detailItem(
              scale, customerName, paymentDetails['customerName'] ?? ''),
          _divider(scale),
          _detailItem(
              scale,
              status,
              Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString(paymentDetails['status'].toLowerCase())),
          _divider(scale),
          _detailItem(
              scale, prNumber, paymentDetails['prNumber']?.toString() ?? ''),
          _divider(scale),
          if (paymentDetails['msisdnReceipt'] != null) ...[
            _detailItem(
                scale, msisdn, paymentDetails['msisdn']?.toString() ?? ''),
            _divider(scale),
            _detailItem(scale, msisdnReceipt,
                paymentDetails['msisdnReceipt']?.toString() ?? ''),
            _divider(scale),
          ] else ...[
            _detailItem(
                scale, msisdn, paymentDetails['msisdn']?.toString() ?? ''),
            _divider(scale),
          ],
          _detailItem(
              scale,
              paymentMethod,
              Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString(
                      paymentDetails['paymentMethod'].toLowerCase())),
          if ((paymentDetails['paymentMethod']?.toLowerCase() == "check") ||
              (paymentDetails['paymentMethod'] == "شيك")) ...[
            _divider(scale),
            _detailItem(scale, amountCheck,
                paymentDetails['amountCheck']?.toString() ?? ''),
            _divider(scale),
            _detailItem(scale, currency, AppearedCurrency ?? ''),
            _divider(scale),
            _detailNoteItem(
                scale,
                theSumOf,
                languageCode == 'ar'
                    ? Tafqeet.convert(
                        paymentDetails['amountCheck']?.toInt().toString() ?? '')
                    : NumberToWordsEnglish.convert(
                        paymentDetails['amountCheck'] != null
                            ? (paymentDetails['amountCheck'] as double).toInt()
                            : 0),
                Provider.of<LocalizationService>(context, listen: false)
                    .selectedLanguageCode),
            _divider(scale),
            _detailItem(scale, checkNumber,
                paymentDetails['checkNumber']?.toString() ?? ''),
            _divider(scale),
            _detailItem(scale, bankBranch, AppearedBank ?? ''),
            _divider(scale),
            _detailItem(
                scale,
                dueDateCheck,
                paymentDetails['dueDateCheck'] != null
                    ? DateFormat('yyyy-MM-dd')
                        .format(DateTime.parse(paymentDetails['dueDateCheck']))
                    : ''),
          ],
          if ((paymentDetails['paymentMethod']?.toLowerCase() == "cash") ||
              (paymentDetails['paymentMethod'] == "كاش")) ...[
            _divider(scale),
            _detailItem(
                scale, amount, paymentDetails['amount']?.toString() ?? ''),
            _divider(scale),
            _detailItem(scale, currency, AppearedCurrency!),
            _divider(scale),
            _detailNoteItem(
                scale,
                theSumOf,
                languageCode == 'ar'
                    ? paymentDetails['amount'] != null
                        ? Tafqeet.convert(
                            paymentDetails['amount'].toInt().toString())
                        : 'Invalid amount'
                    : NumberToWordsEnglish.convert(
                        paymentDetails['amount'] != null
                            ? (paymentDetails['amount'] as double).toInt()
                            : 0),
                Provider.of<LocalizationService>(context, listen: false)
                    .selectedLanguageCode),
          ],
          _divider(scale),
          _detailItem(
              scale,
              deposit,
              paymentDetails['isDepositChecked'] == 0
                  ? Provider.of<LocalizationService>(context, listen: false)
                      .getLocalizedString('no')
                  : Provider.of<LocalizationService>(context, listen: false)
                      .getLocalizedString('yes')),
          _divider(scale),
          _detailItem(
            scale,
            isDisconnected,
            paymentDetails['isDisconnected'] == 0
                ? Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('no')
                : Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('yes'),
          ),
          if ((paymentDetails['paymentMethod']?.toLowerCase() == "check") ||
              (paymentDetails['paymentMethod'] == "شيك")) ...[
            _divider(scale),
            _detailItem(
                scale,
                checkApproval,
                paymentDetails['checkApproval'] == 0
                    ? Provider.of<LocalizationService>(context, listen: false)
                        .getLocalizedString('no')
                    : Provider.of<LocalizationService>(context, listen: false)
                        .getLocalizedString('yes')),
            _divider(scale),
            _detailItem(
                scale,
                notifyFinance,
                paymentDetails['notifyFinance'] == 0
                    ? Provider.of<LocalizationService>(context, listen: false)
                        .getLocalizedString('no')
                    : Provider.of<LocalizationService>(context, listen: false)
                        .getLocalizedString('yes')),
            _divider(scale),
          ],
          _detailItem(
            scale,
            cancellationStatus,
            paymentDetails['cancellationStatus'] != null
                ? Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString(
                        paymentDetails['cancellationStatus']!.toLowerCase())
                : '',
          ),
          _divider(scale),
          _detailNoteItem(
              scale,
              paymentInvoiceFor,
              paymentDetails['paymentInvoiceFor']?.toString() ?? '',
              Provider.of<LocalizationService>(context, listen: false)
                  .selectedLanguageCode),
          _divider(scale),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  checkImages,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          paymentDetails['checkImages'] != null
                              ? Provider.of<LocalizationService>(context,
                                      listen: false)
                                  .getLocalizedString(
                                      paymentDetails['checkImages']
                                          .toLowerCase())
                              : '',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 14 * scale,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      IconButton(
                        icon: Icon(Icons.attach_file,
                            color: AppColors.primaryRed),
                        onPressed: () {
                          _showImagesPreview();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImagesPreview() async {
    try {
      // fetch images for this payment
      final images =
          await DatabaseProvider.getCheckImagesByPaymentId(widget.paymentId);
      if (images.isEmpty) {
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.info, color: AppColors.informationPopup, size: 40),
          message: Provider.of<LocalizationService>(context, listen: false)
              .getLocalizedString('noImagesAttached'),
          buttonText: Provider.of<LocalizationService>(context, listen: false)
              .getLocalizedString('ok'),
          onPressButton: () {
            // Define what happens when the button is pressed
            print('Success acknowledged');
          },
        );
        return;
      }

      // decode base64 to bytes
      final List<Uint8List> bytesList = images.map<Uint8List>((img) {
        final String b64 = img['base64Content'] ?? '';
        try {
          return base64.decode(b64);
        } catch (_) {
          return Uint8List(0);
        }
      }).toList();

      // delegate to reusable widget
      await showImageGalleryPreview(context: context, images: bytesList);
    } catch (e) {
      print('Error showing images preview: $e');
    }
  }

  Widget _buildSummaryHeader(
      double scale, String paymentStatus, String? cancellationStatus) {
    // Determine if icons should be shown based on conditions
    bool canEdit = paymentStatus == 'saved';
    bool canDelete = paymentStatus == 'saved';
    bool canConfirm = paymentStatus == 'saved';
    bool canView = paymentStatus != 'saved' && paymentStatus != 'confirmed';
    bool canSend = (paymentStatus != 'saved' &&
        paymentStatus != 'confirmed' &&
        paymentStatus != 'rejected');
    bool canCancel = (paymentStatus == 'synced' && cancellationStatus == null);

    // print("status actions ${paymentStatus}");
    // print("canSend ${canSend}");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          paymentSummary,
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (canView)
              Tooltip(
                message:
                    Provider.of<LocalizationService>(context, listen: false)
                        .getLocalizedString('openAsPdf'),
                child: IconButton(
                  icon: FaIcon(FontAwesomeIcons.filePdf,
                      color: AppColors.primaryRed),
                  onPressed: () async {
                    ShareScreenOptions.showLanguageSelectionAndShare(
                        context, widget.paymentId, ShareOption.OpenPDF);
                  },
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canCancel)
                  Tooltip(
                    message:
                        Provider.of<LocalizationService>(context, listen: false)
                            .getLocalizedString('cancelPayment'),
                    child: IconButton(
                        icon: Icon(Icons.cancel, color: AppColors.primaryRed),
                        onPressed: () async {
                          // widget.paymentId is non-nullable
                          final int idToCancel = widget.paymentId;
                          final result = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return PaymentCancellationScreen(id: idToCancel);
                            },
                          );
                          if (result == true) {
                            // If cancellation was successful, refresh the payment details
                            _fetchPaymentDetails();
                          }
                        }),
                  ),
                if (canSend) ...[
                  Tooltip(
                    message:
                        Provider.of<LocalizationService>(context, listen: false)
                            .getLocalizedString('sendPrinter'),
                    child: IconButton(
                      icon: Icon(Icons.print, color: Colors.black),
                      onPressed: () async {
                        // Function to get the default printer info from SharedPreferences
                        final prefs = await SharedPreferences.getInstance();
                        String? printerLabel =
                            prefs.getString('default_device_label');
                        String? printerAddress =
                            prefs.getString('default_device_address');

                        if (printerLabel == null ||
                            printerLabel.isEmpty ||
                            printerAddress == null ||
                            printerAddress.isEmpty) {
                          CustomPopups.showTwoButtonPopup(
                            context: context,
                            icon: Icon(Icons.warning,
                                size: 40, color: AppColors.primaryRed),
                            message: Provider.of<LocalizationService>(context,
                                    listen: false)
                                .getLocalizedString('noDefaultDeviceSetBody'),
                            firstButtonText: Provider.of<LocalizationService>(
                                    context,
                                    listen: false)
                                .getLocalizedString('cancel'),
                            onFirstButtonPressed: () {
                              // Handle cancel action
                              print('Cancel button pressed');
                            },
                            secondButtonText: Provider.of<LocalizationService>(
                                    context,
                                    listen: false)
                                .getLocalizedString("printerSettings"),
                            onSecondButtonPressed: () {
                              // Handle confirm action
                              print('Confirm button pressed');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PrinterSettingScreen(),
                                ),
                              );
                            },
                          );
                        } else {
                          if (Platform.isIOS) {
                            bool isBluetoothOn = await iosPlat.BluetoothService
                                .isBluetoothPoweredOn();
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
                            } else
                              ShareScreenOptions.showLanguageSelectionAndShare(
                                  context, widget.paymentId, ShareOption.print);
                          } else if (Platform.isAndroid) {
                            ShareScreenOptions.showLanguageSelectionAndShare(
                                context, widget.paymentId, ShareOption.print);
                          }
                        }
                      },
                    ),
                  ),
                  Tooltip(
                      message: Provider.of<LocalizationService>(context,
                              listen: false)
                          .getLocalizedString('sendSms'),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      textStyle: TextStyle(color: Colors.white),
                      child: IconButton(
                        icon: Icon(
                          Icons.message,
                          color: Colors.green, // Set the color of the icon here
                        ),
                        onPressed: () async {
                          var connectivityResult =
                              await (Connectivity().checkConnectivity());
                          if (connectivityResult.toString() ==
                              '[ConnectivityResult.none]') {
                            CustomPopups.showLoginFailedDialog(
                                context,
                                Provider.of<LocalizationService>(context,
                                        listen: false)
                                    .getLocalizedString("noInternet"),
                                Provider.of<LocalizationService>(context,
                                            listen: false)
                                        .isLocalizationLoaded
                                    ? Provider.of<LocalizationService>(context,
                                            listen: false)
                                        .getLocalizedString(
                                            'noInternetConnection')
                                    : 'No Internet Connection',
                                Provider.of<LocalizationService>(context,
                                        listen: false)
                                    .selectedLanguageCode);
                          } else
                            ShareScreenOptions.showLanguageSelectionAndShare(
                                context, widget.paymentId, ShareOption.sendSms);
                        },
                      )),
                  Tooltip(
                    message:
                        Provider.of<LocalizationService>(context, listen: false)
                            .getLocalizedString('sendEmail'),
                    child: IconButton(
                      icon: Icon(
                        Icons.email,
                        color: Colors.blue,
                      ),
                      onPressed: () async {
                        var connectivityResult =
                            await (Connectivity().checkConnectivity());
                        if (connectivityResult.toString() ==
                            '[ConnectivityResult.none]') {
                          CustomPopups.showLoginFailedDialog(
                              context,
                              Provider.of<LocalizationService>(context,
                                      listen: false)
                                  .getLocalizedString("noInternet"),
                              Provider.of<LocalizationService>(context,
                                          listen: false)
                                      .isLocalizationLoaded
                                  ? Provider.of<LocalizationService>(context,
                                          listen: false)
                                      .getLocalizedString(
                                          'noInternetConnection')
                                  : 'No Internet Connection',
                              Provider.of<LocalizationService>(context,
                                      listen: false)
                                  .selectedLanguageCode);
                        } else
                          ShareScreenOptions.showLanguageSelectionAndShare(
                              context, widget.paymentId, ShareOption.sendEmail);
                      },
                    ),
                  ), //
                  Tooltip(
                    message:
                        Provider.of<LocalizationService>(context, listen: false)
                            .getLocalizedString('sharePayment'),
                    child: IconButton(
                      icon: FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.green,
                      ),
                      onPressed: () async {
                        var connectivityResult =
                            await (Connectivity().checkConnectivity());
                        if (connectivityResult.toString() ==
                            '[ConnectivityResult.none]') {
                          CustomPopups.showLoginFailedDialog(
                              context,
                              Provider.of<LocalizationService>(context,
                                      listen: false)
                                  .getLocalizedString("noInternet"),
                              Provider.of<LocalizationService>(context,
                                          listen: false)
                                      .isLocalizationLoaded
                                  ? Provider.of<LocalizationService>(context,
                                          listen: false)
                                      .getLocalizedString(
                                          'noInternetConnection')
                                  : 'No Internet Connection',
                              Provider.of<LocalizationService>(context,
                                      listen: false)
                                  .selectedLanguageCode);
                        } else
                          ShareScreenOptions.showLanguageSelectionAndShare(
                              context, widget.paymentId, ShareOption.sendWhats);
                      },
                    ),
                  ),
                ],
                if (canDelete)
                  Tooltip(
                    message:
                        Provider.of<LocalizationService>(context, listen: false)
                            .getLocalizedString('deletePayment'),
                    child: IconButton(
                      icon: Icon(Icons.delete, color: AppColors.primaryRed),
                      onPressed: () {
                        CustomPopups.showCustomDialog(
                          context: context,
                          icon: Icon(Icons.delete,
                              size: 60, color: AppColors.primaryRed),
                          title: Provider.of<LocalizationService>(context,
                                  listen: false)
                              .getLocalizedString('deletePayment'),
                          message: Provider.of<LocalizationService>(context,
                                  listen: false)
                              .getLocalizedString('deletePaymentBody'),
                          deleteButtonText: Provider.of<LocalizationService>(
                                  context,
                                  listen: false)
                              .getLocalizedString('ok'),
                          onPressButton: () async {
                            // Show the loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext dialogContext) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            );

                            try {
                              // Perform the delete operation
                              await DatabaseProvider.deletePayment(
                                  widget.paymentId);

                              // Ensure the loading dialog is shown for at least 1 second
                              await Future.delayed(Duration(seconds: 1));
                            } catch (error) {
                              // Handle any errors here if needed
                              print('Error deleting payment: $error');
                            } finally {
                              // Close the loading dialog
                              Navigator.pop(context); // pop the dialog

                              // Pop the current screen
                              Navigator.of(context).pop();

                              // Push the HistoryScreen
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      PaymentHistoryScreen()));
                            }
                          },
                        );
                      },
                    ),
                  ),
                if (canEdit)
                  Tooltip(
                    message:
                        Provider.of<LocalizationService>(context, listen: false)
                            .getLocalizedString('editPayment'),
                    child: IconButton(
                      icon: Icon(Icons.edit, color: Color(0xFFA67438)),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  RecordPaymentScreen(id: widget.paymentId)),
                        );
                      },
                    ),
                  ),
                if (canConfirm)
                  Tooltip(
                    message:
                        Provider.of<LocalizationService>(context, listen: false)
                            .getLocalizedString('confirmPayment'),
                    child: IconButton(
                      icon: Icon(Icons.check_circle, color: Colors.blue),
                      onPressed: () {
                        CustomPopups.showCustomDialog(
                          context: context,
                          icon: Icon(Icons.check_circle,
                              size: 60.0, color: AppColors.primaryRed),
                          title: Provider.of<LocalizationService>(context,
                                  listen: false)
                              .getLocalizedString('confirmPayment'),
                          message: Provider.of<LocalizationService>(context,
                                  listen: false)
                              .getLocalizedString('confirmPaymentBody'),
                          deleteButtonText: Provider.of<LocalizationService>(
                                  context,
                                  listen: false)
                              .getLocalizedString('ok'),
                          onPressButton: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext dialogContext) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            );
                            // Simulate a network request/waiting time
                            await DatabaseProvider.updatePaymentStatus(
                                widget.paymentId, 'Confirmed');
                            Navigator.pop(context); // pop the dialog
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailItem(double scale, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14 * scale,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailNoteItem(
      double scale, String title, String value, String languageCode) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: languageCode == 'ar'
                      ? TextAlign.right
                      : TextAlign.left, // Adjust alignment based on language
                ),
              ),
            ],
          ),
          SizedBox(height: 5 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  textAlign: languageCode == 'ar'
                      ? TextAlign.left
                      : TextAlign.right, // Opposite alignment for value
                  style: TextStyle(
                    fontSize: 14 * scale,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider(double scale) {
    return Divider(color: const Color(0xFFCCCCCC), height: 10 * scale);
  }
}
