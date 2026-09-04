import 'package:flutter/material.dart';

class AppLanguageState {
  const AppLanguageState({this.locale = const Locale('zh')});

  final Locale locale;

  AppLanguageState copyWith({Locale? locale}) {
    return AppLanguageState(locale: locale ?? this.locale);
  }
}
