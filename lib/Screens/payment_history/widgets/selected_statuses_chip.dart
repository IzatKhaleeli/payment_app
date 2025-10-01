import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Services/LocalizationService.dart';

typedef StatusRemovedCallback = void Function(String status);

class SelectedStatusesChip extends StatelessWidget {
  final double scale;
  final List<String> selectedStatuses;
  final StatusRemovedCallback onStatusRemoved;

  const SelectedStatusesChip({
    Key? key,
    required this.scale,
    required this.selectedStatuses,
    required this.onStatusRemoved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5.0,
      children: selectedStatuses.map((status) {
        return Padding(
          padding: const EdgeInsets.only(top: 7.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: Colors.grey[200], // Background color
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Colors.transparent, // No visible border
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Provider.of<LocalizationService>(context, listen: false)
                      .getLocalizedString(status.toLowerCase()),
                  style: TextStyle(
                    fontSize: 12.0 * scale,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8.0),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: GestureDetector(
                    onTap: () {
                      onStatusRemoved(status);
                    },
                    child: Icon(
                      Icons.close,
                      size: 18.0,
                      color: Colors.grey[700], // Delete icon color
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
