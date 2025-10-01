import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Services/LocalizationService.dart';
import 'required_fields_indicator.dart';

class ExpandableSection extends StatelessWidget {
  final double scale;
  final String title;
  final IconData iconData;
  final List<Widget> children;
  final bool Function() checkIfFilled;
  final LocalizationService localizationService;

  const ExpandableSection({
    super.key,
    required this.scale,
    required this.title,
    required this.iconData,
    required this.children,
    required this.checkIfFilled,
    required this.localizationService,
  });

  @override
  Widget build(BuildContext context) {
    bool isFilled = checkIfFilled();
    Color iconColor = isFilled ? const Color(0xFF4CAF50) : Colors.grey[600]!;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 3.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, size: 24 * scale, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'NotoSansUI',
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...children,
                const SizedBox(height: 10),
                RequiredFieldsIndicator(
                  scale: scale,
                  localizationService: localizationService,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
