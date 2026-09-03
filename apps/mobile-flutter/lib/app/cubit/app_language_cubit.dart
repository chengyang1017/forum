import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language_state.dart';

class AppLanguageCubit extends Cubit<AppLanguageState> {
  AppLanguageCubit() : super(const AppLanguageState()) {
    _loadSavedLanguage();
  }

  static const String _preferenceKey = 'languageCode';
  static const String chunomCode = 'chunom';

  static const Locale chunomLocale = Locale.fromSubtags(
    languageCode: 'vi',
    scriptCode: 'Hani',
  );

  bool _hasExplicitChange = false;

  Locale get locale => state.locale;

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_preferenceKey) ?? 'zh';
    final canonicalCode = _canonicalCode(savedCode);

    if (_hasExplicitChange || isClosed) {
      return;
    }

    emit(state.copyWith(locale: _localeFromCanonicalCode(canonicalCode)));

    if (savedCode != canonicalCode) {
      await prefs.setString(_preferenceKey, canonicalCode);
    }
  }

  Future<void> changeLanguageByCode(String code) async {
    final canonicalCode = _canonicalCode(code);
    _hasExplicitChange = true;
    emit(state.copyWith(locale: _localeFromCanonicalCode(canonicalCode)));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, canonicalCode);

    debugPrint(
      '切换语言: code=$canonicalCode, locale=${_localeFromCanonicalCode(canonicalCode)}',
    );
  }

  Future<void> changeLanguage(Locale newLocale) async {
    await changeLanguageByCode(_codeFromLocale(newLocale));
  }

  Future<void> setLocale(Locale newLocale) async {
    await changeLanguage(newLocale);
  }

  String _canonicalCode(String code) {
    final normalized = code.trim().replaceAll('_', '-').toLowerCase();

    if (normalized == chunomCode ||
        normalized == 'vi-hani' ||
        normalized == 'vi-hnom' ||
        normalized == 'vi-nom') {
      return chunomCode;
    }

    if (normalized.isEmpty) {
      return 'zh';
    }

    return normalized.split('-').first;
  }

  Locale _localeFromCanonicalCode(String code) {
    if (code == chunomCode) {
      return chunomLocale;
    }

    return Locale(code);
  }

  String _codeFromLocale(Locale locale) {
    final scriptCode = locale.scriptCode?.toLowerCase();
    final countryCode = locale.countryCode?.toLowerCase();

    if (locale.languageCode.toLowerCase() == 'vi' &&
        (scriptCode == 'hani' ||
            scriptCode == 'hnom' ||
            scriptCode == 'nom' ||
            countryCode == 'nom')) {
      return chunomCode;
    }

    if (locale.languageCode.toLowerCase() == chunomCode) {
      return chunomCode;
    }

    return _canonicalCode(locale.languageCode);
  }

  String get currentCode {
    return _codeFromLocale(state.locale);
  }
}
