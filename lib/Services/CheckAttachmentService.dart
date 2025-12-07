import 'package:ooredoo_app/core/constants.dart';

import '../Models/PaymentImages.dart';
import '../Models/CheckImage.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:ooredoo_app/Services/database.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../core/api_service/attachment_api_service.dart';
import 'LocalizationService.dart';
import 'PaymentService.dart';

class CheckAttachmentService {
  static Future<List<PaymentImages>>
      getConfirmedImagesGroupedByPayment() async {
    final dbImages = await DatabaseProvider.getConfirmedCheckImages();
    Map<String, List<CheckImage>> grouped = {};
    for (final imgMap in dbImages) {
      final img = CheckImage.fromMap(imgMap);
      final voucherNumber = imgMap['voucherSerialNumber'] ?? '';
      if (voucherNumber.isNotEmpty) {
        grouped.putIfAbsent(voucherNumber, () => []).add(img);
      }
    }
    return grouped.entries
        .map((e) => PaymentImages(voucherSerialNumber: e.key, images: e.value))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> prepareImageRecords(
      List<File> files, int paymentId, String voucherNumber) async {
    List<Map<String, dynamic>> imageRecords = [];
    for (final file in files) {
      final fileName = file.path.split('/').last;
      final mimeType = 'image/${fileName.split('.').last}';
      final base64Content = await file.readAsBytes();
      imageRecords.add({
        'paymentId': paymentId,
        'voucherSerialNumber': voucherNumber,
        'fileName': fileName,
        'mimeType': mimeType,
        'base64Content': base64Content,
        'status': 'confirmed',
      });
    }
    return imageRecords;
  }

  static void showSelectedFilesPopup({
    required BuildContext context,
    required String voucherNumber,
    required int paymentId,
    required List<File> initialFiles,
  }) {
    var appLocalization =
        Provider.of<LocalizationService>(context, listen: false);
    List<File> selectedFiles = List<File>.from(initialFiles);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                appLocalization.getLocalizedString('upload_files'),
                style: const TextStyle(color: AppColors.primaryRed),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.add_circle,
                              color: AppColors.primaryRed, size: 28),
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'upload',
                              child: Text(
                                  appLocalization.getLocalizedString(
                                      'upload_from_gallery'),
                                  style: const TextStyle(
                                      color: AppColors.primaryRed)),
                            ),
                            PopupMenuItem<String>(
                              value: 'camera',
                              child: Text(
                                  appLocalization
                                      .getLocalizedString('take_a_photo'),
                                  style: const TextStyle(
                                      color: AppColors.primaryRed)),
                            ),
                          ],
                          onSelected: (value) async {
                            final picker = ImagePicker();
                            if (value == 'upload') {
                              final List<XFile> images =
                                  await picker.pickMultiImage();
                              if (images.isNotEmpty) {
                                setState(() {
                                  selectedFiles
                                      .addAll(images.map((e) => File(e.path)));
                                });
                              }
                            } else if (value == 'camera') {
                              final XFile? photo = await picker.pickImage(
                                  source: ImageSource.camera);
                              if (photo != null) {
                                setState(() {
                                  selectedFiles.insert(0, File(photo.path));
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    if (selectedFiles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: Text(
                              appLocalization
                                  .getLocalizedString('no_files_selected'),
                              textAlign: TextAlign.center),
                        ),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedFiles.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final f = selectedFiles[index];
                            return Stack(
                              key: ValueKey(f.path),
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    f,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0.5,
                                  right: 0.5,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: AppColors.primaryRed, size: 22),
                                    onPressed: () {
                                      setState(() {
                                        if (index >= 0 &&
                                            index < selectedFiles.length) {
                                          selectedFiles.removeAt(index);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(appLocalization.getLocalizedString('cancel'),
                      style: const TextStyle(color: AppColors.primaryRed)),
                  onPressed: () {
                    setState(() {
                      selectedFiles.clear();
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed),
                  onPressed: selectedFiles.isEmpty
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          final imageRecords =
                              await CheckAttachmentService.prepareImageRecords(
                                  selectedFiles, paymentId, voucherNumber);
                          await DatabaseProvider.addCheckImagesToPayment(
                              voucherNumber, imageRecords);
                        },
                  child: Text(appLocalization.getLocalizedString('confirm'),
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> uploadAttachments({
    required BuildContext context,
    required String voucherNumber,
    required List<File> files,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? tokenID = prefs.getString('token');
      if (tokenID == null) {
        print('Token not found');
        return;
      }
      var fullToken = "Barer " + tokenID;
      var headers = {
        'Content-Type': 'application/json',
        'tokenID': fullToken,
      };

      final response = await AttachmentApiService.uploadAttachments(
        voucherSerialNumber: voucherNumber,
        headers: headers,
        files: files,
      );
      final int status = response['status'] ?? 0;
      final bool success = response['success'] ?? false;
      final dynamic data = response['data'];
      if (success && status == 200 && data is List) {
        print('Attachments uploaded successfully for $voucherNumber');
      } else if (status == 401) {
        int tokenStatus = await PaymentService.attemptReLogin(context);
        if (tokenStatus == 200) {
          print("Token refreshed, retrying...");
          await uploadAttachments(
            context: context,
            voucherNumber: voucherNumber,
            files: files,
          );
        } else {
          print("Unable to refresh token");
        }
      } else if (status == 408) {
        print("Request timed out");
      } else if (status == 429) {
        print("Too many requests");
      } else {
        print("Error: Status $status, Data: $data");
      }
    } on SocketException catch (e) {
      print("Network error occurred: $e");
    } on TimeoutException catch (e) {
      print("Request timed out: $e");
    } catch (e, stack) {
      print("Unexpected error uploading attachments: $e");
      print(stack);
    }
  }
}
