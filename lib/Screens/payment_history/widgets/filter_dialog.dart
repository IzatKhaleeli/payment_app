import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Services/LocalizationService.dart';
import '../../../core/constants.dart';
import '../../../core/utils/enum/cancellation_status_enum.dart';

void showFilterDialog({
  required BuildContext context,
  required double scale,
  required List<String> selectedStatuses,
  required List<CancellationStatus> selectedCancellationStatuses,
  required VoidCallback onApply,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final localizationService =
              Provider.of<LocalizationService>(context, listen: false);

          final List<String> statuses = [
            'Confirmed',
            'Synced',
            'CancelPending',
            'Cancelled'
          ];

          int totalSelected =
              selectedStatuses.length + selectedCancellationStatuses.length;

          Widget buildSection<T>({
            required String title,
            required List<T> items,
            required List<T> selected,
            required String Function(T) getLabel,
          }) {
            return ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 8 * scale),
              title: Text(
                "$title (${selected.length} ${localizationService.getLocalizedString('selected')})",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12 * scale),
              ),
              children: items.map((item) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12 * scale),
                  title: Text(
                    getLabel(item),
                    style: TextStyle(color: Colors.black, fontSize: 12 * scale),
                  ),
                  value: selected.contains(item),
                  activeColor: AppColors.primaryRed,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selected.add(item);
                      } else {
                        selected.remove(item);
                      }
                    });
                  },
                  secondary: Transform.scale(
                    scale: 0.8 * scale,
                    child: Checkbox(
                      value: selected.contains(item),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selected.add(item);
                          } else {
                            selected.remove(item);
                          }
                        });
                      },
                      activeColor: AppColors.primaryRed,
                    ),
                  ),
                );
              }).toList(),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final maxDialogWidth = constraints.maxWidth > 500
                  ? 500.0
                  : constraints.maxWidth * 0.95;
              final maxDialogHeight = MediaQuery.of(context).size.height * 0.7;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxDialogWidth,
                    maxHeight: maxDialogHeight,
                  ),
                  child: AlertDialog(
                    insetPadding: EdgeInsets.all(12 * scale),
                    contentPadding: EdgeInsets.all(8 * scale),
                    titlePadding: EdgeInsets.symmetric(
                        horizontal: 12 * scale, vertical: 8 * scale),
                    actionsPadding: EdgeInsets.symmetric(
                        horizontal: 12 * scale, vertical: 8 * scale),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            localizationService
                                .getLocalizedString('filterOptions'),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14 * scale),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedStatuses.clear();
                              selectedCancellationStatuses.clear();
                            });
                          },
                          child: Text(
                            localizationService.getLocalizedString('clearAll'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      ],
                    ),
                    content: SizedBox(
                      height: maxDialogHeight * 0.75,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildSection<String>(
                              title: localizationService
                                  .getLocalizedString('status'),
                              items: statuses,
                              selected: selectedStatuses,
                              getLabel: (s) => localizationService
                                  .getLocalizedString(s.toLowerCase()),
                            ),
                            buildSection<CancellationStatus>(
                              title: localizationService
                                  .getLocalizedString('cancellationStatus'),
                              items: CancellationStatus.values,
                              selected: selectedCancellationStatuses,
                              getLabel: (s) => localizationService
                                  .getLocalizedString(s.value.toLowerCase()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            padding: EdgeInsets.symmetric(vertical: 12 * scale),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onApply();
                          },
                          child: Text(
                            "${localizationService.getLocalizedString('applyFilters')} ($totalSelected)",
                            style: TextStyle(
                                color: Colors.white, fontSize: 14 * scale),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}
