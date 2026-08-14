import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  Locale _locale = const Locale('en');

  LanguageProvider(this.prefs) {
    final lang = prefs.getString('language') ?? 'en';
    _locale = Locale(lang);
  }

  Locale get locale => _locale;
  String get currentLanguage => _locale.languageCode;

  void setLanguage(String languageCode) {
    _locale = Locale(languageCode);
    prefs.setString('language', languageCode);
    notifyListeners();
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'en') {
      setLanguage('bn');
    } else {
      setLanguage('en');
    }
  }

  String getText(String en, String bn) {
    return _locale.languageCode == 'bn' ? bn : en;
  }
}