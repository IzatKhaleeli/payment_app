import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants.dart';
import 'custom_date_field.dart';

typedef DateSelectedCallback = void Function(DateTime date);

class PaymentFilterSection extends StatelessWidget {
  final double scale;
  final TextEditingController fromController;
  final TextEditingController toController;
  final DateSelectedCallback onFromDateSelected;
  final DateSelectedCallback onToDateSelected;
  final VoidCallback onFilterPressed;
  final String fromLabel;
  final String toLabel;

  const PaymentFilterSection({
    Key? key,
    required this.scale,
    required this.fromController,
    required this.toController,
    required this.onFromDateSelected,
    required this.onToDateSelected,
    required this.onFilterPressed,
    required this.fromLabel,
    required this.toLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: CustomDateField(
              scale: scale,
              label: fromLabel,
              controller: fromController,
              onDateSelected: onFromDateSelected,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: CustomDateField(
              scale: scale,
              label: toLabel,
              controller: toController,
              onDateSelected: onToDateSelected,
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            height: 40.h,
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list, color: Colors.white),
              onPressed: onFilterPressed,
            ),
          ),
        ],
      ),
    );
  }
}
