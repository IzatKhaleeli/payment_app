import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// Save credentials
Future<void> saveCredentials(String username, String password) async {
  await storage.write(key: 'username', value: username);
  await storage.write(key: 'password', value: password);
}

// Retrieve credentials
Future<Map<String, String?>> getCredentials() async {
  String? username = await storage.read(key: 'username');
  String? password = await storage.read(key: 'password');
  return {'username': username, 'password': password};
}

// Delete credentials
Future<void> deleteCredentials() async {
  await storage.delete(key: 'username');
  await storage.delete(key: 'password');
}