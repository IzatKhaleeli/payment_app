import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Models/Payment.dart';
import '../../../Services/LocalizationService.dart';

class SimplePaymentCard extends StatelessWidget {
  final Payment record;
  final double scale;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SimplePaymentCard({
    Key? key,
    required this.record,
    required this.scale,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localization =
        Provider.of<LocalizationService>(context, listen: false);
    final String currentLang = localization.selectedLanguageCode;
    final String method = (record.paymentMethod).toLowerCase();
    final bool isCheck = method == 'check';

    final String voucherLabel =
        localization.getLocalizedString('voucherNumber');
    final String checkNumberLabel =
        localization.getLocalizedString('checkNumber');
    final String amountLabel = localization.getLocalizedString('amount');
    final String currencyLabel = record.currency ?? '';

    return Directionality(
      textDirection:
          currentLang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Card(
        elevation: selected ? 6 : 2,
        margin: EdgeInsets.symmetric(vertical: 3.h, horizontal: 2.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32.w,
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) {
                      if (onTap != null) onTap!();
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.customerName,
                        style: TextStyle(
                            fontSize: 13 * scale, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$voucherLabel: ${record.voucherSerialNumber}',
                              style: TextStyle(
                                  fontSize: 12 * scale,
                                  color: Colors.grey[700]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            constraints:
                                BoxConstraints(minWidth: 48.w, maxWidth: 100.w),
                            padding: EdgeInsets.symmetric(
                                vertical: 6.h, horizontal: 8.w),
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8.r)),
                            alignment: Alignment.center,
                            child: Text(
                              (record.paymentMethod).isNotEmpty
                                  ? localization.getLocalizedString(
                                      record.paymentMethod.toLowerCase())
                                  : 'N/A',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            vertical: 8.h, horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: isCheck
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$checkNumberLabel: ${record.checkNumber ?? ''}',
                                    style: TextStyle(
                                        fontSize: 12 * scale,
                                        color: Colors.grey[700]),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    '$amountLabel: ${record.amountCheck ?? ''} ${currencyLabel.isNotEmpty ? '($currencyLabel)' : (record.currency ?? '')}',
                                    style: TextStyle(
                                        fontSize: 12 * scale,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              )
                            : Text(
                                '$amountLabel: ${record.amount ?? ''} ${currencyLabel.isNotEmpty ? '($currencyLabel)' : (record.currency ?? '')}',
                                style: TextStyle(
                                    fontSize: 12 * scale,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
