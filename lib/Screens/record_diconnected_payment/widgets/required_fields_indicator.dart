import 'package:flutter/material.dart';

import '../../../Services/LocalizationService.dart';

class RequiredFieldsIndicator extends StatelessWidget {
  final double scale;
  final LocalizationService localizationService;

  const RequiredFieldsIndicator({
    super.key,
    required this.scale,
    required this.localizationService,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '* ',
          style: TextStyle(color: Color(0xFFC62828)),
        ),
        Text(
          localizationService.getLocalizedString('requiredFields')!,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12 * scale,
          ),
        ),
      ],
    );
  }
}
