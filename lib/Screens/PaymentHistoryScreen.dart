import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Screens/PaymentCancellationScreen.dart';
import '../Screens/RecordPaymentScreen.dart';
import '../Screens/ShareScreenOptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/LocalizationService.dart';
import 'package:provider/provider.dart';
import '../Services/database.dart';
import '../Models/Payment.dart';
import '../Services/secure_storage.dart';
import '../Utils/Enum.dart';
import 'PaymentConfirmationScreen.dart';
import '../Services/PaymentService.dart';
import '../Custom_Widgets/CustomPopups.dart';


class PaymentHistoryScreen extends StatefulWidget {
  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  String paymentHistory='';
  String from='';
  String to='';
  String search='';
  late StreamSubscription _syncSubscription;
  List<String> _selectedStatuses = [];
  List<Payment> _paymentRecords = [];
  Map<String, String> _currencies = {};
  Map<String, String> _banks = {};


  void _fetchPayments() async {
    if (!mounted) return;

    if (_currencies ==null || _currencies.length<1){
     // print("no currency");
      List<Map<String, dynamic>> currencies = await DatabaseProvider.getAllCurrencies();
      String selectedCode = Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode;
      Map<String, String> currencyMap = {};
      for (var currency in currencies) {
        String id = currency["id"];
        String name = selectedCode == "ar" ? currency["arabicName"] : currency["englishName"];
        currencyMap[id] = name;
      }
      setState(() {
        _currencies=currencyMap;
      });
    }
    if (_banks ==null || _banks.length<1){
    //  print("no banks");
      List<Map<String, dynamic>> banks = await DatabaseProvider.getAllBanks();
      String selectedCode = Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode;
      Map<String, String> bankMap = {};
      for (var bank in banks) {
        String id = bank["id"];
        String name = selectedCode == "ar" ? bank["arabicName"] : bank["englishName"];
        bankMap[id] = name;
      }
      setState(() {
        _banks=bankMap;
      });
    }

    //print("_fetchPayments method in PaymentHistory screen started");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String usernameLogin = prefs.getString('usernameLogin') ?? 'null';
    List<Map<String, dynamic>> payments = await DatabaseProvider.getPaymentsWithDateFilter(_selectedFromDate, _selectedToDate, _selectedStatuses,usernameLogin.toLowerCase());
    String? dueDateCheckString ;
    DateTime? dueDateCheck;
    String? lastUpdatedDateString ;
    DateTime? lastUpdatedDate;
    String? transactionDateString ;
    DateTime? transactionDate;
    String? cancellationDateString ;
    DateTime? cancellationDate;
    String serialNumber="";
    if (mounted){
    setState(() {
      _paymentRecords = payments.map((payment) {
        dueDateCheckString = payment['dueDateCheck'];
        lastUpdatedDateString = payment['lastUpdatedDate'];
        transactionDateString = payment['transactionDate'];
        cancellationDateString = payment['cancellationDate'];

        if(cancellationDateString != null && cancellationDateString!.isNotEmpty)
          try {
            cancellationDate =  DateTime.parse(cancellationDateString!);
          } catch (e) {
            //print('Error parsing cancellationDate: $cancellationDate');
            cancellationDate = null;
          }

        if(payment['voucherSerialNumber'] != null)
          serialNumber=payment['voucherSerialNumber'];
        if (dueDateCheckString != null && dueDateCheckString!.isNotEmpty) {
          try {
            dueDateCheck = DateFormat('yyyy-MM-dd').parse(dueDateCheckString!);
          } catch (e) {
            //print('Error parsing dueDateCheck: $dueDateCheckString');
            dueDateCheck = null;
          }
        } else {
          dueDateCheck = null;
        }
        if (lastUpdatedDateString != null && lastUpdatedDateString!.isNotEmpty) {
          try {
            lastUpdatedDate =  DateTime.parse(lastUpdatedDateString!);
          } catch (e) {
            //print('Error parsing dueDateCheck: $lastUpdatedDate');
            lastUpdatedDate = null;
          }
        } else {
          lastUpdatedDate = null;
        }
        if (transactionDateString != null && transactionDateString!.isNotEmpty) {
          try {
            transactionDate =  DateTime.parse(transactionDateString!);
          } catch (e) {
            //print('Error parsing dueDateCheck: $transactionDate');
            transactionDate = null;
          }
        } else {
          transactionDate = null;
        }

        return Payment(
            id:payment['id'],
            transactionDate:transactionDate,
            lastUpdatedDate:lastUpdatedDate,
            customerName: payment['customerName'],
            msisdn: payment['msisdn'],
            prNumber: payment['prNumber'],
            paymentMethod: payment['paymentMethod'],
            amount: payment['amount'],
            currency: _currencies[payment['currency']],
            amountCheck: payment['amountCheck'],
            checkNumber: payment['checkNumber'],
            bankBranch: _banks[payment['bankBranch']],
            dueDateCheck: dueDateCheck,
            paymentInvoiceFor: payment['paymentInvoiceFor'],
            status: payment['status'],
            voucherSerialNumber:serialNumber,
            cancelReason:payment['cancelReason'],
            cancellationDate:cancellationDate
        );
      }).toList();
      _paymentRecords.sort((a, b) {
        // Determine the date to use for sorting for each record
        DateTime aDate = a.transactionDate ?? a.lastUpdatedDate ?? DateTime.now();
        DateTime bDate = b.transactionDate ?? b.lastUpdatedDate ?? DateTime.now();

        // Compare the dates in descending order
        return bDate.compareTo(aDate);
      });

    });
    }
  }

