import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Models/Payment.dart';
import '../../../Services/LocalizationService.dart';

class PaymentRecordsList extends StatelessWidget {
  final double scale;
  final List<Payment> paymentRecords;
  final Widget Function(double scale, Payment record) itemBuilder;

  const PaymentRecordsList({
    Key? key,
    required this.scale,
    required this.paymentRecords,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localization =
        Provider.of<LocalizationService>(context, listen: false);

    if (paymentRecords.isEmpty) {
      return Center(
        child: Text(
          localization.getLocalizedString('noRecordsFound'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paymentRecords.length,
      itemBuilder: (context, index) {
        return itemBuilder(scale, paymentRecords[index]);
      },
    );
  }
}
