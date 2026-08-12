import 'package:flutter/material.dart';

import 'app_localizations.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    if (locale.languageCode == 'vi' && locale.scriptCode == 'Hani') {
      return true;
    }

    return const [
      'zh',
      'en',
      'ja',
      'ko',
      'ms',
      'vi',
      'th',
    ].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant AppLocalizationsDelegate old) {
    return false;
  }
}
