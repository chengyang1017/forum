import 'package:glyphora_language_core/glyphora_language_core.dart';

class ForumCategory {
  final String id;
  final String? parentId;
  final Map<String, String> names;
  final String? languageCode;
  final String? scriptCode;

  const ForumCategory({
    required this.id,
    this.parentId,
    this.names = const {},
    this.languageCode,
    this.scriptCode,
  });

  bool get isRoot => parentId == null;

  String nameOf(String uiLanguageCode) {
    final normalizedCode = uiLanguageCode.trim().toLowerCase();
    final resolvedLanguageCode = languageCode;
    final resolvedScriptCode = scriptCode;

    if (resolvedLanguageCode != null && resolvedScriptCode != null) {
      final language = LanguageConfig.findByCode(resolvedLanguageCode);

      if (language != null) {
        return language.scriptNameOf(resolvedScriptCode, normalizedCode);
      }

      return ScriptConfig.findByCode(
            resolvedScriptCode,
          )?.nameOf(normalizedCode) ??
          resolvedScriptCode;
    }

    return names[normalizedCode] ??
        names['en'] ??
        names['zh'] ??
        id.replaceAll('_', ' ');
  }
}

class ForumCategories {
  const ForumCategories._();

  static const String languageLearningCategoryId = 'language_learning';
  static const String _languageLearningPrefix = 'language_learning__';
  static const String _languageLearningScriptMarker = '__script__';

  static const List<ForumCategory> all = [
    // ============================================================
    // 一级分类
    // ============================================================
    ForumCategory(
      id: languageLearningCategoryId,
      names: {'zh': '语言学习', 'en': 'Language Learning'},
    ),
    ForumCategory(
      id: 'programming',
      names: {'zh': '编程开发', 'en': 'Programming'},
    ),
    ForumCategory(id: 'ai', names: {'zh': 'AI', 'en': 'AI'}),
    ForumCategory(id: 'technology', names: {'zh': '科技', 'en': 'Technology'}),
    ForumCategory(id: 'gaming', names: {'zh': '游戏', 'en': 'Gaming'}),
    ForumCategory(id: 'music', names: {'zh': '音乐', 'en': 'Music'}),
    ForumCategory(id: 'movies', names: {'zh': '影视', 'en': 'Film & TV'}),
    ForumCategory(id: 'campus', names: {'zh': '校园', 'en': 'Campus'}),
    ForumCategory(id: 'startup', names: {'zh': '创业', 'en': 'Startups'}),
    ForumCategory(id: 'friends', names: {'zh': '交友', 'en': 'Friends'}),
    ForumCategory(id: 'travel', names: {'zh': '旅行', 'en': 'Travel'}),
    ForumCategory(id: 'chat', names: {'zh': '闲聊', 'en': 'Chat'}),
    ForumCategory(id: 'love', names: {'zh': '爱情', 'en': 'Relationships'}),
    ForumCategory(id: 'food', names: {'zh': '美食', 'en': 'Food'}),
    ForumCategory(id: 'medicine', names: {'zh': '医学', 'en': 'Medicine'}),

    // ============================================================
    // 编程开发
    // ============================================================
    ForumCategory(
      id: 'mobile_development',
      parentId: 'programming',
      names: {'zh': '移动开发', 'en': 'Mobile Development'},
    ),
    ForumCategory(
      id: 'web_development',
      parentId: 'programming',
      names: {'zh': 'Web 开发', 'en': 'Web Development'},
    ),
    ForumCategory(
      id: 'backend_development',
      parentId: 'programming',
      names: {'zh': '后端开发', 'en': 'Backend Development'},
    ),
    ForumCategory(
      id: 'database_development',
      parentId: 'programming',
      names: {'zh': '数据库', 'en': 'Databases'},
    ),
    ForumCategory(
      id: 'flutter',
      parentId: 'mobile_development',
      names: {'zh': 'Flutter', 'en': 'Flutter'},
    ),
    ForumCategory(
      id: 'react_native',
      parentId: 'mobile_development',
      names: {'zh': 'React Native', 'en': 'React Native'},
    ),

    // ============================================================
    // 游戏
    // ============================================================
    ForumCategory(
      id: 'rpg',
      parentId: 'gaming',
      names: {'zh': 'RPG', 'en': 'RPG'},
    ),
    ForumCategory(
      id: 'fps',
      parentId: 'gaming',
      names: {'zh': 'FPS', 'en': 'FPS'},
    ),
    ForumCategory(
      id: 'strategy_games',
      parentId: 'gaming',
      names: {'zh': '策略游戏', 'en': 'Strategy Games'},
    ),
    ForumCategory(
      id: 'simulation_games',
      parentId: 'gaming',
      names: {'zh': '模拟游戏', 'en': 'Simulation Games'},
    ),

    // ============================================================
    // 影视
    // ============================================================
    ForumCategory(
      id: 'film',
      parentId: 'movies',
      names: {'zh': '电影', 'en': 'Film'},
    ),
    ForumCategory(
      id: 'tv_series',
      parentId: 'movies',
      names: {'zh': '电视剧', 'en': 'TV Series'},
    ),
    ForumCategory(
      id: 'animation',
      parentId: 'movies',
      names: {'zh': '动画', 'en': 'Animation'},
    ),
    ForumCategory(
      id: 'documentary',
      parentId: 'movies',
      names: {'zh': '纪录片', 'en': 'Documentary'},
    ),

    // ============================================================
    // 医学
    // ============================================================
    ForumCategory(
      id: 'internal_medicine',
      parentId: 'medicine',
      names: {'zh': '内科', 'en': 'Internal Medicine'},
    ),
    ForumCategory(
      id: 'surgery',
      parentId: 'medicine',
      names: {'zh': '外科', 'en': 'Surgery'},
    ),
    ForumCategory(
      id: 'pediatrics',
      parentId: 'medicine',
      names: {'zh': '儿科', 'en': 'Pediatrics'},
    ),
    ForumCategory(
      id: 'dermatology',
      parentId: 'medicine',
      names: {'zh': '皮肤科', 'en': 'Dermatology'},
    ),
    ForumCategory(
      id: 'psychiatry',
      parentId: 'medicine',
      names: {'zh': '精神医学', 'en': 'Psychiatry'},
    ),
    ForumCategory(
      id: 'cardiology',
      parentId: 'internal_medicine',
      names: {'zh': '心血管内科', 'en': 'Cardiology'},
    ),
  ];

