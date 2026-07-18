// lib/config/languages.dart
// 完整升级版：支持多语言显示名 + 根据当前界面语言排序

class LanguageConfig {
  final String code;
  final String flag;
  final Map<String, String> names;
  final Map<String, String> sortKeys;

  const LanguageConfig({
    required this.code,
    required this.flag,
    required this.names,
    required this.sortKeys,
  });

  /// 兼容你旧代码里的 language.name，默认显示中文
  String get name => nameOf('zh');

  /// 兼容你旧代码里的 language.pinyin，默认返回中文排序 key
  String get pinyin => sortKeyOf('zh');

  /// 兼容你旧代码里的 language.firstLetter，默认按中文排序 key 分组
  String get firstLetter => firstLetterOf('zh');

  String _normalizeUiCode(String uiLangCode) {
    final code = uiLangCode.toLowerCase().trim();
    if (code.contains('-')) return code.split('-').first;
    if (code.contains('_')) return code.split('_').first;
    return code;
  }

  String nameOf(String uiLangCode) {
    final uiCode = _normalizeUiCode(uiLangCode);
    return names[uiCode] ?? names['en'] ?? names['zh'] ?? code;
  }

  String sortKeyOf(String uiLangCode) {
    final uiCode = _normalizeUiCode(uiLangCode);
    return sortKeys[uiCode] ?? sortKeys['en'] ?? sortKeys['zh'] ?? nameOf(uiCode).toLowerCase();
  }

