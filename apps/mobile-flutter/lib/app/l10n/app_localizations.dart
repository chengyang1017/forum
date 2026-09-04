import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms'),
    Locale('vi'),
    Locale('th'),
    Locale.fromSubtags(languageCode: 'vi', scriptCode: 'Hani'),
  ];

  final Locale locale;

  Map<String, String> _strings = <String, String>{};
  List<String> _categoryNames = <String>[];
  Map<String, String> _categoryTranslations = <String, String>{};
  Map<String, String> _languageTranslations = <String, String>{};

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  bool get isChunom =>
      locale.languageCode == 'vi' && locale.scriptCode == 'Hani';

  String get assetCode => isChunom ? 'chunom' : locale.languageCode;

  String get _fallbackAssetCode => isChunom ? 'vi' : 'en';

  Future<Map<String, dynamic>> _readAsset(String code) async {
    final jsonString = await rootBundle.loadString('assets/l10n/$code.json');
    return Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
  }

  Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) {
      return <String, String>{};
    }

    return value.map<String, String>(
      (key, item) => MapEntry(key.toString(), item.toString()),
    );
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value.map((item) => item.toString()).toList(growable: true);
  }

  void _overlayList(List<String> target, List<String> overlay) {
    for (var index = 0; index < overlay.length; index++) {
      if (index < target.length) {
        target[index] = overlay[index];
      } else {
        target.add(overlay[index]);
      }
    }
  }

  void _collectStrings(Map<String, dynamic> source) {
    source.forEach((key, value) {
      if (key == 'categoryNames' ||
          key == 'categoryTranslations' ||
          key == 'languageTranslations') {
        return;
      }

      if (value is String || value is num || value is bool) {
        _strings[key] = value.toString();
      }
    });
  }

  Future<bool> load() async {
    try {
      final fallback = await _readAsset(_fallbackAssetCode);
      Map<String, dynamic> overlay = fallback;

      if (assetCode != _fallbackAssetCode) {
        overlay = await _readAsset(assetCode);
      }

      _strings = <String, String>{};
      _collectStrings(fallback);
      if (!identical(fallback, overlay)) {
        _collectStrings(overlay);
      }

      _categoryNames = _stringList(fallback['categoryNames']);
      if (!identical(fallback, overlay)) {
        _overlayList(_categoryNames, _stringList(overlay['categoryNames']));
      }
      if (_categoryNames.isEmpty) {
        _categoryNames = _getDefaultCategoryNames();
      }

      _categoryTranslations = _stringMap(fallback['categoryTranslations']);
      if (!identical(fallback, overlay)) {
        _categoryTranslations.addAll(
          _stringMap(overlay['categoryTranslations']),
        );
      }

      _languageTranslations = _stringMap(fallback['languageTranslations']);
      if (!identical(fallback, overlay)) {
        _languageTranslations.addAll(
          _stringMap(overlay['languageTranslations']),
        );
      }
      if (_languageTranslations.isEmpty) {
        _languageTranslations = _getDefaultLanguageTranslations();
      }

      return true;
    } catch (error) {
      debugPrint('加载本地化资源失败: $error');

      try {
        final fallback = await _readAsset('en');
        _strings = <String, String>{};
        _collectStrings(fallback);
        _categoryNames = _stringList(fallback['categoryNames']);
        _categoryTranslations = _stringMap(fallback['categoryTranslations']);
        _languageTranslations = _stringMap(fallback['languageTranslations']);
        return true;
      } catch (_) {
        _strings = <String, String>{};
        _categoryNames = _getDefaultCategoryNames();
        _categoryTranslations = <String, String>{};
        _languageTranslations = _getDefaultLanguageTranslations();
        return false;
      }
    }
  }

  List<String> _getDefaultCategoryNames() {
    return <String>[
      '语言学习',
      '编程开发',
      'AI',
      '科技',
      '游戏',
      '音乐',
      '影视',
      '校园',
      '创业',
      '交友',
      '旅行',
      '闲聊',
      '爱情',
      '美食',
      '医学',
    ];
  }

  Map<String, String> _getDefaultLanguageTranslations() {
    return <String, String>{
      'zh': '中文',
      'en': 'English',
      'ja': '日本語',
      'ko': '한국어',
      'fr': 'Français',
      'de': 'Deutsch',
      'es': 'Español',
      'pt': 'Português',
      'ru': 'Русский',
      'it': 'Italiano',
      'ar': 'العربية',
      'th': 'ภาษาไทย',
      'vi': 'Tiếng Việt',
      'ms': 'Bahasa Melayu',
      'id': 'Bahasa Indonesia',
      'hi': 'हिन्दी',
      'tr': 'Türkçe',
    };
  }

  String get(String key) => _strings[key] ?? key;

  String getWithArgs(String key, Map<String, String> args) {
    var text = _strings[key] ?? key;
    args.forEach((key, value) {
      text = text.replaceAll('{$key}', value);
    });
    return text;
  }

  String get appTitle => get('appTitle');
  String get forumCategories => get('forumCategories');
  String get currentChannel => get('currentChannel');
  String get currentLanguage => get('currentLanguage');
  String get switchLanguage => get('switchLanguage');
  String get selectLanguage => get('selectLanguage');
  String get home => get('home');
  String get messages => get('messages');
  String get profile => get('profile');
  String get post => get('post');
  String get publish => get('publish');
  String get title => get('title');
  String get content => get('content');
  String get selectImage => get('selectImage');
  String get addMoreImages => get('addMoreImages');
  String get uploading => get('uploading');
  String get noPosts => get('noPosts');
  String get loadFailed => get('loadFailed');
  String get refresh => get('refresh');
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get search => get('search');
  String get settings => get('settings');
  String get midnightMode => get('midnightMode');
  String get midnightModeDesc => get('midnightModeDesc');
  String get logout => get('logout');
  String get login => get('login');
  String get register => get('register');
  String get email => get('email');
  String get password => get('password');
  String get username => get('username');
  String get send => get('send');
  String get reply => get('reply');
  String get like => get('like');
  String get comment => get('comment');
  String get share => get('share');
  String get delete => get('delete');
  String get edit => get('edit');
  String get save => get('save');
  String get justNow => get('justNow');
  String get minutesAgo => get('minutesAgo');
  String get hoursAgo => get('hoursAgo');
  String get daysAgo => get('daysAgo');
  String get setNickname => get('setNickname');
  String get setBirthday => get('setBirthday');
  String get selectBirthDate => get('selectBirthDate');
  String get clearBirthday => get('clearBirthday');
  String get showAge => get('showAge');
  String get showAgeDesc => get('showAgeDesc');
  String get posts => get('posts');
  String get likesCount => get('likesCount');
  String get introYourself => get('introYourself');
  String get addTagsHint => get('addTagsHint');
  String get languageAbility => get('languageAbility');
  String get add => get('add');
  String get nativeLanguage => get('nativeLanguage');
  String get native => get('native');
  String get changeLevel => get('changeLevel');
  String get quickSelect => get('quickSelect');
  String get myPosts => get('myPosts');
  String get editTags => get('editTags');
  String get editNickname => get('editNickname');
  String get newNickname => get('newNickname');
  String get nicknameHint => get('nicknameHint');
  String get editUsername => get('editUsername');
  String get newUsername => get('newUsername');
  String get usernameHint => get('usernameHint');
  String get editBio => get('editBio');
  String get bioHint => get('bioHint');
  String get done => get('done');
  String get addTag => get('addTag');
  String get selectedTags => get('selectedTags');
  String get recommendTags => get('recommendTags');
  String get customTagHint => get('customTagHint');
  String get tagExists => get('tagExists');
  String get tagMax => get('tagMax');
  String get tagsUpdated => get('tagsUpdated');
  String get birthdayUpdated => get('birthdayUpdated');
  String get updateFailed => get('updateFailed');
  String get avatarUpdated => get('avatarUpdated');
  String get avatarFailed => get('avatarFailed');
  String get permissionDenied => get('permissionDenied');
  String get nicknameUpdated => get('nicknameUpdated');
  String get usernameUpdated => get('usernameUpdated');
  String get usernameUsed => get('usernameUsed');
  String get bioUpdated => get('bioUpdated');
  String get languageUpdated => get('languageUpdated');
  String get languageExists => get('languageExists');
  String get languageName => get('languageName');
  String get notLoggedIn => get('notLoggedIn');
  String get noDynamic => get('noDynamic');
  String get error => get('error');
  String get securitySettings => get('securitySettings');
  String get securitySettingsDesc => get('securitySettingsDesc');
  String get changePassword => get('changePassword');
  String get changePasswordDesc => get('changePasswordDesc');
  String get blockList => get('blockList');
  String get blockListDesc => get('blockListDesc');
  String get logoutConfirm => get('logoutConfirm');
  String get logoutConfirmDesc => get('logoutConfirmDesc');
  String get developing => get('developing');
  String get discover => get('discover');
  String get addFriend => get('addFriend');
  String get startChat => get('startChat');
  String get friendRequestSent => get('friendRequestSent');
  String get noOtherUsers => get('noOtherUsers');
  String get createChatFailed => get('createChatFailed');
  String get editTagsTitle => get('editTagsTitle');
  String get editAgeTitle => get('editAgeTitle');
  String get year => get('year');
  String get month => get('month');
  String get day => get('day');
  String get editNicknameTitle => get('editNicknameTitle');
  String get newNicknameLabel => get('newNicknameLabel');
  String get editUsernameTitle => get('editUsernameTitle');
  String get newUsernameLabel => get('newUsernameLabel');
  String get editBioTitle => get('editBioTitle');
  String get languagesTitle => get('languagesTitle');
  String get languagesUpdated => get('languagesUpdated');
  String get addLanguage => get('addLanguage');
  String get ageUpdated => get('ageUpdated');
  String get galleryPermission => get('galleryPermission');
  String get tagUpdated => get('tagUpdated');
  String get tagInputHint => get('tagInputHint');

  List<String> get categoryNames => List<String>.unmodifiable(_categoryNames);

  String categoryName(String categoryId, {String? fallback}) {
    return _categoryTranslations[categoryId] ??
        fallback ??
        categoryId.replaceAll('_', ' ');
  }

  String translateLanguage(String code) {
    return _languageTranslations[code] ?? code;
  }

  String getLanguageName(String code) {
    if (code == 'chunom') {
      return get('nomWritingSystem');
    }
    return translateLanguage(code);
  }
}
