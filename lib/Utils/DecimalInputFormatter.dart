import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Services/LocalizationService.dart';

class DecimalInputFormatter extends TextInputFormatter {
  final _regex = RegExp(
      r'^\d{0,10}(\.\d{0,2})?$'); // Accept up to 10 digits before decimal and 2 digits after.

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (_regex.hasMatch(newValue.text)) {
      return newValue; // Allow valid input
    } else {
      // Show a SnackBar for invalid input
      // _showSnackBar();
      return oldValue; // Reject invalid input
    }
  }
}
