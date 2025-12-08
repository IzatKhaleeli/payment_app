import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

import '../Services/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Services/database.dart';
import 'package:intl/intl.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:number_to_words_english/number_to_words_english.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Models/LoginState.dart';
import '../Screens/LoginScreen.dart';
import '../Screens/SMS_Service.dart';
import 'CheckAttachmentService.dart';
import 'LocalizationService.dart';
import 'apiConstants.dart';
import 'package:mutex/mutex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'globalError.dart';

class PaymentService {
  /// Converts a list of CheckImage or Map records into Files ready for upload.
  static Future<List<File>> checkImagesToFiles(List<dynamic> images) async {
    final tempDir = await getTemporaryDirectory();
    List<File> files = [];
    for (int idx = 0; idx < images.length; idx++) {
      final img = images[idx];
      try {
        String? filePath;
        dynamic base64Content;
        String? fileName;

        if (img is Map) {
          filePath = img['filePath'] as String?;
          base64Content = img['base64Content'];
          fileName = img['fileName'] as String?;
        } else {
          // Support CheckImage objects and other dynamic shapes
          filePath = (img as dynamic).filePath as String?;
          base64Content = (img as dynamic).base64Content;
          fileName = (img as dynamic).fileName as String?;
        }

        // Prefer existing file on disk
        if (filePath != null && filePath.isNotEmpty) {
          final f = File(filePath);
          if (await f.exists()) {
            files.add(f);
            continue;
          }
        }

        // Fallback: convert base64 content to a temp file
        if (base64Content != null) {
          Uint8List bytes;
          if (base64Content is String) {
            bytes = base64.decode(base64Content);
          } else if (base64Content is Uint8List) {
            bytes = base64Content;
          } else if (base64Content is List<int>) {
            bytes = Uint8List.fromList(base64Content);
          } else {
            // unsupported format
            continue;
          }

          final safeName = fileName ??
              'img_${DateTime.now().millisecondsSinceEpoch}_$idx.jpg';
          final out = File(p.join(tempDir.path, safeName));
          await out.writeAsBytes(bytes, flush: true);
          files.add(out);
          continue;
        }
      } catch (e) {
        print('Error converting image to file: $e');
      }
    }
    return files;
  }

  static Timer? _networkTimer;
  static final StreamController<void> _syncController =
      StreamController<void>.broadcast();
  static Stream<void> get syncStream => _syncController.stream;
  static final Mutex _syncMutex = Mutex();

  static void _cancelNetworkTimer() {
    if (_networkTimer != null) {
      _networkTimer!.cancel();
      _networkTimer = null;
    }
  }

  static Future<void> startPeriodicNetworkTest(BuildContext context) async {
    _cancelNetworkTimer();
    _networkTimer = Timer.periodic(
      Duration(seconds: 5),
      (Timer timer) async {
        await _checkNetworkAndSync(context);
      },
    );
  }

