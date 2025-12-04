import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ooredoo_app/Screens/printerService/PrinterSettingScreen.dart';
import '../../core/api_service/status_api_service.dart';
import '../../core/constants.dart';
import '../../core/utils/enum/cancellation_status_enum.dart';
import '../PaymentCancellationScreen.dart';
import '../../Services/globalError.dart';
import '../recordPayment/RecordPaymentScreen.dart';
import '../ShareScreenOptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Services/LocalizationService.dart';
import 'package:provider/provider.dart';
import '../../Services/database.dart';
import '../../Models/Payment.dart';
import '../../Utils/Enum.dart';
import '../PaymentConfirmationScreen.dart';
import '../../Services/PaymentService.dart';
import '../../Custom_Widgets/CustomPopups.dart';
import '../printerService/iosMethods.dart' as iosPlat;
import 'widgets/detail_note_item.dart';
import 'widgets/filter_dialog.dart';
import 'widgets/payment_detail_row.dart';
import 'widgets/payment_filter_section.dart';
import 'widgets/payment_records_list.dart';
import 'widgets/selected_statuses_chip.dart';
import 'widgets/simple_payment_card.dart';

class PaymentHistoryScreen extends StatefulWidget {
  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  String paymentHistory = '';
  String from = '';
  String to = '';
  String search = '';
  late StreamSubscription _syncSubscription;
  List<String> _selectedStatuses = [];
  List<String> _selectedCancellationStatuses = [];
  List<Payment> _paymentRecords = [];
  Map<String, String> _currencies = {};
  Map<String, String> _banks = {};
  bool _editMode = false;
  Set<int> _selectedIds = {};

  List<Payment> _selectablePaymentRecords() {
    return _paymentRecords.where((p) {
      final s = p.status.toLowerCase();
      return s != 'saved' && s != 'confirmed' && s != 'rejected';
    }).toList();
  }

