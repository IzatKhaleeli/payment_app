import '../../Services/apiConstants.dart';
import '../../Services/networking.dart';

class PaymentApiService {
  static Future<Map<String, dynamic>> getPortalStatuses({
    required dynamic body,
    required Map<String, String> headers,
  }) async {
    final helper = NetworkHelper(
      url: apiUrlStatuses,
      method: 'GET',
      map: body,
      headers: headers,
    );

    final response = await helper.getData();

    if (response is List) {
      return {
        'success': true,
        'status': 200,
        'data': response
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList(),
      };
    } else if (response is Map<String, dynamic>) {
      int statusCode = 0;

      if (response.containsKey('code')) {
        statusCode = int.tryParse(response['code'].toString()) ?? 0;
      }

      return {
        'success': statusCode == 200,
        'status': statusCode,
        'data': response,
      };
    } else {
      return {
        'success': false,
        'status': 0,
        'data': response,
      };
    }
  }
}
