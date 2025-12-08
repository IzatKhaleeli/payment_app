import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../Custom_Widgets/CustomPopups.dart';
import '../../Models/Bank.dart';
import '../../Models/CheckImage.dart';
import '../../Models/Currency.dart';
import '../../Services/database.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../PaymentConfirmationScreen.dart';
import '../../Models/Payment.dart';
import '../../Services/LocalizationService.dart';
import 'package:intl/intl.dart';
import '../recordPayment/widgets/upload_file_widget.dart';
import './widgets/record_payment_widgets.dart' as record_widgets;
import 'widgets/animated_button.dart';
import 'widgets/custom_dropdown.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/expandable_section.dart';

class RecordPaymentDisconnectedScreen extends StatefulWidget {
  final int? id;
  final Map<String, dynamic>? paymentParams;
  const RecordPaymentDisconnectedScreen({this.id, this.paymentParams});

  @override
  _RecordPaymentDisconnectedScreenState createState() =>
      _RecordPaymentDisconnectedScreenState();
}

class _RecordPaymentDisconnectedScreenState
    extends State<RecordPaymentDisconnectedScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _msisdnController = TextEditingController();
  final TextEditingController _msisdnReceiptController =
      TextEditingController();
  final TextEditingController _prNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amountCheckController = TextEditingController();
  final TextEditingController _checkNumberController = TextEditingController();
  final TextEditingController _dueDateCheckController = TextEditingController();
  final TextEditingController _paymentInvoiceForController =
      TextEditingController();
  final FocusNode _customerNameFocusNode = FocusNode();
  final FocusNode _msisdnFocusNode = FocusNode();
  final FocusNode _msisdnReceiptFocusNode = FocusNode();

  final FocusNode _prNumberFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _amountCheckFocusNode = FocusNode();
  final FocusNode _checkNumberFocusNode = FocusNode();
  final FocusNode _dueDateCheckFocusNode = FocusNode();
  final FocusNode _paymentInvoiceForNode = FocusNode();

  String? _selectedPaymentMethod = '';
  List<String> _paymentMethods = ['cash', 'check'];
  late AnimationController _animationController;
  bool isDepositChecked = false;
  bool checkApprovalFlag = false;
  bool notifyFinanceFlag = false;

  String? _selectedCurrencyDB;
  List<Currency> _currenciesDB = [];

  String? _selectedBankDB;
  List<Bank> _banksDB = [];

  List<File> selectedFiles = [];

  late Map<String, String> localizedStrings;

  Future<void> _loadCurrencies() async {
    try {
      List<Map<String, dynamic>> currencyMaps =
          await DatabaseProvider.getAllCurrencies();
      List<Currency> currencies =
          currencyMaps.map((map) => Currency.fromMap(map)).toList();
      setState(() {
        _currenciesDB = currencies;
      });
    } catch (e) {
      print('Error loading currencies: $e');
    }
  }

  Future<void> _loadBanks() async {
    try {
      List<Map<String, dynamic>> bankMaps =
          await DatabaseProvider.getAllBanks();
      List<Bank> banks = bankMaps.map((map) => Bank.fromMap(map)).toList();
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
  }

  void _initializeLocalizationStrings() {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    void _initializeLocalizationStrings() {
      final keys = [
        'file',
        'requiredFields',
        'recordPayment',
        'customerDetails',
        'paymentInformation',
        'savePayment',
        'confirmPayment',
        'paymentMethod',
        'currency',
        'amount',
        'amountCheck',
        'checkNumber',
        'bankBranchCheck',
        'dueDateCheck',
        'customerName',
        'fieldsMissedMessageError',
        'fieldsMissedMessageSuccess',
        'PR',
        'MSISDN',
        'cash',
        'check',
        'paymentInvoiceFor',
        'msisdn_receipt',
        'msisdn_payment'
      ];
      localizedStrings = {
        for (var k in keys) k: localizationService.getLocalizedString(k)
      };
    }

    _paymentMethods = _paymentMethods
        .map((method) => localizationService.getLocalizedString(method))
        .toSet()
        .toList();
  }

  void _initializeFields() async {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);

    if (widget.id != null) {
      int id = widget.id!;
      Map<String, dynamic>? paymentToEdit =
          await DatabaseProvider.getPaymentById(id);
      print("the paymentToEdit from db is :${paymentToEdit} ");
      if (paymentToEdit != null) {
        Payment payment = Payment.fromMap(paymentToEdit);
        print(" the payment to edit after parse is :${payment}");
        setState(() {
          _selectedPaymentMethod =
              localizationService.getLocalizedString('cash');
          _selectedCurrencyDB = payment.currency;
        });
        if (payment.paymentMethod == "Check") {
          setState(() {
            _selectedPaymentMethod =
                localizationService.getLocalizedString('check');
            _selectedCurrencyDB = payment.currency;
            _selectedBankDB = payment.bankBranch;
          });
        }
        _customerNameController.text = payment.customerName;
        _msisdnReceiptController.text = payment.msisdn ?? '';
        _msisdnController.text = payment.msisdn ?? '';
        _prNumberController.text = payment.prNumber ?? '';
        _amountController.text = payment.amount.toString() ?? '';
        _amountCheckController.text = payment.amountCheck.toString() ?? '';
        _checkNumberController.text = payment.checkNumber.toString() ?? '';
        _paymentInvoiceForController.text = payment.paymentInvoiceFor ?? '';
        _dueDateCheckController.text = payment.dueDateCheck.toString() ?? '';
      } else {
        print('No payment found with ID $id');
      }
    }

    if (widget.paymentParams != null) {
      print("the paymentParams from parameter not null ");
      Map<String, dynamic> paymentParams =
          widget.paymentParams!; // Ensure id is not null
      if (paymentParams != null) {
        print("check1");
        setState(() {
          _selectedPaymentMethod =
              localizationService.getLocalizedString('cash');
          _selectedCurrencyDB = paymentParams["currency"];
        });
        print("check2");

        if (paymentParams["paymentMethod"] == "Check") {
          setState(() {
            _selectedPaymentMethod =
                localizationService.getLocalizedString('check');
            _selectedCurrencyDB = paymentParams["currency"];
            _selectedBankDB = paymentParams["bankBranch"];
          });
        }

        _customerNameController.text = paymentParams["customerName"];

        _msisdnController.text = paymentParams["msisdn"] ?? '';

        _msisdnReceiptController.text = paymentParams["msisdn"] ?? '';

        _prNumberController.text = paymentParams["prNumber"] ?? '';

        _amountController.text = paymentParams["amount"].toString() ?? '';

        _amountCheckController.text =
            paymentParams["amountCheck"].toString() ?? '';

        _checkNumberController.text =
            paymentParams["checkNumber"].toString() ?? '';

        _paymentInvoiceForController.text =
            paymentParams["paymentInvoiceFor"] ?? '';

        _dueDateCheckController.text =
            paymentParams["dueDateCheck"].toString() ?? '';

        isDepositChecked =
            paymentParams["isDepositChecked"] == 0 ? false : true;
        checkApprovalFlag = paymentParams["checkApproval"] == 0 ? false : true;
        notifyFinanceFlag = paymentParams["notifyFinance"] == 0 ? false : true;
      }
    } else {
      _selectedPaymentMethod = localizationService.getLocalizedString('cash');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customerNameController.dispose();
    _msisdnController.dispose();
    _msisdnReceiptController.dispose();
    _prNumberController.dispose();
    _amountController.dispose();
    _amountCheckController.dispose();
    _checkNumberController.dispose();
    _dueDateCheckController.dispose();
    _paymentInvoiceForController.dispose();

    _customerNameFocusNode.dispose();
    _msisdnFocusNode.dispose();
    _msisdnReceiptFocusNode.dispose();
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
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 375).clamp(0.8, 1.3);
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1.0,
          ),
        ),
        title: Text(localizationService.getLocalizedString('recordPayment'),
            style: TextStyle(
                color: Colors.white,
                fontSize: 22 * scale,
                fontFamily: 'NotoSansUI')),
        backgroundColor: AppColors.primaryRed,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(15 * scale),
          child: Column(
            children: [
              ExpandableSection(
                scale: scale,
                title:
                    localizationService.getLocalizedString('customerDetails'),
                iconData: Icons.account_circle,
                localizationService: localizationService,
                checkIfFilled: () => _customerNameController.text.isNotEmpty,
                children: [
                  CustomTextField(
                    scale: scale,
                    controller: _customerNameController,
                    labelText:
                        localizationService.getLocalizedString('customerName'),
                    icon: Icons.person_outline,
                    focusNode: _customerNameFocusNode,
                    required: true,
                  ),
                  CustomTextField(
                    scale: scale,
                    controller: _msisdnController,
                    labelText: localizationService
                        .getLocalizedString('msisdn_payment'),
                    icon: Icons.phone_android,
                    focusNode: _msisdnFocusNode,
                    isNumeric: true,
                    required: true,
                  ),
                  CustomTextField(
                    scale: scale,
                    controller: _msisdnReceiptController,
                    labelText: localizationService
                        .getLocalizedString('msisdn_receipt'),
                    icon: Icons.phone_android,
                    focusNode: _msisdnReceiptFocusNode,
                    isNumeric: true,
                    required: true,
                  ),
                  CustomTextField(
                    scale: scale,
                    controller: _prNumberController,
                    labelText: localizationService.getLocalizedString('PR'),
                    icon: Icons.numbers_sharp,
                    focusNode: _prNumberFocusNode,
                    isNumeric: true,
                  ),
                ],
              ),
              ExpandableSection(
                scale: scale,
                title: localizationService
                    .getLocalizedString('paymentInformation'),
                iconData: Icons.payment,
                localizationService: localizationService,
                checkIfFilled: () {
                  if (_selectedPaymentMethod ==
                      localizationService.getLocalizedString('cash')) {
                    return _amountController.text.isNotEmpty &&
                        _selectedCurrencyDB != null;
                  } else if (_selectedPaymentMethod ==
                      localizationService.getLocalizedString('check')) {
                    return _amountCheckController.text.isNotEmpty &&
                        _checkNumberController.text.isNotEmpty &&
                        _dueDateCheckController.text.isNotEmpty &&
                        _selectedCurrencyDB != null &&
                        _selectedBankDB != null;
                  }
                  return false;
                },
                children: [
                  CustomDropdown<String>(
                    scale: scale,
                    label: localizationService.getLocalizedString('cash'),
                    required: true,
                    items: _paymentMethods,
                    value: _selectedPaymentMethod,
                    itemBuilder: (value) => value,
                    onChanged: (String? newValue) {
                      setState(() {
                        if (newValue ==
                            localizationService.getLocalizedString('cash')) {
                          checkApprovalFlag = false;
                          selectedFiles = [];
                        }
                        _selectedPaymentMethod = newValue;
                        _clearPaymentMethodFields();
                      });
                    },
                  ),
                  if (_selectedPaymentMethod ==
                      localizationService.getLocalizedString('cash')) ...[
                    CustomTextField(
                      scale: scale,
                      controller: _amountController,
                      labelText:
                          localizationService.getLocalizedString('amount'),
                      focusNode: _amountFocusNode,
                      required: true,
                      isNumeric: true,
                      isDecimal: true,
                    ),
                    CustomDropdown<Currency>(
                      scale: scale,
                      label: localizationService.getLocalizedString('currency'),
                      required: true,
                      items: _currenciesDB,
                      value: _currenciesDB.isNotEmpty &&
                              _selectedCurrencyDB != null
                          ? _currenciesDB.firstWhere(
                              (currency) => currency.id == _selectedCurrencyDB,
                              orElse: () => _currenciesDB.first,
                            )
                          : null,
                      itemBuilder: (currency) =>
                          Provider.of<LocalizationService>(context,
                                          listen: false)
                                      .selectedLanguageCode ==
                                  'ar'
                              ? currency.arabicName!
                              : currency.englishName!,
                      onChanged: (Currency? newValue) {
                        setState(() {
                          _selectedCurrencyDB = newValue?.id;
                        });
                      },
                    ),
                  ],
                  if (_selectedPaymentMethod ==
                      localizationService.getLocalizedString('check')) ...[
                    CustomTextField(
                      scale: scale,
                      controller: _amountCheckController,
                      labelText:
                          localizationService.getLocalizedString('amountCheck'),
                      focusNode: _amountCheckFocusNode,
                      required: true,
                      isNumeric: true,
                      isDecimal: true,
                    ),
                    CustomDropdown<Currency>(
                      scale: scale,
                      label: localizationService.getLocalizedString('currency'),
                      required: true,
                      items: _currenciesDB,
                      value: _currenciesDB.isNotEmpty &&
                              _selectedCurrencyDB != null
                          ? _currenciesDB.firstWhere(
                              (currency) => currency.id == _selectedCurrencyDB,
                              orElse: () => _currenciesDB.first,
                            )
                          : null,
                      itemBuilder: (currency) =>
                          Provider.of<LocalizationService>(context,
                                          listen: false)
                                      .selectedLanguageCode ==
                                  'ar'
                              ? currency.arabicName!
                              : currency.englishName!,
                      onChanged: (Currency? newValue) {
                        setState(() {
                          _selectedCurrencyDB = newValue?.id;
                        });
                      },
                    ),
                    CustomTextField(
                      scale: scale,
                      controller: _checkNumberController,
                      labelText:
                          localizationService.getLocalizedString('checkNumber'),
                      icon: Icons.receipt_long_outlined,
                      focusNode: _checkNumberFocusNode,
                      required: true,
                      isNumeric: true,
                    ),
                    CustomDropdown<Bank>(
                      scale: scale,
                      label: localizationService
                          .getLocalizedString('bankBranchCheck'),
                      required: true,
                      items: _banksDB,
                      value: _banksDB.isNotEmpty && _selectedBankDB != null
                          ? _banksDB.firstWhere(
                              (bank) => bank.id == _selectedBankDB,
                              orElse: () => _banksDB.first,
                            )
                          : null,
                      itemBuilder: (bank) => Provider.of<LocalizationService>(
                                      context,
                                      listen: false)
                                  .selectedLanguageCode ==
                              'ar'
                          ? bank.arabicName!
                          : bank.englishName!,
                      onChanged: (Bank? newValue) {
                        setState(() {
                          _selectedBankDB = newValue?.id;
                        });
                      },
                    ),
                    CustomTextField(
                      scale: scale,
                      controller: _dueDateCheckController,
                      labelText: localizationService
                          .getLocalizedString('dueDateCheck'),
                      icon: Icons.date_range_outlined,
                      focusNode: _dueDateCheckFocusNode,
                      isDate: true,
                      required: true,
                      onDateTap: () =>
                          _selectDate(context, _dueDateCheckController),
                    ),
                    UploadFileWidget(
                      fileToShow: selectedFiles,
                      scale: scale,
                      label: localizationService.getLocalizedString('file'),
                      onFilesSelected: (files) async {
                        setState(() {
                          selectedFiles = files;
                        });
                        if (files.isNotEmpty) {
                          print(
                              "Selected files: ${files.map((f) => f.path.split('/').last).join(', ')}");
                        }
                      },
                    ),
                    record_widgets.RecordPaymentWidgets.buildDepositCheckbox(
                      scale: scale,
                      isChecked: checkApprovalFlag,
                      onChanged: (newValue) {
                        setState(() {
                          checkApprovalFlag = newValue ?? false;
                        });
                      },
                      required: true,
                      context: context,
                      titleKey: 'checkApproval',
                    ),
                  ],
                  record_widgets.RecordPaymentWidgets.buildDepositCheckbox(
                    scale: scale,
                    isChecked: isDepositChecked,
                    onChanged: (newValue) {
                      setState(() {
                        isDepositChecked = newValue ?? false;
                      });
                    },
                    required: true,
                    context: context,
                    titleKey: 'deposit',
                  ),
                  record_widgets.RecordPaymentWidgets.buildDepositCheckbox(
                    scale: scale,
                    isChecked: notifyFinanceFlag,
                    onChanged: (newValue) {
                      setState(() {
                        notifyFinanceFlag = newValue ?? false;
                      });
                    },
                    required: true,
                    context: context,
                    titleKey: 'notifyFinance',
                  ),
                  CustomTextField(
                    scale: scale,
                    controller: _paymentInvoiceForController,
                    labelText: localizationService
                        .getLocalizedString('paymentInvoiceFor'),
                    icon: Icons.receipt,
                    maxLines: 3,
                    focusNode: _paymentInvoiceForNode,
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: AnimatedButton(
                      text: localizationService
                          .getLocalizedString('confirmPayment'),
                      onPressed: () => _confirmPayment(localizationService),
                      backgroundColor: AppColors.primaryRed,
                      scale: scale,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
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

  bool _validateFields(LocalizationService localizationService) {
    String isRequired = Provider.of<LocalizationService>(context, listen: false)
        .getLocalizedString('isRequired');
    String mustContainOnlyNumber =
        Provider.of<LocalizationService>(context, listen: false)
            .getLocalizedString('mustContainOnlyNumber');
    String invalidMSISDN =
        Provider.of<LocalizationService>(context, listen: false)
            .getLocalizedString('invalidMSISDN');
    String maxLengthExceeded =
        Provider.of<LocalizationService>(context, listen: false)
            .getLocalizedString('maxLengthExceeded');

    // Validate customer name
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('customerName')} ${isRequired}'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return false;
    }

    if (_msisdnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('MSISDN')} ${isRequired}'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return false;
    } else if (!_msisdnController.text.isEmpty &&
        _msisdnController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(maxLengthExceeded),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return false;
    }

    // Validate payment method
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('paymentMethod')} ${isRequired}'),
          backgroundColor: AppColors.primaryRed,
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
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return false;
      }
    }

    if (_prNumberController.text.isNotEmpty) {
      if (!RegExp(r'^[0-9]+$').hasMatch(_prNumberController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('PR')} ${mustContainOnlyNumber}'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return false;
      }
    }

    if (_selectedPaymentMethod ==
        localizationService.getLocalizedString('cash')) {
      if (_amountController.text.isEmpty || _selectedCurrencyDB == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizationService
                .getLocalizedString('fieldsMissedMessageError')),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return false;
      }
      if (double.tryParse(_amountController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('invalidAmount')),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return false;
      }
    } else if (_selectedPaymentMethod ==
        localizationService.getLocalizedString('check')) {
      if (_amountCheckController.text.isEmpty ||
          _checkNumberController.text.isEmpty ||
          _selectedBankDB == null ||
          _dueDateCheckController.text.isEmpty) {
        print(_selectedBankDB);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizationService
                .getLocalizedString('fieldsMissedMessageError')),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return false;
      }
      print("selectedFiles length is :${selectedFiles.length}");

      if (selectedFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizationService.getLocalizedString('file') +
                ' ' +
                isRequired),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return false;
      }

      if (double.tryParse(_amountCheckController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('invalidAmount')),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return false;
      }

      // Validate check number (only numeric characters)
      if (!RegExp(r'^[0-9]*$').hasMatch(_checkNumberController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('checkNumber')} ${mustContainOnlyNumber}'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return false;
      }
    }

    return true;
  }

  void _confirmPayment(LocalizationService localizationService) {
    if (!_validateFields(localizationService)) return;
    Payment paymentDetails =
        _preparePaymentObject('Confirmed', localizationService);
    print("paymymentdetails :${paymentDetails}");
    CustomPopups.showCustomDialog(
      context: context,
      icon: Icon(Icons.check_circle, size: 60.0, color: AppColors.primaryRed),
      title: Provider.of<LocalizationService>(context, listen: false)
          .getLocalizedString('confirmPayment'),
      message: Provider.of<LocalizationService>(context, listen: false)
          .getLocalizedString('confirmPaymentBody'),
      deleteButtonText: Provider.of<LocalizationService>(context, listen: false)
          .getLocalizedString('ok'),
      onPressButton: () {
        _agreedPayment(paymentDetails);
      },
    );

    print("_confirmPayment method finished");
  }

  void _savePayment(LocalizationService localizationService) {
    if (!_validateFields(localizationService)) return;
    Payment paymentDetails =
        _preparePaymentObject('Saved', localizationService);
    CustomPopups.showCustomDialog(
      context: context,
      icon: Icon(Icons.warning, size: 60.0, color: AppColors.primaryRed),
      message: Provider.of<LocalizationService>(context, listen: false)
          .getLocalizedString('savePaymentBody'),
      deleteButtonText: Provider.of<LocalizationService>(context, listen: false)
          .getLocalizedString('ok'),
      title: Provider.of<LocalizationService>(context, listen: false)
          .getLocalizedString('savePayment'),
      onPressButton: () {
        _agreedPayment(paymentDetails);
      },
    );
  }

  Payment _preparePaymentObject(
      String status, LocalizationService localizationService) {
    DateTime? parseDueDate;
    if (_selectedPaymentMethod!.toLowerCase() == 'cash' ||
        _selectedPaymentMethod!.toLowerCase() == 'كاش') {
      if ([
        _customerNameController.text,
        _amountController.text,
        _selectedCurrencyDB,
        _selectedPaymentMethod
      ].any((element) => element == null || element.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizationService
                .getLocalizedString('fieldsMissedMessageError')),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return Payment(
            customerName: '',
            paymentMethod: '',
            status: '',
            isDepositChecked: 0,
            checkApproval: 0,
            notifyFinance: 0);
      }
    } else if (_selectedPaymentMethod!.toLowerCase() == 'check' ||
        _selectedPaymentMethod!.toLowerCase() == 'شيك') {
      if ([
        _customerNameController.text,
        _selectedPaymentMethod,
        _amountCheckController.text,
        _checkNumberController.text,
        _selectedBankDB,
        _selectedCurrencyDB,
        _dueDateCheckController.text
      ].any((element) => element == null || element.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizationService
                .getLocalizedString('fieldsMissedMessageError')),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return Payment(
            customerName: '',
            paymentMethod: '',
            status: '',
            isDepositChecked: 0,
            checkApproval: 0,
            notifyFinance: 0);
      }

      if (_selectedPaymentMethod!.toLowerCase() == 'check' ||
          _selectedPaymentMethod!.toLowerCase() == 'شيك') {
        if (_dueDateCheckController.text.isNotEmpty) {
          parseDueDate =
              DateFormat('yyyy-MM-dd').parse(_dueDateCheckController.text);
        }
      }
    }
    Payment paymentDetail = Payment(
        customerName: _customerNameController.text,
        msisdn:
            _msisdnController.text.isNotEmpty ? _msisdnController.text : null,
        msisdnReceipt: _msisdnReceiptController.text.isNotEmpty
            ? _msisdnReceiptController.text
            : null,
        prNumber: _prNumberController.text!,
        paymentMethod: _selectedPaymentMethod!,
        amount: _selectedPaymentMethod!.toLowerCase() == 'cash' ||
                _selectedPaymentMethod!.toLowerCase() == 'كاش'
            ? double.tryParse(_amountController.text)
            : null,
        currency: _selectedCurrencyDB,
        paymentInvoiceFor: _paymentInvoiceForController.text.length > 0
            ? _paymentInvoiceForController.text
            : null,
        amountCheck: _selectedPaymentMethod!.toLowerCase() == 'check' ||
                _selectedPaymentMethod!.toLowerCase() == 'شيك'
            ? double.tryParse(_amountCheckController.text)
            : null,
        checkNumber: _selectedPaymentMethod!.toLowerCase() == 'check' ||
                _selectedPaymentMethod!.toLowerCase() == 'شيك'
            ? int.tryParse(_checkNumberController.text)
            : null,
        bankBranch: _selectedPaymentMethod!.toLowerCase() == 'check' ||
                _selectedPaymentMethod!.toLowerCase() == 'شيك'
            ? _selectedBankDB
            : null,
        dueDateCheck: parseDueDate, // Formatting the date
        id: widget.id != null ? widget.id : null,
        status: status,
        isDepositChecked: isDepositChecked == false ? 0 : 1,
        checkApproval: checkApprovalFlag == false ? 0 : 1,
        notifyFinance: notifyFinanceFlag == false ? 0 : 1,
        isDisconnected: 1);
    return paymentDetail;
  }

  void _agreedPayment(Payment paymentDetails) async {
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
    await Future.delayed(const Duration(seconds: 1));
    int idPaymentStored;
    try {
      if (paymentDetails.paymentMethod == "كاش") {
        paymentDetails.paymentMethod = 'Cash';
      } else if (paymentDetails.paymentMethod == "شيك") {
        paymentDetails.paymentMethod = 'Check';
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? usernameLogin = prefs.getString('usernameLogin');
      print("the user created is ${usernameLogin}");
      if (paymentDetails.id == null) {
        print("no id , create new payment ");
        idPaymentStored = await DatabaseProvider.savePayment({
          'userId': usernameLogin!.toLowerCase(),
          'customerName': paymentDetails.customerName,
          'paymentMethod': paymentDetails.paymentMethod,
          'status': paymentDetails.status,
          'msisdn': paymentDetails.msisdn,
          'msisdnReceipt': paymentDetails.msisdnReceipt,
          'prNumber': paymentDetails.prNumber,
          'amount': paymentDetails.amount,
          'currency': paymentDetails.currency,
          'amountCheck': paymentDetails.amountCheck,
          'checkNumber': paymentDetails.checkNumber,
          'bankBranch': paymentDetails.bankBranch,
          'dueDateCheck': paymentDetails.dueDateCheck.toString(),
          'paymentInvoiceFor': paymentDetails.paymentInvoiceFor,
          'isDepositChecked': paymentDetails.isDepositChecked,
          'checkApproval': paymentDetails.checkApproval,
          'notifyFinance': paymentDetails.notifyFinance,
          'isDisconnected': paymentDetails.isDisconnected,
        });
      } else {
        print("id , update exist payment :");
        final int id = paymentDetails.id!;
        idPaymentStored = id;
        print(paymentDetails.paymentMethod);
        await DatabaseProvider.updatePayment(id, {
          'userId': usernameLogin!.toLowerCase(),
          'customerName': paymentDetails.customerName,
          'paymentMethod': paymentDetails.paymentMethod,
          'status': paymentDetails.status,
          'msisdn': paymentDetails.msisdn,
          'msisdnReceipt': paymentDetails.msisdnReceipt,
          'prNumber': paymentDetails.prNumber,
          'amount': paymentDetails.amount,
          'currency': paymentDetails.currency,
          'amountCheck': paymentDetails.amountCheck,
          'checkNumber': paymentDetails.checkNumber,
          'bankBranch': paymentDetails.bankBranch,
          'dueDateCheck': paymentDetails.dueDateCheck.toString(),
          'paymentInvoiceFor': paymentDetails.paymentInvoiceFor,
          'isDepositChecked': paymentDetails.isDepositChecked,
          'checkApproval': paymentDetails.checkApproval,
          'notifyFinance': paymentDetails.notifyFinance,
          'isDisconnected': paymentDetails.isDisconnected,
        });
      }

      try {
        if (selectedFiles.isNotEmpty) {
          // Copy selected files into app documents and save filePath in DB
          final dir = await getApplicationDocumentsDirectory();
          final uuid = Uuid();
          for (var f in selectedFiles) {
            final originalName = p.basename(f.path);
            final ext = p.extension(originalName);
            final newName =
                '${DateTime.now().millisecondsSinceEpoch}_${uuid.v4()}$ext';
            final newPath = p.join(dir.path, newName);
            try {
              await f.copy(newPath);
            } catch (_) {
              // if copy fails, fallback to using original path
            }

            Uint8List bytes = Uint8List(0);
            try {
              final fileForRead = File(newPath);
              if (await fileForRead.exists()) {
                bytes = await fileForRead.readAsBytes();
              } else {
                bytes = await f.readAsBytes();
              }
            } catch (_) {
              // ignore read errors, mime will fallback
            }

            final mime =
                lookupMimeType(f.path, headerBytes: bytes) ?? 'image/jpeg';

            await DatabaseProvider.insertCheckImage({
              'paymentId': idPaymentStored,
              'fileName': originalName,
              'mimeType': mime,
              'filePath': newPath,
              'status': 'new',
            });
          }
        }
      } catch (e) {
        print('Error saving check images: $e');
      }

      print("_agreedPaymentMethodFinished");
      Navigator.pop(context);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  PaymentConfirmationScreen(paymentId: idPaymentStored)));
    } catch (e) {
      Navigator.pop(context);
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: AppColors.primaryRed, size: 40),
        message:
            '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("unexpectedError")}:\n $e',
        buttonText: Provider.of<LocalizationService>(context, listen: false)
            .getLocalizedString("ok"),
        onPressButton: () {
          print('errorSavingPayment');
        },
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
