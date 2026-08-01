import 'package:glyphora_language_core/glyphora_language_core.dart';

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
    'chunom',
  };

  static List<LanguageConfig> get channelLanguages {
    return LanguageConfig.allLanguages
        .where(
          (language) => channelLanguageCodes.contains(
            language.code,
          ),
        )
        .toList(growable: false);
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
    final code = uiLangCode
        .toLowerCase()
        .split(RegExp(r'[-_]'))
        .first;

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