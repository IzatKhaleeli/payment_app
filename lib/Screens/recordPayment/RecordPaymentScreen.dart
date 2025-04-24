import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Custom_Widgets/CustomPopups.dart';
import '../../Models/Bank.dart';
import '../../Models/Currency.dart';
import '../../Services/database.dart';
import 'package:provider/provider.dart';
import '../../Utils/DecimalInputFormatter.dart';
import '../PaymentConfirmationScreen.dart';
import '../../Models/Payment.dart';
import '../../Services/LocalizationService.dart';
import 'package:intl/intl.dart';
import 'record_payment_widgets.dart' as record_widgets;
import 'package:flutter/services.dart';

class RecordPaymentScreen extends StatefulWidget {
  final int? id;
  final Map<String, dynamic>? paymentParams; // Add the optional parameter

  RecordPaymentScreen({this.id, this.paymentParams}); // Update the constructor

  @override
  _RecordPaymentScreenState createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _msisdnController = TextEditingController();
  final TextEditingController _prNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amountCheckController = TextEditingController();
  final TextEditingController _checkNumberController = TextEditingController();
  final TextEditingController _dueDateCheckController = TextEditingController();
  final TextEditingController _paymentInvoiceForController = TextEditingController();
  final FocusNode _customerNameFocusNode = FocusNode();
  final FocusNode _msisdnFocusNode = FocusNode();
  final FocusNode _prNumberFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _amountCheckFocusNode = FocusNode();
  final FocusNode _checkNumberFocusNode = FocusNode();
  final FocusNode _dueDateCheckFocusNode = FocusNode();
  final FocusNode _paymentInvoiceForNode = FocusNode();
  String? _selectedPaymentMethod='';
  List<String> _paymentMethods = ['cash', 'check'];
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;
  bool isDepositChecked = false;

  String? _selectedCurrencyDB;
  List<Currency> _currenciesDB = [];

  String? _selectedBankDB;
  List<Bank> _banksDB = [];

  String recordPayment = "";
  String customerDetails = "";
  String paymentInformation = "";
  String confirmPayment = "";
  String savePayment = "";
  String currency = "";
  String amount = "";
  String amountCheck = "";
  String checkNumber = "";
  String bankBranchCheck = "";
  String dueDateCheck = "";
  String paymentMethod = "";
  String customerName = "";
  String fieldsMissedMessageError = "";
  String fieldsMissedMessageSuccess = "";
  String paymentInvoiceFor = "";
  String PR = "";
  String MSISDN = "";
  String cash = "";
  String check = "";
  String requiredFields="";

  Future<void> _loadCurrencies() async {
    try {
      // Fetch the currency data from the database
      List<Map<String, dynamic>> currencyMaps = await DatabaseProvider.getAllCurrencies();

      // Convert the list of maps to a list of Currency objects
      List<Currency> currencies = currencyMaps.map((map) => Currency.fromMap(map)).toList();
      // Print raw data from database
      setState(() {
        _currenciesDB = currencies;
      });

    } catch (e) {
      print('Error loading currencies: $e');
    }
  }

  Future<void> _loadBanks() async {
    try {
      // Fetch the bank data from the database
      List<Map<String, dynamic>> bankMaps = await DatabaseProvider.getAllBanks();

      // Convert the list of maps to a list of Bank objects
      List<Bank> banks = bankMaps.map((map) => Bank.fromMap(map)).toList();

      // Store the list of banks in the state
      setState(() {
        _banksDB = banks;
      });

    } catch (e) {
      print('Error loading banks: $e');
    }
  }


