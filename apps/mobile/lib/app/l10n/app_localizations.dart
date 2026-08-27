import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _data;
  late Map<String, String> _strings;
  late List<String> _categoryNames;
  late Map<String, String> _languageTranslations;

  AppLocalizations(this.locale) {
    _data = {};
    _strings = {};
    _categoryNames = [];
    _languageTranslations = {};
  }

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String get _fileName {
    if (locale.languageCode == 'vi' && locale.scriptCode == 'Hani') {
      return 'chunom';
    }
    return locale.languageCode;
  }

  /// 加载指定语言的 JSON 文件
  Future<bool> load() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/l10n/$_fileName.json',
      );

      _data = jsonDecode(jsonString);

      _strings = {};
      _data.forEach((key, value) {
        if (key != 'categoryNames' && key != 'languageTranslations') {
          _strings[key] = value.toString();
        }
      });

      if (_data['categoryNames'] is List) {
        _categoryNames = List<String>.from(_data['categoryNames']);
      } else {
        _categoryNames = _getDefaultCategoryNames();
      }

      if (_data['languageTranslations'] is Map) {
        _languageTranslations = Map<String, String>.from(
          _data['languageTranslations'].map(
            (k, v) => MapEntry(k, v.toString()),
          ),
        );
      } else {
        _languageTranslations = _getDefaultLanguageTranslations();
      }

      return true;
    } catch (e) {
      try {
        final String jsonString = await rootBundle.loadString(
          'assets/l10n/en.json',
        );

        _data = jsonDecode(jsonString);

        _strings = {};
        _data.forEach((key, value) {
          if (key != 'categoryNames' && key != 'languageTranslations') {
            _strings[key] = value.toString();
          }
        });

        if (_data['categoryNames'] is List) {
          _categoryNames = List<String>.from(_data['categoryNames']);
        } else {
          _categoryNames = _getDefaultCategoryNames();
        }

        if (_data['languageTranslations'] is Map) {
          _languageTranslations = Map<String, String>.from(
            _data['languageTranslations'].map(
              (k, v) => MapEntry(k, v.toString()),
            ),
          );
        } else {
          _languageTranslations = _getDefaultLanguageTranslations();
        }

        return true;
      } catch (_) {
        _strings = {};
        _categoryNames = _getDefaultCategoryNames();
        _languageTranslations = _getDefaultLanguageTranslations();
        return false;
      }
    }
  }

  List<String> _getDefaultCategoryNames() {
    return [
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
    ];
  }

  Map<String, String> _getDefaultLanguageTranslations() {
    return {
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

  /// 获取翻译字符串
  String get(String key) {
    return _strings[key] ?? key;
  }

  /// 获取带参数的翻译（支持占位符，如 {name}）
  String getWithArgs(String key, Map<String, String> args) {
    String text = _strings[key] ?? key;
    args.forEach((key, value) {
      text = text.replaceAll('{$key}', value);
    });
    return text;
  }

  // ============ 所有 Getter ============

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

  /// 分类名称列表（从 JSON 读取）
  List<String> get categoryNames => _categoryNames;

  /// 翻译语言名称（从 JSON 读取）
  String translateLanguage(String code) {
    return _languageTranslations[code] ?? code;
  }

  /// 获取语言名称（显示用）
  String getLanguageName(String code) {
    switch (code) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'ms':
        return 'Bahasa Melayu';
      case 'vi':
        return 'Tiếng Việt';
      case 'th':
        return 'ภาษาไทย';
      case 'chunom':
        return '喃字';
      default:
        return code;
    }
  }
}
