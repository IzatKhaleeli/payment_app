import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'dart:io';

class NetworkHelper {
  final String? url;
  final Map<String, dynamic>? map;
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
    print("api :${url}:${map}:${headers}");

    try {
      http.Response response;
      if (method == 'POST') {
        response = await http.post(
          Uri.parse(url!),
          headers: headers ?? {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: map != null ? jsonEncode(map) : null,
        ).timeout(timeoutDuration);
      } else if (method == 'GET') {
        response = await http.get(
          Uri.parse(url!),
          headers: headers ?? {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ).timeout(timeoutDuration);
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 200) {
        print("status iss 200");
        return jsonDecode(response.body);
      } else {
        print("status is: ${response.statusCode}");
        print("Response body: ${response.body}");
        return null;
      }
    }
    on TimeoutException catch (_) {
      // Handle the timeout exception
      print('Request timed out.');
      return http.Response('Request timed out', 408); // Returning a response with 408 Request Timeout status code
    } on SocketException catch (e) {
      // Handle network errors
      print('Network error: $e');
      return http.Response('Network error', 503); // Returning a response with 503 Service Unavailable status code
    }
    catch (e) {
      print("Error during HTTP request: $e");
      return null;
    }
  }


  Future<bool> testConnection() async {
    try {
      http.Response response = await http.get(Uri.parse(url!)).timeout(timeoutDuration);
      if (response.statusCode == 200) {
        print('response'+response.toString());
        return true;
      } else {
        print('response'+response.toString());
        return false;
      }
    } catch (e) {
      return false;
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
      request.headers.addAll(headers ?? {
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

      // Send request
      var response = await request.send().timeout(timeoutDuration);;

      // Get response body
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('File uploaded successfully.');
        return response.statusCode;
      } else {
        try {
          final decodedResponse = jsonDecode(responseBody);

          // Access individual fields
          String errorMessage = decodedResponse['error'];
          String errorDetail = decodedResponse['errorInDetail'];
          // print('Error: $errorMessage');
          // print('Error Detail: $errorDetail');

          // Check if the token is expired
          if (errorMessage == 'Unauthorized' && errorDetail == 'JWT Authentication Failed') {
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