import 'dart:ui';

import '../Services/secure_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Services/database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:number_to_words_english/number_to_words_english.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Models/LoginState.dart';
import '../Screens/LoginScreen.dart';
import '../Screens/SMS_Service.dart';
import 'LocalizationService.dart';
import 'apiConstants.dart';


class PaymentService {
  static Timer? _networkTimer; // Reference to the Timer
  static final StreamController<void> _syncController = StreamController<
      void>.broadcast();

  static Stream<void> get syncStream => _syncController.stream;
  static bool _isSyncing = false;  // Flag to track if sync is in progress


  static void _cancelNetworkTimer() {
    if (_networkTimer != null) {
      _networkTimer!.cancel();
      _networkTimer = null;
    }
  }

  static Future<void> showLoadingAndNavigate(BuildContext context) async {
    // Show custom loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                width: 130.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), // Semi-transparent white for glass effect
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitFadingCircle(
                      itemBuilder: (BuildContext context, int index) {
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index.isEven
                                ? Colors.white
                                : Colors.grey[300], // Adjust color for effect
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10.h), // Reduced space between spinner and text
                    Text(
                      Provider.of<LocalizationService>(context, listen: false).getLocalizedString('pleaseWait'),
                      style: TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontFamily: 'NotoSansUI',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Ensure the loading dialog is displayed for at least 1 second
    await Future.delayed(const Duration(seconds: 1));

    // Clear user data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('language_code');
    await prefs.setString('language_code', 'ar'); // Set default language
    await prefs.remove('usernameLogin');
    _cancelNetworkTimer();

    // Dismiss the loading dialog
    Navigator.of(context).pop(); // Dismiss the progress indicator dialog

    // Navigate to the login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false, // This disables popping the LoginScreen route
    );
  }

  static String convertAmountToWords(dynamic amount) {
    if (amount == null) {
      return ''; // Handle the case where amount is null
    }

    // Convert to int if amount is a double
    int amountInt = (amount is double) ? amount.toInt() : amount as int;

    return NumberToWordsEnglish.convert(amountInt);
  }

  static void startPeriodicNetworkTest(BuildContext context) {
    _cancelNetworkTimer();

    _networkTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) async {
      await testNetwork(context);
    });
  }

  static Future<void> testNetwork(BuildContext context) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print(connectivityResult);
    }
    else {
      print(connectivityResult);
      PaymentService.syncPayments(context);
    }
  }

  static Future<void> syncPayments(BuildContext context) async {
    // Check if a sync operation is already in progress
    if (_isSyncing) {
      print("Sync is already in progress, skipping this sync cycle.");
      return;
    }
    _isSyncing = true;  // Set syncing flag to true to prevent re-entry
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tokenID = prefs.getString('token');
    if (tokenID == null) {
      print('Token not found');
      _isSyncing = false;  // Reset syncing flag after operation
      return;
    }
    String fullToken = "Barer ${tokenID}";

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'tokenID': fullToken,
    };
    // Retrieve all confirmed payments
    List<Map<String,
        dynamic>> ConfirmedAndCancelledPendingPayments = await DatabaseProvider
        .getConfirmedOrCancelledPendingPayments();
    List<Map<String, dynamic>> confirmedPayments = [];
    List<Map<String, dynamic>> cancelledPendingPayments = [];

    // Iterate through the results and separate them based on status
    for (var payment in ConfirmedAndCancelledPendingPayments) {
      if (payment['status'] == 'Confirmed') {
        confirmedPayments.add(payment);
      } else if (payment['status'] == 'CancelPending') {
        cancelledPendingPayments.add(payment);
      }
    }

    for (var payment in confirmedPayments) {
      PaymentService.syncPayment(payment, apiUrl, headers,context);
    }

    for (var p in cancelledPendingPayments) {
      Map<String, String> body = {
        "voucherSerialNumber": p["voucherSerialNumber"],
        "cancelReason": p["cancelReason"].toString(),
        "cancelTransactionDate": p["cancellationDate"] ,
      };
      print(body);
      try {
        final response = await http.delete(
          Uri.parse(apiUrlCancel),
          headers: headers,
          body: json.encode(body),
        );
        if (response.statusCode == 200) {
          print("inside status code 200 of cancel api");
          await DatabaseProvider.updatePaymentStatus(p["id"], 'Cancelled');
          _syncController.add(null);
          String amount = p["paymentMethod"].toString().toLowerCase() == 'cash'
              ? (p["amount"]?.toString() ?? '0')
              : (p["amountCheck"]?.toString() ?? '0');

          await SmsService.sendSmsRequest(context, p["msisdn"], 'ar', amount, p["currency"], p["voucherSerialNumber"], p["paymentMethod"].toString().toLowerCase()=='cash' ? 'كاش' : 'شيك' ,isCancel: true);
        } else {
          print('Failed to cancel payment: ${response.body}');
        }
      } catch (e) {
        // Handle exceptions
        print('Error syncing payment: $e');
      }
    }

    _isSyncing = false;  // Ensure the syncing flag is reset after operation
    _syncController.add(null);
  }

  static Future <void> syncPayment(Map<String, dynamic> payment, String apiUrl,
      Map<String, String> headers, BuildContext context) async {
    String theSumOf = payment['paymentMethod'].toLowerCase() == 'cash'
        ? convertAmountToWords(payment['amount'])
        : convertAmountToWords(payment['amountCheck']);

    print("pp :${payment}");
    Map<String, dynamic> body = {
      'transactionDate': payment['transactionDate'],
      'accountName': payment['customerName'],
      'msisdn': payment['msisdn'],
      'pr': payment['prNumber'],
      'amount': payment['amount'],
      'currency': payment['currency'],
      'paymentMethod': payment['paymentMethod'],
      'checkNumber': payment['checkNumber'],
      'checkAmount': payment['amountCheck'],
      'checkBank': payment['bankBranch'],
      'notes': payment['paymentInvoiceFor'],
      'checkDueDate': payment['dueDateCheck'] != null &&
          payment['dueDateCheck'] != 'null'
          ? DateTime.parse(payment['dueDateCheck']).toIso8601String()
          : null,
      'theSumOf': theSumOf
    };
    print(body);

    try {
      print("before send sync api");
      // Make POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(body),
      ).timeout(Duration(seconds: 4));

      if (response.statusCode == 200) {
        print("inside status code 200 of sync api");

        // Parse the response
        Map<String, dynamic> responseBody = json.decode(response.body);
        String? voucherSerialNumber = responseBody['voucherSerialNumber'];
        print("voucherSerialNumber : ${voucherSerialNumber!}");

        // Update payment in local database
        await DatabaseProvider.updateSyncedPaymentDetail(payment["id"], voucherSerialNumber, 'Synced');
        _syncController.add(null);
        String amount = payment["paymentMethod"].toString().toLowerCase() == 'cash'
            ? (payment["amount"]?.toString() ?? '0')
            : (payment["amountCheck"]?.toString() ?? '0');

      //  await SmsService.sendSmsRequest(context, payment["msisdn"], Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode, amount, payment["currency"], voucherSerialNumber, Provider.of<LocalizationService>(context, listen: false).getLocalizedString(payment["paymentMethod"].toString().toLowerCase()));
        await SmsService.sendSmsRequest(context, payment["msisdn"],'ar', amount, payment["currency"], voucherSerialNumber, payment["paymentMethod"].toString().toLowerCase()=='cash' ? 'كاش' : 'شيك');
      }
      else {
        Map<String, dynamic> errorResponse = json.decode(response.body);
        print("failed to sync heres the body of response: ${response.body}");
        if (errorResponse['error'] == 'Unauthorized' &&
            errorResponse['errorInDetail'] == 'JWT Authentication Failed') {
          await _attemptReLoginAndRetrySync(context);
        } else {
          print('Failed to sync payment: ${response.body}');

        }
      }
    } catch (e) {
      print('Error syncing payment: $e');
    }
  }


  static Future <void> cancelPayment(Map<String, dynamic> paymentToCancel,
      String reason, BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tokenID = prefs.getString('token');

    if (tokenID == null) {
      print('Token not found');
      return;
    }
    String fullToken = "Barer ${tokenID}";
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'tokenID': fullToken,
      };

      DateFormat formatter = DateFormat('yyyy-MM-ddTHH:mm:ss');
      String cancelDateTime = formatter.format(DateTime.now());

      // Create the body map with the necessary information
      Map<String, String> body = {
        "voucherSerialNumber": paymentToCancel["voucherSerialNumber"],
        "cancelReason": reason,
        "cancelTransactionDate": cancelDateTime,
      };
      //print(body);
      try {
        final response = await http.delete(
          Uri.parse(apiUrlCancel),
          headers: headers,
          body: json.encode(body),
        );
        if (response.statusCode == 200) {
          print("inside status code 200 of cancel api :${response.body}");
          await DatabaseProvider.cancelPayment(
              paymentToCancel["voucherSerialNumber"], reason, cancelDateTime, 'Cancelled');
          _syncController.add(null);
          String amount = paymentToCancel["paymentMethod"].toString().toLowerCase() == 'cash'
              ? (paymentToCancel["amount"]?.toString() ?? '0')
              : (paymentToCancel["amountCheck"]?.toString() ?? '0');

          //await SmsService.sendSmsRequest(context, paymentToCancel["msisdn"], Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode, amount, paymentToCancel["currency"], paymentToCancel["voucherSerialNumber"], Provider.of<LocalizationService>(context, listen: false).getLocalizedString(paymentToCancel["paymentMethod"].toString().toLowerCase()),isCancel: true);
          await SmsService.sendSmsRequest(context, paymentToCancel["msisdn"],'ar', amount, paymentToCancel["currency"], paymentToCancel["voucherSerialNumber"], paymentToCancel["paymentMethod"].toString().toLowerCase()=='cash' ? 'كاش' : 'شيك',isCancel: true);

        }

        else {
          Map<String, dynamic> errorResponse = json.decode(response.body);
          print("failed to sync heres the body of response: ${response.body}");
          if (errorResponse['error'] == 'Unauthorized' &&  errorResponse['errorInDetail'] == 'JWT Authentication Failed')
          {
            await DatabaseProvider.cancelPayment(
                paymentToCancel["voucherSerialNumber"], reason, cancelDateTime,
                'CancelPending');
            await _attemptReLoginAndRetrySync(context);
          } else {
            print('^ Failed to cancel/sync payment: ${response.body}');
          }
        }
      } catch (e) {
        await DatabaseProvider.cancelPayment(
            paymentToCancel["voucherSerialNumber"], reason, cancelDateTime,
            'CancelPending');
        _syncController.add(null);
        print('Error cancelling payment: $e');
      }
  }

  static Future<void> _attemptReLoginAndRetrySync(BuildContext context) async {
    Map<String, String?> credentials = await getCredentials();
    String? username = credentials['username'];
    String? password = credentials['password'];
     if (username != null && password != null) {
       LoginState loginState = LoginState();
       var loginSuccessful = await loginState.login(username, password);

       if (loginSuccessful["status"] == 200) {
        print("Re-login successful");
          await syncPayments(context); // Retry the sync with new token
      }
       else if(loginSuccessful["status"] == 503){
           print("Re-login failed.credentials error Unable to sync payment.");
       }
       else if(loginSuccessful["status"] == 408){
         print("Re-login failed.credentials error Unable to sync payment.");
       }
       else {
        print("Re-login failed. Unable to sync payment.");
        _showSessionExpiredDialog(context); // Show session expired message
      }
    } else {
      print("Username or password is missing. Cannot attempt re-login.");
     }
  }

  static Future<int> attemptReLogin(BuildContext context) async {
    Map<String, String?> credentials = await getCredentials();
    String? username = credentials['username'];
    String? password = credentials['password'];
    if (username != null && password != null) {
      LoginState loginState = LoginState();
      var loginSuccessful = await loginState.login(username, password);
      if (loginSuccessful["status"] == 200) {
        return 200;
      } else if(loginSuccessful["status"] == 400) {
        print("Re-login failed.credentials error Unable to sync payment.");
        _showSessionExpiredDialog(context); // Show session expired message
        return 400;
      }
      else if(loginSuccessful["status"] == 503){
        print("Re-login failed. Network issue.");
        return 503;
      }
      else if(loginSuccessful["status"] == 408){
        print("Re-login failed. Network issue.");
        return 408;
      }
      else {
        print("Re-login failed.credentials error Unable to sync payment.");
        _showSessionExpiredDialog(context); // Show session expired message
        return 400;
      }
    } else {
      print("Username or password is missing. Cannot attempt re-login.");
      _showSessionExpiredDialog(context);
      return 400;
    }
  }

  static void _showSessionExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('sesstionExpiredTitle')),
          content: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('sesstionExpiredBody')),
          actions: [
            TextButton(
              onPressed: () async {
                await Future.delayed(Duration(seconds: 1));
                Navigator.of(context).pop(); // Close the dialog
                showLoadingAndNavigate(context); // Navigate to login screen
              },//
              child: Text(Provider.of<LocalizationService>(context, listen: false).getLocalizedString('ok'),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future <void> getExpiredPaymentsNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tokenID = prefs.getString('token');
    if (tokenID == null) {
      print('Token not found');
      return;
    }
    String fullToken = "Barer ${tokenID}";

    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'tokenID': fullToken,
      };
      final response = await http.get(
        Uri.parse(apiUrlDeleteExpired),
        headers: headers,
      );

      if (response.statusCode == 200) {
        int days;
        try {
          days = int.parse(response.body); // Parse the body to an integer
        } catch (e) {
          print('Error parsing days from response body: $e');
          return;
        }
        print("number of ays to delete before is : ${days}");
        await DatabaseProvider.deleteRecordsOlderThan(days);
      }
      else {
        print('Failed to get the number of days. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle the error if needed
      print('Error deleting expired payment: $e');
    }

  }
}