  @override
  void initState() {
    print(widget.id);
    super.initState();
    _initializeLocalizationStrings();
    _initializeFields();
    _loadCurrencies();
    _loadBanks();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  void _initializeLocalizationStrings(){
    final localizationService =
    Provider.of<LocalizationService>(context, listen: false);
    requiredFields = localizationService.getLocalizedString('requiredFields');
    recordPayment = localizationService.getLocalizedString('recordPayment');
    customerDetails = localizationService.getLocalizedString('customerDetails');
    paymentInformation = localizationService.getLocalizedString('paymentInformation');
    savePayment = localizationService.getLocalizedString('savePayment');
    confirmPayment = localizationService.getLocalizedString('confirmPayment');
    paymentMethod = localizationService.getLocalizedString('paymentMethod');
    currency = localizationService.getLocalizedString('currency');
    amount = localizationService.getLocalizedString('amount');
    amountCheck = localizationService.getLocalizedString('amountCheck');
    checkNumber = localizationService.getLocalizedString('checkNumber');
    bankBranchCheck = localizationService.getLocalizedString('bankBranchCheck');
    dueDateCheck = localizationService.getLocalizedString('dueDateCheck');
    customerName = localizationService.getLocalizedString('customerName');
    fieldsMissedMessageError =
        localizationService.getLocalizedString('fieldsMissedMessageError');
    fieldsMissedMessageSuccess =
        localizationService.getLocalizedString('fieldsMissedMessageSuccess');
    PR = localizationService.getLocalizedString('PR');
    MSISDN = localizationService.getLocalizedString('MSISDN');
    cash = localizationService.getLocalizedString('cash');
    check = localizationService.getLocalizedString('check');
    paymentInvoiceFor = localizationService.getLocalizedString('paymentInvoiceFor');
    // Localize and ensure unique values
    _paymentMethods = _paymentMethods
        .map((method) => localizationService.getLocalizedString(method))
        .toSet()
        .toList();
  }

  void _initializeFields() async {
    if (widget.id != null) {
      print("the id from parameter not null ");
      int id = widget.id!; // Ensure id is not null
      Map<String, dynamic>? paymentToEdit = await DatabaseProvider.getPaymentById(id);
      print("the paymentToEdit from db is :${paymentToEdit} ");
      if (paymentToEdit != null) {
        Payment payment = Payment.fromMap(paymentToEdit);
        print(" the payment to edit after parse is :${payment}");
          setState(() {
            _selectedPaymentMethod = cash;
            _selectedCurrencyDB=payment.currency;

          });
          if (payment.paymentMethod == "Check") {
          setState(() {
            _selectedPaymentMethod = check;
            _selectedCurrencyDB=payment.currency;
            _selectedBankDB=payment.bankBranch;
          });
        }
        _customerNameController.text = payment.customerName;
        _msisdnController.text = payment.msisdn ?? '';
        _prNumberController.text = payment.prNumber?? '' ;
        _amountController.text = payment.amount.toString()?? '';
        _amountCheckController.text = payment.amountCheck.toString()?? '';
        _checkNumberController.text = payment.checkNumber.toString()?? '';
        _paymentInvoiceForController.text = payment.paymentInvoiceFor?? '';
        _dueDateCheckController.text = payment.dueDateCheck.toString()?? '';

      } else {
        print('No payment found with ID $id');
      }
    }

    if (widget.paymentParams != null) {
      print("the paymentParams from parameter not null ");
      Map<String, dynamic> paymentParams = widget.paymentParams!; // Ensure id is not null
      if (paymentParams != null) {
        print("check1");
        setState(() {
          _selectedPaymentMethod = cash;
          _selectedCurrencyDB=paymentParams["currency"];
        });
        print("check2");

        if (paymentParams["paymentMethod"] == "Check") {
          setState(() {
            _selectedPaymentMethod = check;
            _selectedCurrencyDB=paymentParams["currency"];
            _selectedBankDB=paymentParams["bankBranch"];
          });
        }

        _customerNameController.text = paymentParams["customerName"];

        _msisdnController.text = paymentParams["msisdn"]?? '';

        _prNumberController.text = paymentParams["prNumber"]?? '' ;

        _amountController.text = paymentParams["amount"].toString()?? '';

        _amountCheckController.text = paymentParams["amountCheck"].toString()?? '';

        _checkNumberController.text = paymentParams["checkNumber"].toString()?? '';

        _paymentInvoiceForController.text = paymentParams["paymentInvoiceFor"]?? '';

        _dueDateCheckController.text = paymentParams["dueDateCheck"].toString()?? '';

        isDepositChecked = paymentParams["isDepositChecked"] == 0 ? false :true ;
        print("isDepositChecked initialzation :${isDepositChecked}");

      }
    }

    else {
      _selectedPaymentMethod=cash;
    }
  }
  @override
  void dispose() {
    _animationController.dispose();
    _customerNameController.dispose();
    _msisdnController.dispose();
    _prNumberController.dispose();
    _amountController.dispose();
    _amountCheckController.dispose();
    _checkNumberController.dispose();
    _dueDateCheckController.dispose();
    _paymentInvoiceForController.dispose();

    _customerNameFocusNode.dispose();
    _msisdnFocusNode.dispose();
    _prNumberFocusNode.dispose();
    _amountFocusNode.dispose();
    _amountCheckFocusNode.dispose();
    _checkNumberFocusNode.dispose();
    _dueDateCheckFocusNode.dispose();
    _paymentInvoiceForNode.dispose();
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
        title: Text(recordPayment,
            style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontFamily: 'NotoSansUI')),
        backgroundColor: Color(0xFFC62828),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(15.w),
          child: Column(
            children: [
              _buildExpandableSection(
                title: customerDetails,
                iconData: Icons.account_circle,
                children: [
                  _buildTextField(
                    _customerNameController,
                    customerName,
                    Icons.person_outline,
                    focusNode: _customerNameFocusNode,
                      required:true,
                  ),
                  _buildTextField(
                    _msisdnController,
                    MSISDN,
                    Icons.phone_android,
                    focusNode: _msisdnFocusNode,
                      isNumeric : true,
                      required:true
                  ),
                  _buildTextField(
                    _prNumberController,
                    PR,
                    Icons.numbers_sharp,
                    focusNode: _prNumberFocusNode,
                      isNumeric : true
                  ),
                ],
                checkIfFilled: () {
                  return _customerNameController.text.isNotEmpty;
                },
              ),
              _buildExpandableSection(
                title: paymentInformation,
                iconData: Icons.payment,
                children: [
                  //
                  _buildDropdown(paymentMethod, _paymentMethods,required: true),
                  if (_selectedPaymentMethod == cash)
                    ...[
                      _buildTextField(
                        _amountController,
                        amount, null ,
                        focusNode: _amountFocusNode,
                          required:true,
                          isNumeric : true,
                          isDecimal: true
                      ),
                      _buildDropdownCurrencyDynamic(currency, _currenciesDB,Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode, required: true),
                    ],

                  if (_selectedPaymentMethod == check)
                    ...[
                      _buildTextField(
                        _amountCheckController,
                        amountCheck,
                        null ,
                        focusNode: _amountCheckFocusNode,
                          required:true,
                          isNumeric : true,
                          isDecimal: true
                      ),
                      _currenciesDB.isEmpty
                          ? Center(child: CircularProgressIndicator()):
                      _buildDropdownCurrencyDynamic(currency, _currenciesDB,Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode, required: true),
                      _buildTextField(
                        _checkNumberController,
                        checkNumber,
                        Icons.receipt_long_outlined,
                        focusNode: _checkNumberFocusNode,
                          required:true,
                          isNumeric : true
                      ),
                      _buildDropdownBankDynamic(bankBranchCheck, _banksDB,Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode, required: true),
                      _buildTextField(
                        _dueDateCheckController,
                        dueDateCheck,
                        Icons.date_range_outlined,
                        focusNode: _dueDateCheckFocusNode,
                          isDate: true,
                          required:true
                      ),
                    ],
                  record_widgets.RecordPaymentWidgets.buildDepositCheckbox(
                    isChecked: isDepositChecked,  // Bind to the state variable
                    onChanged: (newValue) {
                      setState(() {
                        isDepositChecked = newValue ?? false;  // Update the state variable
                      });
                    },
                    required: true,
                    context: context ,  // Optional, mark as required if needed
                  ),
                  _buildTextField(
                    _paymentInvoiceForController,
                    paymentInvoiceFor,
                    Icons.receipt,
                    maxLines: 3,
                    focusNode: _paymentInvoiceForNode,
                  ),
                ],
                checkIfFilled: () {
                  if (_selectedPaymentMethod == cash) {
                    return _amountController.text.isNotEmpty &&
                        _selectedCurrencyDB != null;
                  } else if (_selectedPaymentMethod == check) {
                    return _amountCheckController.text.isNotEmpty &&
                        _checkNumberController.text.isNotEmpty &&
                        _dueDateCheckController.text.isNotEmpty && _selectedCurrencyDB != null && _selectedBankDB != null;

                  }
                  return false;
                },
              ),
              Row(
                children: [
                  // Expanded(child: _buildSaveButton()), // Takes full width
                  // SizedBox(width: 16.w), // Adjust spacing between buttons
                  Expanded(child: _buildConfirmedButton()), // Takes full width
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData iconData,
    required List<Widget> children,
    required bool Function() checkIfFilled,
  }) {
    bool isFilled = checkIfFilled();
    Color iconColor = isFilled ? Color(0xFF4CAF50) : Colors.grey[600]!;
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 3.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, size: 22.sp, color: iconColor),
                SizedBox(width: 10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'NotoSansUI',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...children,
                SizedBox(height: 8.h),
                _buildRequiredFieldsIndicator(checkIfFilled),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredFieldsIndicator(bool Function() checkIfFilled) {
    return Row(
      children: [
        Text(
          '* ',
          style: TextStyle(color: Colors.red),
        ),
        Text(
          requiredFields,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }


  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        controller.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  Widget _buildTextField(
      TextEditingController controller,
      String labelText,
      IconData? icon, {
        int maxLines = 1,
        required FocusNode focusNode,
        bool required = false,
        bool isDate = false,
        bool isNumeric = false,
        bool isDecimal = false, // New flag to handle decimal input
      }) {
    // Add a listener for numeric and decimal inputs
    if (isDecimal) {
      print("amount validators");
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: labelText,
              style: TextStyle(
                fontFamily: 'NotoSansUI',
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
              children: <TextSpan>[
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12.sp,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4), // Adjust spacing between label and text field
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            readOnly: isDate,
            keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            inputFormatters: isDecimal
                ? [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), // Allow digits and dot
              DecimalInputFormatter(), // Ensure proper handling of decimal inputs
            ]   : null,
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Icon(icon, color: Color(0xFFC62828)),
              )
                  : null,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Color(0xFFC62828),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            style: TextStyle(fontSize: 14.sp, color: Colors.black),
            onTap: isDate ? () => _selectDate(context, controller) : null,
          ),
        ],
      ),
    );
  }


  Widget _buildDropdown(String label, List<String> items, {bool required = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontFamily: 'NotoSansUI',
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
              children: <TextSpan>[
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12.sp,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4), // Adjust spacing between label and dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Color(0xFFC62828),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            value: _selectedPaymentMethod,
            onChanged: (String? newValue) {
              setState(() {
                _selectedPaymentMethod = newValue;
                _clearPaymentMethodFields(); // Clear fields when payment method changes
              });
            },
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCurrencyDynamic(
      String label,
      List<Currency> items,
      String languageCode, {
        bool required = false,
      }) {
    // Find the Currency object with the id matching _selectedCurrencyDB

    Currency? initialCurrency;
    if (_selectedCurrencyDB != null && items.isNotEmpty) {
      initialCurrency = items.firstWhere(
            (currency) => currency.id == _selectedCurrencyDB,

      );
    }
    else if (items.any((currency) => currency.id == 'ILS')) {
      initialCurrency = items.firstWhere((currency) => currency.id == 'ILS');
      if (initialCurrency != null) {
        setState(() {
          _selectedCurrencyDB = 'ILS';
        });
      }
      print("check21");

    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontFamily: 'NotoSansUI',
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
              children: <TextSpan>[
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12.sp,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4), // Adjust spacing between label and dropdown
          DropdownButtonFormField<Currency>(
            value: initialCurrency, // Set the initial value
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Color(0xFFC62828),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (Currency? newValue) {
              setState(() {
                _selectedCurrencyDB = newValue?.id;
              });
            },
            items: items.map<DropdownMenuItem<Currency>>((Currency currency) {
              return DropdownMenuItem<Currency>(
                value: currency,
                child: Text(
                  languageCode == 'ar' ? currency.arabicName! : currency.englishName!,
                  style: TextStyle(
                    fontSize: 12.sp,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownBankDynamic(
      String label,
      List<Bank> items,
      String languageCode, {
        bool required = false,
      }) {
    // Find the Bank object with the id matching _selectedBankDB
    Bank? initialBank;
    if (items.isEmpty) {
      // Handle the empty case, e.g., show a message or return a default value
      return DropdownButton<String>(
        items: [],
        onChanged: null, // Disable the dropdown if there are no banks
      );
    }
    if (_selectedBankDB != null) {
      initialBank = items.firstWhere(
            (bank) => bank.id == _selectedBankDB,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontFamily: 'NotoSansUI',
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
              children: <TextSpan>[
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12.sp,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 4), // Adjust spacing between label and dropdown
          DropdownButtonFormField<Bank>(
            value: initialBank, // Set the initial value
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Color(0xFFC62828),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (Bank? newValue) {
              setState(() {
                _selectedBankDB = newValue?.id;
              });
            },
            items: items.map<DropdownMenuItem<Bank>>((Bank bank) {
              return DropdownMenuItem<Bank>(
                value: bank,
                child: Text(
                  languageCode == 'ar' ? bank.arabicName! : bank.englishName!,
                  style: TextStyle(
                    fontSize: 12.sp,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _validateFields() {
    String isRequired =Provider.of<LocalizationService>(context, listen: false).getLocalizedString('isRequired');
    String mustContainOnlyNumber =Provider.of<LocalizationService>(context, listen: false).getLocalizedString('mustContainOnlyNumber');
    String invalidMSISDN = Provider.of<LocalizationService>(context, listen: false).getLocalizedString('invalidMSISDN');
    String maxLengthExceeded = Provider.of<LocalizationService>(context, listen: false).getLocalizedString('maxLengthExceeded');

    // Validate customer name
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('customerName')} ${isRequired}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_msisdnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('MSISDN')} ${isRequired}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    else if (!_msisdnController.text.isEmpty && _msisdnController.text.length != 10){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(maxLengthExceeded),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Validate payment method
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('paymentMethod')} ${isRequired}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Validate msisdn
    final msisdnRegex = RegExp(r'^05\d{8}$');
    if (_msisdnController.text.isNotEmpty) {
      if (!msisdnRegex.hasMatch(_msisdnController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(invalidMSISDN),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    if (_prNumberController.text.isNotEmpty) {
      if (!RegExp(r'^[0-9]+$').hasMatch(_prNumberController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('PR')} ${mustContainOnlyNumber}'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    // Validate based on selected payment method
    if (_selectedPaymentMethod == cash) {
      // Validate amount for cash payment
      if (_amountController.text.isEmpty || _selectedCurrencyDB == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fieldsMissedMessageError),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      // Validate amount format (accepts decimal numbers)
      if (double.tryParse(_amountController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('invalidAmount')),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } else if (_selectedPaymentMethod == check) {
      // Validate fields for check payment
      if (_amountCheckController.text.isEmpty ||
          _checkNumberController.text.isEmpty ||
          _selectedBankDB == null ||
          _dueDateCheckController.text.isEmpty) {
        print(_selectedBankDB);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fieldsMissedMessageError),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // Validate amount check format (accepts decimal numbers)
      if (double.tryParse(_amountCheckController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('invalidAmount')),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // Validate check number (only numeric characters)
      if (!RegExp(r'^[0-9]*$').hasMatch(_checkNumberController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('checkNumber')} ${mustContainOnlyNumber}'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    return true;
  }

  Widget _buildConfirmedButton() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        child: ScaleTransition(
          scale: _buttonScaleAnimation,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC62828),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _confirmPayment,
              child: Text(
                confirmPayment,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontFamily: 'NotoSansUI'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        child: ScaleTransition(
          scale: _buttonScaleAnimation,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC62828),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _savePayment,
              child: Text(
                savePayment,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontFamily: 'NotoSansUI'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmPayment() {
    if (!_validateFields()) return;
    Payment paymentDetails = _preparePaymentObject('Confirmed');
    CustomPopups.showCustomDialog(
      context: context,
      icon: Icon(Icons.check_circle, size: 60.0, color: Color(0xFFC62828)),
      title: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('confirmPayment'),
      message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('confirmPaymentBody'),
      deleteButtonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('ok'),
      onPressButton: ()  {

      // Convert the instance to a map
      Map<String, dynamic> paymentMap = paymentDetails.toMap();
      // Print all keys and values
      paymentMap.forEach((key, value) {
        print('$key: $value');
      });
      _agreedPayment(paymentDetails);
    },
    );

    print("_confirmPayment method finished");

  }

  void _savePayment() {
    if (!_validateFields()) return;
    Payment paymentDetails = _preparePaymentObject('Saved');
    print("aa");
    CustomPopups.showCustomDialog(
      context: context,
      icon: Icon(Icons.warning, size: 60.0, color: Color(0xFFC62828)),
      message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('savePaymentBody'),
      deleteButtonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('ok'),
      title: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('savePayment'),
      onPressButton: ()  {
        print("dd");

        _agreedPayment(paymentDetails);
        print("ff");

      },);
  }

  Payment _preparePaymentObject(String status) {
    DateTime? parseDueDate;
    if (_selectedPaymentMethod!.toLowerCase() == 'cash' || _selectedPaymentMethod!.toLowerCase() == 'كاش') {
      if ([_customerNameController.text, _amountController.text, _selectedCurrencyDB, _selectedPaymentMethod]
          .any((element) => element == null || element.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fieldsMissedMessageError),
            backgroundColor: Colors.red,
          ),
        );
        return Payment(customerName: '', paymentMethod: '', status: '',isDepositChecked: 0);
      }
    }
    else if (_selectedPaymentMethod!.toLowerCase() == 'check' || _selectedPaymentMethod!.toLowerCase() == 'شيك') {
      if ([_customerNameController.text, _selectedPaymentMethod, _amountCheckController.text,
        _checkNumberController.text, _selectedBankDB,_selectedCurrencyDB, _dueDateCheckController.text]
          .any((element) => element == null || element.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fieldsMissedMessageError),
            backgroundColor: Colors.red,
          ),
        );
        return Payment(customerName: '', paymentMethod: '', status: '', isDepositChecked: 0,);
      }

      if (_selectedPaymentMethod!.toLowerCase() == 'check' || _selectedPaymentMethod!.toLowerCase() == 'شيك') {
        if (_dueDateCheckController.text.isNotEmpty) {
          parseDueDate = DateFormat('yyyy-MM-dd').parse(_dueDateCheckController.text);
        }
      }

    }
    Payment paymentDetail= Payment(
      customerName: _customerNameController.text,
      msisdn: _msisdnController.text.isNotEmpty?_msisdnController.text: null,
      prNumber: _prNumberController.text!,
      paymentMethod: _selectedPaymentMethod!,
      amount: _selectedPaymentMethod!.toLowerCase() == 'cash' ||_selectedPaymentMethod!.toLowerCase() == 'كاش'? double.tryParse(_amountController.text) : null,
      currency: _selectedCurrencyDB,
      paymentInvoiceFor: _paymentInvoiceForController.text.length>0?_paymentInvoiceForController.text:null,
      amountCheck: _selectedPaymentMethod!.toLowerCase() == 'check'||_selectedPaymentMethod!.toLowerCase() == 'شيك' ? double.tryParse(_amountCheckController.text) : null,
      checkNumber: _selectedPaymentMethod!.toLowerCase() == 'check' ||_selectedPaymentMethod!.toLowerCase() == 'شيك'?  int.tryParse(_checkNumberController.text) : null,
      bankBranch: _selectedPaymentMethod!.toLowerCase() == 'check' ||_selectedPaymentMethod!.toLowerCase() == 'شيك'? _selectedBankDB : null,
      dueDateCheck: parseDueDate , // Formatting the date
      id:widget.id !=null ? widget.id : null,
      status: status,
      isDepositChecked:isDepositChecked == false ? 0:1
    );
    return paymentDetail;
  }

  void _agreedPayment(Payment paymentDetails) async {
    showDialog( context: context,  barrierDismissible: false,  builder: (BuildContext dialogContext) {
      return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Simulate a network request/waiting time
    await Future.delayed(Duration(seconds: 2));
    int idPaymentStored;
    try{
      if(paymentDetails.paymentMethod == "كاش") {
        paymentDetails.paymentMethod = 'Cash';
      }
      else if(paymentDetails.paymentMethod == "شيك"){
        paymentDetails.paymentMethod = 'Check';
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? usernameLogin = prefs.getString('usernameLogin');
      print("the user created is ${usernameLogin}");
      if(paymentDetails.id == null)
      {

        print("no id , create new payment ");
        idPaymentStored= await DatabaseProvider.savePayment({
          'userId': usernameLogin!.toLowerCase(),
          'customerName': paymentDetails.customerName,
          'paymentMethod': paymentDetails.paymentMethod,
          'status':paymentDetails.status,
          'msisdn': paymentDetails.msisdn,
          'prNumber': paymentDetails.prNumber,
          'amount': paymentDetails.amount ,
          'currency':  paymentDetails.currency,
          'amountCheck':  paymentDetails.amountCheck,
          'checkNumber':  paymentDetails.checkNumber,
          'bankBranch': paymentDetails.bankBranch ,
          'dueDateCheck':  paymentDetails.dueDateCheck.toString(),
          'paymentInvoiceFor': paymentDetails.paymentInvoiceFor ,
          'isDepositChecked':paymentDetails.isDepositChecked,
        });
         }
      else {
        print("id , update exist payment :");
        final int id = paymentDetails.id!;
        idPaymentStored=id;
        print(paymentDetails.paymentMethod);
        await DatabaseProvider.updatePayment(id, {
          'userId':usernameLogin!.toLowerCase(),
          'customerName': paymentDetails.customerName,
          'paymentMethod': paymentDetails.paymentMethod,
          'status': paymentDetails.status,
          'msisdn': paymentDetails.msisdn,
          'prNumber': paymentDetails.prNumber,
          'amount': paymentDetails.amount,
          'currency': paymentDetails.currency,
          'amountCheck': paymentDetails.amountCheck,
          'checkNumber': paymentDetails.checkNumber,
          'bankBranch': paymentDetails.bankBranch,
          'dueDateCheck': paymentDetails.dueDateCheck.toString(),
          'paymentInvoiceFor': paymentDetails.paymentInvoiceFor,
          'isDepositChecked':paymentDetails.isDepositChecked,
        });
      }
      print("_agreedPaymentMethodFinished");
      Navigator.pop(context); // pop the dialog
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PaymentConfirmationScreen(paymentId: idPaymentStored))); // Navigate to view payment screen after agreed
    }catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearPaymentMethodFields() {
    _amountController.clear();
    _amountCheckController.clear();
    _checkNumberController.clear();
    _dueDateCheckController.clear();
    _selectedCurrencyDB = null;
    _selectedBankDB = null;
  }

}