import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Services/LocalizationService.dart';
import '../Services/database.dart';
import '../core/constants.dart';

class PaymentCancellationScreen extends StatefulWidget {
  final int id;

  PaymentCancellationScreen({required this.id});

  @override
  _PaymentCancellationScreenState createState() =>
      _PaymentCancellationScreenState();
}

class _PaymentCancellationScreenState extends State<PaymentCancellationScreen> {
  static final StreamController<void> _syncController =
      StreamController<void>.broadcast();
  static Stream<void> get syncStream => _syncController.stream;

  final TextEditingController _reasonController = TextEditingController();
  String? _errorText;
  late Future<Map<String, dynamic>?> _paymentFuture;

  Future<Map<String, dynamic>?> _fetchPayment(int id) async {
    final payment = await DatabaseProvider.getPaymentById(id);
    return payment;
  }

  @override
  void initState() {
    super.initState();
    _paymentFuture = _fetchPayment(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 375).clamp(0.8, 1.3);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _paymentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error fetching voucher number'));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('No voucher number found'));
            }

            final paymentToCancel = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Provider.of<LocalizationService>(context, listen: false)
                      .getLocalizedString('cancelPayment'),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('voucherNumber')}: ${paymentToCancel["voucherSerialNumber"]}',
                  style: TextStyle(color: Colors.grey, fontSize: 12 * scale),
                ),
                const SizedBox(height: 30),
                Text(
                  Provider.of<LocalizationService>(context, listen: false)
                      .getLocalizedString('reasonCancellation'),
                  style: TextStyle(
                      fontSize: 14 * scale, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        Provider.of<LocalizationService>(context, listen: false)
                            .getLocalizedString('enterTheReasonHere'),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    fillColor: Colors.white,
                    filled: true,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppColors.primaryRed, width: 1.5),
                    ),
                    errorText: _errorText,
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                          Provider.of<LocalizationService>(context,
                                  listen: false)
                              .getLocalizedString('cancel'),
                          style: TextStyle(fontSize: 14 * scale)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        _handleCancellation(context, paymentToCancel);
                      },
                      child: Text(
                          Provider.of<LocalizationService>(context,
                                  listen: false)
                              .getLocalizedString('submit'),
                          style: TextStyle(fontSize: 14 * scale)),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _syncController.close();
    _reasonController.dispose();
    super.dispose();
  }

  void _handleCancellation(
    BuildContext context,
    Map<String, dynamic> paymentToCancel,
  ) async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorText =
            '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('reasonCancellation')} ${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('isRequired')}';
      });
    } else {
      if (!mounted) return;
      setState(() {
        _errorText = null;
      });
      Navigator.of(context).pop(true);
      DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
      String cancelDateTime = formatter.format(DateTime.now());
      await DatabaseProvider.cancelPayment(
          paymentToCancel["voucherSerialNumber"],
          reason,
          cancelDateTime,
          'CancelPending');
      _syncController.add(null);
    }
  }
}
