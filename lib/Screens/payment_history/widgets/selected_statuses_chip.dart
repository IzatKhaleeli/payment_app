import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Services/LocalizationService.dart';

class SelectedFiltersSummary extends StatelessWidget {
  final double scale;
  final int statusCount;
  final int cancellationCount;
  final VoidCallback? onClearStatus;
  final VoidCallback? onClearAcceptance;
  final VoidCallback? onClearCancellation;

  const SelectedFiltersSummary({
    Key? key,
    required this.scale,
    required this.statusCount,
    required this.cancellationCount,
    this.onClearStatus,
    this.onClearAcceptance,
    this.onClearCancellation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);

    final items = <Map<String, dynamic>>[
      {
        "label": localizationService.getLocalizedString("status"),
        "count": statusCount,
        "onClear": onClearStatus,
      },
      {
        "label": localizationService.getLocalizedString("cancellationStatus"),
        "count": cancellationCount,
        "onClear": onClearCancellation,
      },
    ];

    return Wrap(
      spacing: 8.0,
      children: items.where((item) => item["count"] > 0).map((item) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${item['label']} (${item['count']} ${localizationService.getLocalizedString('selected')})",
                style: TextStyle(
                  fontSize: 12.0 * scale,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 6.0),
              if (item['onClear'] != null)
                GestureDetector(
                  onTap: item['onClear'],
                  child: Icon(
                    Icons.close,
                    size: 16.0,
                    color: Colors.grey[700],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
