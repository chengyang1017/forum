import 'package:glyphora_language_core/glyphora_language_core.dart';

class ForumLanguageChannel {
  final LanguageConfig language;
  final String? scriptCode;

  const ForumLanguageChannel({required this.language, this.scriptCode});

  String get languageCode => language.code;

  String get key {
    final script = scriptCode;

    if (script == null || script.isEmpty) {
      return language.code;
    }

    return '${language.code}:$script';
  }

  String get contentLanguageCode {
    final code = scriptCode;

    if (code == null || code.isEmpty) {
      return language.code;
    }

    final script = ScriptConfig.findByCode(code);

    if (script != null && script.aliases.isNotEmpty) {
      return script.aliases.first;
    }

    return language.code;
  }

  String nameOf(String uiLanguageCode) {
    final languageName = language.nameOf(uiLanguageCode);

    final script = scriptCode;

    if (script == null || script.isEmpty) {
      return languageName;
    }

    final scriptName = language.scriptNameOf(script, uiLanguageCode);

    return '$languageName-$scriptName';
  }
}

class ForumLanguages {
  const ForumLanguages._();

  static const Set<String> channelLanguageCodes = {
    'zh',
    'en',
    'vi',
    'ru',
    'ms',
    'th',
    'id',
    'jv',
    'ko',
    'kk',
  };

  static List<LanguageConfig> get channelLanguages {
    return LanguageConfig.allLanguages
        .where((language) => channelLanguageCodes.contains(language.code))
        .toList(growable: false);
  }

  static List<ForumLanguageChannel> get channels {
    final result = <ForumLanguageChannel>[];

    for (final language in channelLanguages) {
      // 有多个文字系统：
      // 每个文字系统独立成为一个频道。
      if (language.scriptCodes.length > 1) {
        for (final scriptCode in language.scriptCodes) {
          result.add(
            ForumLanguageChannel(language: language, scriptCode: scriptCode),
          );
        }

        continue;
      }

      result.add(ForumLanguageChannel(language: language));
    }

    return result;
  }

  static ForumLanguageChannel? findChannelByKey(String key) {
    for (final channel in channels) {
      if (channel.key == key) {
        return channel;
      }
    }

    return null;
  }

  static List<LanguageConfig> get supportedLanguages {
    return LanguageConfig.allLanguages;
  }

  static LanguageConfig getDefaultLanguage() {
    return LanguageConfig.allLanguages.firstWhere(
      (language) => language.code == 'zh',
    );
  }

  static String languageSelectTitleOf(String uiLangCode) {
    final code = uiLangCode.toLowerCase().split(RegExp(r'[-_]')).first;

    switch (code) {
      case 'en':
        return 'Select Language Channel';
      case 'ms':
        return 'Pilih Saluran Bahasa';
      case 'vi':
        return 'Chọn kênh ngôn ngữ';
      case 'ru':
        return 'Выберите языковой канал';
      case 'ja':
        return '言語チャンネルを選択';
      case 'ko':
        return '언어 채널 선택';
      case 'th':
        return 'เลือกช่องภาษา';
      case 'id':
        return 'Pilih Kanal Bahasa';
      case 'es':
        return 'Seleccionar canal de idioma';
      case 'fr':
        return 'Sélectionner le canal linguistique';
      case 'de':
        return 'Sprachkanal auswählen';
      case 'zh':
      default:
        return '选择语言频道';
    }
  }
}
