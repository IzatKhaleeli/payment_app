import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';

class CustomDateField extends StatelessWidget {
  final double scale;
  final String label;
  final TextEditingController controller;
  final Function(DateTime) onDateSelected;

  const CustomDateField({
    Key? key,
    required this.scale,
    required this.label,
    required this.controller,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 11 * scale),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12 * scale),
        suffixIcon:
            const Icon(Icons.calendar_today, color: AppColors.primaryRed),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      readOnly: true,
      expands: false,
      minLines: 1,
      maxLines: null,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
          onDateSelected(picked);
        }
      },
    );
  }
}
