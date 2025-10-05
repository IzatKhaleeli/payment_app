import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants.dart'; // Ensure you have this import

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use ScreenUtil to make the button width responsive to screen size
    double buttonWidth = ScreenUtil().screenWidth *
        0.7; // The button takes 70% of the screen width

    return Center(
      child: SizedBox(
        width: buttonWidth, // Use the responsive width here
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed, // Disable button if loading
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.primaryRed,
            padding: EdgeInsets.symmetric(
                vertical: 12.0.h), // Use ScreenUtil for responsive padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  20.r), // Use ScreenUtil for responsive border radius
            ),
            elevation: 4, // Elevation for depth
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp, // Use ScreenUtil for responsive font size
              fontFamily: 'NotoSansUI',
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(text),
        ),
      ),
    );
  }
}
