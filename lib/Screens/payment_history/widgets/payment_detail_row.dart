import 'package:flutter/material.dart';

class PaymentDetailRow extends StatelessWidget {
  final double scale;
  final String title;
  final String value;

  const PaymentDetailRow({
    super.key,
    required this.scale,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.0 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
