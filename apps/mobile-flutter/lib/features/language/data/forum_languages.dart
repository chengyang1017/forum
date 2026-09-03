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

  String scriptNameOf(String uiLanguageCode) {
    final script = scriptCode;

    if (script == null || script.isEmpty) {
      return '';
    }

    return language.scriptNameOf(script, uiLanguageCode);
  }

  String nameOf(String uiLanguageCode) {
    final languageName = language.nameOf(uiLanguageCode);
    final scriptName = scriptNameOf(uiLanguageCode);

    if (scriptName.isEmpty) {
      return languageName;
    }

    return '$languageName · $scriptName';
  }
}

class ForumLanguageGroup {
  final LanguageConfig language;
  final List<ForumLanguageChannel> channels;

  ForumLanguageGroup({
    required this.language,
    required List<ForumLanguageChannel> channels,
  }) : channels = List<ForumLanguageChannel>.unmodifiable(channels);

  String get languageCode => language.code;

  String nameOf(String uiLanguageCode) => language.nameOf(uiLanguageCode);

  bool get hasScriptChoices => channels.length > 1;

  bool containsChannelKey(String key) {
    return channels.any((channel) => channel.key == key);
  }

  ForumLanguageChannel? selectedChannelForKey(String key) {
    for (final channel in channels) {
      if (channel.key == key) {
        return channel;
      }
    }

    return null;
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

  static List<ForumLanguageChannel> channelsForLanguage(
    LanguageConfig language,
  ) {
    if (language.scriptCodes.length > 1) {
      return language.scriptCodes
          .map(
            (scriptCode) => ForumLanguageChannel(
              language: language,
              scriptCode: scriptCode,
            ),
          )
          .toList(growable: false);
    }

    return <ForumLanguageChannel>[ForumLanguageChannel(language: language)];
  }

  static List<ForumLanguageGroup> get channelGroups {
    return channelLanguages
        .map(
          (language) => ForumLanguageGroup(
            language: language,
            channels: channelsForLanguage(language),
          ),
        )
        .toList(growable: false);
  }

  static List<ForumLanguageChannel> get channels {
    return <ForumLanguageChannel>[
      for (final group in channelGroups) ...group.channels,
    ];
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

  static String scriptSelectTitleOf(String uiLangCode) {
    final code = uiLangCode.toLowerCase().split(RegExp(r'[-_]')).first;

    switch (code) {
      case 'en':
        return 'Select Writing System';
      case 'ms':
        return 'Pilih Sistem Tulisan';
      case 'vi':
        return 'Chọn hệ chữ';
      case 'ru':
        return 'Выберите письменность';
      case 'ja':
        return '文字体系を選択';
      case 'ko':
        return '문자 체계 선택';
      case 'th':
        return 'เลือกระบบอักษร';
      case 'id':
        return 'Pilih Sistem Tulisan';
      case 'zh':
      default:
        return '选择文字系统';
    }
  }
}
