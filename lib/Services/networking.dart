import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';

class NetworkHelper {
  final String? url;
  final dynamic map;
  final Map<String, String>? headers;
  final String method;
  final Duration timeoutDuration;

  NetworkHelper({
    this.url,
    this.map,
    this.headers,
    this.method = 'POST',
    this.timeoutDuration = const Duration(seconds: 4),
  });

  Future<dynamic> getData() async {
    try {
      http.Response response;
      if (method == 'POST') {
        print("request info \nbody:${map}\nurl:${url}");
        response = await http
            .post(
              Uri.parse(url!),
              headers: headers ??
                  {
                    'Content-Type': 'application/json',
                  },
              body: map != null ? jsonEncode(map) : null,
            )
            .timeout(timeoutDuration);
      } else if (method == 'GET') {
        if (map != null && map!.isNotEmpty) {
          var request = http.Request('GET', Uri.parse(url!));

          final requestHeaders = headers ??
              {
                'Content-Type': 'application/json',
              };
          request.headers.addAll(requestHeaders);
          request.body = jsonEncode(map);

          print("GET Request URL: ${request.url}");
          print("GET Request Headers: $requestHeaders");
          print("GET Request Body: ${jsonEncode(map)}");

          var streamedResponse = await request.send().timeout(timeoutDuration);
          response = await http.Response.fromStream(streamedResponse);
        } else {
          response = await http
              .get(
                Uri.parse(url!),
                headers: headers ??
                    {
                      'Content-Type': 'application/json ',
                    },
              )
              .timeout(timeoutDuration);
        }
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }
      // print("Response status: ${response.statusCode}, body: ${response.body}");
      if (response.statusCode == 200) {
        // print("status is 200");
        final decodedBody = utf8.decode(response.bodyBytes);
        if (decodedBody.trim().startsWith('{') ||
            decodedBody.trim().startsWith('[')) {
          return response.body.isNotEmpty ? jsonDecode(decodedBody) : {};
        } else {
          // print("Unexpected response format: $decodedBody");
          return {
            'error': 'Request Rejected',
            'status': 'Request Rejected',
          };
        }
      } else {
        // print("Response body: ${response.body}");
        // print("Error_Status: ${response.statusCode}");
        return {
          'error': 'Error: Status code ${response.statusCode}',
          'status': response.statusCode,
          'body': response.body
        };
      }
    } on TimeoutException catch (_) {
      print('Request timed out.');
      return {
        'error': 'Request timed out',
        'status': 408,
      };
    } on SocketException catch (e) {
      // Handle network errors
      print('Network error: $e');
      return {
        'error': 'Network error',
        'status': 503,
      };
    } catch (e) {
      print("Error during HTTP request: $e");
      return {
        'error': 'Exception: $e',
      };
    }
  }

  Future<dynamic> uploadFile({
    required File file,
    required String fileName,
    required String emailDetailsJson,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(url!));

      // Add headers
      request.headers.addAll(headers ??
          {
            'Content-Type': 'multipart/form-data',
          });

      // Add email details
      request.fields['emailDetails'] = emailDetailsJson;

      // Add file
      var fileStream = http.ByteStream(file.openRead());
      var length = await file.length();
      var multipartFile = http.MultipartFile(
        'files',
        fileStream,
        length,
        filename: '${fileName}.pdf',
        contentType: MediaType('application', 'pdf'),
      );
      request.files.add(multipartFile);

      var response = await request.send().timeout(timeoutDuration);

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('File uploaded successfully.');
        return response.statusCode;
      } else {
        try {
          final decodedResponse = jsonDecode(responseBody);

          String errorMessage = decodedResponse['error'];
          String errorDetail = decodedResponse['errorInDetail'];

          if (errorMessage == 'Unauthorized' &&
              errorDetail == 'JWT Authentication Failed') {
            return 401;
          }
        } catch (e) {
          print('Failed to decode JSON: $e');
        }
        return null;
      }
    } catch (e) {
      print('Error during HTTP request: $e');
      return null;
    }
  }
}
