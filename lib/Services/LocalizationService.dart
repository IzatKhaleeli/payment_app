import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  late Map<String, dynamic> _localizedStrings;
  late bool _isLocalizationLoaded;
  late String _selectedLanguageCode;

  LocalizationService() {
    _localizedStrings = {};
    _isLocalizationLoaded = false;
    _selectedLanguageCode = 'en';
    _loadLocalizedStrings();
  }


  Map<String, dynamic> get localizedStrings => _localizedStrings;
  bool get isLocalizationLoaded => _isLocalizationLoaded;
  String get selectedLanguageCode => _selectedLanguageCode;

  set selectedLanguageCode(String languageCode) {
    _selectedLanguageCode = languageCode;
    _loadLocalizedStrings();
    notifyListeners();
    _saveSelectedLanguageToPrefs(languageCode);
  }

  Future<void> initLocalization() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLanguageCode = prefs.getString('language_code');
    print("value inside pref language code : $savedLanguageCode");
    if (savedLanguageCode != null) {
      _selectedLanguageCode = savedLanguageCode;
    }
    _loadLocalizedStrings();
  }

  void _loadLocalizedStrings() async {
    try {
      String jsonString = await rootBundle.loadString('assets/languages/$_selectedLanguageCode.json');
      _localizedStrings = json.decode(jsonString);
      _isLocalizationLoaded = true;
      notifyListeners(); // Notify listeners when localized strings are loaded
    } catch (e) {
      print("Error loading localized strings: $e");
    }
  }

  void changeLanguage(String languageCode) {
    _selectedLanguageCode = languageCode;
    _loadLocalizedStrings();
  }
  void _saveSelectedLanguageToPrefs(String languageCode) async {
    print("saved share language: $languageCode");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }
  String getLocalizedString(String key) {
    var localizedString = _localizedStrings[key];
    if (localizedString == null) {
      print("Key '$key' not found in localized strings");
      return '** $key not found';
    }
    return localizedString;
  }

  Future<Map<String, dynamic>> loadLocalizedStrings(String languageCode) async {
    try {
      String jsonString = await rootBundle.loadString('assets/languages/$languageCode.json');
      return json.decode(jsonString);
    } catch (e) {
      print("Error loading localized strings for $languageCode: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> getLocalizedStringsForLanguage(String languageCode) async {
    try {
      String jsonString = await rootBundle.loadString('assets/languages/$languageCode.json');
      return json.decode(jsonString);
    } catch (e) {
      print("Error loading localized strings for $languageCode: $e");
      return {};
    }
  }

}
