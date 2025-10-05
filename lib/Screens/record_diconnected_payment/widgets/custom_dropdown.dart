import 'package:flutter/material.dart';

import '../../../core/constants.dart';

class CustomDropdown<T> extends StatelessWidget {
  final double scale;
  final String label;
  final bool required;
  final T? value;
  final List<T> items;
  final String Function(T) itemBuilder;
  final ValueChanged<T?> onChanged;

  const CustomDropdown({
    super.key,
    required this.scale,
    required this.label,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    this.value,
    this.required = false,
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
              text: label,
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
                      color: AppColors.primaryRed,
                      fontSize: 12 * scale,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<T>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
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
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: items.isEmpty ? null : onChanged,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemBuilder(item),
                  style: TextStyle(
                    fontSize: 12 * scale,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
