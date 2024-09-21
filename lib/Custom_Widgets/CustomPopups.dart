import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../Services/LocalizationService.dart';

class CustomPopups {

  static void showCustomDialog({
    required BuildContext context,
    required Icon icon,
    required String title,
    required String message,
    required String deleteButtonText,
    required VoidCallback onPressButton,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('cancel'), style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(deleteButtonText),
              onPressed: () {
                Navigator.of(context).pop();
                onPressButton();

              },
            ),
          ],
        );
      },
    );
  }


  static Future<void> showConfirmDialog(BuildContext context, VoidCallback onConfirm) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Payment',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Are you sure you want to confirm this payment?',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Confirm',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.blue,
                ),
              ),
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void showCustomResultPopup({
    required BuildContext context,
    required Icon icon,
    required String message,
    required String buttonText,
    required VoidCallback onPressButton,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            backgroundColor: Colors.white, // White background for the dialog
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black, // Black text color for readability
                  ),
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF7F7F7), // Set light red button color
                    elevation: 0, // Remove shadow for a flat button effect
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15), // Padding for a larger button
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black, // Black text for contrast
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPressButton();
                  },
                ),
              ),
            ],
          );
        },
      );
    });


  }

  static void showLoginFailedDialog(BuildContext context, String errorMessage,
      String loginFailed, String langauage) {
    showDialog(
      context: context,
      barrierDismissible: true,
      // Allow dismissing the dialog by tapping outside of it
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: langauage == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr, // Set text direction to left-to-right
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  width: 300.w,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    // Semi-transparent white for glass effect
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // Use the minimum space necessary
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        loginFailed,
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansUI',
                          color: Color(0xFFC62828),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 14.sp,
                          fontFamily: 'NotoSansUI',
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext)
                                .pop(); // Dismiss the dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFC62828), // Button color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              decoration: TextDecoration.none,
                              fontFamily: 'NotoSansUI',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
