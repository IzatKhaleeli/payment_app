import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Utils/DecimalInputFormatter.dart';
import '../../../core/constants.dart';

class CustomTextField extends StatelessWidget {
  final double scale;
  final TextEditingController controller;
  final String labelText;
  final IconData? icon;
  final int maxLines;
  final FocusNode focusNode;
  final bool requiredField;
  final bool isDate;
  final bool isNumeric;
  final bool isDecimal;
  final Function(BuildContext, TextEditingController)? onDateTap;

  const CustomTextField({
    Key? key,
    required this.scale,
    required this.controller,
    required this.labelText,
    this.icon,
    this.maxLines = 1,
    required this.focusNode,
    this.requiredField = false,
    this.isDate = false,
    this.isNumeric = false,
    this.isDecimal = false,
    this.onDateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + Asterisk if required
          RichText(
            text: TextSpan(
              text: labelText,
              style: TextStyle(
                fontFamily: 'NotoSansUI',
                fontSize: 12 * scale,
                color: Colors.grey[500],
              ),
              children: <TextSpan>[
                if (requiredField)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 12 * scale,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          // TextField
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            readOnly: isDate,
            keyboardType: isNumeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: isDecimal
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    DecimalInputFormatter(),
                  ]
                : null,
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Icon(icon, color: AppColors.primaryRed),
                    )
                  : null,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryRed,
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
            style: TextStyle(fontSize: 14 * scale, color: Colors.black),
            onTap: isDate ? () => onDateTap?.call(context, controller) : null,
          ),
        ],
      ),
    );
  }
}