  static final List<ForumCategory> _languageLearningLanguages = LanguageConfig
      .allLanguages
      .map(
        (language) => ForumCategory(
          id: languageLearningCategoryIdFor(language.code),
          parentId: languageLearningCategoryId,
          names: Map<String, String>.from(language.names),
          languageCode: language.code,
        ),
      )
      .toList(growable: false);

  static final List<ForumCategory> _languageLearningScripts = [
    for (final language in LanguageConfig.allLanguages)
      if (language.scriptCodes.length > 1)
        for (final scriptCode in language.scriptCodes)
          ForumCategory(
            id: languageLearningScriptCategoryIdFor(language.code, scriptCode),
            parentId: languageLearningCategoryIdFor(language.code),
            languageCode: language.code,
            scriptCode: scriptCode,
          ),
  ];

  static final List<ForumCategory> _languageLearningDynamicCategories = [
    ..._languageLearningLanguages,
    ..._languageLearningScripts,
  ];

  static final Map<String, ForumCategory> _languageLearningById = {
    for (final category in _languageLearningDynamicCategories)
      category.id: category,
  };

  static List<ForumCategory> get roots {
    return all.where((category) => category.isRoot).toList(growable: false);
  }

  static String languageLearningCategoryIdFor(String languageCode) {
    final normalizedCode = languageCode.trim().toLowerCase();
    return '$_languageLearningPrefix$normalizedCode';
  }

  static String languageLearningScriptCategoryIdFor(
    String languageCode,
    String scriptCode,
  ) {
    final normalizedLanguageCode = languageCode.trim().toLowerCase();
    final normalizedScriptCode = scriptCode.trim().toLowerCase();

    return '$_languageLearningPrefix$normalizedLanguageCode'
        '$_languageLearningScriptMarker$normalizedScriptCode';
  }