  void _initializeLocalizationStrings( ) {
    final localizationService = Provider.of<LocalizationService>(
        context, listen: false);
    paymentHistory = localizationService.getLocalizedString('paymentHistory');
    from = localizationService.getLocalizedString('from');
    to = localizationService.getLocalizedString('to');
    search = localizationService.getLocalizedString('search');
  }

  @override
  void initState() {
    _fetchPayments();
    super.initState();
        // Initialize the localization strings
    _initializeLocalizationStrings();
    _syncSubscription = PaymentService.syncStream.listen((_) {
      _fetchPayments(); // Refresh payment records
    });
  }

  @override
  void dispose() {
    _syncSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690));
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1.0,
          ),
        ),
        title: Text(paymentHistory,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontFamily: 'NotoSansUI',
            )),
        backgroundColor: Color(0xFFC62828),

      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            _buildDateFilterSection(),
            SizedBox(height: 10.h),
            _buildSearchButton(),
            SizedBox(height: 5.h),
            _buildSelectedStatuses(),
            Container(
              margin: EdgeInsets.only(bottom: 50.h), // Margin from the bottom button
              child: _buildPaymentRecordsList(),
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
              // Navigate to the RecordPaymentScreen to add a new payment
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RecordPaymentScreen()));
            },
            backgroundColor: Color(0xFFC62828),
            child: Icon(Icons.add),
          ),
        ),
      ),

    );
  }

  Widget _buildDateFilterSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            context,
            label: from,
            controller: _fromDateController,
            onDateSelected: (date) {
              setState(() => _selectedFromDate = date);
            },
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildDateField(
            context,
            label: to,
            controller: _toDateController,
            onDateSelected: (date) {
              setState(() => _selectedToDate = date);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, {required String label, required TextEditingController controller, required Function(DateTime) onDateSelected}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Icon(Icons.calendar_today, color: Color(0xFFC62828)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        fillColor: Colors.white,
        filled: true,
      ),
      readOnly: true,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null && picked != _selectedFromDate) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
          onDateSelected(picked);
        }
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return ''; // handle null date
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Widget _buildSelectedStatuses() {
    return Wrap(
      spacing: 5.0, // Horizontal spacing between chips
      children: _selectedStatuses.map((status) {
        return Padding(
          padding: const EdgeInsets.only(top: 7.0), // Add margin to the top
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0), // Padding inside the chip
            decoration: BoxDecoration(
              color: Colors.grey[200],  // Background color
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Colors.transparent, // No visible border
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getLocalizedString(status.toLowerCase()),
                  style: TextStyle(
                    fontSize: 12.0,  // Font size
                    fontWeight: FontWeight.w300,  // Font weight
                    color: Colors.grey[600],  // Text color
                  ),
                ),
                SizedBox(width: 8.0), // Space between text and delete icon
                Padding(
                  padding: const EdgeInsets.all(2.0), // Padding around the delete icon
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStatuses.remove(status);
                        _fetchPayments();
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 18.0,
                      color: Colors.grey[700],  // Delete icon color
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.search, color: Colors.white),
            label: Text(
              search,
              style: TextStyle(fontSize: 14.sp, fontFamily: 'NotoSansUI'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFC62828),
              minimumSize: Size(double.infinity, 40.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              //print("from date: $_selectedFromDate : $_selectedToDate");
              _fetchPayments();
              // Add any post-operation logic if needed
            },
          ),
        ),
        SizedBox(width: 10.w), // Add spacing between the button and the icon
        Container(
          height: 40.h,
          decoration: BoxDecoration(
            color: Color(0xFFC62828),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('selectStatus')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <String>['Saved', 'Confirmed', 'Synced', 'cancelPending', 'Cancelled']
                    .map((String status) {
                  return CheckboxListTile(
                    title: Text(
                      Provider.of<LocalizationService>(context, listen: false).getLocalizedString(status.toLowerCase()),
                    ),
                    value: _selectedStatuses.contains(status),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedStatuses.add(status);
                        } else {
                          _selectedStatuses.remove(status);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  child: Text(  Provider.of<LocalizationService>(context, listen: false).getLocalizedString('cancel')),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('ok')),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _fetchPayments();
                    setState(() {}); // Update the state to reflect changes
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

    Widget _buildPaymentRecordsList() {
    return _paymentRecords.isEmpty
        ? Center(child: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('noRecordsFound')))
        : ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _paymentRecords.length,
      itemBuilder: (context, index) {
        return _buildPaymentRecordItem(_paymentRecords[index] );
      },
    );
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String formatTime(DateTime date) {
    return DateFormat('HH:mm:ss').format(date);
  }

  Widget _buildPaymentRecordItem(Payment record) {
    IconData statusIcon;
    Color statusColor;

    // Determine icon and color based on payment status
    switch (record.status.toLowerCase()) {
      case 'saved':
        statusIcon = Icons.save_rounded;
        statusColor = Color(0xFF284DA6);
        break;
      case 'confirmed':
        statusIcon = Icons.sync_problem_outlined;
        statusColor = Colors.blue;
        break;
      case 'synced':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;

        break;
      case 'cancelled':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      case 'canceldpending':
        statusIcon = Icons.payment;
        statusColor = Colors.red;

        break;
      default:
        statusIcon = Icons.payment;
        statusColor = Color(0xFFC62828); // Default color
        break;
    }

    return Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 3.w),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
    child: Theme(
    data: ThemeData(dividerColor: Colors.transparent),
    child: ExpansionTile(
    leading: CircleAvatar(
    backgroundColor: Colors.white,
    child: Icon(statusIcon, color: statusColor, size: 26),
    ),
    title:    Text(
      record.customerName,
      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
      maxLines: 2, // Allow a maximum of 2 lines
      overflow: TextOverflow.ellipsis, // Show '...' if it exceeds 2 lines
      softWrap: true, // Allow wrapping to next line
    ),
    subtitle: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString(record.status.toLowerCase()),
    style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
    childrenPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
    children: [
      if (record.status.toLowerCase() != 'saved' && record.status.toLowerCase() != 'confirmed')
        _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('voucherNumber'), record.voucherSerialNumber),

      if(record.status.toLowerCase() == 'saved') ...[
    _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('transactionDate'), formatDate((record.lastUpdatedDate!)).toString()),
      _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('transactionTime'), formatTime((record.lastUpdatedDate!)).toString())
    ]
      else ...[
    _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('transactionDate'), formatDate(record.transactionDate!).toString()),
      _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('transactionTime'), formatTime((record.transactionDate!)).toString())

    ],

    _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('paymentMethod'),Provider.of<LocalizationService>(context, listen: false).getLocalizedString(record.paymentMethod.toLowerCase()) ),
    _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('status'), Provider.of<LocalizationService>(context, listen: false).getLocalizedString(record.status.toLowerCase())),
    if (record.msisdn != null && record.msisdn!.isNotEmpty)
    _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('MSISDN'), record.msisdn.toString()),
    if (record.prNumber != null && record.prNumber!.isNotEmpty)
    _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('PR'), record.prNumber.toString()),
    if (record.paymentMethod.toLowerCase() == 'cash')
    _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('amount'), record.amount.toString()),
    if (record.paymentMethod.toLowerCase() == 'check')
    _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('amount'), record.amountCheck.toString()),
      _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('currency'), record.currency.toString()),
      if (record.paymentMethod.toLowerCase() == 'check')
    _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('checkNumber'), record.checkNumber.toString()),
    if (record.paymentMethod.toLowerCase() == 'check')
    _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('bankBranchCheck'), record.bankBranch.toString()),
    if (record.paymentMethod.toLowerCase() == 'check')
    _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('dueDateCheck'), _formatDate(record.dueDateCheck)),
      if(record.status.toLowerCase() == 'canceldpending' || record.status.toLowerCase() == 'cancelled' ) ...[
        _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('cancellationDate'), formatDate((record.cancellationDate!)).toString()),
        _paymentDetailRow(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('cancellationTime'), formatTime((record.cancellationDate!)).toString()),
        _detailNoteItem(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('cancelReason'), (record.cancelReason!),Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode),
      //lll
      ],
      if (record.paymentInvoiceFor != null && record.paymentInvoiceFor!.isNotEmpty)
        _detailNoteItem(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('paymentInvoiceFor'), record.paymentInvoiceFor.toString(),Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode),
    SizedBox(height: 10.h),
      Wrap(
        spacing: 8.0, // Add some spacing between the items
        runSpacing: 8.0, // Spacing between rows if they wrap
        children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Tooltip(
                  message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('viewPayment'),
                  child: IconButton(
                    icon: Icon(Icons.visibility, color: Colors.blue), // View icon always on the left
                    onPressed: () {
                      if (record.id != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentConfirmationScreen(paymentId: record.id!),
                          ),
                        );
                      } else {
                        // Handle the case when record.id is null
                        print('Error: record.id is null');
                      }
                    },
                  ),
                ),
                if (record.status.toLowerCase() == 'synced')
                Tooltip(
                  message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('openAsPdf'),
                  child: IconButton(
                    icon: FaIcon(FontAwesomeIcons.filePdf, color: Colors.red ,size: 22,),
                    onPressed: () async{
                      ShareScreenOptions.showLanguageSelectionAndShare(context,record.id!,ShareOption.OpenPDF);
                    },
                  ),
                ),
              ],
            ),
            // Icons to be shown based on status
            Row(children: [
              if (record.status.toLowerCase() == 'saved') ...[
                Row(
                  children: [
                    Tooltip(
                      message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('deletePayment'),
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          CustomPopups.showCustomDialog(
                            context: context,
                            icon: Icon(Icons.delete, size: 60, color: Colors.red),
                            title: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('deletePayment'),
                            message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('deletePaymentBody'),
                            deleteButtonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('delete'),
                            onPressButton: () async {
                              final int id = record.id!;
                              await DatabaseProvider.deletePayment(id);
                              _fetchPayments();
                              setState(() {
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Tooltip(
                      message:Provider.of<LocalizationService>(context, listen: false).getLocalizedString('editPayment') ,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Color(0xFFA67438),size: 22),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => RecordPaymentScreen(id: record.id)),
                          );
                        },
                      ),
                    ),
                    Tooltip(
                      message:Provider.of<LocalizationService>(context, listen: false).getLocalizedString('confirmPayment') ,
                      child: IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.green,size: 22),
                        onPressed: () async {
                          CustomPopups.showCustomDialog(
                            context: context,
                            icon: Icon(Icons.check_circle, size: 50, color: Colors.red), // Customize your icon as needed
                            title: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('confirmPayment'),
                            message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('confirmPaymentBody'),
                            deleteButtonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('confirm'),
                            onPressButton: () async {
                              if (record.id != null) {
                                Map<String, String?> credentials = await getCredentials();
                                String? username = credentials['username'];
                                String? password = credentials['password'];
                                print("the username and password to relogin is :${username} : ${password}");
                                final int idToConfirm = record.id!;
                                await DatabaseProvider.updatePaymentStatus(idToConfirm, 'Confirmed');
                                await PaymentService.syncPayments(context);
        
                                // Ensure that the syncSubscription is properly set up
                                _syncSubscription = PaymentService.syncStream.listen((_) {
                                  _fetchPayments(); // Refresh payment records
                                  for (Payment p in _paymentRecords) {
                                    print("name: ${p.customerName} : status : ${p.status}");
                                  }
                                  setState(() {}); // Ensure the UI is updated
                                });
                              }
                            },
                          );
        
                        },
                      ),
                    ),
                  ],
                ),
              ] else if (record.status.toLowerCase() == 'synced') ...[
                Row(
                  children: [
                    Tooltip(
                      message:Provider.of<LocalizationService>(context, listen: false).getLocalizedString('cancelPayment') ,
        
                      child: IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red,size: 22),
                        onPressed: () async {
                          if (record.id != null) {
                            final int idToCancel = record.id!;
        
                            final bool result = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return PaymentCancellationScreen(id: idToCancel);
                              },
                            ) ?? false; // Default to false if dialog is dismissed
        
                            if (result) {
                              await PaymentService.syncPayments(context);
                              _fetchPayments();
                              setState(() {});
                            }
                          }
                        },
                      ),
                    ),
                    Tooltip(
                      message:Provider.of<LocalizationService>(context, listen: false).getLocalizedString('sendPrinter') ,
                      child: IconButton(
                        icon: Icon(Icons.print, color: Colors.black,size: 22),
                        onPressed: (){
                          ShareScreenOptions.showLanguageSelectionAndShare(context, record.id!,ShareOption.print);
                        },
                      ),
                    ),
                    Tooltip(
                      message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('sendEmail'),
                      child:IconButton(
                        icon: Icon(Icons.email,  color: Colors.blue,size: 22,
                        ),
                        onPressed: () async{
                          var connectivityResult = await (Connectivity().checkConnectivity());
                          if(connectivityResult.toString() == '[ConnectivityResult.none]'){
                            CustomPopups.showLoginFailedDialog(context, Provider.of<LocalizationService>(context, listen: false).getLocalizedString("noInternet"), Provider.of<LocalizationService>(context, listen: false).isLocalizationLoaded ?  Provider.of<LocalizationService>(context, listen: false).getLocalizedString('noInternetConnection')
                                : 'No Internet Connection',  Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode);
                          }
                          else
                            ShareScreenOptions.showLanguageSelectionAndShare(context, record.id!,ShareOption.sendEmail);
                        },
                      ),),
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
                            size: 22,
                          ),
                          onPressed: () async{
                            var connectivityResult = await (Connectivity().checkConnectivity());
                            if(connectivityResult.toString() == '[ConnectivityResult.none]'){
                              CustomPopups.showLoginFailedDialog(context, Provider.of<LocalizationService>(context, listen: false).getLocalizedString("noInternet"), Provider.of<LocalizationService>(context, listen: false).isLocalizationLoaded ?  Provider.of<LocalizationService>(context, listen: false).getLocalizedString('noInternetConnection')
                                  : 'No Internet Connection',  Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode);
                            }
                            else
                              ShareScreenOptions.showLanguageSelectionAndShare(context, record.id!,ShareOption.sendSms);
        
                          },
                        )
                    ),
                    Tooltip(
                      message:Provider.of<LocalizationService>(context, listen: false).getLocalizedString('sharePayment') ,
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.green,size: 22,),
                        onPressed: () async{
                          var connectivityResult = await (Connectivity().checkConnectivity());
                          if(connectivityResult.toString() == '[ConnectivityResult.none]'){
                            CustomPopups.showLoginFailedDialog(context, Provider.of<LocalizationService>(context, listen: false).getLocalizedString("noInternet"), Provider.of<LocalizationService>(context, listen: false).isLocalizationLoaded ?  Provider.of<LocalizationService>(context, listen: false).getLocalizedString('noInternetConnection')
                                : 'No Internet Connection',  Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode);
                          }
                          else
                            ShareScreenOptions.showLanguageSelectionAndShare(context, record.id!,ShareOption.sendWhats);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ])
        
          ],
        ),]
      ),
    ],
    onExpansionChanged: (bool expanded) {
    // Optionally add analytics or state management hooks here
    },
    ),
    ),);
  }

  Widget _paymentDetailRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14.sp,fontWeight: FontWeight.w400,color: Colors.grey.shade500)),
          Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _detailNoteItem(String title, String value, String locale) {
    // Determine if the locale is RTL
    bool isRtl = locale == 'ar'; // Assuming 'ar' is the locale for Arabic

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Expanded(
            flex: 2,
            child: Align(
              alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                title,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade500,
                  // Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.0),
          // Value
          Expanded(
            flex: 3,
            child: Align(
              alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
              child: Text(
                value,
                textAlign: isRtl ? TextAlign.left : TextAlign.right,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

