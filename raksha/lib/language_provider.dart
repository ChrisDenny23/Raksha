import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en'; // Default language is English

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  // Load saved language preference
  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('app_language');

    if (savedLanguage != null) {
      _currentLanguage = savedLanguage;
      notifyListeners();
    }
  }

  // Set new language
  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageCode);

      notifyListeners();
    }
  }

  // Get display name for language code
  String getLanguageDisplayName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'bn':
        return 'বাংলা (Bengali)';
      case 'te':
        return 'తెలుగు (Telugu)';
      case 'mr':
        return 'मराठी (Marathi)';
      case 'ta':
        return 'தமிழ் (Tamil)';
      case 'ur':
        return 'اردو (Urdu)';
      case 'gu':
        return 'ગુજરાતી (Gujarati)';
      case 'kn':
        return 'ಕನ್ನಡ (Kannada)';
      case 'ml':
        return 'മലയാളം (Malayalam)';
      case 'pa':
        return 'ਪੰਜਾਬੀ (Punjabi)';
      case 'or':
        return 'ଓଡ଼ିଆ (Odia)';
      case 'as':
        return 'অসমীয়া (Assamese)';
      case 'sd':
        return 'سنڌي (Sindhi)';
      case 'sa':
        return 'संस्कृतम् (Sanskrit)';
      case 'ks':
        return 'कॉशुर (Kashmiri)';
      case 'ne':
        return 'नेपाली (Nepali)';
      case 'kok':
        return 'कोंकणी (Konkani)';
      case 'mai':
        return 'मैथिली (Maithili)';
      case 'doi':
        return 'डोगरी (Dogri)';
      case 'mni':
        return 'মৈতৈলোন্ (Manipuri)';
      case 'brx':
        return 'बड़ो (Bodo)';
      case 'sat':
        return 'संताली (Santali)';
      default:
        return code;
    }
  }
}
