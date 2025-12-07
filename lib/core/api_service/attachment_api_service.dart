import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import '../../Services/apiConstants.dart';
import '../../Services/globalError.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AttachmentApiService {
  static Future<Map<String, dynamic>> uploadAttachments({
    required String voucherSerialNumber,
    required Map<String, String> headers,
    required List<File> files,
  }) async {
    print(
        "Uploading attachments for voucher: $voucherSerialNumber with ${files.length} files.");
    http.Response? response;
    final uri = Uri.parse(apiUrlAttachments(voucherSerialNumber));
    final request = http.MultipartRequest('POST', uri);

    for (var file in files) {
      try {
        if (!file.existsSync()) continue;
        String fileName = file.path.split('/').last;
        String? mimeType =
            lookupMimeType(file.path) ?? 'application/octet-stream';

        final multipartFile = await http.MultipartFile.fromPath(
          'attachments',
          file.path,
          filename: fileName,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
        request.files.add(multipartFile);
      } catch (e) {
        print('Error attaching file ${file.path}: $e');
      }
    }
    // Print full request before sending
    // print('--- Multipart Request ---');
    print('URL: ${request.url}');
    print('Headers: ${request.headers}');
    // print('Fields: ${request.fields}');
    print('Files:');
    for (var f in request.files) {
      print(
          '  name: ${f.field}, filename: ${f.filename}, length: ${f.length}, contentType: ${f.contentType}');
    }
    // print('-------------------------');

    http.StreamedResponse? streamedResponse;
    try {
      request.headers.addAll(headers);
      streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      response = await http.Response.fromStream(streamedResponse);
    } on TimeoutException catch (e) {
      print('Multipart upload timed out: $e');
      GlobalErrorNotifier.showError('Upload timed out.');
      return {
        'success': false,
        'status': 0,
        'data': response,
      };
    } catch (e) {
      print('Error uploading attachments: $e');
      return {
        'success': false,
        'status': 0,
        'data': 'Error uploading attachments: $e',
      };
    }

    try {
      final int statusCode = response.statusCode;
      final dynamic data =
          response.body.isNotEmpty ? json.decode(response.body) : null;
      final bool success = statusCode == 200 || statusCode == 201;
      print(
          'Upload response - Status: $statusCode, Success: $success, Data: $data');

      if (success && files.isNotEmpty) {
        List<Map<String, dynamic>> imageRecords = [];
        for (var file in files) {
          String fileName = file.path.split('/').last;
          String? mimeType =
              lookupMimeType(file.path) ?? 'application/octet-stream';
          String base64Content = base64.encode(await file.readAsBytes());
          imageRecords.add({
            'fileName': fileName,
            'mimeType': mimeType,
            'base64Content': base64Content,
            'paymentId': voucherSerialNumber,
          });
        }
      }

      return {
        'success': success,
        'status': statusCode,
        'data': data,
      };
    } catch (e) {
      print('Error parsing response: $e');
      return {
        'success': false,
        'status': response.statusCode,
        'data': response.body,
      };
    }
  }
}