  Future<void> _fetchPayments() async {
    if (!mounted) return;
    if (_currencies.length < 1) {
      // print("no currency");
      List<Map<String, dynamic>> currencies =
          await DatabaseProvider.getAllCurrencies();
      String selectedCode =
          Provider.of<LocalizationService>(context, listen: false)
              .selectedLanguageCode;
      Map<String, String> currencyMap = {};
      for (var currency in currencies) {
        String id = currency["id"];
        String name = selectedCode == "ar"
            ? currency["arabicName"]
            : currency["englishName"];
        currencyMap[id] = name;
      }
      if (!mounted) return;
      setState(() {
        _currencies = currencyMap;
      });
    }
    if (_banks.length < 1) {
      List<Map<String, dynamic>> banks = await DatabaseProvider.getAllBanks();
      String selectedCode =
          Provider.of<LocalizationService>(context, listen: false)
              .selectedLanguageCode;
      Map<String, String> bankMap = {};
      for (var bank in banks) {
        String id = bank["id"];
        String name =
            selectedCode == "ar" ? bank["arabicName"] : bank["englishName"];
        bankMap[id] = name;
      }
      if (!mounted) return;
      setState(() {
        _banks = bankMap;
      });
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String usernameLogin = prefs.getString('usernameLogin') ?? 'null';
    List<Map<String, dynamic>> payments =
        await DatabaseProvider.getPaymentsWithDateFilter(
            _selectedFromDate,
            _selectedToDate,
            _selectedStatuses,
            _selectedCancellationStatuses,
            usernameLogin.toLowerCase());

    String? dueDateCheckString;
    DateTime? dueDateCheck;
    String? lastUpdatedDateString;
    DateTime? lastUpdatedDate;
    String? transactionDateString;
    DateTime? transactionDate;
    String? cancellationDateString;
    DateTime? cancellationDate;
    String serialNumber = "";
    if (mounted) {
      setState(() {
        _paymentRecords = payments.map((payment) {
          dueDateCheckString = payment['dueDateCheck'];
          lastUpdatedDateString = payment['lastUpdatedDate'];
          transactionDateString = payment['transactionDate'];
          cancellationDateString = payment['cancellationDate'];

          if (cancellationDateString != null &&
              cancellationDateString!.isNotEmpty) {
            try {
              cancellationDate = DateTime.parse(cancellationDateString!);
            } catch (e) {
              cancellationDate = null;
            }
          } else {
            cancellationDate = null;
          }

          if (payment['voucherSerialNumber'] != null)
            serialNumber = payment['voucherSerialNumber'];
          if (dueDateCheckString != null && dueDateCheckString!.isNotEmpty) {
            try {
              dueDateCheck =
                  DateFormat('yyyy-MM-dd').parse(dueDateCheckString!);
            } catch (e) {
              //print('Error parsing dueDateCheck: $dueDateCheckString');
              dueDateCheck = null;
            }
          } else {
            dueDateCheck = null;
          }
          if (lastUpdatedDateString != null &&
              lastUpdatedDateString!.isNotEmpty) {
            try {
              lastUpdatedDate = DateTime.parse(lastUpdatedDateString!);
            } catch (e) {
              //print('Error parsing dueDateCheck: $lastUpdatedDate');
              lastUpdatedDate = null;
            }
          } else {
            lastUpdatedDate = null;
          }
          if (transactionDateString != null &&
              transactionDateString!.isNotEmpty) {
            try {
              transactionDate = DateTime.parse(transactionDateString!);
            } catch (e) {
              //print('Error parsing dueDateCheck: $transactionDate');
              transactionDate = null;
            }
          } else {
            transactionDate = null;
          }
          return Payment(
            id: payment['id'],
            transactionDate: transactionDate,
            lastUpdatedDate: lastUpdatedDate,
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
            voucherSerialNumber: serialNumber,
            cancelReason: payment['cancelReason'],
            cancellationDate: cancellationDate,
            isDepositChecked: payment['isDepositChecked'],
            isDisconnected: payment['isDisconnected'],
            cancellationStatus: CancellationStatusExtension.fromString(
                payment['cancellationStatus']),
            msisdnReceipt: payment['msisdnReceipt'],
            notifyFinance: payment['notifyFinance'],
            checkApproval: payment['checkApproval'],
          );
        }).toList();
        _paymentRecords.sort((a, b) {
          // Determine the date to use for sorting for each record
          DateTime aDate =
              a.transactionDate ?? a.lastUpdatedDate ?? DateTime.now();
          DateTime bDate =
              b.transactionDate ?? b.lastUpdatedDate ?? DateTime.now();

          // Compare the dates in descending order
          return bDate.compareTo(aDate);
        });
      });
    }
  }

  Future<void> _fetchPortalStatuses() async {
    // print('_fetchPortalStatuses');
    // print('_paymentRecords ${_paymentRecords}');
    try {
      List<String> voucherSerials = _paymentRecords
          .where((payment) => payment.status.toLowerCase() == 'synced'
              // &&
              // payment.cancellationStatus == null
              )
          .map((payment) => payment.voucherSerialNumber)
          .toList();

      if (voucherSerials.isEmpty) {
        print("[]");
        return;
      }
      print("Voucher serials to fetch statuses: $voucherSerials");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? tokenID = prefs.getString('token');
      if (tokenID == null) {
        print('Token not found');
        return;
      }
      var fullToken = "Barer ${tokenID}";

      var headers = {
        'Content-Type': 'application/json',
        'tokenID': fullToken,
      };

      final response = await PaymentApiService.getPortalStatuses(
          body: voucherSerials, headers: headers);

      if (response is Map<String, dynamic>) {
        final int status = response['status'] ?? 0;
        final bool success = response['success'] ?? false;
        final dynamic data = response['data'];

        if (success && status == 200 && data is List) {
          print("Portal Statuses Response:");
          for (var item in data) {
            print(
              "Voucher: ${item['voucherSerialNumber']}, "
              "Acceptance: ${item['acceptanceStatus']}, "
              "Cancel: ${item['cancelStatus']}",
            );
          }

          await DatabaseProvider.updatePaymentsFromPortalStatus(
            List<Map<String, dynamic>>.from(data),
          );
        } else if (status == 401) {
          int tokenStatus = await PaymentService.attemptReLogin(context);
          if (tokenStatus == 200) {
            print("Token refreshed, retrying...");
            await _fetchPortalStatuses(); // retry
          } else {
            print("Unable to refresh token");
          }
        } else if (status == 408) {
          print("Request timed out");
        } else if (status == 429) {
          print("Too many requests");
        } else {
          print("Error: Status $status, Data: $data");
        }
      } else {
        print("Unexpected response format: $response");
      }
    } on SocketException {
      print("Network error occurred");
    } on TimeoutException {
      print("Request timed out");
    } catch (e) {
      print("Error fetching portal statuses: $e");
    }
  }

  void _initializeLocalizationStrings() {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    paymentHistory = localizationService.getLocalizedString('paymentHistory');
    from = localizationService.getLocalizedString('from');
    to = localizationService.getLocalizedString('to');
    search = localizationService.getLocalizedString('search');
  }

  @override
  void initState() {
    super.initState();
    _initializeLocalizationStrings();

    _fetchPayments().then((_) {
      _fetchPortalStatuses();
    });

    _syncSubscription = PaymentService.syncStream.listen((_) async {
      _fetchPayments();
    });
  }

  @override
  void dispose() {
    _syncSubscription.cancel();
    GlobalErrorNotifier.clearError();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690));
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 375).clamp(0.8, 1.3);

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
        title: !_editMode
            ? Text(paymentHistory,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 * scale,
                  fontFamily: 'NotoSansUI',
                ))
            : Builder(builder: (context) {
                final loc =
                    Provider.of<LocalizationService>(context, listen: false);
                final String selectedLabel = loc.getLocalizedString('selected');
                final String currentLang = loc.selectedLanguageCode;
                final String selectedText = currentLang == 'ar'
                    ? '$selectedLabel ${_selectedIds.length}'
                    : '${_selectedIds.length} $selectedLabel';

                return Text(
                  selectedText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * scale,
                    fontFamily: 'NotoSansUI',
                  ),
                );
              }),
        backgroundColor: AppColors.primaryRed,
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.close : Icons.check_box_outlined,
                color: Colors.white),
            onPressed: () {
              setState(() {
                if (_editMode) {
                  _editMode = false;
                  _selectedIds.clear();
                } else {
                  _editMode = true;
                }
              });
            },
          )
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _fetchPortalStatuses();
            },
            child: ListView(
              padding: EdgeInsets.all(12.w),
              children: [
                PaymentFilterSection(
                  scale: scale,
                  fromController: _fromDateController,
                  toController: _toDateController,
                  onFromDateSelected: (date) {
                    setState(() => _selectedFromDate = date);
                    _fetchPayments();
                  },
                  onToDateSelected: (date) {
                    setState(() => _selectedToDate = date);
                    _fetchPayments();
                  },
                  onFilterPressed: () {
                    showFilterDialog(
                      context: context,
                      scale: scale,
                      selectedStatuses: _selectedStatuses,
                      selectedCancellationStatuses:
                          _selectedCancellationStatuses,
                      onApply: () {
                        _fetchPayments();
                        setState(() {});
                      },
                    );
                  },
                  fromLabel: from,
                  toLabel: to,
                ),
                SelectedFiltersSummary(
                  scale: scale,
                  statusCount: _selectedStatuses.length,
                  cancellationCount: _selectedCancellationStatuses.length,
                  onClearStatus: () {
                    setState(() {
                      _selectedStatuses.clear();
                      _fetchPayments();
                    });
                  },
                  onClearCancellation: () {
                    setState(() {
                      _selectedCancellationStatuses.clear();
                      _fetchPayments();
                    });
                  },
                ),
                SizedBox(height: 10.h),
                Divider(
                  color: Colors.grey[400],
                  height: 3,
                  thickness: 2,
                  indent: 8,
                  endIndent: 8,
                ),
                SizedBox(height: 10.h),
                if (_editMode) ...[
                  Card(
                    elevation: 1,
                    margin: EdgeInsets.symmetric(vertical: 6.h),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 6.h, horizontal: 8.w),
                      child: Builder(builder: (context) {
                        final loc = Provider.of<LocalizationService>(context,
                            listen: false);
                        final String lang = loc.selectedLanguageCode;
                        final bool hasSelection = _selectedIds.isNotEmpty;

                        final Widget whatsappBtn = IconButton(
                          icon: FaIcon(FontAwesomeIcons.whatsapp,
                              color: Colors.green),
                          onPressed: hasSelection
                              ? () {
                                  ShareScreenOptions
                                      .showLanguageSelectionAndShare(
                                          context,
                                          _selectedIds.toList(),
                                          ShareOption.sendWhats,
                                          multiPaymentFlag: true);
                                }
                              : null,
                        );

                        final Widget pdfBtn = IconButton(
                          icon: FaIcon(FontAwesomeIcons.filePdf,
                              color: AppColors.primaryRed),
                          onPressed: hasSelection
                              ? () {
                                  ShareScreenOptions
                                      .showLanguageSelectionAndShare(
                                          context,
                                          _selectedIds.toList(),
                                          ShareOption.OpenPDF,
                                          multiPaymentFlag: true);
                                }
                              : null,
                        );

                        final Widget emailBtn = IconButton(
                          icon: Icon(Icons.email, color: Colors.blue),
                          onPressed: hasSelection
                              ? () {
                                  ShareScreenOptions
                                      .showLanguageSelectionAndShare(
                                          context,
                                          _selectedIds.toList(),
                                          ShareOption.sendEmail,
                                          multiPaymentFlag: true);
                                }
                              : null,
                        );

                        List<Widget> leftChildren;
                        List<Widget> rightChildren;

                        if (lang == 'ar') {
                          leftChildren = [
                            whatsappBtn,
                            SizedBox(width: 8.w),
                            emailBtn
                          ];
                          rightChildren = [pdfBtn];
                        } else {
                          leftChildren = [pdfBtn];
                          rightChildren = [
                            whatsappBtn,
                            SizedBox(width: 8.w),
                            emailBtn
                          ];
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: leftChildren,
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: rightChildren,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
                SizedBox(height: 10.h),
                Container(
                  margin: EdgeInsets.only(bottom: 50.h),
                  child: PaymentRecordsList(
                    scale: scale,
                    paymentRecords: (() {
                      if (!_editMode) return _paymentRecords;

                      // In edit mode: base list
                      final base = _selectablePaymentRecords();

                      // If nothing selected yet, show base list
                      if (_selectedIds.isEmpty) return base;

                      // Determine the transaction date and msisdn of the first selected payment
                      final int firstId = _selectedIds.first;
                      Payment? firstPayment;
                      try {
                        firstPayment =
                            _paymentRecords.firstWhere((p) => p.id == firstId);
                      } catch (e) {
                        firstPayment = null;
                      }

                      final DateTime? firstDate = firstPayment?.transactionDate;
                      final String? firstMsisdn = firstPayment?.msisdn;
                      if (firstDate == null) return base;

                      // If first msisdn is null/empty, fall back to date-only filtering.
                      final bool requireMsisdn =
                          firstMsisdn != null && firstMsisdn.trim().isNotEmpty;

                      // Return only payments that share the same Y/M/D (and msisdn when available)
                      return base.where((p) {
                        final d = p.transactionDate;
                        if (d == null) return false;
                        final bool sameDate = d.year == firstDate.year &&
                            d.month == firstDate.month &&
                            d.day == firstDate.day;
                        if (!sameDate) return false;
                        if (!requireMsisdn) return true;
                        final String? ms = p.msisdn;
                        if (ms == null) return false;
                        return ms.trim() == firstMsisdn.trim();
                      }).toList();
                    })(),
                    itemBuilder: (scale, record) {
                      final bool isSelected =
                          record.id != null && _selectedIds.contains(record.id);
                      if (_editMode) {
                        return SimplePaymentCard(
                          record: record,
                          scale: scale,
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              if (record.id == null) return;

                              // If there is at least one selected id, enforce matching
                              // transaction date and msisdn silently (no SnackBar).
                              if (_selectedIds.isNotEmpty) {
                                final int firstId = _selectedIds.first;
                                Payment? firstPayment;
                                try {
                                  firstPayment = _paymentRecords
                                      .firstWhere((p) => p.id == firstId);
                                } catch (e) {
                                  firstPayment = null;
                                }

                                final DateTime? firstDate =
                                    firstPayment?.transactionDate;
                                final String? firstMsisdn =
                                    firstPayment?.msisdn;

                                // If we can't determine first date, allow toggle
                                if (firstDate == null) {
                                  if (_selectedIds.contains(record.id))
                                    _selectedIds.remove(record.id);
                                  else
                                    _selectedIds.add(record.id!);
                                  return;
                                }

                                final d = record.transactionDate;
                                if (d == null) return;
                                final bool sameDate =
                                    d.year == firstDate.year &&
                                        d.month == firstDate.month &&
                                        d.day == firstDate.day;

                                final bool requireMsisdn =
                                    firstMsisdn != null &&
                                        firstMsisdn.trim().isNotEmpty;

                                if (!sameDate) return;

                                if (requireMsisdn) {
                                  final ms = record.msisdn;
                                  if (ms == null) return;
                                  if (ms.trim() != firstMsisdn.trim()) return;
                                }

                                if (_selectedIds.contains(record.id))
                                  _selectedIds.remove(record.id);
                                else
                                  _selectedIds.add(record.id!);
                              } else {
                                if (_selectedIds.contains(record.id))
                                  _selectedIds.remove(record.id);
                                else
                                  _selectedIds.add(record.id!);
                              }
                            });
                          },
                          onLongPress: () {},
                        );
                      }
                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _editMode = true;
                            if (record.id != null) _selectedIds.add(record.id!);
                          });
                        },
                        child: _buildPaymentRecordItem(scale, record),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<String?>(
            valueListenable: GlobalErrorNotifier.errorTextNotifier,
            builder: (context, errorText, _) {
              if (errorText == null) return SizedBox.shrink();

              return Positioned(
                bottom: 60,
                left: 8,
                right: 8,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.primaryRed,
                  child: ListTile(
                    title: Text(
                      errorText,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        GlobalErrorNotifier.clearError();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RecordPaymentScreen()));
            },
            backgroundColor: AppColors.primaryRed,
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 24 * scale,
            ),
          ),
        ),
      ),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return ''; // handle null date
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String formatTime(DateTime date) {
    return DateFormat('HH:mm:ss').format(date);
  }

  Widget _buildPaymentRecordItem(double scale, Payment record) {
    IconData statusIcon;
    Color statusColor;

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
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusIcon = Icons.cancel;
        statusColor = AppColors.primaryRed;
        break;
      case 'canceldpending':
        statusIcon = Icons.payment;
        statusColor = AppColors.primaryRed;
        break;
      case 'accepted':
        statusIcon = Icons.check_circle;
        statusColor = Colors.blue;
        break;
      case 'rejected':
        statusIcon = Icons.cancel;
        statusColor = AppColors.primaryRed;
        break;
      case 'completed':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      default:
        statusIcon = Icons.payment;
        statusColor = AppColors.primaryRed;
        break;
    }

    // print("Building payment ${record}");
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
          title: Row(
            children: [
              Expanded(
                child: Text(
                  record.customerName,
                  style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
              SizedBox(width: 8),
              Text(
                formatDate(record.transactionDate!).toString(),
                style: TextStyle(
                    fontSize: 14 * scale, color: Colors.grey.shade600),
              ),
            ],
          ),
          subtitle: Text(
              "${record.amount != null ? record.amount.toString() : record.amountCheck.toString()} ${record.currency!.toLowerCase()}",
              style:
                  TextStyle(fontSize: 12 * scale, color: Colors.grey.shade600)),
          childrenPadding:
              EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
          children: [
            if (record.status.toLowerCase() != 'saved' &&
                record.status.toLowerCase() != 'confirmed')
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('voucherNumber'),
                value: record.voucherSerialNumber,
              ),
            if (record.status.toLowerCase() == 'saved') ...[
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('transactionDate'),
                value: record.lastUpdatedDate != null
                    ? formatDate(record.lastUpdatedDate!).toString()
                    : '',
              ),
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('transactionTime'),
                value: record.lastUpdatedDate != null
                    ? formatTime(record.lastUpdatedDate!).toString()
                    : '',
              ),
            ] else ...[
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('transactionDate'),
                value: record.transactionDate != null
                    ? formatDate(record.transactionDate!).toString()
                    : '',
              ),
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('transactionTime'),
                value: record.transactionDate != null
                    ? formatTime(record.transactionDate!).toString()
                    : '',
              ),
            ],
            PaymentDetailRow(
              scale: scale,
              title: Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString('paymentMethod'),
              value: Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString(record.paymentMethod.toLowerCase()),
            ),
            PaymentDetailRow(
              scale: scale,
              title: Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString('status'),
              value: Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString(record.status.toLowerCase()),
            ),
            if (record.msisdn != null && record.msisdn!.isNotEmpty)
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('MSISDN'),
                value: record.msisdn?.toString() ?? '',
              ),
            if (record.isDisconnected == 1) ...[
              DetailNoteItem(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('isDisconnected'),
                value: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString(
                  record.isDisconnected == 0 ? 'no' : 'yes',
                ),
                locale: Provider.of<LocalizationService>(context, listen: false)
                    .selectedLanguageCode,
              ),
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('msisdn_receipt'),
                value: record.msisdnReceipt?.toString() ?? '',
              ),
            ], //
            if (record.prNumber != null && record.prNumber!.isNotEmpty)
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('PR'),
                value: record.prNumber?.toString() ?? '',
              ),
            if (record.paymentMethod.toLowerCase() == 'cash')
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('amount'),
                value: record.amount?.toString() ?? '',
              ),
            if (record.paymentMethod.toLowerCase() == 'check')
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('amount'),
                value: record.amountCheck?.toString() ?? '',
              ),
            PaymentDetailRow(
              scale: scale,
              title: Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString('currency'),
              value: record.currency?.toString() ?? '',
            ),
            if (record.paymentMethod.toLowerCase() == 'check') ...[
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('checkNumber'),
                value: record.checkNumber?.toString() ?? '',
              ),
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('bankBranchCheck'),
                value: record.bankBranch?.toString() ?? '',
              ),
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('dueDateCheck'),
                value: record.dueDateCheck != null
                    ? formatDate(record.dueDateCheck!)
                    : '',
              ),
            ],
            if (record.cancellationStatus != null)
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('cancellationStatus'),
                value: record.cancellationStatus != null
                    ? Provider.of<LocalizationService>(context, listen: false)
                        .getLocalizedString(record.cancellationStatus!.value)
                    : Provider.of<LocalizationService>(context, listen: false)
                        .getLocalizedString('notSelectedYet'),
              ),
            if (record.cancellationDate != null) ...[
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('cancellationDate'),
                value: record.cancellationDate != null
                    ? formatDate(record.cancellationDate!).toString()
                    : '',
              ),
              PaymentDetailRow(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('cancellationTime'),
                value: record.cancellationDate != null
                    ? formatTime(record.cancellationDate!).toString()
                    : '',
              ),
              DetailNoteItem(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('cancelReason'),
                value: record.cancelReason?.toString() ?? '',
                locale: Provider.of<LocalizationService>(context, listen: false)
                    .selectedLanguageCode,
              ),
            ],
            DetailNoteItem(
              scale: scale,
              title: Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString('deposit'),
              value: Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString(
                record.isDepositChecked == 0 ? 'no' : 'yes',
              ),
              locale: Provider.of<LocalizationService>(context, listen: false)
                  .selectedLanguageCode,
            ),
            DetailNoteItem(
              scale: scale,
              title: Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString('checkApproval'),
              value: Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString(
                record.checkApproval == 0 ? 'no' : 'yes',
              ),
              locale: Provider.of<LocalizationService>(context, listen: false)
                  .selectedLanguageCode,
            ),
            DetailNoteItem(
              scale: scale,
              title: Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString('notifyFinance'),
              value: Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString(
                record.notifyFinance == 0 ? 'no' : 'yes',
              ),
              locale: Provider.of<LocalizationService>(context, listen: false)
                  .selectedLanguageCode,
            ),

            if (record.paymentInvoiceFor != null &&
                record.paymentInvoiceFor!.isNotEmpty)
              DetailNoteItem(
                scale: scale,
                title: Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('paymentInvoiceFor'),
                value: record.paymentInvoiceFor?.toString() ?? '',
                locale: Provider.of<LocalizationService>(context, listen: false)
                    .selectedLanguageCode,
              ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Tooltip(
                          message: Provider.of<LocalizationService>(context,
                                  listen: false)
                              .getLocalizedString('viewPayment'),
                          child: IconButton(
                            icon: Icon(Icons.visibility, color: Colors.blue),
                            onPressed: () {
                              if (record.id != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PaymentConfirmationScreen(
                                            paymentId: record.id!),
                                  ),
                                );
                              } else {
                                // Handle the case when record.id is null
                                print('Error: record.id is null');
                              }
                            },
                          ),
                        ),
                        if (record.status.toLowerCase() == 'synced' ||
                            record.status.toLowerCase() == 'completed' ||
                            record.status.toLowerCase() == 'rejected')
                          Tooltip(
                            message: Provider.of<LocalizationService>(context,
                                    listen: false)
                                .getLocalizedString('openAsPdf'),
                            child: IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.filePdf,
                                color: AppColors.primaryRed,
                                size: 22,
                              ),
                              onPressed: () async {
                                ShareScreenOptions
                                    .showLanguageSelectionAndShare(context,
                                        [record.id!], ShareOption.OpenPDF);
                              },
                            ),
                          ),
                      ],
                    ),
                    Row(children: [
                      if (record.status.toLowerCase() == 'synced' &&
                          record.cancellationStatus == null) ...[
                        Row(
                          children: [
                            Tooltip(
                              message: Provider.of<LocalizationService>(context,
                                      listen: false)
                                  .getLocalizedString('cancelPayment'),
                              child: IconButton(
                                icon: Icon(Icons.cancel,
                                    color: AppColors.primaryRed, size: 22),
                                onPressed: () async {
                                  if (record.id != null) {
                                    final int idToCancel = record.id!;

                                    final bool result = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return PaymentCancellationScreen(
                                                id: idToCancel);
                                          },
                                        ) ??
                                        false; // Default to false if dialog is dismissed

                                    if (result == true) {
                                      // If cancellation was successful, refresh the payment details
                                      _fetchPayments();
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ]),
                    Row(children: [
                      if (record.status.toLowerCase() != 'saved' &&
                          record.status.toLowerCase() != 'confirmed' &&
                          record.status.toLowerCase() != 'rejected') ...[
                        Row(
                          children: [
                            Tooltip(
                              message: Provider.of<LocalizationService>(context,
                                      listen: false)
                                  .getLocalizedString('sendPrinter'),
                              child: IconButton(
                                icon: Icon(Icons.print,
                                    color: Colors.black, size: 22),
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
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
                                          size: 40,
                                          color: AppColors.primaryRed),
                                      message: Provider.of<LocalizationService>(
                                              context,
                                              listen: false)
                                          .getLocalizedString(
                                              'noDefaultDeviceSetBody'),
                                      firstButtonText:
                                          Provider.of<LocalizationService>(
                                                  context,
                                                  listen: false)
                                              .getLocalizedString('cancel'),
                                      onFirstButtonPressed: () {
                                        // Handle cancel action
                                        print('Cancel button pressed');
                                      },
                                      secondButtonText:
                                          Provider.of<LocalizationService>(
                                                  context,
                                                  listen: false)
                                              .getLocalizedString(
                                                  "printerSettings"),
                                      onSecondButtonPressed: () {
                                        // Handle confirm action
                                        print('Confirm button pressed');
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PrinterSettingScreen(),
                                          ),
                                        );
                                      },
                                    );
                                  } else {
                                    if (Platform.isIOS) {
                                      bool isBluetoothOn =
                                          await iosPlat.BluetoothService
                                              .isBluetoothPoweredOn();
                                      if (!isBluetoothOn) {
                                        CustomPopups.showCustomResultPopup(
                                          context: context,
                                          icon: Icon(Icons.error,
                                              color: AppColors.primaryRed,
                                              size: 40),
                                          message:
                                              Provider.of<LocalizationService>(
                                                      context,
                                                      listen: false)
                                                  .getLocalizedString(
                                                      "bluetooth_off_message"),
                                          buttonText:
                                              Provider.of<LocalizationService>(
                                                      context,
                                                      listen: false)
                                                  .getLocalizedString("ok"),
                                          onPressButton: () {
                                            // Define what happens when the button is pressed
                                            print(
                                                'bluetooth is not powered ..');
                                            return;
                                          },
                                        );
                                      } else
                                        ShareScreenOptions
                                            .showLanguageSelectionAndShare(
                                                context,
                                                record.id!,
                                                ShareOption.print);
                                    } else if (Platform.isAndroid) {
                                      ShareScreenOptions
                                          .showLanguageSelectionAndShare(
                                              context,
                                              record.id!,
                                              ShareOption.print);
                                    }
                                  }
                                },
                              ),
                            ),
                            Tooltip(
                              message: Provider.of<LocalizationService>(context,
                                      listen: false)
                                  .getLocalizedString('sendEmail'),
                              child: IconButton(
                                icon: Icon(
                                  Icons.email,
                                  color: Colors.blue,
                                  size: 22,
                                ),
                                onPressed: () async {
                                  var connectivityResult = await (Connectivity()
                                      .checkConnectivity());
                                  if (connectivityResult.toString() ==
                                      '[ConnectivityResult.none]') {
                                    CustomPopups.showLoginFailedDialog(
                                        context,
                                        Provider.of<LocalizationService>(
                                                context,
                                                listen: false)
                                            .getLocalizedString("noInternet"),
                                        Provider.of<LocalizationService>(
                                                    context,
                                                    listen: false)
                                                .isLocalizationLoaded
                                            ? Provider.of<LocalizationService>(
                                                    context,
                                                    listen: false)
                                                .getLocalizedString(
                                                    'noInternetConnection')
                                            : 'No Internet Connection',
                                        Provider.of<LocalizationService>(
                                                context,
                                                listen: false)
                                            .selectedLanguageCode);
                                  } else
                                    ShareScreenOptions
                                        .showLanguageSelectionAndShare(
                                            context,
                                            [record.id!],
                                            ShareOption.sendEmail);
                                },
                              ),
                            ),
                            Tooltip(
                                message: Provider.of<LocalizationService>(
                                        context,
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
                                    color: Colors
                                        .green, // Set the color of the icon here
                                    size: 22,
                                  ),
                                  onPressed: () async {
                                    var connectivityResult =
                                        await (Connectivity()
                                            .checkConnectivity());
                                    if (connectivityResult.toString() ==
                                        '[ConnectivityResult.none]') {
                                      CustomPopups.showLoginFailedDialog(
                                          context,
                                          Provider.of<LocalizationService>(
                                                  context,
                                                  listen: false)
                                              .getLocalizedString("noInternet"),
                                          Provider.of<LocalizationService>(
                                                      context,
                                                      listen: false)
                                                  .isLocalizationLoaded
                                              ? Provider.of<
                                                          LocalizationService>(
                                                      context,
                                                      listen: false)
                                                  .getLocalizedString(
                                                      'noInternetConnection')
                                              : 'No Internet Connection',
                                          Provider.of<LocalizationService>(
                                                  context,
                                                  listen: false)
                                              .selectedLanguageCode);
                                    } else
                                      ShareScreenOptions
                                          .showLanguageSelectionAndShare(
                                              context,
                                              record.id!,
                                              ShareOption.sendSms);
                                  },
                                )),
                            Tooltip(
                              message: Provider.of<LocalizationService>(context,
                                      listen: false)
                                  .getLocalizedString('sharePayment'),
                              child: IconButton(
                                icon: FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Colors.green,
                                  size: 22,
                                ),
                                onPressed: () async {
                                  var connectivityResult = await (Connectivity()
                                      .checkConnectivity());
                                  if (connectivityResult.toString() ==
                                      '[ConnectivityResult.none]') {
                                    CustomPopups.showLoginFailedDialog(
                                        context,
                                        Provider.of<LocalizationService>(
                                                context,
                                                listen: false)
                                            .getLocalizedString("noInternet"),
                                        Provider.of<LocalizationService>(
                                                    context,
                                                    listen: false)
                                                .isLocalizationLoaded
                                            ? Provider.of<LocalizationService>(
                                                    context,
                                                    listen: false)
                                                .getLocalizedString(
                                                    'noInternetConnection')
                                            : 'No Internet Connection',
                                        Provider.of<LocalizationService>(
                                                context,
                                                listen: false)
                                            .selectedLanguageCode);
                                  } else
                                    ShareScreenOptions
                                        .showLanguageSelectionAndShare(
                                            context,
                                            [record.id!],
                                            ShareOption.sendWhats);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ])
                  ],
                ),
              ],
            ),
          ],
          onExpansionChanged: (bool expanded) {
            // Optionally add analytics or state management hooks here
          },
        ),
      ),
    );
  }

  Widget buildPaymentActions({
    required BuildContext context,
    required dynamic record, // replace `dynamic` with your record type
    required VoidCallback fetchPayments,
    required bool mounted,
  }) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);

    if (record.status.toLowerCase() != 'saved') {
      return const SizedBox.shrink(); // Return empty widget if not 'saved'
    }

    return Row(
      children: [
        // Delete Button
        Tooltip(
          message: localizationService.getLocalizedString('deletePayment'),
          child: IconButton(
            icon: const Icon(Icons.delete, color: AppColors.primaryRed),
            onPressed: () async {
              CustomPopups.showCustomDialog(
                context: context,
                icon: const Icon(Icons.delete,
                    size: 60, color: AppColors.primaryRed),
                title: localizationService.getLocalizedString('deletePayment'),
                message:
                    localizationService.getLocalizedString('deletePaymentBody'),
                deleteButtonText:
                    localizationService.getLocalizedString('delete'),
                onPressButton: () async {
                  final int id = record.id!;
                  await DatabaseProvider.deletePayment(id);
                  fetchPayments();
                },
              );
            },
          ),
        ),

        // Edit Button
        Tooltip(
          message: localizationService.getLocalizedString('editPayment'),
          child: IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFFA67438), size: 22),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RecordPaymentScreen(id: record.id),
                ),
              );
            },
          ),
        ),

        // Confirm Button
        Tooltip(
          message: localizationService.getLocalizedString('confirmPayment'),
          child: IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 22),
            onPressed: () async {
              CustomPopups.showCustomDialog(
                context: context,
                icon: const Icon(Icons.check_circle,
                    size: 50, color: AppColors.primaryRed),
                title: localizationService.getLocalizedString('confirmPayment'),
                message: localizationService
                    .getLocalizedString('confirmPaymentBody'),
                deleteButtonText:
                    localizationService.getLocalizedString('confirm'),
                onPressButton: () async {
                  if (record.id != null) {
                    final int idToConfirm = record.id!;
                    await DatabaseProvider.updatePaymentStatus(
                        idToConfirm, 'Confirmed');
                    await PaymentService.syncPayments(context);

                    // Listen to sync stream
                    _syncSubscription = PaymentService.syncStream.listen((_) {
                      if (!mounted) return;
                      fetchPayments();
                    });
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
