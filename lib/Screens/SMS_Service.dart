import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../Custom_Widgets/CustomPopups.dart';
import '../Services/LocalizationService.dart';
import '../Services/PaymentService.dart';
import 'package:provider/provider.dart';
import '../Services/apiConstants.dart';
import '../Services/database.dart';

class SmsService {
  static Future<void> sendSmsRequest(
      BuildContext context,
      String phoneNumber,
      String selectedMessageLanguage,
      String amount,
      String currency,
      String voucherSerialNumber,
      String paymentMethod,
      {
        bool isCancel = false,
      }

      ) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('usernameLogin');
    String? tokenID = prefs.getString('token');
    if (tokenID == null) {
      print('Token not found');
      return;
    }
    String? AppearedCurrency;
    Map<String, dynamic>? currentCurrency = await DatabaseProvider.getCurrencyById(currency);

    AppearedCurrency = selectedMessageLanguage == 'ar' ? currentCurrency!["arabicName"] :  currentCurrency!["englishName"];


    String fullToken = "Barer ${tokenID}";
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'tokenID': fullToken,
    };


    Map<String, String> body = {
      "to": phoneNumber,
      "lang": selectedMessageLanguage,
      "username": username!,
      "paymentMethod": paymentMethod,
      "voucherSerialNumber": voucherSerialNumber,
      "currency": AppearedCurrency.toString(),
      "amount": amount,
      "type":isCancel== true ? "cancel":"sync",
    };

    print("body is :${body}");
    print("headers is :${headers}");
    print("apiUrlSMS is :${apiUrlSMS}");
    print("url send here");//
    try {
      final response = await http.post(
        Uri.parse(apiUrlSMS),
        headers: headers,
        body: json.encode(body),
      ).timeout(Duration(seconds: 5));
print("response.statusCode :${response.statusCode}");
      if (response.statusCode == 200) {
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.check_circle, color: Colors.green, size: 40),
          message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentSmsOk"),
          buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
          onPressButton: () {
            print('Success acknowledged');
          },
        );
      }
      else if (response.statusCode == 429) {
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.error, color: Colors.red, size: 40),
          message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("exceedNumberOfRequest"),
          buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
          onPressButton: () {
            print('Exceed number of request');
          },
        );
      }
      else if (response.statusCode == 400 || response.statusCode == 401) {
        print(response.body);
        int responseNumber = await PaymentService.attemptReLogin(context);
        print("The response number from get expand the session is :${responseNumber}");
        if (responseNumber == 200) {
          print("Re-login successfully");
          tokenID = prefs.getString('token');
          if (tokenID == null) {
            print('Token not found');
            return;
          }
          fullToken = "Bearer ${tokenID}";

          headers = {
            'Content-Type': 'application/json',
            'tokenID': fullToken,
          };
          final reloginResponse = await http.post(
            Uri.parse(apiUrlSMS),
            headers: headers,
            body: json.encode(body),
          );
          if (reloginResponse.statusCode == 200) {
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.check_circle, color: Colors.green, size: 40),
              message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentSmsOk"),
              buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
              onPressButton: () {
                print('Success acknowledged');
              },
            );
          }
          else if (response.statusCode == 429) {
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.error, color: Colors.red, size: 40),
              message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("exceedNumberOfRequest"),
              buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
              onPressButton: () {
                print('Exceed number of request');
              },
            );
          }
          else {
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.error, color: Colors.red, size: 40),
              message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentSmsFailed"),
              buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
              onPressButton: () {
                print('Error acknowledgeds');
                print(reloginResponse.body);
                print(reloginResponse.statusCode);
              },
            );
          }
        }
      } else if (response.statusCode == 408) {
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.error, color: Colors.red, size: 40),
          message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("networkTimeoutError"),
          buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
          onPressButton: () {
            print('Error timeout');
          },
        );
      } else {
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.error, color: Colors.red, size: 40),
          message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentSmsFailed"),
          buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
          onPressButton: () {
            print('Error acknowledgedq');
            print(response.body);
            print(response.statusCode);
          },
        );
      }
    }
    on SocketException catch (e) {
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: Colors.red, size: 40),
        message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("networkError"),
        buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
        onPressButton: () {
          print('Network error acknowledged :${e}');
        },
      );
    }
    on TimeoutException catch (e) {
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: Colors.red, size: 40),
        message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("networkTimeoutError"),
        buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
        onPressButton: () {
          print('Timeout error acknowledgede :${e}');
        },
      );
    }
    catch (e) {
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: Colors.red, size: 40),
        message: '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentSmsFailed")}: $e',
        buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
        onPressButton: () {
          print('Error acknowledgedr :${e}');
        },
      );
    }
  }

}
