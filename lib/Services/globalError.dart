import 'package:flutter/material.dart';

class GlobalErrorNotifier {
  static final ValueNotifier<String?> errorTextNotifier = ValueNotifier(null);

  static void showError(String error) {
    errorTextNotifier.value = error;
  }

  static void clearError() {
    errorTextNotifier.value = null;
  }
}
