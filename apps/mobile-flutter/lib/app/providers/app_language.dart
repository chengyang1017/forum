import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  Locale _locale = const Locale('zh');

  Locale get locale => _locale;

  // 喃字：用标准脚本码 Hani，不要用 Nom / nom / chunom
  static const Locale chunomLocale = Locale.fromSubtags(
    languageCode: 'vi',
    scriptCode: 'Hani',
  );

  AppLanguage() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('languageCode') ?? 'zh';

    _locale = _localeFromCode(code);
    notifyListeners();
  }

  Future<void> changeLanguageByCode(String code) async {
    _locale = _localeFromCode(code);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);

    debugPrint('切换语言: code=$code, locale=$_locale');

    notifyListeners();
  }

  Future<void> changeLanguage(Locale newLocale) async {
    final code = _codeFromLocale(newLocale);
    await changeLanguageByCode(code);
  }

  Future<void> setLocale(Locale newLocale) async {
    await changeLanguage(newLocale);
  }

  Locale _localeFromCode(String code) {
    if (code == 'chunom' ||
        code == 'vi_Hani' ||
        code == 'vi_Nom' ||
        code == 'vi_nom') {
      return chunomLocale;
    }

    return Locale(code);
  }

  String _codeFromLocale(Locale locale) {
    if (locale.languageCode == 'vi' &&
        (locale.scriptCode == 'Hani' ||
            locale.scriptCode == 'Nom' ||
            locale.countryCode == 'NOM' ||
            locale.countryCode == 'nom')) {
      return 'chunom';
    }

    if (locale.languageCode == 'chunom') {
      return 'chunom';
    }

    return locale.languageCode;
  }

  String get currentCode {
    if (_locale.languageCode == 'vi' && _locale.scriptCode == 'Hani') {
      return 'chunom';
    }

    return _locale.languageCode;
  }
}
