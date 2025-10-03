import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Services/apiConstants.dart';
import '../Services/networking.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LoginState with ChangeNotifier {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  String _username = '';
  String _password = '';
  String _usernameLogin = '';
  bool _isLoading = false;
  bool _isLoginSuccessful = false;

  bool get isLoading => _isLoading;
  bool get isLoginSuccessful => _isLoginSuccessful;
  String get username => _username;
  String get usernameLogin => _usernameLogin;
  String get password => _password;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setUsernameLogin(String username) {
    _usernameLogin = username;
    notifyListeners();
  }

  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    Map<String, dynamic> map = {
      "username": username.trim(),
      "password": password,
    };
    NetworkHelper helper = NetworkHelper(url: apiUrlLogin, map: map);
    var userData;
    try {
      userData = await helper.getData();
      if (userData.containsKey('token')) {
        String token = userData['token'].toString().substring(6);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('usernameLogin', username.toLowerCase());
        await prefs.setString('token', token);

        if (userData.containsKey('hasDisconnectedPermission')) {
          int permission =
              userData['hasDisconnectedPermission'] == true ? 1 : 0;
          await prefs.setInt('disconnectedPermission', permission);
          print("saved permission is ${permission}");
        }

        return {
          'success': true,
          'token': token,
          'status': 200,
        };
      } else if (userData.containsKey('error')) {
        return {
          'success': false,
          'message': userData['error'],
          'status': userData['status'],
        };
      } else {
        print("Login failed: Token not found");
        return {
          'success': false,
          'message': 'Token not found',
          'status': 400,
        };
      }
    } catch (e) {
      print("Login failed: $e");
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }
}