  String firstLetterOf(String uiLangCode) {
    final key = sortKeyOf(uiLangCode).trim();
    if (key.isEmpty) return '#';
    return key.substring(0, 1).toUpperCase();
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

  static const List<LanguageConfig> allLanguages  = [
    // A
    LanguageConfig(
      code: 'ar',
      flag: '🇸🇦',
      names: {'zh': '阿拉伯语', 'en': 'Arabic', 'ms': 'Bahasa Arab', 'vi': 'Tiếng Ả Rập', 'ru': 'Арабский'},
      sortKeys: {'zh': 'a001', 'en': 'arabic', 'ms': 'arab', 'vi': 'a rap', 'ru': 'арабский'},
    ),
    // B
    LanguageConfig(
      code: 'is',
      flag: '🇮🇸',
      names: {'zh': '冰岛语', 'en': 'Icelandic', 'ms': 'Bahasa Iceland', 'vi': 'Tiếng Iceland', 'ru': 'Исландский'},
      sortKeys: {'zh': 'b002', 'en': 'icelandic', 'ms': 'iceland', 'vi': 'iceland', 'ru': 'исландский'},
    ),
    LanguageConfig(
      code: 'pl',
      flag: '🇵🇱',
      names: {'zh': '波兰语', 'en': 'Polish', 'ms': 'Bahasa Poland', 'vi': 'Tiếng Ba Lan', 'ru': 'Польский'},
      sortKeys: {'zh': 'b003', 'en': 'polish', 'ms': 'poland', 'vi': 'ba lan', 'ru': 'польский'},
    ),
    LanguageConfig(
      code: 'bs',
      flag: '🇧🇦',
      names: {'zh': '波斯尼亚语', 'en': 'Bosnian', 'ms': 'Bahasa Bosnia', 'vi': 'Tiếng Bosnia', 'ru': 'Боснийский'},
      sortKeys: {'zh': 'b004', 'en': 'bosnian', 'ms': 'bosnia', 'vi': 'bosnia', 'ru': 'боснийский'},
    ),
    LanguageConfig(
      code: 'fa',
      flag: '🇮🇷',
      names: {'zh': '波斯语', 'en': 'Persian', 'ms': 'Bahasa Parsi', 'vi': 'Tiếng Ba Tư', 'ru': 'Персидский'},
      sortKeys: {'zh': 'b005', 'en': 'persian', 'ms': 'parsi', 'vi': 'ba tu', 'ru': 'персидский'},
    ),
    // C
    LanguageConfig(
      code: 'tn',
      flag: '🇧🇼',
      names: {'zh': '茨瓦纳语', 'en': 'Tswana', 'ms': 'Bahasa Tswana', 'vi': 'Tiếng Tswana', 'ru': 'Тсвана'},
      sortKeys: {'zh': 'c006', 'en': 'tswana', 'ms': 'tswana', 'vi': 'tswana', 'ru': 'тсвана'},
    ),
    // D
    LanguageConfig(
      code: 'da',
      flag: '🇩🇰',
      names: {'zh': '丹麦语', 'en': 'Danish', 'ms': 'Bahasa Denmark', 'vi': 'Tiếng Đan Mạch', 'ru': 'Датский'},
      sortKeys: {'zh': 'd007', 'en': 'danish', 'ms': 'denmark', 'vi': 'dan mach', 'ru': 'датский'},
    ),
    LanguageConfig(
      code: 'de',
      flag: '🇩🇪',
      names: {'zh': '德语', 'en': 'German', 'ms': 'Bahasa Jerman', 'vi': 'Tiếng Đức', 'ru': 'Немецкий'},
      sortKeys: {'zh': 'd008', 'en': 'german', 'ms': 'jerman', 'vi': 'duc', 'ru': 'немецкий'},
    ),
    // // E
    LanguageConfig(
      code: 'ru',
      flag: '🇷🇺',
      names: {'zh': '俄语', 'en': 'Russian', 'ms': 'Bahasa Rusia', 'vi': 'Tiếng Nga', 'ru': 'Русский'},
      sortKeys: {'zh': 'e009', 'en': 'russian', 'ms': 'rusia', 'vi': 'nga', 'ru': 'русский'},
    ),
    // F
    LanguageConfig(
      code: 'fr',
      flag: '🇫🇷',
      names: {'zh': '法语', 'en': 'French', 'ms': 'Bahasa Perancis', 'vi': 'Tiếng Pháp', 'ru': 'Французский'},
      sortKeys: {'zh': 'f010', 'en': 'french', 'ms': 'perancis', 'vi': 'phap', 'ru': 'французский'},
    ),
    LanguageConfig(
      code: 'sa',
      flag: '🇮🇳',
      names: {'zh': '梵语', 'en': 'Sanskrit', 'ms': 'Bahasa Sanskrit', 'vi': 'Tiếng Phạn', 'ru': 'Санскрит'},
      sortKeys: {'zh': 'f011', 'en': 'sanskrit', 'ms': 'sanskrit', 'vi': 'phan', 'ru': 'санскрит'},
    ),
    LanguageConfig(
      code: 'tl',
      flag: '🇵🇭',
      names: {'zh': '菲律宾语', 'en': 'Filipino', 'ms': 'Bahasa Filipina', 'vi': 'Tiếng Philippines', 'ru': 'Филиппинский'},
      sortKeys: {'zh': 'f012', 'en': 'filipino', 'ms': 'filipina', 'vi': 'philippines', 'ru': 'филиппинский'},
    ),
    LanguageConfig(
      code: 'fi',
      flag: '🇫🇮',
      names: {'zh': '芬兰语', 'en': 'Finnish', 'ms': 'Bahasa Finland', 'vi': 'Tiếng Phần Lan', 'ru': 'Финский'},
      sortKeys: {'zh': 'f013', 'en': 'finnish', 'ms': 'finland', 'vi': 'phan lan', 'ru': 'финский'},
    ),
    LanguageConfig(
      code: 'fj',
      flag: '🇫🇯',
      names: {'zh': '斐济语', 'en': 'Fijian', 'ms': 'Bahasa Fiji', 'vi': 'Tiếng Fiji', 'ru': 'Фиджийский'},
      sortKeys: {'zh': 'f014', 'en': 'fijian', 'ms': 'fiji', 'vi': 'fiji', 'ru': 'фиджийский'},
    ),
    LanguageConfig(
      code: 'fy',
      flag: '🇳🇱',
      names: {'zh': '弗里斯兰语', 'en': 'Frisian', 'ms': 'Bahasa Frisia', 'vi': 'Tiếng Frisia', 'ru': 'Фризский'},
      sortKeys: {'zh': 'f015', 'en': 'frisian', 'ms': 'frisia', 'vi': 'frisia', 'ru': 'фризский'},
    ),
    // // G
    LanguageConfig(
      code: 'km',
      flag: '🇰🇭',
      names: {'zh': '高棉语', 'en': 'Khmer', 'ms': 'Bahasa Khmer', 'vi': 'Tiếng Khmer', 'ru': 'Кхмерский'},
      sortKeys: {'zh': 'g016', 'en': 'khmer', 'ms': 'khmer', 'vi': 'khmer', 'ru': 'кхмерский'},
    ),
    LanguageConfig(
      code: 'ka',
      flag: '🇬🇪',
      names: {'zh': '格鲁吉亚语', 'en': 'Georgian', 'ms': 'Bahasa Georgia', 'vi': 'Tiếng Gruzia', 'ru': 'Грузинский'},
      sortKeys: {'zh': 'g017', 'en': 'georgian', 'ms': 'georgia', 'vi': 'gruzia', 'ru': 'грузинский'},
    ),
    LanguageConfig(
      code: 'gu',
      flag: '🇮🇳',
      names: {'zh': '古吉拉特语', 'en': 'Gujarati', 'ms': 'Bahasa Gujarati', 'vi': 'Tiếng Gujarat', 'ru': 'Гуджарати'},
      sortKeys: {'zh': 'g018', 'en': 'gujarati', 'ms': 'gujarati', 'vi': 'gujarat', 'ru': 'гуджарати'},
    ),
    LanguageConfig(
      code: 'gn',
      flag: '🇵🇾',
      names: {'zh': '瓜拉尼语', 'en': 'Guarani', 'ms': 'Bahasa Guarani', 'vi': 'Tiếng Guarani', 'ru': 'Гуарани'},
      sortKeys: {'zh': 'g019', 'en': 'guarani', 'ms': 'guarani', 'vi': 'guarani', 'ru': 'гуарани'},
    ),
    // H
    LanguageConfig(
      code: 'kk',
      flag: '🇰🇿',
      names: {'zh': '哈萨克语', 'en': 'Kazakh', 'ms': 'Bahasa Kazakh', 'vi': 'Tiếng Kazakh', 'ru': 'Казахский'},
      sortKeys: {'zh': 'h020', 'en': 'kazakh', 'ms': 'kazakh', 'vi': 'kazakh', 'ru': 'казахский'},
    ),
    LanguageConfig(
      code: 'ht',
      flag: '🇭🇹',
      names: {'zh': '海地克里奥尔语', 'en': 'Haitian Creole', 'ms': 'Kreol Haiti', 'vi': 'Tiếng Creole Haiti', 'ru': 'Гаитянский креольский'},
      sortKeys: {'zh': 'h021', 'en': 'haitian creole', 'ms': 'kreol haiti', 'vi': 'creole haiti', 'ru': 'гаитянский креольский'},
    ),
    LanguageConfig(
      code: 'ko',
      flag: '🇰🇷',
      names: {'zh': '韩语', 'en': 'Korean', 'ms': 'Bahasa Korea', 'vi': 'Tiếng Hàn', 'ru': 'Корейский'},
      sortKeys: {'zh': 'h022', 'en': 'korean', 'ms': 'korea', 'vi': 'han', 'ru': 'корейский'},
    ),
    LanguageConfig(
      code: 'ha',
      flag: '🇳🇬',
      names: {'zh': '豪萨语', 'en': 'Hausa', 'ms': 'Bahasa Hausa', 'vi': 'Tiếng Hausa', 'ru': 'Хауса'},
      sortKeys: {'zh': 'h023', 'en': 'hausa', 'ms': 'hausa', 'vi': 'hausa', 'ru': 'хауса'},
    ),
    LanguageConfig(
      code: 'nl',
      flag: '🇳🇱',
      names: {'zh': '荷兰语', 'en': 'Dutch', 'ms': 'Bahasa Belanda', 'vi': 'Tiếng Hà Lan', 'ru': 'Нидерландский'},
      sortKeys: {'zh': 'h024', 'en': 'dutch', 'ms': 'belanda', 'vi': 'ha lan', 'ru': 'нидерландский'},
    ),
    // J
    LanguageConfig(
      code: 'ky',
      flag: '🇰🇬',
      names: {'zh': '吉尔吉斯语', 'en': 'Kyrgyz', 'ms': 'Bahasa Kyrgyz', 'vi': 'Tiếng Kyrgyz', 'ru': 'Киргизский'},
      sortKeys: {'zh': 'j025', 'en': 'kyrgyz', 'ms': 'kyrgyz', 'vi': 'kyrgyz', 'ru': 'киргизский'},
    ),
    LanguageConfig(
      code: 'gl',
      flag: '🇪🇸',
      names: {'zh': '加利西亚语', 'en': 'Galician', 'ms': 'Bahasa Galicia', 'vi': 'Tiếng Galicia', 'ru': 'Галисийский'},
      sortKeys: {'zh': 'j026', 'en': 'galician', 'ms': 'galicia', 'vi': 'galicia', 'ru': 'галисийский'},
    ),
    LanguageConfig(
      code: 'ca',
      flag: '🇪🇸',
      names: {'zh': '加泰罗尼亚语', 'en': 'Catalan', 'ms': 'Bahasa Catalan', 'vi': 'Tiếng Catalan', 'ru': 'Каталанский'},
      sortKeys: {'zh': 'j027', 'en': 'catalan', 'ms': 'catalan', 'vi': 'catalan', 'ru': 'каталанский'},
    ),
    LanguageConfig(
      code: 'cs',
      flag: '🇨🇿',
      names: {'zh': '捷克语', 'en': 'Czech', 'ms': 'Bahasa Czech', 'vi': 'Tiếng Séc', 'ru': 'Чешский'},
      sortKeys: {'zh': 'j028', 'en': 'czech', 'ms': 'czech', 'vi': 'sec', 'ru': 'чешский'},
    ),
    // K
    LanguageConfig(
      code: 'kn',
      flag: '🇮🇳',
      names: {'zh': '卡纳达语', 'en': 'Kannada', 'ms': 'Bahasa Kannada', 'vi': 'Tiếng Kannada', 'ru': 'Каннада'},
      sortKeys: {'zh': 'k029', 'en': 'kannada', 'ms': 'kannada', 'vi': 'kannada', 'ru': 'каннада'},
    ),
    LanguageConfig(
      code: 'qu',
      flag: '🇵🇪',
      names: {'zh': '克丘亚语', 'en': 'Quechua', 'ms': 'Bahasa Quechua', 'vi': 'Tiếng Quechua', 'ru': 'Кечуа'},
      sortKeys: {'zh': 'k030', 'en': 'quechua', 'ms': 'quechua', 'vi': 'quechua', 'ru': 'кечуа'},
    ),
    LanguageConfig(
      code: 'hr',
      flag: '🇭🇷',
      names: {'zh': '克罗地亚语', 'en': 'Croatian', 'ms': 'Bahasa Croatia', 'vi': 'Tiếng Croatia', 'ru': 'Хорватский'},
      sortKeys: {'zh': 'k031', 'en': 'croatian', 'ms': 'croatia', 'vi': 'croatia', 'ru': 'хорватский'},
    ),
    LanguageConfig(
      code: 'ku',
      flag: '🇮🇶',
      names: {'zh': '库尔德语', 'en': 'Kurdish', 'ms': 'Bahasa Kurdish', 'vi': 'Tiếng Kurd', 'ru': 'Курдский'},
      sortKeys: {'zh': 'k032', 'en': 'kurdish', 'ms': 'kurdish', 'vi': 'kurd', 'ru': 'курдский'},
    ),
    // L
    LanguageConfig(
      code: 'la',
      flag: '🏛️',
      names: {'zh': '拉丁语', 'en': 'Latin', 'ms': 'Bahasa Latin', 'vi': 'Tiếng Latinh', 'ru': 'Латинский'},
      sortKeys: {'zh': 'l033', 'en': 'latin', 'ms': 'latin', 'vi': 'latinh', 'ru': 'латинский'},
    ),
    LanguageConfig(
      code: 'lv',
      flag: '🇱🇻',
      names: {'zh': '拉脱维亚语', 'en': 'Latvian', 'ms': 'Bahasa Latvia', 'vi': 'Tiếng Latvia', 'ru': 'Латышский'},
      sortKeys: {'zh': 'l034', 'en': 'latvian', 'ms': 'latvia', 'vi': 'latvia', 'ru': 'латышский'},
    ),
    LanguageConfig(
      code: 'lo',
      flag: '🇱🇦',
      names: {'zh': '老挝语', 'en': 'Lao', 'ms': 'Bahasa Lao', 'vi': 'Tiếng Lào', 'ru': 'Лаосский'},
      sortKeys: {'zh': 'l035', 'en': 'lao', 'ms': 'lao', 'vi': 'lao', 'ru': 'лаосский'},
    ),
    LanguageConfig(
      code: 'lt',
      flag: '🇱🇹',
      names: {'zh': '立陶宛语', 'en': 'Lithuanian', 'ms': 'Bahasa Lithuania', 'vi': 'Tiếng Litva', 'ru': 'Литовский'},
      sortKeys: {'zh': 'l036', 'en': 'lithuanian', 'ms': 'lithuania', 'vi': 'litva', 'ru': 'литовский'},
    ),
    LanguageConfig(
      code: 'ln',
      flag: '🇨🇩',
      names: {'zh': '林加拉语', 'en': 'Lingala', 'ms': 'Bahasa Lingala', 'vi': 'Tiếng Lingala', 'ru': 'Лингала'},
      sortKeys: {'zh': 'l037', 'en': 'lingala', 'ms': 'lingala', 'vi': 'lingala', 'ru': 'лингала'},
    ),
    LanguageConfig(
      code: 'rn',
      flag: '🇧🇮',
      names: {'zh': '隆迪语', 'en': 'Kirundi', 'ms': 'Bahasa Kirundi', 'vi': 'Tiếng Kirundi', 'ru': 'Кирунди'},
      sortKeys: {'zh': 'l038', 'en': 'kirundi', 'ms': 'kirundi', 'vi': 'kirundi', 'ru': 'кирунди'},
    ),
    LanguageConfig(
      code: 'rw',
      flag: '🇷🇼',
      names: {'zh': '卢旺达语', 'en': 'Kinyarwanda', 'ms': 'Bahasa Kinyarwanda', 'vi': 'Tiếng Kinyarwanda', 'ru': 'Киньяруанда'},
      sortKeys: {'zh': 'l039', 'en': 'kinyarwanda', 'ms': 'kinyarwanda', 'vi': 'kinyarwanda', 'ru': 'киньяруанда'},
    ),
    LanguageConfig(
      code: 'lb',
      flag: '🇱🇺',
      names: {'zh': '卢森堡语', 'en': 'Luxembourgish', 'ms': 'Bahasa Luxembourg', 'vi': 'Tiếng Luxembourg', 'ru': 'Люксембургский'},
      sortKeys: {'zh': 'l040', 'en': 'luxembourgish', 'ms': 'luxembourg', 'vi': 'luxembourg', 'ru': 'люксембургский'},
    ),
    LanguageConfig(
      code: 'ro',
      flag: '🇷🇴',
      names: {'zh': '罗马尼亚语', 'en': 'Romanian', 'ms': 'Bahasa Romania', 'vi': 'Tiếng Romania', 'ru': 'Румынский'},
      sortKeys: {'zh': 'l041', 'en': 'romanian', 'ms': 'romania', 'vi': 'romania', 'ru': 'румынский'},
    ),
    // M
    LanguageConfig(
      code: 'mg',
      flag: '🇲🇬',
      names: {'zh': '马达加斯加语', 'en': 'Malagasy', 'ms': 'Bahasa Malagasy', 'vi': 'Tiếng Malagasy', 'ru': 'Малагасийский'},
      sortKeys: {'zh': 'm042', 'en': 'malagasy', 'ms': 'malagasy', 'vi': 'malagasy', 'ru': 'малагасийский'},
    ),
    LanguageConfig(
      code: 'mt',
      flag: '🇲🇹',
      names: {'zh': '马耳他语', 'en': 'Maltese', 'ms': 'Bahasa Malta', 'vi': 'Tiếng Malta', 'ru': 'Мальтийский'},
      sortKeys: {'zh': 'm043', 'en': 'maltese', 'ms': 'malta', 'vi': 'malta', 'ru': 'мальтийский'},
    ),
    LanguageConfig(
      code: 'ml',
      flag: '🇮🇳',
      names: {'zh': '马拉雅拉姆语', 'en': 'Malayalam', 'ms': 'Bahasa Malayalam', 'vi': 'Tiếng Malayalam', 'ru': 'Малаялам'},
      sortKeys: {'zh': 'm044', 'en': 'malayalam', 'ms': 'malayalam', 'vi': 'malayalam', 'ru': 'малаялам'},
    ),
    LanguageConfig(
      code: 'mr',
      flag: '🇮🇳',
      names: {'zh': '马拉地语', 'en': 'Marathi', 'ms': 'Bahasa Marathi', 'vi': 'Tiếng Marathi', 'ru': 'Маратхи'},
      sortKeys: {'zh': 'm045', 'en': 'marathi', 'ms': 'marathi', 'vi': 'marathi', 'ru': 'маратхи'},
    ),
    LanguageConfig(
      code: 'ms',
      flag: '🇲🇾',
      names: {'zh': '马来语', 'en': 'Malay', 'ms': 'Bahasa Melayu', 'vi': 'Tiếng Mã Lai', 'ru': 'Малайский'},
      sortKeys: {'zh': 'm046', 'en': 'malay', 'ms': 'melayu', 'vi': 'ma lai', 'ru': 'малайский'},
    ),
    LanguageConfig(
     code: 'mk',
     flag: '🇲🇰',
     names: {'zh': '马其顿语', 'en': 'Macedonian', 'ms': 'Bahasa Macedonia', 'vi': 'Tiếng Macedonia', 'ru': 'Македонский'},
     sortKeys: {'zh': 'm047', 'en': 'macedonian', 'ms': 'macedonia', 'vi': 'macedonia', 'ru': 'македонский'},
    ),
    LanguageConfig(
      code: 'mi',
      flag: '🇳🇿',
      names: {'zh': '毛利语', 'en': 'Maori', 'ms': 'Bahasa Maori', 'vi': 'Tiếng Maori', 'ru': 'Маори'},
      sortKeys: {'zh': 'm048', 'en': 'maori', 'ms': 'maori', 'vi': 'maori', 'ru': 'маори'},
    ),
    LanguageConfig(
      code: 'mn',
      flag: '🇲🇳',
      names: {'zh': '蒙古语', 'en': 'Mongolian', 'ms': 'Bahasa Mongolia', 'vi': 'Tiếng Mông Cổ', 'ru': 'Монгольский'},
      sortKeys: {'zh': 'm049', 'en': 'mongolian', 'ms': 'mongolia', 'vi': 'mong co', 'ru': 'монгольский'},
    ),
    LanguageConfig(
      code: 'bn',
      flag: '🇧🇩',
      names: {'zh': '孟加拉语', 'en': 'Bengali', 'ms': 'Bahasa Bengali', 'vi': 'Tiếng Bengal', 'ru': 'Бенгальский'},
      sortKeys: {'zh': 'm050', 'en': 'bengali', 'ms': 'bengali', 'vi': 'bengal', 'ru': 'бенгальский'},
    ),
    LanguageConfig(
      code: 'my',
      flag: '🇲🇲',
      names: {'zh': '缅甸语', 'en': 'Burmese', 'ms': 'Bahasa Burma', 'vi': 'Tiếng Miến Điện', 'ru': 'Бирманский'},
      sortKeys: {'zh': 'm051', 'en': 'burmese', 'ms': 'burma', 'vi': 'mien dien', 'ru': 'бирманский'},
    ),
    // N
    LanguageConfig(
      code: 'chunom',
      flag: '🇻🇳',
      names: {'zh': '越南语-喃字', 'en': 'Chữ Nôm', 'ms': 'Aksara Nôm', 'vi': 'Chữ Nôm', 'ru': 'Тьы Ном'},
      sortKeys: {'zh': 'n105', 'en': 'chu nom', 'ms': 'aksara nom', 'vi': 'chu nom', 'ru': 'ты ном'},
    ),
    LanguageConfig(
      code: 'nv',
      flag: '🇺🇸',
      names: {'zh': '纳瓦霍语', 'en': 'Navajo', 'ms': 'Bahasa Navajo', 'vi': 'Tiếng Navajo', 'ru': 'Навахо'},
      sortKeys: {'zh': 'n052', 'en': 'navajo', 'ms': 'navajo', 'vi': 'navajo', 'ru': 'навахо'},
    ),
    LanguageConfig(
      code: 'af',
      flag: '🇿🇦',
      names: {'zh': '南非荷兰语', 'en': 'Afrikaans', 'ms': 'Bahasa Afrikaans', 'vi': 'Tiếng Afrikaans', 'ru': 'Африкаанс'},
      sortKeys: {'zh': 'n053', 'en': 'afrikaans', 'ms': 'afrikaans', 'vi': 'afrikaans', 'ru': 'африкаанс'},
    ),
    LanguageConfig(
      code: 'ne',
      flag: '🇳🇵',
      names: {'zh': '尼泊尔语', 'en': 'Nepali', 'ms': 'Bahasa Nepal', 'vi': 'Tiếng Nepal', 'ru': 'Непальский'},
      sortKeys: {'zh': 'n054', 'en': 'nepali', 'ms': 'nepal', 'vi': 'nepal', 'ru': 'непальский'},
    ),
    LanguageConfig(
      code: 'no',
      flag: '🇳🇴',
      names: {'zh': '挪威语', 'en': 'Norwegian', 'ms': 'Bahasa Norway', 'vi': 'Tiếng Na Uy', 'ru': 'Норвежский'},
      sortKeys: {'zh': 'n055', 'en': 'norwegian', 'ms': 'norway', 'vi': 'na uy', 'ru': 'норвежский'},
    ),
    
    // // P
    LanguageConfig(
      code: 'pa',
      flag: '🇮🇳',
      names: {'zh': '旁遮普语', 'en': 'Punjabi', 'ms': 'Bahasa Punjabi', 'vi': 'Tiếng Punjab', 'ru': 'Панджаби'},
      sortKeys: {'zh': 'p056', 'en': 'punjabi', 'ms': 'punjabi', 'vi': 'punjab', 'ru': 'панджаби'},
    ),
    LanguageConfig(
      code: 'pt',
      flag: '🇧🇷',
      names: {'zh': '葡萄牙语', 'en': 'Portuguese', 'ms': 'Bahasa Portugis', 'vi': 'Tiếng Bồ Đào Nha', 'ru': 'Португальский'},
      sortKeys: {'zh': 'p057', 'en': 'portuguese', 'ms': 'portugis', 'vi': 'bo dao nha', 'ru': 'португальский'},
    ),
    LanguageConfig(
      code: 'ps',
      flag: '🇦🇫',
      names: {'zh': '普什图语', 'en': 'Pashto', 'ms': 'Bahasa Pashto', 'vi': 'Tiếng Pashto', 'ru': 'Пушту'},
      sortKeys: {'zh': 'p058', 'en': 'pashto', 'ms': 'pashto', 'vi': 'pashto', 'ru': 'пушту'},
    ),
    // Q
    LanguageConfig(
      code: 'ny',
      flag: '🇲🇼',
      names: {'zh': '齐切瓦语', 'en': 'Chichewa', 'ms': 'Bahasa Chichewa', 'vi': 'Tiếng Chichewa', 'ru': 'Чичева'},
      sortKeys: {'zh': 'q059', 'en': 'chichewa', 'ms': 'chichewa', 'vi': 'chichewa', 'ru': 'чичева'},
    ),
    LanguageConfig(
      code: 'chr',
      flag: '🇺🇸',
      names: {'zh': '切罗基语', 'en': 'Cherokee', 'ms': 'Bahasa Cherokee', 'vi': 'Tiếng Cherokee', 'ru': 'Чероки'},
      sortKeys: {'zh': 'q060', 'en': 'cherokee', 'ms': 'cherokee', 'vi': 'cherokee', 'ru': 'чероки'},
    ),
    // // R
    LanguageConfig(
      code: 'ja',
      flag: '🇯🇵',
      names: {'zh': '日语', 'en': 'Japanese', 'ms': 'Bahasa Jepun', 'vi': 'Tiếng Nhật', 'ru': 'Японский'},
      sortKeys: {'zh': 'r061', 'en': 'japanese', 'ms': 'jepun', 'vi': 'nhat', 'ru': 'японский'},
    ),
    LanguageConfig(
      code: 'sv',
      flag: '🇸🇪',
      names: {'zh': '瑞典语', 'en': 'Swedish', 'ms': 'Bahasa Sweden', 'vi': 'Tiếng Thụy Điển', 'ru': 'Шведский'},
      sortKeys: {'zh': 'r062', 'en': 'swedish', 'ms': 'sweden', 'vi': 'thuy dien', 'ru': 'шведский'},
    ),
    // S
    LanguageConfig(
      code: 'sm',
      flag: '🇼🇸',
      names: {'zh': '萨摩亚语', 'en': 'Samoan', 'ms': 'Bahasa Samoa', 'vi': 'Tiếng Samoa', 'ru': 'Самоанский'},
      sortKeys: {'zh': 's063', 'en': 'samoan', 'ms': 'samoa', 'vi': 'samoa', 'ru': 'самоанский'},
    ),
    LanguageConfig(
      code: 'sr',
      flag: '🇷🇸',
      names: {'zh': '塞尔维亚语', 'en': 'Serbian', 'ms': 'Bahasa Serbia', 'vi': 'Tiếng Serbia', 'ru': 'Сербский'},
      sortKeys: {'zh': 's064', 'en': 'serbian', 'ms': 'serbia', 'vi': 'serbia', 'ru': 'сербский'},
    ),
    LanguageConfig(
      code: 'st',
      flag: '🇱🇸',
      names: {'zh': '塞索托语', 'en': 'Sesotho', 'ms': 'Bahasa Sesotho', 'vi': 'Tiếng Sesotho', 'ru': 'Сесото'},
      sortKeys: {'zh': 's065', 'en': 'sesotho', 'ms': 'sesotho', 'vi': 'sesotho', 'ru': 'сесото'},
    ),
    LanguageConfig(
      code: 'si',
      flag: '🇱🇰',
      names: {'zh': '僧伽罗语', 'en': 'Sinhala', 'ms': 'Bahasa Sinhala', 'vi': 'Tiếng Sinhala', 'ru': 'Сингальский'},
      sortKeys: {'zh': 's066', 'en': 'sinhala', 'ms': 'sinhala', 'vi': 'sinhala', 'ru': 'сингальский'},
    ),
    LanguageConfig(
      code: 'eo',
      flag: '🌐',
      names: {'zh': '世界语', 'en': 'Esperanto', 'ms': 'Bahasa Esperanto', 'vi': 'Tiếng Esperanto', 'ru': 'Эсперанто'},
      sortKeys: {'zh': 's067', 'en': 'esperanto', 'ms': 'esperanto', 'vi': 'esperanto', 'ru': 'эсперанто'},
    ),
    LanguageConfig(
      code: 'sk',
      flag: '🇸🇰',
      names: {'zh': '斯洛伐克语', 'en': 'Slovak', 'ms': 'Bahasa Slovak', 'vi': 'Tiếng Slovak', 'ru': 'Словацкий'},
      sortKeys: {'zh': 's068', 'en': 'slovak', 'ms': 'slovak', 'vi': 'slovak', 'ru': 'словацкий'},
    ),
    LanguageConfig(
      code: 'sl',
      flag: '🇸🇮',
      names: {'zh': '斯洛文尼亚语', 'en': 'Slovenian', 'ms': 'Bahasa Slovene', 'vi': 'Tiếng Slovenia', 'ru': 'Словенский'},
      sortKeys: {'zh': 's069', 'en': 'slovenian', 'ms': 'slovene', 'vi': 'slovenia', 'ru': 'словенский'},
    ),
    LanguageConfig(
      code: 'sw',
      flag: '🇰🇪',
      names: {'zh': '斯瓦希里语', 'en': 'Swahili', 'ms': 'Bahasa Swahili', 'vi': 'Tiếng Swahili', 'ru': 'Суахили'},
      sortKeys: {'zh': 's070', 'en': 'swahili', 'ms': 'swahili', 'vi': 'swahili', 'ru': 'суахили'},
    ),
    LanguageConfig(
      code: 'so',
      flag: '🇸🇴',
      names: {'zh': '索马里语', 'en': 'Somali', 'ms': 'Bahasa Somalia', 'vi': 'Tiếng Somali', 'ru': 'Сомалийский'},
      sortKeys: {'zh': 's071', 'en': 'somali', 'ms': 'somalia', 'vi': 'somali', 'ru': 'сомалийский'},
    ),
    // T
    LanguageConfig(
      code: 'tg',
      flag: '🇹🇯',
      names: {'zh': '塔吉克语', 'en': 'Tajik', 'ms': 'Bahasa Tajik', 'vi': 'Tiếng Tajik', 'ru': 'Таджикский'},
      sortKeys: {'zh': 't072', 'en': 'tajik', 'ms': 'tajik', 'vi': 'tajik', 'ru': 'таджикский'},
    ),
    LanguageConfig(
      code: 'ta',
      flag: '🇮🇳',
      names: {'zh': '泰米尔语', 'en': 'Tamil', 'ms': 'Bahasa Tamil', 'vi': 'Tiếng Tamil', 'ru': 'Тамильский'},
      sortKeys: {'zh': 't073', 'en': 'tamil', 'ms': 'tamil', 'vi': 'tamil', 'ru': 'тамильский'},
    ),
    LanguageConfig(
      code: 'te',
      flag: '🇮🇳',
      names: {'zh': '泰卢固语', 'en': 'Telugu', 'ms': 'Bahasa Telugu', 'vi': 'Tiếng Telugu', 'ru': 'Телугу'},
      sortKeys: {'zh': 't074', 'en': 'telugu', 'ms': 'telugu', 'vi': 'telugu', 'ru': 'телугу'},
    ),
    LanguageConfig(
      code: 'th',
      flag: '🇹🇭',
      names: {'zh': '泰语', 'en': 'Thai', 'ms': 'Bahasa Thai', 'vi': 'Tiếng Thái', 'ru': 'Тайский'},
      sortKeys: {'zh': 't075', 'en': 'thai', 'ms': 'thai', 'vi': 'thai', 'ru': 'тайский'},
    ),
    LanguageConfig(
      code: 'to',
      flag: '🇹🇴',
      names: {'zh': '汤加语', 'en': 'Tongan', 'ms': 'Bahasa Tonga', 'vi': 'Tiếng Tonga', 'ru': 'Тонганский'},
      sortKeys: {'zh': 't076', 'en': 'tongan', 'ms': 'tonga', 'vi': 'tonga', 'ru': 'тонганский'},
    ),
    LanguageConfig(
      code: 'tr',
      flag: '🇹🇷',
      names: {'zh': '土耳其语', 'en': 'Turkish', 'ms': 'Bahasa Turki', 'vi': 'Tiếng Thổ Nhĩ Kỳ', 'ru': 'Турецкий'},
      sortKeys: {'zh': 't077', 'en': 'turkish', 'ms': 'turki', 'vi': 'tho nhi ky', 'ru': 'турецкий'},
    ),
    LanguageConfig(
      code: 'tk',
      flag: '🇹🇲',
      names: {'zh': '土库曼语', 'en': 'Turkmen', 'ms': 'Bahasa Turkmen', 'vi': 'Tiếng Turkmen', 'ru': 'Туркменский'},
      sortKeys: {'zh': 't078', 'en': 'turkmen', 'ms': 'turkmen', 'vi': 'turkmen', 'ru': 'туркменский'},
    ),
    // W
    LanguageConfig(
      code: 'wa',
      flag: '🇧🇪',
      names: {'zh': '瓦隆语', 'en': 'Walloon', 'ms': 'Bahasa Walloon', 'vi': 'Tiếng Walloon', 'ru': 'Валлонский'},
      sortKeys: {'zh': 'w079', 'en': 'walloon', 'ms': 'walloon', 'vi': 'walloon', 'ru': 'валлонский'},
    ),
    LanguageConfig(
      code: 'cy',
      flag: '🇬🇧',
      names: {'zh': '威尔士语', 'en': 'Welsh', 'ms': 'Bahasa Wales', 'vi': 'Tiếng Wales', 'ru': 'Валлийский'},
      sortKeys: {'zh': 'w080', 'en': 'welsh', 'ms': 'wales', 'vi': 'wales', 'ru': 'валлийский'},
    ),
    LanguageConfig(
      code: 'ug',
      flag: '🇨🇳',
      names: {'zh': '维吾尔语', 'en': 'Uyghur', 'ms': 'Bahasa Uyghur', 'vi': 'Tiếng Uyghur', 'ru': 'Уйгурский'},
      sortKeys: {'zh': 'w081', 'en': 'uyghur', 'ms': 'uyghur', 'vi': 'uyghur', 'ru': 'уйгурский'},
    ),
    LanguageConfig(
      code: 'uk',
      flag: '🇺🇦',
      names: {'zh': '乌克兰语', 'en': 'Ukrainian', 'ms': 'Bahasa Ukraine', 'vi': 'Tiếng Ukraina', 'ru': 'Украинский'},
      sortKeys: {'zh': 'w082', 'en': 'ukrainian', 'ms': 'ukraine', 'vi': 'ukraina', 'ru': 'украинский'},
    ),
    LanguageConfig(
      code: 'ur',
      flag: '🇵🇰',
      names: {'zh': '乌尔都语', 'en': 'Urdu', 'ms': 'Bahasa Urdu', 'vi': 'Tiếng Urdu', 'ru': 'Урду'},
      sortKeys: {'zh': 'w083', 'en': 'urdu', 'ms': 'urdu', 'vi': 'urdu', 'ru': 'урду'},
    ),
    LanguageConfig(
      code: 'uz',
      flag: '🇺🇿',
      names: {'zh': '乌兹别克语', 'en': 'Uzbek', 'ms': 'Bahasa Uzbek', 'vi': 'Tiếng Uzbek', 'ru': 'Узбекский'},
      sortKeys: {'zh': 'w084', 'en': 'uzbek', 'ms': 'uzbek', 'vi': 'uzbek', 'ru': 'узбекский'},
    ),
    LanguageConfig(
      code: 'wo',
      flag: '🇸🇳',
      names: {'zh': '沃洛夫语', 'en': 'Wolof', 'ms': 'Bahasa Wolof', 'vi': 'Tiếng Wolof', 'ru': 'Волоф'},
      sortKeys: {'zh': 'w085', 'en': 'wolof', 'ms': 'wolof', 'vi': 'wolof', 'ru': 'волоф'},
    ),
    // X
    LanguageConfig(
      code: 'es',
      flag: '🇪🇸',
      names: {'zh': '西班牙语', 'en': 'Spanish', 'ms': 'Bahasa Sepanyol', 'vi': 'Tiếng Tây Ban Nha', 'ru': 'Испанский'},
      sortKeys: {'zh': 'x086', 'en': 'spanish', 'ms': 'sepanyol', 'vi': 'tay ban nha', 'ru': 'испанский'},
    ),
    LanguageConfig(
      code: 'he',
      flag: '🇮🇱',
      names: {'zh': '希伯来语', 'en': 'Hebrew', 'ms': 'Bahasa Ibrani', 'vi': 'Tiếng Hebrew', 'ru': 'Иврит'},
      sortKeys: {'zh': 'x087', 'en': 'hebrew', 'ms': 'ibrani', 'vi': 'hebrew', 'ru': 'иврит'},
    ),
    LanguageConfig(
      code: 'el',
      flag: '🇬🇷',
      names: {'zh': '希腊语', 'en': 'Greek', 'ms': 'Bahasa Yunani', 'vi': 'Tiếng Hy Lạp', 'ru': 'Греческий'},
      sortKeys: {'zh': 'x088', 'en': 'greek', 'ms': 'yunani', 'vi': 'hy lap', 'ru': 'греческий'},
    ),
    LanguageConfig(
      code: 'haw',
      flag: '🇺🇸',
      names: {'zh': '夏威夷语', 'en': 'Hawaiian', 'ms': 'Bahasa Hawaii', 'vi': 'Tiếng Hawaii', 'ru': 'Гавайский'},
      sortKeys: {'zh': 'x089', 'en': 'hawaiian', 'ms': 'hawaii', 'vi': 'hawaii', 'ru': 'гавайский'},
    ),
    LanguageConfig(
      code: 'sd',
      flag: '🇵🇰',
      names: {'zh': '信德语', 'en': 'Sindhi', 'ms': 'Bahasa Sindhi', 'vi': 'Tiếng Sindhi', 'ru': 'Синдхи'},
      sortKeys: {'zh': 'x090', 'en': 'sindhi', 'ms': 'sindhi', 'vi': 'sindhi', 'ru': 'синдхи'},
    ),
    LanguageConfig(
      code: 'hu',
      flag: '🇭🇺',
      names: {'zh': '匈牙利语', 'en': 'Hungarian', 'ms': 'Bahasa Hungary', 'vi': 'Tiếng Hungary', 'ru': 'Венгерский'},
      sortKeys: {'zh': 'x091', 'en': 'hungarian', 'ms': 'hungary', 'vi': 'hungary', 'ru': 'венгерский'},
    ),
    LanguageConfig(
      code: 'su',
      flag: '🇮🇩',
      names: {'zh': '巽他语', 'en': 'Sundanese', 'ms': 'Bahasa Sunda', 'vi': 'Tiếng Sunda', 'ru': 'Сунданский'},
      sortKeys: {'zh': 'x092', 'en': 'sundanese', 'ms': 'sunda', 'vi': 'sunda', 'ru': 'сунданский'},
    ),
    // // Y
    // LanguageConfig(
    //   code: 'hy',
    //   flag: '🇦🇲',
    //   names: {'zh': '亚美尼亚语', 'en': 'Armenian', 'ms': 'Bahasa Armenia', 'vi': 'Tiếng Armenia', 'ru': 'Армянский'},
    //   sortKeys: {'zh': 'y093', 'en': 'armenian', 'ms': 'armenia', 'vi': 'armenia', 'ru': 'армянский'},
    // ),
    // LanguageConfig(
    //   code: 'yi',
    //   flag: '🇮🇱',
    //   names: {'zh': '意第绪语', 'en': 'Yiddish', 'ms': 'Bahasa Yiddish', 'vi': 'Tiếng Yiddish', 'ru': 'Идиш'},
    //   sortKeys: {'zh': 'y094', 'en': 'yiddish', 'ms': 'yiddish', 'vi': 'yiddish', 'ru': 'идиш'},
    // ),
    // LanguageConfig(
    //   code: 'it',
    //   flag: '🇮🇹',
    //   names: {'zh': '意大利语', 'en': 'Italian', 'ms': 'Bahasa Itali', 'vi': 'Tiếng Ý', 'ru': 'Итальянский'},
    //   sortKeys: {'zh': 'y095', 'en': 'italian', 'ms': 'itali', 'vi': 'y', 'ru': 'итальянский'},
    // ),
    // LanguageConfig(
    //   code: 'hi',
    //   flag: '🇮🇳',
    //   names: {'zh': '印地语', 'en': 'Hindi', 'ms': 'Bahasa Hindi', 'vi': 'Tiếng Hindi', 'ru': 'Хинди'},
    //   sortKeys: {'zh': 'y096', 'en': 'hindi', 'ms': 'hindi', 'vi': 'hindi', 'ru': 'хинди'},
    // ),
    LanguageConfig(
      code: 'id',
      flag: '🇮🇩',
      names: {'zh': '印尼语', 'en': 'Indonesian', 'ms': 'Bahasa Indonesia', 'vi': 'Tiếng Indonesia', 'ru': 'Индонезийский'},
      sortKeys: {'zh': 'y097', 'en': 'indonesian', 'ms': 'indonesia', 'vi': 'indonesia', 'ru': 'индонезийский'},
    ),
    // LanguageConfig(
    //   code: 'iu',
    //   flag: '🇨🇦',
    //   names: {'zh': '因纽特语', 'en': 'Inuktitut', 'ms': 'Bahasa Inuktitut', 'vi': 'Tiếng Inuktitut', 'ru': 'Инуктитут'},
    //   sortKeys: {'zh': 'y098', 'en': 'inuktitut', 'ms': 'inuktitut', 'vi': 'inuktitut', 'ru': 'инуктитут'},
    // ),
    LanguageConfig(
      code: 'en',
      flag: '🇺🇸',
      names: {'zh': '英语', 'en': 'English', 'ms': 'Bahasa Inggeris', 'vi': 'Tiếng Anh', 'ru': 'Английский'},
      sortKeys: {'zh': 'y099', 'en': 'english', 'ms': 'inggeris', 'vi': 'anh', 'ru': 'английский'},
    ),
    // LanguageConfig(
    //   code: 'yo',
    //   flag: '🇳🇬',
    //   names: {'zh': '约鲁巴语', 'en': 'Yoruba', 'ms': 'Bahasa Yoruba', 'vi': 'Tiếng Yoruba', 'ru': 'Йоруба'},
    //   sortKeys: {'zh': 'y100', 'en': 'yoruba', 'ms': 'yoruba', 'vi': 'yoruba', 'ru': 'йоруба'},
    // ),
    LanguageConfig(
      code: 'vi',
      flag: '🇻🇳',
      names: {'zh': '越南语-国语字', 'en': 'Vietnamese', 'ms': 'Bahasa Vietnam', 'vi': 'Tiếng Việt', 'ru': 'Вьетнамский'},
      sortKeys: {'zh': 'y101', 'en': 'vietnamese', 'ms': 'vietnam', 'vi': 'viet', 'ru': 'вьетнамский'},
    ),
    // Z
    // LanguageConfig(
    //   code: 'bo',
    //   flag: '🇨🇳',
    //   names: {'zh': '藏语', 'en': 'Tibetan', 'ms': 'Bahasa Tibet', 'vi': 'Tiếng Tây Tạng', 'ru': 'Тибетский'},
    //   sortKeys: {'zh': 'z102', 'en': 'tibetan', 'ms': 'tibet', 'vi': 'tay tang', 'ru': 'тибетский'},
    // ),
    LanguageConfig(
      code: 'jv',
      flag: '🇮🇩',
      names: {'zh': '爪哇语', 'en': 'Javanese', 'ms': 'Bahasa Jawa', 'vi': 'Tiếng Java', 'ru': 'Яванский'},
      sortKeys: {'zh': 'z103', 'en': 'javanese', 'ms': 'jawa', 'vi': 'java', 'ru': 'яванский'},
    ),
    LanguageConfig(
      code: 'zh',
      flag: '🇨🇳',
      names: {'zh': '中文', 'en': 'Chinese', 'ms': 'Bahasa Cina', 'vi': 'Tiếng Trung', 'ru': 'Китайский'},
      sortKeys: {'zh': 'z104', 'en': 'chinese', 'ms': 'cina', 'vi': 'trung', 'ru': 'китайский'},
    ),
  ];
  // 当前已经开放的语言频道。
// LanguageSelectScreen 只显示这里面的语言。
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

// 语言频道列表。
static List<LanguageConfig> get channelLanguages {
  return allLanguages
      .where(
        (language) => channelLanguageCodes.contains(language.code),
      )
      .toList(growable: false);
}

// 兼容项目里暂时还没修改的旧代码。
// 后续建议逐步明确改为 allLanguages 或 channelLanguages。
static List<LanguageConfig> get supportedLanguages {
  return allLanguages;
}
  

static LanguageConfig getDefaultLanguage() {
  return allLanguages.firstWhere(
    (language) => language.code == 'zh',
  );
}
}