  static Future<void> _checkNetworkAndSync(BuildContext context) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      print("Internet available: " + connectivityResult.toString());
      await syncPayments(context);
      await syncConfirmedCheckImages(context);
    } else {
      print("No internet: " + connectivityResult.toString());
    }
  }

  static Future<void> syncConfirmedCheckImages(BuildContext context) async {
    final groupedImages =
        await CheckAttachmentService.getConfirmedImagesGroupedByPayment();
    for (var paymentImages in groupedImages) {
      final voucherNumber = paymentImages.voucherSerialNumber;
      if (voucherNumber == null || voucherNumber.toString().isEmpty) {
        print('Skipping sync: voucherNumber is null or empty');
        continue;
      }
      print("Syncing images for voucher: $voucherNumber");
      final images = paymentImages.images;
      if (images.isEmpty) continue;
      final files = await checkImagesToFiles(images);
      await CheckAttachmentService.uploadAttachments(
          context: context, voucherNumber: voucherNumber, files: files);
    }
  }

  static Future<void> syncPayments(BuildContext context) async {
    if (_syncMutex.isLocked) {
      print("Sync already in progress, skipping.");
      return;
    }
    await _syncMutex.acquire();

    try {
      _cancelNetworkTimer();

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
      List<Map<String, dynamic>> ConfirmedAndCancelledPendingPayments =
          await DatabaseProvider.getConfirmedOrCancelledPendingPayments();
      List<Map<String, dynamic>> confirmedPayments = [];
      List<Map<String, dynamic>> cancelledPendingPayments = [];

      for (var payment in ConfirmedAndCancelledPendingPayments) {
        if (payment['status'] == 'Confirmed') {
          confirmedPayments.add(payment);
        } else if (payment['cancellationStatus'] == 'CancelPending') {
          cancelledPendingPayments.add(payment);
        }
      }

      for (var payment in confirmedPayments) {
        await PaymentService.syncPayment(payment, apiUrl, headers, context);
      }

      for (var p in cancelledPendingPayments) {
        if (p['cancellationStatus'] != 'CancelPending') {
          continue;
        }

        Map<String, String> body = {
          "voucherSerialNumber": p["voucherSerialNumber"],
          "cancelReason": p["cancelReason"].toString(),
          "cancelTransactionDate": p["cancellationDate"],
        };

        try {
          final response = await http.delete(
            Uri.parse(apiUrlCancel),
            headers: headers,
            body: json.encode(body),
          );
          if (response.statusCode == 200) {
            print("inside status code 200 of cancel api");
            await DatabaseProvider.updateCancellationStatus(
                p["id"], 'Cancelled');
            _syncController.add(null);
            String amount =
                p["paymentMethod"].toString().toLowerCase() == 'cash'
                    ? (p["amount"]?.toString() ?? '0')
                    : (p["amountCheck"]?.toString() ?? '0');

            await SmsService.sendSmsRequest(
                context,
                p["msisdnReceipt"] ?? p["msisdn"],
                'ar',
                amount,
                p["currency"],
                p["voucherSerialNumber"],
                p["paymentMethod"].toString().toLowerCase() == 'cash'
                    ? 'كاش'
                    : 'شيك',
                isCancel: true);
          } else {
            print('Failed to cancel payment: ${response.body}');
          }
        } catch (e) {
          // Handle exceptions
          print('Error syncing confirm or cancel payment: $e');
        }
      }
    } finally {
      _syncMutex.release();
      startPeriodicNetworkTest(context);
      _syncController.add(null);
    }
  }

  static Future<void> syncPayment(Map<String, dynamic> payment, String apiUrl,
      Map<String, String> headers, BuildContext context) async {
    try {
      String theSumOf = payment['paymentMethod'].toLowerCase() == 'cash'
          ? convertAmountToWords(payment['amount'])
          : convertAmountToWords(payment['amountCheck']);

      Map<String, dynamic> body = {
        'transactionId': payment['transactionId'],
        'transactionDate': payment['transactionDate'],
        'accountName': payment['customerName'],
        'msisdn': payment['msisdn'],
        'msisdnReceipt': payment['msisdnReceipt'],
        'pr': payment['prNumber'],
        'amount': payment['amount'],
        'currency': payment['currency'],
        'paymentMethod': payment['paymentMethod'],
        'checkNumber': payment['checkNumber'],
        'checkAmount': payment['amountCheck'],
        'checkBank': payment['bankBranch'],
        'notes': payment['paymentInvoiceFor'],
        'checkDueDate':
            payment['dueDateCheck'] != null && payment['dueDateCheck'] != 'null'
                ? DateTime.parse(payment['dueDateCheck']).toIso8601String()
                : null,
        'theSumOf': theSumOf,
        'isDeposit': payment['isDepositChecked'] == 0 ? false : true,
        "isDisconnected": payment['isDisconnected'],
        "toCheckApproval": payment['checkApproval'],
        "toNotifyFinance": payment['notifyFinance'],
      };
      // print("body payment to sync :${body}");

      if (payment["status"].toString().toLowerCase() == "synced") return;

      http.Response? response;

      try {
        final uri = Uri.parse(apiUrl);
        final request = http.MultipartRequest('POST', uri);

        headers.forEach((k, v) {
          if (k.toLowerCase() != 'content-type') request.headers[k] = v;
        });

        request.fields['paymentRequest'] = json.encode(body);

        try {
          List<Map<String, dynamic>> images =
              await DatabaseProvider.getCheckImagesByPaymentId(payment['id']);
          for (var img in images) {
            try {
              // Prefer file on disk (filePath) to avoid decoding large base64 from DB
              Uint8List bytes = Uint8List(0);

              final String? filePath = (img['filePath'] as String?)?.trim();
              if (filePath != null && filePath.isNotEmpty) {
                final file = File(filePath);
                if (await file.exists()) {
                  bytes = await file.readAsBytes();
                }
              }

              // Fallback to base64Content only if file not available
              if (bytes.isEmpty) {
                final dynamic base64Content = img['base64Content'];
                if (base64Content is String && base64Content.isNotEmpty) {
                  bytes = base64.decode(base64Content);
                } else if (base64Content is Uint8List) {
                  bytes = base64Content;
                } else if (base64Content is List<int>) {
                  bytes = Uint8List.fromList(base64Content);
                } else {
                  // nothing to attach
                  continue;
                }
              }

              final String fileName =
                  img['fileName'] ?? '${payment['transactionId']}_img.jpg';
              final String mimeType = (img['mimeType'] as String?) ??
                  lookupMimeType(fileName, headerBytes: bytes) ??
                  'image/jpeg';

              MediaType? mediaType;
              try {
                mediaType = MediaType.parse(mimeType);
              } catch (e) {
                mediaType = MediaType('image', 'jpeg');
              }

              final multipartFile = http.MultipartFile.fromBytes(
                'attachments',
                bytes,
                filename: fileName,
                contentType: mediaType,
              );
              request.files.add(multipartFile);
            } catch (e) {
              print('Error attaching image for payment ${payment['id']}: $e');
            }
          }
        } catch (e) {
          print('Error fetching images for payment ${payment['id']}: $e');
        }
        print("image processing complete");

        http.StreamedResponse? streamedResponse;
        try {
          streamedResponse =
              await request.send().timeout(const Duration(seconds: 60));
        } on TimeoutException catch (e) {
          print('Multipart upload timed out: $e');
          GlobalErrorNotifier.showError('Request timed out.');
          return;
        } on SocketException catch (e) {
          print('No internet connection: $e');
          GlobalErrorNotifier.showError('No internet connection.');
          return;
        }
        print(
            "image upload complete streamedResponse ${streamedResponse.statusCode}");
        response = await http.Response.fromStream(streamedResponse);
        print("multipart post request");
      } on SocketException catch (e) {
        print('No internet connection: $e');
        GlobalErrorNotifier.showError('No internet connection.');
        return;
      } on TimeoutException catch (e) {
        print('Request timed out: $e');
        GlobalErrorNotifier.showError('Request timed out.');
        return;
      } catch (e) {
        GlobalErrorNotifier.showError("Error: $e");
      }
      if (response!.statusCode == 200) {
        print("inside status code 200 of sync api");

        // Parse the response
        Map<String, dynamic> responseBody = json.decode(response.body);
        String? voucherSerialNumber = responseBody['voucherSerialNumber'];
        print("voucherSerialNumber : \\${voucherSerialNumber!}");

        await DatabaseProvider.setVoucherNumberForCheckImages(
            payment["id"], voucherSerialNumber);
        await DatabaseProvider.markAllCheckImagesAsSynced(
            voucherSerialNumber, 'new');

        await DatabaseProvider.updateSyncedPaymentDetail(
            payment["id"], voucherSerialNumber, 'Synced');
        _syncController.add(null);
        String amount =
            payment["paymentMethod"].toString().toLowerCase() == 'cash'
                ? (payment["amount"]?.toString() ?? '0')
                : (payment["amountCheck"]?.toString() ?? '0');

        await SmsService.sendSmsRequest(
            context,
            payment["msisdnReceipt"] ?? payment["msisdn"],
            'ar',
            amount,
            payment["currency"],
            voucherSerialNumber,
            payment["paymentMethod"].toString().toLowerCase() == 'cash'
                ? 'كاش'
                : 'شيك');
      } else {
        print("elseee");

        Map<String, dynamic> errorResponse = json.decode(response.body);
        print("failed to sync heres the body of response: ${response.body}");
        if (errorResponse['error'] == 'Unauthorized' &&
            errorResponse['errorInDetail'] == 'JWT Authentication Failed') {
          await _attemptReLoginAndRetrySync(context);
        } else {
          print('Failed to sync payment: ${response.body}');
        }
      }
      print("sync payment try");
    } catch (e) {
      print("sync payment error :${e}");
    }
  }

  static Future<void> cancelPayment(Map<String, dynamic> paymentToCancel,
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
            paymentToCancel["voucherSerialNumber"],
            reason,
            cancelDateTime,
            'Cancelled');
        _syncController.add(null);
        String amount =
            paymentToCancel["paymentMethod"].toString().toLowerCase() == 'cash'
                ? (paymentToCancel["amount"]?.toString() ?? '0')
                : (paymentToCancel["amountCheck"]?.toString() ?? '0');
        await SmsService.sendSmsRequest(
            context,
            paymentToCancel["msisdnReceipt"] ?? paymentToCancel["msisdn"],
            'ar',
            amount,
            paymentToCancel["currency"],
            paymentToCancel["voucherSerialNumber"],
            paymentToCancel["paymentMethod"].toString().toLowerCase() == 'cash'
                ? 'كاش'
                : 'شيك',
            isCancel: true);
      } else {
        Map<String, dynamic> errorResponse = json.decode(response.body);
        print("failed to sync heres the body of response: ${response.body}");
        if (errorResponse['error'] == 'Unauthorized' &&
            errorResponse['errorInDetail'] == 'JWT Authentication Failed') {
          await DatabaseProvider.cancelPayment(
              paymentToCancel["voucherSerialNumber"],
              reason,
              cancelDateTime,
              'CancelPending');
          _syncController.add(null);
          await _attemptReLoginAndRetrySync(context);
        } else {
          print('^ Failed to cancel/sync payment: ${response.body}');
        }
      }
    } catch (e) {
      await DatabaseProvider.cancelPayment(
          paymentToCancel["voucherSerialNumber"],
          reason,
          cancelDateTime,
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
      } else if (loginSuccessful["status"] == 503) {
        print("Re-login failed.credentials error Unable to sync payment.");
      } else if (loginSuccessful["status"] == 408) {
        print("Re-login failed.credentials error Unable to sync payment.");
      } else {
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
      } else if (loginSuccessful["status"] == 400) {
        print("Re-login failed.credentials error Unable to sync payment.");
        _showSessionExpiredDialog(context); // Show session expired message
        return 400;
      } else if (loginSuccessful["status"] == 503) {
        print("Re-login failed. Network issue.");
        return 503;
      } else if (loginSuccessful["status"] == 408) {
        print("Re-login failed. Network issue.");
        return 408;
      } else {
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
          title: Text(Provider.of<LocalizationService>(context, listen: false)
              .getLocalizedString('sesstionExpiredTitle')),
          content: Text(Provider.of<LocalizationService>(context, listen: false)
              .getLocalizedString('sesstionExpiredBody')),
          actions: [
            TextButton(
              onPressed: () async {
                await Future.delayed(Duration(seconds: 1));
                Navigator.of(context).pop(); // Close the dialog
                showLoadingAndNavigate(context); // Navigate to login screen
              }, //
              child: Text(
                Provider.of<LocalizationService>(context, listen: false)
                    .getLocalizedString('ok'),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> getExpiredPaymentsNumber() async {
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
        // print("number of ays to delete before is : ${days}");
        await DatabaseProvider.deleteRecordsOlderThan(days);
      } else {
        print(
            'Failed to get the number of days. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle the error if needed
      print('Error deleting expired payment: $e');
    }
  }

  static Future<bool> getMinVersion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tokenID = prefs.getString('token');
    if (tokenID == null) {
      print('Token not found');
      return false;
    }
    String fullToken = "Barer ${tokenID}";

    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'tokenID': fullToken,
      };
      final response = await http
          .get(
            Uri.parse(apiUrlMinVersion),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        print(
            'Failed to get the min version. Status code: ${response.statusCode}');
        return false;
      }
      String backendVersion = response.body.trim();
      print("MIN_VERSION from backend: $backendVersion");

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      // String currentVersion = '1.1.0';

      print("APP_VERSION: $currentVersion");

      List<String> backendParts = backendVersion.split('.');
      List<String> appParts = currentVersion.split('.');

      if (backendParts.length < 3 || appParts.length < 3) {
        print("Invalid version format");
        return false;
      }

      int backendMajor = int.tryParse(backendParts[0]) ?? 0;
      int backendMinor = int.tryParse(backendParts[1]) ?? 0;
      int backendPatch = int.tryParse(backendParts[2]) ?? 0;

      int appMajor = int.tryParse(appParts[0]) ?? 0;
      int appMinor = int.tryParse(appParts[1]) ?? 0;
      int appPatch = int.tryParse(appParts[2]) ?? 0;

      if (backendMajor > appMajor) {
        print("Major/Minor mismatch → force update required.");
        return false;
      }

      if (backendMinor > appMinor || backendPatch > appPatch) {
        print("Patch mismatch → new version available, but not mandatory.");
        return true;
      }

      print("App is up-to-date.");
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting the min version: $e');
      }
      return false;
    }
  }

  static Future<void> showLoadingAndNavigate(BuildContext context) async {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 375).clamp(0.8, 1.3);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                width: 130.w,
                height: 100.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                      0.2), // Semi-transparent white for glass effect
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
                    SizedBox(height: 10.h),
                    Text(
                      Provider.of<LocalizationService>(context, listen: false)
                          .getLocalizedString('pleaseWait'),
                      style: TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontFamily: 'NotoSansUI',
                        fontSize: 12 * scale,
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

    await Future.delayed(const Duration(seconds: 1));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('language_code');
    await prefs.setString('language_code', 'ar');
    await prefs.remove('usernameLogin');
    await prefs.remove('disconnectedPermission');

    _cancelNetworkTimer();

    Navigator.of(context).pop();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  static String convertAmountToWords(dynamic amount) {
    if (amount == null) {
      return '';
    }

    int amountInt = (amount is double) ? amount.toInt() : amount as int;

    return NumberToWordsEnglish.convert(amountInt);
  }

  static void showLoadingOnly(BuildContext context, double scale) {
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
                width: 130,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
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
                            color:
                                index.isEven ? Colors.white : Colors.grey[300],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    Text(
                      Provider.of<LocalizationService>(context, listen: false)
                          .getLocalizedString('pleaseWait'),
                      style: TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontFamily: 'NotoSansUI',
                        fontSize: 14 * scale,
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
  }

  static Future<void> completeLogout(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 500));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('language_code');
    await prefs.setString('language_code', 'ar');
    await prefs.remove('usernameLogin');
    await prefs.remove('disconnectedPermission');

    _cancelNetworkTimer();

    Navigator.of(context).pop();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }
}
