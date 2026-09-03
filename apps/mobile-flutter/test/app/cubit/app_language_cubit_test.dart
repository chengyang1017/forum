import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glyphora_mobile/app/cubit/app_language_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loads saved language code on startup', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'languageCode': 'en',
    });

    final cubit = AppLanguageCubit();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.locale, const Locale('en'));
    expect(cubit.currentCode, 'en');
  });

  test(
    'changeLanguageByCode updates state and persists language code',
    () async {
      final cubit = AppLanguageCubit();
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);
      await cubit.changeLanguageByCode('ms');

      final prefs = await SharedPreferences.getInstance();
      expect(cubit.locale, const Locale('ms'));
      expect(cubit.currentCode, 'ms');
      expect(prefs.getString('languageCode'), 'ms');
    },
  );

  test('normalizes Nom locale variants to vi-Hani and stores chunom', () async {
    final cubit = AppLanguageCubit();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);
    await cubit.changeLanguage(
      const Locale.fromSubtags(languageCode: 'vi', scriptCode: 'Nom'),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(cubit.locale, AppLanguageCubit.chunomLocale);
    expect(cubit.currentCode, 'chunom');
    expect(prefs.getString('languageCode'), 'chunom');
  });

  test('loads legacy Nom preference as standard vi-Hani locale', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'languageCode': 'vi_Nom',
    });

    final cubit = AppLanguageCubit();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(cubit.locale, AppLanguageCubit.chunomLocale);
    expect(cubit.currentCode, 'chunom');
    expect(prefs.getString('languageCode'), 'chunom');
  });

  test(
    'accepts hyphenated Hani and Hnom aliases and persists canonical code',
    () async {
      final cubit = AppLanguageCubit();
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      await cubit.changeLanguageByCode('vi-Hani');
      expect(cubit.locale, AppLanguageCubit.chunomLocale);

      await cubit.changeLanguageByCode('vi-Hnom');
      final prefs = await SharedPreferences.getInstance();
      expect(cubit.currentCode, 'chunom');
      expect(prefs.getString('languageCode'), 'chunom');
    },
  );

  test(
    'an explicit language change wins over the asynchronous saved load',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'languageCode': 'en',
      });

      final cubit = AppLanguageCubit();
      addTearDown(cubit.close);
      await cubit.changeLanguageByCode('vi');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.locale, const Locale('vi'));
      expect(cubit.currentCode, 'vi');
    },
  );
}
