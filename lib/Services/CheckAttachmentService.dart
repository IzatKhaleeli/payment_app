import 'dart:convert';
import 'dart:typed_data';

import 'package:ooredoo_app/Custom_Widgets/ImageGalleryPreview.dart';
import 'package:ooredoo_app/core/constants.dart';

import '../Custom_Widgets/CustomPopups.dart';
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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CheckAttachmentService {
  static Future<void> showCheckImagesPreview({
    required BuildContext context,
    required int paymentId,
  }) async {
    try {
      // fetch images for this payment
      final images =
          await DatabaseProvider.getCheckImagesByPaymentId(paymentId);
      if (images.isEmpty) {
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: const Icon(Icons.info,
              color: AppColors.informationPopup, size: 40),
          message: Provider.of<LocalizationService>(context, listen: false)
              .getLocalizedString('noImagesAttached'),
          buttonText: Provider.of<LocalizationService>(context, listen: false)
              .getLocalizedString('ok'),
          onPressButton: () {
            // Define what happens when the button is pressed
            print('Success acknowledged');
          },
        );
        return;
      }

      // Prepare images and their sync status by reading file bytes from filePath.
      final List<Map<String, dynamic>> galleryImages = [];
      for (var img in images) {
        Uint8List bytes = Uint8List(0);
        try {
          final dynamic filePath = img['filePath'];
          if (filePath is String && filePath.isNotEmpty) {
            final file = File(filePath);
            if (await file.exists()) {
              bytes = await file.readAsBytes();
            } else {
              // fallback to base64Content if file missing
              final b64 = img['base64Content'];
              if (b64 is String) {
                bytes = base64.decode(b64);
              } else if (b64 is Uint8List) {
                bytes = b64;
              } else if (b64 is List<int>) {
                bytes = Uint8List.fromList(b64);
              }
            }
          } else {
            final b64 = img['base64Content'];
            if (b64 is String) {
              bytes = base64.decode(b64);
            } else if (b64 is Uint8List) {
              bytes = b64;
            } else if (b64 is List<int>) {
              bytes = Uint8List.fromList(b64);
            }
          }
        } catch (_) {
          bytes = Uint8List(0);
        }

        // Skip invalid/empty image bytes to prevent Image.memory exceptions
        if (bytes.isNotEmpty) {
          galleryImages.add({
            'bytes': bytes,
            'isSynced': (img['status']?.toString().toLowerCase() == 'synced'),
          });
        } else {
          print(
              'Skipping image (empty/invalid data) for record id: ${img['id'] ?? 'unknown'}');
        }
      }

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              Provider.of<LocalizationService>(context, listen: false)
                  .getLocalizedString('attachements'),
              style: const TextStyle(color: AppColors.primaryRed),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: galleryImages.isEmpty
                  ? Center(
                      child: Text(
                        Provider.of<LocalizationService>(context, listen: false)
                            .getLocalizedString('noImagesAttached'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: galleryImages.length,
                      itemBuilder: (context, index) {
                        final img = galleryImages[index];
                        final isSynced = img['isSynced'] as bool;
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: EdgeInsets.all(0),
                                  child: Stack(
                                    children: [
                                      Container(
                                        color: Colors.black,
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: Center(
                                          child: InteractiveViewer(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(0),
                                              child: isSynced
                                                  ? Image.memory(
                                                      img['bytes'],
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      height:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .height,
                                                      fit: BoxFit.contain,
                                                    )
                                                  : ColorFiltered(
                                                      colorFilter:
                                                          const ColorFilter
                                                              .mode(
                                                        Colors.grey,
                                                        BlendMode.saturation,
                                                      ),
                                                      child: Image.memory(
                                                        img['bytes'],
                                                        width: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width,
                                                        height: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .height,
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 32,
                                        right: 32,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.white, size: 32),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: isSynced
                                      ? Image.memory(
                                          img['bytes'],
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : ColorFiltered(
                                          colorFilter: const ColorFilter.mode(
                                            Colors.grey,
                                            BlendMode.saturation,
                                          ),
                                          child: Image.memory(
                                            img['bytes'],
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ),
                              if (!isSynced)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    color: Colors.black.withOpacity(0.7),
                                    child: Center(
                                      child: Text(
                                        Provider.of<LocalizationService>(
                                                context,
                                                listen: false)
                                            .getLocalizedString(
                                                'not_uploaded_yet'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                child: Text(
                  Provider.of<LocalizationService>(context, listen: false)
                      .getLocalizedString('ok'),
                  style: const TextStyle(color: AppColors.primaryRed),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error showing images preview: $e');
    }
  }

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
    final dir = await getApplicationDocumentsDirectory();
    final uuid = Uuid();
    for (final file in files) {
      final originalName = p.basename(file.path);
      final ext = p.extension(originalName);
      final mimeType = 'image/${ext.replaceFirst('.', '')}';
      final newName =
          '${DateTime.now().millisecondsSinceEpoch}_${uuid.v4()}$ext';
      final newPath = p.join(dir.path, newName);
      try {
        await file.copy(newPath);
      } catch (_) {
        // fallback to using original path if copy failed
        // (for example when running on platforms where original path is already in app space)
      }

      imageRecords.add({
        'paymentId': paymentId,
        'voucherSerialNumber': voucherNumber,
        'fileName': originalName,
        'mimeType': mimeType,
        'filePath': newPath,
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
      if (success && status == 200) {
        await DatabaseProvider.markAllCheckImagesAsSynced(
            voucherNumber, 'confirmed');
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
