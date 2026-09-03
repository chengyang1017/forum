import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glyphora_mobile/app/l10n/app_localizations.dart';
import 'package:glyphora_mobile/core/constants/forum_categories.dart';

void main() {
  final assetDirectory = Directory('assets/l10n');

  String assetCodeForLocale(locale) {
    if (locale.languageCode == 'vi' && locale.scriptCode == 'Hani') {
      return 'chunom';
    }
    return locale.languageCode;
  }

  Map<String, dynamic> readLocale(String code) {
    final file = File('${assetDirectory.path}/$code.json');
    return Map<String, dynamic>.from(
      jsonDecode(file.readAsStringSync()) as Map,
    );
  }

  test('every supported interface locale has an asset', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final code = assetCodeForLocale(locale);
      expect(
        File('${assetDirectory.path}/$code.json').existsSync(),
        isTrue,
        reason: 'missing localization asset for $locale ($code.json)',
      );
    }
  });

  test('base interface locale files cover every English scalar key', () {
    final english = readLocale('en');
    final englishScalarKeys = english.entries
        .where((entry) => entry.value is! List && entry.value is! Map)
        .map((entry) => entry.key)
        .toSet();

    for (final code in <String>['zh', 'ja', 'ko', 'ms', 'vi', 'th']) {
      final data = readLocale(code);
      final scalarKeys = data.entries
          .where((entry) => entry.value is! List && entry.value is! Map)
          .map((entry) => entry.key)
          .toSet();
      expect(
        scalarKeys,
        containsAll(englishScalarKeys),
        reason: '$code.json is missing interface strings',
      );
    }
  });

  test('base locale category arrays match current root category count', () {
    for (final code in <String>['en', 'zh', 'ja', 'ko', 'ms', 'vi', 'th']) {
      final data = readLocale(code);
      final names = List<dynamic>.from(data['categoryNames'] as List);
      expect(
        names.length,
        ForumCategories.roots.length,
        reason: '$code.json categoryNames is stale',
      );
    }
  });

  test('base locale category maps cover every static forum category', () {
    for (final code in <String>['en', 'zh', 'ja', 'ko', 'ms', 'vi', 'th']) {
      final data = readLocale(code);
      final categories = Map<String, dynamic>.from(
        data['categoryTranslations'] as Map,
      );
      for (final category in ForumCategories.all) {
        expect(
          categories.containsKey(category.id),
          isTrue,
          reason: '$code.json is missing category ${category.id}',
        );
      }
    }
  });

  test('Chữ Nôm remains a partial overlay with Vietnamese fallback', () {
    final nom = readLocale('chunom');
    final vietnamese = readLocale('vi');

    expect(nom['selectWritingSystem'], isNull);
    expect(vietnamese['selectWritingSystem'], isNotNull);
    expect(nom['categoryTranslations'], isA<Map>());
  });
}
