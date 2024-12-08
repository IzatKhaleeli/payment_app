// record_payment_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../Services/LocalizationService.dart';

class RecordPaymentWidgets {
  // Static method for Deposit Checkbox
  static Widget buildDepositCheckbox({
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
    bool required = false,
    required BuildContext context
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 16.w),
      child: CheckboxListTile(
        title: Text(
          Provider.of<LocalizationService>(context, listen: false).getLocalizedString('deposit'),
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.black,
          ),
        ),
        value: isChecked,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.platform,  // Adjust checkbox position
        activeColor: Color(0xFFC62828),  // Checkbox color when checked
        checkColor: Colors.white,  // Color of the check mark
        contentPadding: EdgeInsets.zero,  // Remove padding for a compact look
      ),
    );
  }

}
