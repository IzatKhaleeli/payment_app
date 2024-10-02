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

  // Method to create the message template based on parameters
  static Future<String> createMessageTemplate({
    required String language,
    required String amount,
    required String currency,
    required String voucherSerialNumber,
    required String paymentMethod,
    required String username,
    required bool isCancel
  }) async {
    Map<String, dynamic>? translatedCurrency = await DatabaseProvider.getCurrencyById(currency);
    String appearedCurrency = language == 'ar'
        ? translatedCurrency!["arabicName"]
        : translatedCurrency!["englishName"];
    if(isCancel==false){
    if (language == 'ar') {
      return'''   
تم استلام دفعه ${paymentMethod} بقيمة ${amount} ${appearedCurrency} من مدير حسابكم ${username}
رقم الحركة ${voucherSerialNumber}

ملاحظة: سيصلكم رسالة حال الإيداع في صندوق الشركة 
''';
    } else {
      return '''
$amount $appearedCurrency ${paymentMethod.toLowerCase()} payment has been received by account manager $username
Transaction reference ${voucherSerialNumber}

Note: You will receive a message once the payment is deposited into your account.
''';
    }
    }
    else {
      // if (language == 'ar') {
        return '''
تم تقديم إلغاء دفعة ${paymentMethod} بقيمة ${amount} ${appearedCurrency} من مدير حسابكم ${username}
رقم الحركة ${voucherSerialNumber}
''';
   //   }
//       else {
//         return '''
// $amount $appearedCurrency ${paymentMethod.toLowerCase()} payment has been submitted for cancellation by account manager $username
// Transaction reference ${voucherSerialNumber}
// ''';
//       }
    }
  }

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
    String fullToken = "Barer ${tokenID}";
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'tokenID': fullToken,
    };

    String message = await createMessageTemplate(
      language: selectedMessageLanguage,
      amount: amount,
      currency: currency,
      voucherSerialNumber: voucherSerialNumber,
      paymentMethod: paymentMethod,
      username: username!,
      isCancel:isCancel
    );


    Map<String, String> body = {
      "to": phoneNumber,
      "lang": selectedMessageLanguage,
      "message": message,
    };
    print("body is :${body}");
    print("headers is :${headers}");
    print("apiUrlSMS is :${apiUrlSMS}");
    try {
      final response = await http.post(
        Uri.parse(apiUrlSMS),
        headers: headers,
        body: json.encode(body),
      ).timeout(Duration(seconds: 3));

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
      } else if (response.statusCode == 401) {
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
          } else {
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.error, color: Colors.red, size: 40),
              message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentSmsFailed"),
              buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
              onPressButton: () {
                print('Error acknowledged');
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
            print('Error acknowledged');
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
          print('Timeout error acknowledged :${e}');
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
          print('Error acknowledged :${e}');
        },
      );
    }
  }

}
