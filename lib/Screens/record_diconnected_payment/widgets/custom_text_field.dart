import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Utils/DecimalInputFormatter.dart';

class CustomTextField extends StatelessWidget {
  final double scale;
  final TextEditingController controller;
  final String labelText;
  final IconData? icon;
  final int maxLines;
  final FocusNode focusNode;
  final bool required;
  final bool isDate;
  final bool isNumeric;
  final bool isDecimal;
  final VoidCallback? onDateTap;

  const CustomTextField({
    super.key,
    required this.scale,
    required this.controller,
    required this.labelText,
    this.icon,
    this.maxLines = 1,
    required this.focusNode,
    this.required = false,
    this.isDate = false,
    this.isNumeric = false,
    this.isDecimal = false,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: labelText,
              style: TextStyle(
                fontFamily: 'NotoSansUI',
                fontSize: 12 * scale,
                color: Colors.grey[500],
              ),
              children: <TextSpan>[
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: const Color(0xFFC62828),
                      fontSize: 12 * scale,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
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
                    if (DecimalInputFormatter != null) DecimalInputFormatter(),
                  ]
                : null,
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Icon(icon, color: const Color(0xFFC62828)),
                    )
                  : null,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFC62828),
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
            onTap: isDate ? onDateTap ?? () {} : null,
          ),
        ],
      ),
    );
  }
}
