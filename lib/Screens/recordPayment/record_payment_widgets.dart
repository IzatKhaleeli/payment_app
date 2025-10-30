import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Services/LocalizationService.dart';
import '../../core/constants.dart';

class RecordPaymentWidgets {
  // Static method for Deposit Checkbox
  static Widget buildDepositCheckbox(
      {required double scale,
      required bool isChecked,
      required ValueChanged<bool?> onChanged,
      bool required = false,
      required BuildContext context,
      required String titleKey}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: CheckboxListTile(
        title: Text(
          Provider.of<LocalizationService>(context, listen: false)
              .getLocalizedString(titleKey),
          style: TextStyle(
            fontSize: 12 * scale,
            color: Colors.grey[500],
          ),
        ),
        value: isChecked,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.platform,
        activeColor: AppColors.primaryRed,
        checkColor: Colors.white,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
