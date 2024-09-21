import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/LocalizationService.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../Services/PaymentService.dart';
import '../Services/database.dart';

class PaymentCancellationScreen extends StatefulWidget {
  final int id;

  PaymentCancellationScreen({required this.id});

  @override
  _PaymentCancellationScreenState createState() => _PaymentCancellationScreenState();
}

class _PaymentCancellationScreenState extends State<PaymentCancellationScreen> {
  final TextEditingController _reasonController = TextEditingController();
  String? _errorText;
  bool _isLoading = false; // For loading indicator


  Future<Map<String, dynamic>?> _fetchPayment(int id) async {
    final payment = await DatabaseProvider.getPaymentById(id);
    return payment;
  }

  void _handleCancellation(BuildContext context, Map<String, dynamic> paymentToCancel, ) async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _errorText = '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('reasonCancellation')} ${Provider.of<LocalizationService>(context, listen: false).getLocalizedString('isRequired')}';
      });
    } else {
      setState(() {
        _errorText = null;
        _isLoading = true; // Show loading indicator

      });
      // Show a loading indicator
      await PaymentService.cancelPayment(paymentToCancel, reason,context);
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchPayment(widget.id),
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
                  Provider.of<LocalizationService>(context, listen: false).getLocalizedString('cancelPayment'),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${ Provider.of<LocalizationService>(context, listen: false).getLocalizedString('voucherNumber')}: ${paymentToCancel["voucherNumber"]}',
                  style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                ),
                SizedBox(height: 16.h),
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getLocalizedString('reasonCancellation'),
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString('enterTheReasonHere'),
                    fillColor: Color(0xFFF2F2F2),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    errorText: _errorText,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();

                      },
                      child: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('cancel'), style: TextStyle(fontSize: 16.sp)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFC62828),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _handleCancellation(context, paymentToCancel);
                      },
                      child: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('submit'), style: TextStyle(fontSize: 16.sp)),
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
    _reasonController.dispose();
    super.dispose();
  }
}
