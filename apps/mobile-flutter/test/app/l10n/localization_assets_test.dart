import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glyphora_mobile/app/l10n/app_localizations.dart';
import 'package:glyphora_mobile/core/constants/forum_categories.dart';

void main() {
  final arbDirectory = Directory('lib/l10n');

  String arbCodeForLocale(locale) {
    if (locale.languageCode == 'vi' && locale.scriptCode == 'Hani') {
      return 'vi_Hani';
    }
    return locale.languageCode;
  }

  Map<String, dynamic> readLocale(String code) {
    final file = File('${arbDirectory.path}/app_$code.arb');
    return Map<String, dynamic>.from(
      jsonDecode(file.readAsStringSync()) as Map,
    );
  }

  Set<String> messageKeys(Map<String, dynamic> data) {
    return data.keys.where((key) => !key.startsWith('@')).toSet();
  }

  String categoryMessageKey(String categoryId) {
    final parts = categoryId
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((part) => part.isNotEmpty);
    final suffix = parts
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join();
    return 'category$suffix';
  }

  test('every supported interface locale has an ARB source', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final code = arbCodeForLocale(locale);
      expect(
        File('${arbDirectory.path}/app_$code.arb').existsSync(),
        isTrue,
        reason: 'missing localization ARB for $locale (app_$code.arb)',
      );
    }
  });

  test('base interface ARB files cover every English message key', () {
    final english = readLocale('en');
    final englishKeys = messageKeys(english);

    for (final code in <String>['zh', 'ja', 'ko', 'ms', 'vi', 'th']) {
      final data = readLocale(code);
      expect(
        messageKeys(data),
        containsAll(englishKeys),
        reason: 'app_$code.arb is missing interface strings',
      );
    }
  });

  test(
    'base locale category-name messages match current root category count',
    () {
      final categoryNamePattern = RegExp(r'^categoryName\d+$');

      for (final code in <String>['en', 'zh', 'ja', 'ko', 'ms', 'vi', 'th']) {
        final data = readLocale(code);
        final categoryNameKeys = messageKeys(
          data,
        ).where(categoryNamePattern.hasMatch).toList();

        expect(
          categoryNameKeys.length,
          ForumCategories.roots.length,
          reason: 'app_$code.arb categoryName messages are stale',
        );
      }
    },
  );

  test('base locale category messages cover every static forum category', () {
    for (final code in <String>['en', 'zh', 'ja', 'ko', 'ms', 'vi', 'th']) {
      final data = readLocale(code);
      final keys = messageKeys(data);

      for (final category in ForumCategories.all) {
        final key = categoryMessageKey(category.id);
        expect(
          keys.contains(key),
          isTrue,
          reason: 'app_$code.arb is missing category ${category.id} ($key)',
        );
      }
    }
  });

  test('Chữ Nôm ARB keeps Nôm overrides and Vietnamese fallback coverage', () {
    final nom = readLocale('vi_Hani');
    final vietnamese = readLocale('vi');

    expect(messageKeys(nom), containsAll(messageKeys(vietnamese)));
    expect(nom['appTitle'], '演壇');
    expect(nom['appTitle'], isNot(vietnamese['appTitle']));
    expect(nom['selectWritingSystem'], isNotNull);
  });
}
