  import 'dart:async';
  import 'dart:ui';
  import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:provider/provider.dart';
  import '../Services/LocalizationService.dart';
  import 'package:intl/intl.dart';
  import 'package:number_to_word_arabic/number_to_word_arabic.dart';
  import 'package:number_to_words_english/number_to_words_english.dart';
  import '../Services/PaymentService.dart';
  import '../Services/database.dart';
  import '../Utils/Enum.dart';
import 'PaymentCancellationScreen.dart';
  import 'PaymentHistoryScreen.dart';
  import '../Custom_Widgets/CustomPopups.dart';
  import '../Screens/RecordPaymentScreen.dart';
  import '../Screens/ShareScreenOptions.dart';
  import 'package:font_awesome_flutter/font_awesome_flutter.dart';

  class PaymentConfirmationScreen extends StatefulWidget {
    final int paymentId;
    Map<String, dynamic>? paymentDetails;
    PaymentConfirmationScreen({required this.paymentId});

    @override
    State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
  }

  class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
    String voucherNumber = "";
    String paymentInvoiceFor = "";
    String amountCheck = "";
    String checkNumber = "";
    String bankBranch = "";
    String dueDateCheck = "";
    String amount = "";
    String currency = "";
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
    String status = '';
    String theSumOf = '';
    String numberConvertBody = '';
    String languageCode = "";
    String cancelReason = "";

    String saved= "";
    String synced= "";
    String confirmed= "";
    String cancelled= "";
    String cancelPending= "";

    late StreamSubscription _syncSubscription;
    String? AppearedCurrency;
    String? AppearedBank;

    @override
    void initState() {
      _fetchPaymentDetails();
      super.initState();
      _initializeLocalizationStrings();
      _syncSubscription = PaymentService.syncStream.listen((_) {
        _fetchPaymentDetails();
      });
    }

    @override
    void dispose() {
      _syncSubscription.cancel();
      super.dispose();
    }

    void _initializeLocalizationStrings() {
      final localizationService = Provider.of<LocalizationService>(context, listen: false);
      languageCode = localizationService.selectedLanguageCode;
      voucherNumber = localizationService.getLocalizedString('voucherNumber') ?? 'Voucher Number';
      paymentInvoiceFor = localizationService.getLocalizedString('paymentInvoiceFor') ?? 'Confirm Payment';
      amountCheck = localizationService.getLocalizedString('amountCheck') ?? 'Confirm Payment';
      checkNumber = localizationService.getLocalizedString('checkNumber') ?? 'Confirm Payment';
      bankBranch = localizationService.getLocalizedString('bankBranchCheck') ?? 'Confirm Payment';
      dueDateCheck = localizationService.getLocalizedString('dueDateCheck') ?? 'Confirm Payment';
      amount = localizationService.getLocalizedString('amount') ?? 'Confirm Payment';
      currency = localizationService.getLocalizedString('currency') ?? 'Confirm Payment';
      cancellationDate = localizationService.getLocalizedString('cancellationDate') ?? 'Confirm Payment';

      ok = localizationService.getLocalizedString('ok') ?? 'Confirm Payment';
      status = localizationService.getLocalizedString('status') ?? '';
      prNumber = localizationService.getLocalizedString('PR') ?? 'Confirm Payment';
      msisdn = localizationService.getLocalizedString('MSISDN') ?? 'Confirm Payment';
      theSumOf = localizationService.getLocalizedString('theSumOf') ?? 'Confirm Payment';

      viewPayment = localizationService.getLocalizedString('viewPayment') ?? 'Confirm Payment';
      savePayment = localizationService.getLocalizedString('savePayment') ?? 'Save Payment';
      confirmPayment = localizationService.getLocalizedString('confirmPayment') ?? 'Confirm Payment';

      paymentSummary = localizationService.getLocalizedString('paymentSummary') ?? 'Payment Summary';
      customerName = localizationService.getLocalizedString('customerName') ?? 'Customer Name';
      paymentMethod = localizationService.getLocalizedString('paymentMethod') ?? 'Payment Method';

      confirm = localizationService.getLocalizedString('confirm') ?? 'Confirm';
      paymentSuccessful = localizationService.getLocalizedString('paymentSuccessful') ?? 'Payment Successful';
      paymentSuccessfulBody = localizationService.getLocalizedString('paymentSuccessfulBody') ?? 'Your payment was successful!';
      cancel = localizationService.getLocalizedString('cancel') ?? 'Cancel';
      cancelReason = localizationService.getLocalizedString('cancelReason') ?? 'Confirm Payment';

      transactionDate = localizationService.getLocalizedString('transactionDate') ?? 'Confirm Payment';
      transactionTime = localizationService.getLocalizedString('transactionTime') ?? 'Confirm Payment';
      saved = localizationService.getLocalizedString('saved') ?? 'Confirm Payment';
      synced = localizationService.getLocalizedString('synced') ?? 'Confirm Payment';
      confirmed = localizationService.getLocalizedString('confirmed') ?? 'Confirm Payment';
      cancelled = localizationService.getLocalizedString('cancelled') ?? 'Confirm Payment';
      cancelPending = localizationService.getLocalizedString('cancelpending') ?? 'Confirm Payment';
    }

    Future<void> _fetchPaymentDetails() async {
      try {
        if (widget.paymentId != null) {
          widget.paymentDetails = await DatabaseProvider.getPaymentById(widget.paymentId);
          String currencyId = widget.paymentDetails!['currency']?.toString() ?? '';
          // Fetch the currency by ID
          Map<String, dynamic>? currency = await DatabaseProvider.getCurrencyById(currencyId);
          setState(() {
            AppearedCurrency = Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode == 'ar' ? currency!["arabicName"] :  currency!["englishName"];
          });

          String bankId = widget.paymentDetails!['bankBranch']?.toString() ?? '';
          Map<String, dynamic>? bank = await DatabaseProvider.getBankById(bankId);
          setState(() {
            if (bank != null) {
              AppearedBank = Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode == 'ar'
                  ? bank["arabicName"] ?? 'Unknown Bank'
                  : bank["englishName"] ?? 'Unknown Bank';
            } else {
              AppearedBank = 'Unknown Bank';
            }
          });

          // print(AppearedCurrency);
          // print(AppearedBank);

        } else {
          print('No payment details found for ID ${widget.paymentId}');
        }
      } catch (e) {
        print('Error fetching payment details: $e');
      }
    }

    @override
    Widget build(BuildContext context) {
      ScreenUtil.init(context, designSize: Size(360, 690));
      return Scaffold(
        appBar: AppBar(
          title: Text(
            viewPayment,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontFamily: 'NotoSansUI',
            ),
          ),
          backgroundColor: Color(0xFFC62828),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
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
                margin: EdgeInsets.only(bottom: 30.h), // Margin from the bottom button
                child: _buildPaymentDetailCard(),
              ),
            ],
          ),
        ),
        floatingActionButton: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: FloatingActionButton(
              onPressed: () {
                // Navigate to the RecordPaymentScreen with the optional paymentParams
                print("payment detail to pass to record screen :");
                print(widget.paymentDetails);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecordPaymentScreen(
                      paymentParams:widget.paymentDetails , // Pass the paymentParams here
                    ),
                  ),
                );
              },
              backgroundColor: Color(0xFFC62828),
              child: Icon(Icons.add,color: Colors.white),
            ),
          ),
        ),
      );
    }

    Widget _buildPaymentDetailCard() {
      if (widget.paymentDetails == null) {
        return Center(child: CircularProgressIndicator());
      }

       final paymentDetails = widget.paymentDetails!;

      return Container(
        padding: EdgeInsets.all(16.w),
        margin: EdgeInsets.only(bottom: 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryHeader(paymentDetails['status'].toLowerCase()),

            Divider(color: Color(0xFFC62828), thickness: 2, height: 15.h),

            if ((paymentDetails['status']?.toLowerCase() == "synced") || (paymentDetails['status']?.toLowerCase() == "cancelled") || (paymentDetails['status']?.toLowerCase() == "canceldpending")) ...[
              _detailItem(voucherNumber, paymentDetails['voucherSerialNumber'] ?? ''),
              _divider(),

            ],
            _detailItem(transactionDate, paymentDetails['status']?.toLowerCase() == "saved"
                ? (paymentDetails['lastUpdatedDate'] != null
                ? DateFormat('yyyy-MM-dd').format(DateTime.parse(paymentDetails['lastUpdatedDate']))
                : '')
                : (paymentDetails['transactionDate'] != null
                ? DateFormat('yyyy-MM-dd').format(DateTime.parse(paymentDetails['transactionDate']))
                : '')),
            _divider(),
            _detailItem(transactionTime, paymentDetails['status']?.toLowerCase() == "saved"
                ? (paymentDetails['lastUpdatedDate'] != null
                ? DateFormat('HH:mm:ss').format(DateTime.parse(paymentDetails['lastUpdatedDate']))
                : '')
                : (paymentDetails['transactionDate'] != null
                ? DateFormat('HH:mm:ss').format(DateTime.parse(paymentDetails['transactionDate']))
                : '')),
            _divider(),
            if ((paymentDetails['status']?.toLowerCase() == "cancelled") || (paymentDetails['status']?.toLowerCase() == "canceldpending"))
              ...[
                _detailItem(cancellationDate, paymentDetails['cancellationDate']?.toString() ?? ''),
                _divider(),
                _detailItem(cancelReason, paymentDetails['cancelReason']?.toString() ?? ''),
                _divider(),
              ],


              _detailItem(customerName, paymentDetails['customerName'] ?? ''),
            _divider(),
            _detailItem(status,Provider.of<LocalizationService>(context, listen: false).getLocalizedString(paymentDetails['status'].toLowerCase()) ?? ''),
            _divider(),
            _detailItem(prNumber, paymentDetails['prNumber']?.toString() ?? ''),
            _divider(),
            _detailItem(msisdn, paymentDetails['msisdn']?.toString() ?? ''),
            _divider(),
            _detailItem(paymentMethod, Provider.of<LocalizationService>(context, listen: false).getLocalizedString(paymentDetails['paymentMethod'].toLowerCase()) ?? ''),

            if ((paymentDetails['paymentMethod']?.toLowerCase() == "check") || (paymentDetails['paymentMethod'] == "شيك")) ...[
              _divider(),
              _detailItem(amountCheck, paymentDetails['amountCheck']?.toString() ?? ''),
              _divider(),
              _detailItem(currency, AppearedCurrency!),
              _divider(),
              _detailNoteItem(
                  theSumOf,
                  languageCode == 'ar'
                      ? Tafqeet.convert(paymentDetails['amountCheck']?.toInt().toString() ?? '')
                      : NumberToWordsEnglish.convert(paymentDetails['amountCheck'] != null ? (paymentDetails['amountCheck'] as double).toInt() : 0)
              ,Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode),
              _divider(),
              _detailItem(checkNumber, paymentDetails['checkNumber']?.toString() ?? ''),
              _divider(),
              _detailItem(bankBranch,AppearedBank ?? ''),
              _divider(),
              _detailItem(dueDateCheck, DateFormat('yyyy-MM-dd').format(DateTime.parse(paymentDetails['dueDateCheck'])) ?? ''),
            ],
            if ((paymentDetails['paymentMethod']?.toLowerCase() == "cash") || (paymentDetails['paymentMethod'] == "كاش")) ...[
              _divider(),
              _detailItem(amount, paymentDetails['amount']?.toString() ?? ''),
              _divider(),
              _detailItem(currency, AppearedCurrency!),
              _divider(),
              _detailNoteItem(
                theSumOf,
                languageCode == 'ar'
                    ?  paymentDetails['amount']!= null ? Tafqeet.convert(paymentDetails['amount'].toInt().toString() )  : 'Invalid amount'
                    : NumberToWordsEnglish.convert(paymentDetails['amount'] != null ? (paymentDetails['amount'] as double).toInt() : 0),
      Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode),
            ],
            _divider(),
            _detailNoteItem(paymentInvoiceFor, paymentDetails['paymentInvoiceFor']?.toString() ?? '',Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode),
          ],
        ),
      );
    }

    Widget _buildSummaryHeader(String paymentStatus) {
      // Determine if icons should be shown based on conditions
      bool canEdit = paymentStatus == 'saved';
      bool canDelete = paymentStatus == 'saved';
      bool canConfirm = paymentStatus == 'saved';
      bool canSend = paymentStatus == 'synced';
      bool canCancel = paymentStatus == 'synced';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paymentSummary,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (canSend)
                Tooltip(
                  message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('openAsPdf'),
                  child: IconButton(
                    icon: FaIcon(FontAwesomeIcons.filePdf, color: Colors.red),
                    onPressed: () async{
                      ShareScreenOptions.showLanguageSelectionAndShare(context, widget.paymentId,ShareOption.OpenPDF);
                    },
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
              if (canCancel)
                Tooltip(
                  message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('cancelPayment'),
                  child: IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      if (widget.paymentId != null) {
                        final int idToCancel = widget.paymentId!;
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return PaymentCancellationScreen(id: idToCancel);
                          },
                        );
                      }
                    },
                  ),
                ),
              if (canSend)
                ...[
                  // Tooltip(
                  //   message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('sendPrinter'),
                  //   child:IconButton(
                  //     icon: Icon(Icons.print, color: Colors.black),
                  //     onPressed: () async{
                  //       var connectivityResult = await (Connectivity().checkConnectivity());
                  //       if(connectivityResult.toString() == '[ConnectivityResult.none]'){
                  //         CustomPopups.showLoginFailedDialog(context, Provider.of<LocalizationService>(context, listen: false).getLocalizedString("noInternet"), Provider.of<LocalizationService>(context, listen: false).isLocalizationLoaded ?  Provider.of<LocalizationService>(context, listen: false).getLocalizedString('noInternetConnection')
                  //             : 'No Internet Connection',  Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode);
                  //       }
                  //       else
                  //         ShareScreenOptions.showLanguageSelectionAndShare(context, widget.paymentId,ShareOption.print);
                  //
                  //     },
                  //   ),),
                  Tooltip(
                    message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('sendSms'),
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
                      onPressed: () async{
                        var connectivityResult = await (Connectivity().checkConnectivity());
                        if(connectivityResult.toString() == '[ConnectivityResult.none]'){
                          CustomPopups.showLoginFailedDialog(context, Provider.of<LocalizationService>(context, listen: false).getLocalizedString("noInternet"), Provider.of<LocalizationService>(context, listen: false).isLocalizationLoaded ?  Provider.of<LocalizationService>(context, listen: false).getLocalizedString('noInternetConnection')
                              : 'No Internet Connection',  Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode);
                        }
                        else
                        ShareScreenOptions.showLanguageSelectionAndShare(context, widget.paymentId,ShareOption.sendSms);

                      },
                    )
                  ),
                  Tooltip(
                    message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('sendEmail'),
                    child:IconButton(
                      icon: Icon(Icons.email,  color: Colors.blue,
                      ),
                      onPressed: () async{
                        var connectivityResult = await (Connectivity().checkConnectivity());
                        if(connectivityResult.toString() == '[ConnectivityResult.none]'){
                          CustomPopups.showLoginFailedDialog(context, Provider.of<LocalizationService>(context, listen: false).getLocalizedString("noInternet"), Provider.of<LocalizationService>(context, listen: false).isLocalizationLoaded ?  Provider.of<LocalizationService>(context, listen: false).getLocalizedString('noInternetConnection')
                              : 'No Internet Connection',  Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode);
                        }
                        else
                        ShareScreenOptions.showLanguageSelectionAndShare(context, widget.paymentId,ShareOption.sendEmail);
                      },
                    ),),//
                Tooltip(
                    message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('sharePayment'),
                    child:IconButton(
                      icon:FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green,),
                      onPressed: () async{
                        var connectivityResult = await (Connectivity().checkConnectivity());
                        if(connectivityResult.toString() == '[ConnectivityResult.none]'){
                          CustomPopups.showLoginFailedDialog(context, Provider.of<LocalizationService>(context, listen: false).getLocalizedString("noInternet"), Provider.of<LocalizationService>(context, listen: false).isLocalizationLoaded ?  Provider.of<LocalizationService>(context, listen: false).getLocalizedString('noInternetConnection')
                              : 'No Internet Connection',  Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode);
                        }
                        else
                          ShareScreenOptions.showLanguageSelectionAndShare(context, widget.paymentId,ShareOption.sendWhats);
                },
                    ),
                ),

                ],

              if (canDelete)
                Tooltip(
                  message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('deletePayment'),
                  child: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      CustomPopups.showCustomDialog(  context: context,
                        icon: Icon(Icons.delete, size: 60, color: Colors.red),
                        title: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('deletePayment'),
                        message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('deletePaymentBody'),
                        deleteButtonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('ok'),
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
                            await DatabaseProvider.deletePayment(widget.paymentId);

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
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => PaymentHistoryScreen()));
                          }
                        },

                      );
                    },
                  ),
                ),
              if (canEdit)
                Tooltip(
                  message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('editPayment'),
                  child: IconButton(
                    icon: Icon(Icons.edit, color: Color(0xFFA67438)),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => RecordPaymentScreen(id: widget.paymentId)),
                      );
                    },
                  ),
                ),
              if (canConfirm)
                Tooltip(
                  message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('confirmPayment'),
                  child: IconButton(
                    icon: Icon(Icons.check_circle, color: Colors.blue),
                    onPressed: () {
                      CustomPopups.showCustomDialog(
                        context: context,
                        icon: Icon(Icons.check_circle, size: 60.0, color: Color(0xFFC62828)),
                        title: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('confirmPayment'),
                        message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('confirmPaymentBody'),
                        deleteButtonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('ok'),
                        onPressButton: () async {
                          showDialog( context: context,  barrierDismissible: false,  builder: (BuildContext dialogContext) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          );
                          // Simulate a network request/waiting time
                          await DatabaseProvider.updatePaymentStatus(widget.paymentId,'Confirmed');
                          Navigator.pop(context); // pop the dialog

                        },
                      );
                      },
                  ),
                ),
            ],
          ),
            ],),
        ],
      );
    }

    Widget _detailItem(String title, String value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _detailNoteItem(String title, String value, String languageCode) {
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: languageCode == 'ar' ? TextAlign.right : TextAlign.left, // Adjust alignment based on language
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h), // Adjust space between title and value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    textAlign: languageCode == 'ar' ? TextAlign.left : TextAlign.right, // Opposite alignment for value
                    style: TextStyle(
                      fontSize: 14.sp,
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

    Widget _divider() {
      return Divider(color: Color(0xFFCCCCCC), height: 10.h);
    }
  }
