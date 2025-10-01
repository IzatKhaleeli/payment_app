import 'package:flutter/material.dart';

class DetailNoteItem extends StatelessWidget {
  final double scale;
  final String title;
  final String value;
  final String locale;

  const DetailNoteItem({
    super.key,
    required this.scale,
    required this.title,
    required this.value,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    bool isRtl = locale == 'ar'; // RTL check

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Expanded(
            flex: 2,
            child: Align(
              alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                title,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // Value
          Expanded(
            flex: 3,
            child: Align(
              alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
              child: Text(
                value,
                textAlign: isRtl ? TextAlign.left : TextAlign.right,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
