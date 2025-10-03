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
        crossAxisAlignment: CrossAxisAlignment.start, // allow multi-line value
        children: [
          // Title
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade500,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8.0),
          // Value aligned to end
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              softWrap: true,
              textAlign: TextAlign.right, // keep at end
            ),
          ),
        ],
      ),
    );
  }
}
