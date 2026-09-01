import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language_state.dart';

class AppLanguageCubit extends Cubit<AppLanguageState> {
  AppLanguageCubit() : super(const AppLanguageState()) {
    _loadSavedLanguage();
  }

  Locale get locale => state.locale;

  // 喃字：用标准脚本码 Hani，不要用 Nom / nom / chunom
  static const Locale chunomLocale = Locale.fromSubtags(
    languageCode: 'vi',
    scriptCode: 'Hani',
  );

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('languageCode') ?? 'zh';

    emit(state.copyWith(locale: _localeFromCode(code)));
  }

  Future<void> changeLanguageByCode(String code) async {
    final locale = _localeFromCode(code);
    emit(state.copyWith(locale: locale));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);

    debugPrint('切换语言: code=$code, locale=$locale');
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
    final locale = state.locale;

    if (locale.languageCode == 'vi' && locale.scriptCode == 'Hani') {
      return 'chunom';
    }

    return locale.languageCode;
  }
}