  static bool isLanguageLearningLanguageCategory(String categoryId) {
    if (!categoryId.startsWith(_languageLearningPrefix) ||
        categoryId.contains(_languageLearningScriptMarker)) {
      return false;
    }

    return categoryId.length > _languageLearningPrefix.length;
  }

  static bool isLanguageLearningScriptCategory(String categoryId) {
    if (!categoryId.startsWith(_languageLearningPrefix)) {
      return false;
    }

    final markerIndex = categoryId.indexOf(_languageLearningScriptMarker);
    return markerIndex > _languageLearningPrefix.length &&
        markerIndex + _languageLearningScriptMarker.length < categoryId.length;
  }

  static String? languageCodeOf(String categoryId) {
    if (!categoryId.startsWith(_languageLearningPrefix)) {
      return null;
    }

    final remainder = categoryId.substring(_languageLearningPrefix.length);
    final markerIndex = remainder.indexOf(_languageLearningScriptMarker);
    final rawCode = markerIndex == -1
        ? remainder
        : remainder.substring(0, markerIndex);

    if (rawCode.isEmpty) {
      return null;
    }

    return LanguageConfig.findByCode(rawCode)?.code;
  }

  static String? scriptCodeOf(String categoryId) {
    if (!isLanguageLearningScriptCategory(categoryId)) {
      return null;
    }

    final languageCode = languageCodeOf(categoryId);
    if (languageCode == null) {
      return null;
    }

    final markerIndex = categoryId.indexOf(_languageLearningScriptMarker);
    final rawScriptCode = categoryId
        .substring(markerIndex + _languageLearningScriptMarker.length)
        .trim()
        .toLowerCase();
    final language = LanguageConfig.findByCode(languageCode);

    for (final scriptCode in language?.scriptCodes ?? const <String>[]) {
      if (scriptCode.toLowerCase() == rawScriptCode) {
        return scriptCode;
      }
    }

    return null;
  }

  static ForumCategory? findById(String id) {
    for (final category in all) {
      if (category.id == id) {
        return category;
      }
    }

    return _languageLearningById[id];
  }

  static String nameOf(String categoryId, String uiLanguageCode) {
    return findById(categoryId)?.nameOf(uiLanguageCode) ??
        categoryId.replaceAll('_', ' ');
  }

  static List<ForumCategory> childrenOf(String parentId) {
    final dynamicChildren = _languageLearningDynamicCategories
        .where((category) => category.parentId == parentId)
        .toList(growable: false);

    if (dynamicChildren.isNotEmpty) {
      return dynamicChildren;
    }

    return all
        .where((category) => category.parentId == parentId)
        .toList(growable: false);
  }

  static bool hasChildren(String categoryId) {
    return childrenOf(categoryId).isNotEmpty;
  }

  static List<ForumCategory> descendantsOf(String categoryId) {
    final result = <ForumCategory>[];
    final queue = <ForumCategory>[...childrenOf(categoryId)];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);
      queue.addAll(childrenOf(current.id));
    }

    return result.toList(growable: false);
  }

  static bool isDescendantOf({
    required String categoryId,
    required String ancestorId,
  }) {
    final path = pathOf(categoryId);

    return path.length > 1 && path.take(path.length - 1).contains(ancestorId);
  }

  static List<String> pathOf(String categoryId) {
    final path = <String>[];
    final visited = <String>{};

    ForumCategory? current = findById(categoryId);

    while (current != null && visited.add(current.id)) {
      path.add(current.id);

      final parentId = current.parentId;
      if (parentId == null) {
        break;
      }

      current = findById(parentId);
    }

    return path.reversed.toList(growable: false);
  }

  static List<String> localizedPathOf(
    String categoryId,
    String uiLanguageCode,
  ) {
    return pathOf(
      categoryId,
    ).map((id) => nameOf(id, uiLanguageCode)).toList(growable: false);
  }

  static String rootIdOf(String categoryId) {
    final path = pathOf(categoryId);

    if (path.isEmpty) {
      return categoryId;
    }

    return path.first;
  }
}
