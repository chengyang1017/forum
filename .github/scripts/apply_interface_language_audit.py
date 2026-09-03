from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / 'apps' / 'mobile-flutter'


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding='utf-8')


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding='utf-8')


def replace_once(text: str, old: str, new: str, *, label: str) -> str:
    if old not in text:
        raise RuntimeError(f'missing replacement marker for {label}')
    return text.replace(old, new, 1)


def replace_all_checked(text: str, old: str, new: str, *, label: str, minimum: int = 1) -> str:
    count = text.count(old)
    if count < minimum:
        raise RuntimeError(f'missing replacement marker for {label}: found {count}')
    return text.replace(old, new)


# ---------------------------------------------------------------------------
# Canonical interface-language state. Chữ Nôm is a Vietnamese writing system,
# stored canonically as "chunom" while represented by Locale vi-Hani.
# ---------------------------------------------------------------------------
write(
    'apps/mobile-flutter/lib/app/cubit/app_language_cubit.dart',
    r'''import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language_state.dart';

class AppLanguageCubit extends Cubit<AppLanguageState> {
  AppLanguageCubit() : super(const AppLanguageState()) {
    _loadSavedLanguage();
  }

  static const String _preferenceKey = 'languageCode';
  static const String chunomCode = 'chunom';

  static const Locale chunomLocale = Locale.fromSubtags(
    languageCode: 'vi',
    scriptCode: 'Hani',
  );

  bool _hasExplicitChange = false;

  Locale get locale => state.locale;

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_preferenceKey) ?? 'zh';
    final canonicalCode = _canonicalCode(savedCode);

    if (_hasExplicitChange || isClosed) {
      return;
    }

    emit(state.copyWith(locale: _localeFromCanonicalCode(canonicalCode)));

    if (savedCode != canonicalCode) {
      await prefs.setString(_preferenceKey, canonicalCode);
    }
  }

  Future<void> changeLanguageByCode(String code) async {
    final canonicalCode = _canonicalCode(code);
    _hasExplicitChange = true;
    emit(state.copyWith(locale: _localeFromCanonicalCode(canonicalCode)));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, canonicalCode);

    debugPrint(
      '切换语言: code=$canonicalCode, locale=${_localeFromCanonicalCode(canonicalCode)}',
    );
  }

  Future<void> changeLanguage(Locale newLocale) async {
    await changeLanguageByCode(_codeFromLocale(newLocale));
  }

  Future<void> setLocale(Locale newLocale) async {
    await changeLanguage(newLocale);
  }

  String _canonicalCode(String code) {
    final normalized = code.trim().replaceAll('_', '-').toLowerCase();

    if (normalized == chunomCode ||
        normalized == 'vi-hani' ||
        normalized == 'vi-hnom' ||
        normalized == 'vi-nom') {
      return chunomCode;
    }

    if (normalized.isEmpty) {
      return 'zh';
    }

    return normalized.split('-').first;
  }

  Locale _localeFromCanonicalCode(String code) {
    if (code == chunomCode) {
      return chunomLocale;
    }

    return Locale(code);
  }

  String _codeFromLocale(Locale locale) {
    final scriptCode = locale.scriptCode?.toLowerCase();
    final countryCode = locale.countryCode?.toLowerCase();

    if (locale.languageCode.toLowerCase() == 'vi' &&
        (scriptCode == 'hani' ||
            scriptCode == 'hnom' ||
            scriptCode == 'nom' ||
            countryCode == 'nom')) {
      return chunomCode;
    }

    if (locale.languageCode.toLowerCase() == chunomCode) {
      return chunomCode;
    }

    return _canonicalCode(locale.languageCode);
  }

  String get currentCode {
    return _codeFromLocale(state.locale);
  }
}
''',
)


# ---------------------------------------------------------------------------
# Localization loader: one supported-locale registry, per-key fallback, and
# map/list overlays. Nôm intentionally falls back to Vietnamese rather than
# fabricating missing Nôm translations.
# ---------------------------------------------------------------------------
write(
    'apps/mobile-flutter/lib/app/l10n/app_localizations.dart',
    r'''import 'dart:convert';

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

  bool get isChunom => locale.languageCode == 'vi' && locale.scriptCode == 'Hani';

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
''',
)

write(
    'apps/mobile-flutter/lib/app/l10n/localizations_delegate.dart',
    r'''import 'package:flutter/material.dart';

import 'app_localizations.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) =>
          supported.languageCode == locale.languageCode &&
          supported.scriptCode == locale.scriptCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant AppLocalizationsDelegate old) => false;
}
''',
)


# main.dart: remove stale Nom locale, centralize supported locales, localize app title.
path = 'apps/mobile-flutter/lib/main.dart'
text = read(path)
text = replace_once(
    text,
    "import 'app/l10n/localizations_delegate.dart';",
    "import 'app/l10n/app_localizations.dart';\nimport 'app/l10n/localizations_delegate.dart';",
    label='main l10n import',
)
text = re.sub(
    r"\n  static const Locale chunomLocale = Locale\.fromSubtags\(\n    languageCode: 'vi',\n    scriptCode: 'Nom',\n  \);\n",
    '\n',
    text,
    count=1,
)
text = replace_once(
    text,
    "                  title: '论坛App',\n                  locale: languageState.locale,\n                  supportedLocales: const [\n                    Locale('zh'),\n                    Locale('en'),\n                    Locale('ja'),\n                    Locale('ko'),\n                    Locale('ms'),\n                    Locale('vi'),\n                    Locale('th'),\n                    Locale.fromSubtags(\n                      languageCode: 'vi',\n                      scriptCode: 'Hani',\n                    ),\n                  ],",
    "                  onGenerateTitle: (context) =>\n                      AppLocalizations.of(context)?.appTitle ?? 'Glyphora',\n                  locale: languageState.locale,\n                  supportedLocales: AppLocalizations.supportedLocales,",
    label='main supported locales',
)
write(path, text)


# ---------------------------------------------------------------------------
# Settings: Vietnamese is one interface-language group, then Quốc ngữ/Nôm.
# ---------------------------------------------------------------------------
write(
    'apps/mobile-flutter/lib/features/profile/presentation/screens/settings_screen.dart',
    r'''import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/cubit/app_language_cubit.dart';
import '../../../../app/cubit/app_theme_cubit.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart' as auth_cubit;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<_LanguageItem> _languages = <_LanguageItem>[
    _LanguageItem(code: 'zh', flag: '🇨🇳', native: '中文'),
    _LanguageItem(code: 'en', flag: '🇺🇸', native: 'English'),
    _LanguageItem(code: 'ja', flag: '🇯🇵', native: '日本語'),
    _LanguageItem(code: 'ko', flag: '🇰🇷', native: '한국어'),
    _LanguageItem(code: 'ms', flag: '🇲🇾', native: 'Bahasa Melayu'),
    _LanguageItem(
      code: 'vi',
      flag: '🇻🇳',
      native: 'Tiếng Việt',
      hasWritingSystems: true,
    ),
    _LanguageItem(code: 'th', flag: '🇹🇭', native: 'ภาษาไทย'),
  ];

  Future<void> _logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirm),
        content: Text(l10n.logoutConfirmDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await context.read<auth_cubit.AuthCubit>().logout();
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.updateFailed}: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final appLanguage = context.watch<AppLanguageCubit>();
    final appTheme = context.watch<AppThemeCubit>();
    final currentLangName = _currentLanguageName(
      context,
      appLanguage.currentCode,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildItem(
            context,
            icon: Icons.language,
            title: l10n.switchLanguage,
            subtitle: '${l10n.currentLanguage}: $currentLangName',
            onTap: () => _showLanguagePicker(context, appLanguage, l10n),
          ),
          SwitchListTile.adaptive(
            secondary: Icon(Icons.bedtime_rounded, color: colorScheme.primary),
            title: Text(
              l10n.midnightMode,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              l10n.midnightModeDesc,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            value: appTheme.isMidnight,
            onChanged: appTheme.setMidnight,
          ),
          _buildItem(
            context,
            icon: Icons.shield,
            title: l10n.securitySettings,
            subtitle: l10n.securitySettingsDesc,
            onTap: () => context.push(AppRoutes.securitySettings),
          ),
          _buildItem(
            context,
            icon: Icons.lock,
            title: l10n.changePassword,
            subtitle: l10n.changePasswordDesc,
            onTap: () => context.push(AppRoutes.changePassword),
          ),
          _buildItem(
            context,
            icon: Icons.block,
            title: l10n.blockList,
            subtitle: l10n.blockListDesc,
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.developing)));
            },
          ),
          const Divider(height: 32, thickness: 1),
          _buildLogoutItem(context, l10n),
        ],
      ),
    );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    AppLanguageCubit appLanguage,
    AppLocalizations l10n,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.selectLanguage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: _languages.map((language) {
                  final isSelected = language.hasWritingSystems
                      ? appLanguage.currentCode == 'vi' ||
                            appLanguage.currentCode == AppLanguageCubit.chunomCode
                      : appLanguage.currentCode == language.code;

                  return InkWell(
                    onTap: () async {
                      if (language.hasWritingSystems) {
                        Navigator.pop(sheetContext);
                        if (context.mounted) {
                          await _showVietnameseWritingSystemPicker(
                            context,
                            appLanguage,
                            l10n,
                          );
                        }
                        return;
                      }

                      await appLanguage.changeLanguageByCode(language.code);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.12)
                            : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? Border.all(color: colorScheme.primary, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            language.flag,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  language.native,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                if (language.hasWritingSystems) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _vietnameseWritingSystemsLabel(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.52,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (language.hasWritingSystems)
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withValues(alpha: 0.45),
                            )
                          else if (isSelected)
                            _selectedIcon(colorScheme),
                        ],
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showVietnameseWritingSystemPicker(
    BuildContext context,
    AppLanguageCubit appLanguage,
    AppLocalizations l10n,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final vietnamese = LanguageConfig.findByCode('vi');
    final options = <_WritingSystemItem>[
      _WritingSystemItem(
        code: 'vi',
        mark: 'Aa',
        name: vietnamese?.scriptNameOf('Latn', 'vi') ?? 'Chữ Quốc ngữ',
      ),
      _WritingSystemItem(
        code: AppLanguageCubit.chunomCode,
        mark: '𡨸',
        name: vietnamese?.scriptNameOf('Hnom', 'vi') ?? 'Chữ Nôm',
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.get('selectWritingSystem'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Tiếng Việt',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 14),
            for (final option in options) ...[
              Material(
                color: appLanguage.currentCode == option.code
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await appLanguage.changeLanguageByCode(option.code);
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            option.mark,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (appLanguage.currentCode == option.code)
                          _selectedIcon(colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _selectedIcon(ColorScheme colorScheme) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, color: colorScheme.onPrimary, size: 18),
    );
  }

  String _vietnameseWritingSystemsLabel() {
    final vietnamese = LanguageConfig.findByCode('vi');
    final latin = vietnamese?.scriptNameOf('Latn', 'vi') ?? 'Chữ Quốc ngữ';
    final nom = vietnamese?.scriptNameOf('Hnom', 'vi') ?? 'Chữ Nôm';
    return '$latin · $nom';
  }

  String _currentLanguageName(BuildContext context, String code) {
    if (code == 'vi' || code == AppLanguageCubit.chunomCode) {
      final vietnamese = LanguageConfig.findByCode('vi');
      final scriptCode = code == AppLanguageCubit.chunomCode ? 'Hnom' : 'Latn';
      final languageName = vietnamese?.nameOf('vi') ?? 'Tiếng Việt';
      final scriptName =
          vietnamese?.scriptNameOf(scriptCode, 'vi') ??
          (scriptCode == 'Hnom' ? 'Chữ Nôm' : 'Chữ Quốc ngữ');
      return '$languageName · $scriptName';
    }

    for (final language in _languages) {
      if (language.code == code) {
        return language.native;
      }
    }

    return AppLocalizations.of(context)?.getLanguageName(code) ?? code;
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.62),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurface.withValues(alpha: 0.45),
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutItem(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: Text(
        l10n.logout,
        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
      ),
      subtitle: Text(
        l10n.logout,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.62),
        ),
      ),
      onTap: () => _logout(context),
    );
  }
}

class _LanguageItem {
  const _LanguageItem({
    required this.code,
    required this.flag,
    required this.native,
    this.hasWritingSystems = false,
  });

  final String code;
  final String flag;
  final String native;
  final bool hasWritingSystems;
}

class _WritingSystemItem {
  const _WritingSystemItem({
    required this.code,
    required this.mark,
    required this.name,
  });

  final String code;
  final String mark;
  final String name;
}
''',
)


# ---------------------------------------------------------------------------
# Locale JSON audit and additions.
# ---------------------------------------------------------------------------
L10N = APP / 'assets' / 'l10n'

ROOT_CATEGORY_IDS = [
    'language_learning', 'programming', 'ai', 'technology', 'gaming', 'music',
    'movies', 'campus', 'startup', 'friends', 'travel', 'chat', 'love', 'food',
    'medicine',
]

CATEGORY_TRANSLATIONS = {
    'en': {
        'language_learning': 'Language Learning', 'programming': 'Programming',
        'ai': 'AI', 'technology': 'Technology', 'gaming': 'Gaming', 'music': 'Music',
        'movies': 'Film & TV', 'campus': 'Campus', 'startup': 'Startups',
        'friends': 'Friends', 'travel': 'Travel', 'chat': 'Chat',
        'love': 'Relationships', 'food': 'Food', 'medicine': 'Medicine',
        'mobile_development': 'Mobile Development', 'web_development': 'Web Development',
        'backend_development': 'Backend Development', 'database_development': 'Databases',
        'flutter': 'Flutter', 'react_native': 'React Native', 'rpg': 'RPG', 'fps': 'FPS',
        'strategy_games': 'Strategy Games', 'simulation_games': 'Simulation Games',
        'film': 'Film', 'tv_series': 'TV Series', 'animation': 'Animation',
        'documentary': 'Documentary', 'internal_medicine': 'Internal Medicine',
        'surgery': 'Surgery', 'pediatrics': 'Pediatrics', 'dermatology': 'Dermatology',
        'psychiatry': 'Psychiatry', 'cardiology': 'Cardiology',
    },
    'zh': {
        'language_learning': '语言学习', 'programming': '编程开发', 'ai': 'AI',
        'technology': '科技', 'gaming': '游戏', 'music': '音乐', 'movies': '影视',
        'campus': '校园', 'startup': '创业', 'friends': '交友', 'travel': '旅行',
        'chat': '闲聊', 'love': '爱情', 'food': '美食', 'medicine': '医学',
        'mobile_development': '移动开发', 'web_development': 'Web 开发',
        'backend_development': '后端开发', 'database_development': '数据库',
        'flutter': 'Flutter', 'react_native': 'React Native', 'rpg': 'RPG', 'fps': 'FPS',
        'strategy_games': '策略游戏', 'simulation_games': '模拟游戏', 'film': '电影',
        'tv_series': '电视剧', 'animation': '动画', 'documentary': '纪录片',
        'internal_medicine': '内科', 'surgery': '外科', 'pediatrics': '儿科',
        'dermatology': '皮肤科', 'psychiatry': '精神医学', 'cardiology': '心血管内科',
    },
    'ja': {
        'language_learning': '言語学習', 'programming': 'プログラミング', 'ai': 'AI',
        'technology': 'テクノロジー', 'gaming': 'ゲーム', 'music': '音楽', 'movies': '映像',
        'campus': 'キャンパス', 'startup': '起業', 'friends': '交流', 'travel': '旅行',
        'chat': '雑談', 'love': '恋愛', 'food': 'グルメ', 'medicine': '医学',
        'mobile_development': 'モバイル開発', 'web_development': 'Web 開発',
        'backend_development': 'バックエンド開発', 'database_development': 'データベース',
        'flutter': 'Flutter', 'react_native': 'React Native', 'rpg': 'RPG', 'fps': 'FPS',
        'strategy_games': 'ストラテジー', 'simulation_games': 'シミュレーション',
        'film': '映画', 'tv_series': 'テレビドラマ', 'animation': 'アニメーション',
        'documentary': 'ドキュメンタリー', 'internal_medicine': '内科', 'surgery': '外科',
        'pediatrics': '小児科', 'dermatology': '皮膚科', 'psychiatry': '精神医学',
        'cardiology': '循環器内科',
    },
    'vi': {
        'language_learning': 'Học ngôn ngữ', 'programming': 'Lập trình', 'ai': 'AI',
        'technology': 'Công nghệ', 'gaming': 'Trò chơi', 'music': 'Âm nhạc',
        'movies': 'Phim & truyền hình', 'campus': 'Khuôn viên', 'startup': 'Khởi nghiệp',
        'friends': 'Kết bạn', 'travel': 'Du lịch', 'chat': 'Trò chuyện',
        'love': 'Tình cảm', 'food': 'Ẩm thực', 'medicine': 'Y học',
        'mobile_development': 'Phát triển di động', 'web_development': 'Phát triển Web',
        'backend_development': 'Phát triển backend', 'database_development': 'Cơ sở dữ liệu',
        'flutter': 'Flutter', 'react_native': 'React Native', 'rpg': 'RPG', 'fps': 'FPS',
        'strategy_games': 'Game chiến thuật', 'simulation_games': 'Game mô phỏng',
        'film': 'Điện ảnh', 'tv_series': 'Phim truyền hình', 'animation': 'Hoạt hình',
        'documentary': 'Phim tài liệu', 'internal_medicine': 'Nội khoa', 'surgery': 'Ngoại khoa',
        'pediatrics': 'Nhi khoa', 'dermatology': 'Da liễu', 'psychiatry': 'Tâm thần học',
        'cardiology': 'Tim mạch',
    },
    'ko': {
        'language_learning': '언어 학습', 'programming': '프로그래밍', 'ai': 'AI',
        'technology': '기술', 'gaming': '게임', 'music': '음악', 'movies': '영화·TV',
        'campus': '캠퍼스', 'startup': '창업', 'friends': '친구', 'travel': '여행',
        'chat': '잡담', 'love': '연애', 'food': '음식', 'medicine': '의학',
        'mobile_development': '모바일 개발', 'web_development': '웹 개발',
        'backend_development': '백엔드 개발', 'database_development': '데이터베이스',
        'flutter': 'Flutter', 'react_native': 'React Native', 'rpg': 'RPG', 'fps': 'FPS',
        'strategy_games': '전략 게임', 'simulation_games': '시뮬레이션 게임',
        'film': '영화', 'tv_series': 'TV 시리즈', 'animation': '애니메이션',
        'documentary': '다큐멘터리', 'internal_medicine': '내과', 'surgery': '외과',
        'pediatrics': '소아과', 'dermatology': '피부과', 'psychiatry': '정신의학',
        'cardiology': '심장내과',
    },
    'ms': {
        'language_learning': 'Pembelajaran Bahasa', 'programming': 'Pengaturcaraan',
        'ai': 'AI', 'technology': 'Teknologi', 'gaming': 'Permainan', 'music': 'Muzik',
        'movies': 'Filem & TV', 'campus': 'Kampus', 'startup': 'Pemula',
        'friends': 'Kawan', 'travel': 'Perjalanan', 'chat': 'Sembang',
        'love': 'Hubungan', 'food': 'Makanan', 'medicine': 'Perubatan',
        'mobile_development': 'Pembangunan Mudah Alih', 'web_development': 'Pembangunan Web',
        'backend_development': 'Pembangunan Backend', 'database_development': 'Pangkalan Data',
        'flutter': 'Flutter', 'react_native': 'React Native', 'rpg': 'RPG', 'fps': 'FPS',
        'strategy_games': 'Permainan Strategi', 'simulation_games': 'Permainan Simulasi',
        'film': 'Filem', 'tv_series': 'Siri TV', 'animation': 'Animasi',
        'documentary': 'Dokumentari', 'internal_medicine': 'Perubatan Dalaman',
        'surgery': 'Pembedahan', 'pediatrics': 'Pediatrik', 'dermatology': 'Dermatologi',
        'psychiatry': 'Psikiatri', 'cardiology': 'Kardiologi',
    },
    'th': {
        'language_learning': 'การเรียนภาษา', 'programming': 'การเขียนโปรแกรม', 'ai': 'AI',
        'technology': 'เทคโนโลยี', 'gaming': 'เกม', 'music': 'ดนตรี', 'movies': 'ภาพยนตร์และทีวี',
        'campus': 'มหาวิทยาลัย', 'startup': 'สตาร์ทอัพ', 'friends': 'เพื่อน',
        'travel': 'ท่องเที่ยว', 'chat': 'พูดคุย', 'love': 'ความสัมพันธ์', 'food': 'อาหาร',
        'medicine': 'การแพทย์', 'mobile_development': 'พัฒนาแอปมือถือ',
        'web_development': 'พัฒนาเว็บ', 'backend_development': 'พัฒนาแบ็กเอนด์',
        'database_development': 'ฐานข้อมูล', 'flutter': 'Flutter',
        'react_native': 'React Native', 'rpg': 'RPG', 'fps': 'FPS',
        'strategy_games': 'เกมวางแผน', 'simulation_games': 'เกมจำลอง', 'film': 'ภาพยนตร์',
        'tv_series': 'ซีรีส์', 'animation': 'แอนิเมชัน', 'documentary': 'สารคดี',
        'internal_medicine': 'อายุรศาสตร์', 'surgery': 'ศัลยกรรม', 'pediatrics': 'กุมารเวชศาสตร์',
        'dermatology': 'ผิวหนัง', 'psychiatry': 'จิตเวชศาสตร์', 'cardiology': 'โรคหัวใจ',
    },
}

NEW_UI = {
    'en': {
        'selectWritingSystem': 'Select writing system', 'nomWritingSystem': 'Chữ Nôm',
        'recommendedForYou': 'For you', 'recommendedOnlyInterests': 'Only content you marked as interesting',
        'interestHomeTitle': 'Your interest feed', 'interestHomeDesc': 'Choose interests in category channels to shape this feed',
        'languageCommunity': 'Language community', 'languageCommunityTagline': 'Connecting languages, interests, and people',
        'recommendedHome': 'Recommended', 'recommendedHomeDesc': 'Only your selected interests',
        'categoryChannels': 'Category channels', 'categoryChannelsDesc': 'Choose a language, browse topics, and set interests',
        'exploreLanguageContent': 'Explore content across languages', 'selectTopics': 'Explore topics',
        'interestsLoading': 'Loading interests…', 'signInFirst': 'Sign in to manage your interests.',
        'interestUpdateFailed': 'Could not update interest', 'interestCardLabel': 'topics shaping your recommendations',
        'following': 'Following', 'addInterest': 'Add to interests', 'removeInterest': 'Remove from interests',
        'interestSummary': '{selected} of {total} topics shape your recommendations',
        'publishGeneralLanguageLearning': 'Post a general language-learning topic', 'publishPost': 'Publish post',
        'noLanguagePosts': 'No {language} posts yet',
        'languageLearningRootEmpty': 'You can post a general language-learning topic,\nor choose a specific language first.',
        'firstPostInCategory': 'Be the first to post in “{category}”\nin {language}.',
        'publishLanguagePost': 'Post in {language}', 'channelDisplay': '{flag} {language} channel',
        'selectLearningLanguageOptional': 'Choose a learning language (optional)',
        'learningLanguageOptionalDesc': 'You can also post without choosing a language for learning methods, linguistics, or multilingual topics.',
        'chooseFromLanguageLibrary': 'Choose from language library · {count} languages',
        'selectLearningLanguage': 'Choose a learning language',
        'languageLibraryDesc': 'Languages come from Glyphora Language Core. Go back to keep this as a general language-learning topic.',
        'searchLanguageNameOrCode': 'Search language name or code', 'noLanguagesFound': 'No languages found',
        'continueSelectCategory': 'Continue choosing a category', 'untitled': 'Untitled',
        'otherLanguage': 'Other language', 'channelBadge': '{language} channel',
    },
    'zh': {
        'selectWritingSystem': '选择文字系统', 'nomWritingSystem': '喃字',
        'recommendedForYou': '为你推荐', 'recommendedOnlyInterests': '仅显示你主动设为感兴趣的内容',
        'interestHomeTitle': '你的兴趣主页', 'interestHomeDesc': '先到分类频道，把语言频道中的分类设为感兴趣',
        'languageCommunity': '语言社区', 'languageCommunityTagline': '连接语言、兴趣与世界',
        'recommendedHome': '推荐主页', 'recommendedHomeDesc': '只显示已选择的兴趣',
        'categoryChannels': '分类频道', 'categoryChannelsDesc': '选择语言、浏览和设置兴趣',
        'exploreLanguageContent': '探索不同语言的内容', 'selectTopics': '探索主题',
        'interestsLoading': '正在加载兴趣设置…', 'signInFirst': '请先登录后再管理兴趣。',
        'interestUpdateFailed': '更新兴趣失败', 'interestCardLabel': '个主题正在参与塑造你的推荐',
        'following': '已设为感兴趣', 'addInterest': '设为感兴趣', 'removeInterest': '取消感兴趣',
        'interestSummary': '已选择 {selected} / {total} · 点击心形调整推荐',
        'publishGeneralLanguageLearning': '发布综合语言学习话题', 'publishPost': '发布帖子',
        'noLanguagePosts': '暂无{language}帖子',
        'languageLearningRootEmpty': '可以直接发布语言学习综合话题，\n也可以先选择一门具体语言',
        'firstPostInCategory': '成为第一个在「{category}」下\n发布{language}帖子的人吧',
        'publishLanguagePost': '发布{language}帖子', 'channelDisplay': '{flag} {language}频道',
        'selectLearningLanguageOptional': '选择学习语言（可选）',
        'learningLanguageOptionalDesc': '不选择具体语言也可以发帖，适合讨论学习方法、语言学或多语言话题。',
        'chooseFromLanguageLibrary': '从语言库选择 · {count} 种语言',
        'selectLearningLanguage': '选择学习语言',
        'languageLibraryDesc': '语言来自 Glyphora Language Core。返回上一层即可继续使用“综合语言学习”，不要求指定语言。',
        'searchLanguageNameOrCode': '搜索语言名称或代码', 'noLanguagesFound': '没有找到语言',
        'continueSelectCategory': '继续选择分类', 'untitled': '无标题',
        'otherLanguage': '其他语言', 'channelBadge': '{language}频道',
    },
    'ja': {
        'selectWritingSystem': '文字体系を選択', 'nomWritingSystem': 'チュノム',
        'recommendedForYou': 'おすすめ', 'recommendedOnlyInterests': '興味ありに設定した内容だけを表示します',
        'interestHomeTitle': '興味フィード', 'interestHomeDesc': 'カテゴリチャンネルで興味を選ぶと、ここに反映されます',
        'languageCommunity': '言語コミュニティ', 'languageCommunityTagline': '言語・興味・人をつなぐ',
        'recommendedHome': 'おすすめ', 'recommendedHomeDesc': '選択した興味だけを表示',
        'categoryChannels': 'カテゴリチャンネル', 'categoryChannelsDesc': '言語を選び、トピックを閲覧して興味を設定',
        'exploreLanguageContent': 'さまざまな言語の内容を探す', 'selectTopics': 'トピックを探す',
        'interestsLoading': '興味を読み込み中…', 'signInFirst': '興味を管理するにはログインしてください。',
        'interestUpdateFailed': '興味を更新できませんでした', 'interestCardLabel': 'おすすめに反映されるトピック',
        'following': '興味あり', 'addInterest': '興味に追加', 'removeInterest': '興味から削除',
        'interestSummary': '{total} 件中 {selected} 件がおすすめに反映されます',
        'publishGeneralLanguageLearning': '一般的な言語学習トピックを投稿', 'publishPost': '投稿する',
        'noLanguagePosts': '{language}の投稿はまだありません',
        'languageLearningRootEmpty': '一般的な言語学習トピックを直接投稿するか、\n先に特定の言語を選べます。',
        'firstPostInCategory': '「{category}」で最初の\n{language}投稿をしてみましょう。',
        'publishLanguagePost': '{language}で投稿', 'channelDisplay': '{flag} {language}チャンネル',
        'selectLearningLanguageOptional': '学習言語を選択（任意）',
        'learningLanguageOptionalDesc': '学習法、言語学、多言語の話題なら、特定の言語を選ばずに投稿できます。',
        'chooseFromLanguageLibrary': '言語ライブラリから選択 · {count} 言語',
        'selectLearningLanguage': '学習言語を選択',
        'languageLibraryDesc': '言語は Glyphora Language Core から取得しています。戻れば一般的な言語学習として続けられます。',
        'searchLanguageNameOrCode': '言語名またはコードを検索', 'noLanguagesFound': '言語が見つかりません',
        'continueSelectCategory': 'カテゴリをさらに選択', 'untitled': '無題',
        'otherLanguage': 'その他の言語', 'channelBadge': '{language}チャンネル',
    },
    'vi': {
        'selectWritingSystem': 'Chọn hệ chữ', 'nomWritingSystem': 'Chữ Nôm',
        'recommendedForYou': 'Dành cho bạn', 'recommendedOnlyInterests': 'Chỉ hiển thị nội dung bạn đã chủ động đánh dấu quan tâm',
        'interestHomeTitle': 'Bảng tin sở thích', 'interestHomeDesc': 'Chọn chủ đề quan tâm trong các kênh danh mục để định hình bảng tin này',
        'languageCommunity': 'Cộng đồng ngôn ngữ', 'languageCommunityTagline': 'Kết nối ngôn ngữ, sở thích và mọi người',
        'recommendedHome': 'Đề xuất', 'recommendedHomeDesc': 'Chỉ hiển thị sở thích đã chọn',
        'categoryChannels': 'Kênh danh mục', 'categoryChannelsDesc': 'Chọn ngôn ngữ, duyệt chủ đề và đặt sở thích',
        'exploreLanguageContent': 'Khám phá nội dung bằng nhiều ngôn ngữ', 'selectTopics': 'Khám phá chủ đề',
        'interestsLoading': 'Đang tải sở thích…', 'signInFirst': 'Hãy đăng nhập để quản lý sở thích.',
        'interestUpdateFailed': 'Không thể cập nhật sở thích', 'interestCardLabel': 'chủ đề đang định hình phần đề xuất',
        'following': 'Đang quan tâm', 'addInterest': 'Thêm vào sở thích', 'removeInterest': 'Bỏ khỏi sở thích',
        'interestSummary': '{selected}/{total} chủ đề đang ảnh hưởng đến đề xuất',
        'publishGeneralLanguageLearning': 'Đăng chủ đề học ngôn ngữ chung', 'publishPost': 'Đăng bài',
        'noLanguagePosts': 'Chưa có bài viết {language}',
        'languageLearningRootEmpty': 'Bạn có thể đăng chủ đề học ngôn ngữ chung,\nhoặc chọn một ngôn ngữ cụ thể trước.',
        'firstPostInCategory': 'Hãy là người đầu tiên đăng bài {language}\ntrong “{category}”.',
        'publishLanguagePost': 'Đăng bài {language}', 'channelDisplay': '{flag} Kênh {language}',
        'selectLearningLanguageOptional': 'Chọn ngôn ngữ đang học (không bắt buộc)',
        'learningLanguageOptionalDesc': 'Bạn có thể đăng mà không chọn ngôn ngữ cụ thể nếu chủ đề là phương pháp học, ngôn ngữ học hoặc đa ngôn ngữ.',
        'chooseFromLanguageLibrary': 'Chọn từ thư viện · {count} ngôn ngữ',
        'selectLearningLanguage': 'Chọn ngôn ngữ đang học',
        'languageLibraryDesc': 'Ngôn ngữ lấy từ Glyphora Language Core. Quay lại để tiếp tục dưới dạng chủ đề học ngôn ngữ chung.',
        'searchLanguageNameOrCode': 'Tìm tên hoặc mã ngôn ngữ', 'noLanguagesFound': 'Không tìm thấy ngôn ngữ',
        'continueSelectCategory': 'Tiếp tục chọn danh mục', 'untitled': 'Không có tiêu đề',
        'otherLanguage': 'Ngôn ngữ khác', 'channelBadge': 'Kênh {language}',
    },
    'ko': {
        'selectWritingSystem': '문자 체계 선택', 'nomWritingSystem': '쯔놈',
        'recommendedForYou': '추천', 'recommendedOnlyInterests': '직접 관심으로 표시한 콘텐츠만 표시합니다',
        'interestHomeTitle': '관심 피드', 'interestHomeDesc': '카테고리 채널에서 관심사를 선택해 이 피드를 구성하세요',
        'languageCommunity': '언어 커뮤니티', 'languageCommunityTagline': '언어, 관심사, 사람을 연결합니다',
        'recommendedHome': '추천 홈', 'recommendedHomeDesc': '선택한 관심사만 표시',
        'categoryChannels': '카테고리 채널', 'categoryChannelsDesc': '언어를 선택하고 주제를 탐색해 관심사를 설정하세요',
        'exploreLanguageContent': '다양한 언어의 콘텐츠 탐색', 'selectTopics': '주제 탐색',
        'interestsLoading': '관심사를 불러오는 중…', 'signInFirst': '관심사를 관리하려면 로그인하세요.',
        'interestUpdateFailed': '관심사를 업데이트하지 못했습니다', 'interestCardLabel': '추천에 반영되는 주제',
        'following': '관심 있음', 'addInterest': '관심사에 추가', 'removeInterest': '관심사에서 제거',
        'interestSummary': '{total}개 중 {selected}개 주제가 추천에 반영됩니다',
        'publishGeneralLanguageLearning': '일반 언어 학습 주제 게시', 'publishPost': '게시하기',
        'noLanguagePosts': '아직 {language} 게시물이 없습니다',
        'languageLearningRootEmpty': '일반 언어 학습 주제를 바로 게시하거나,\n먼저 특정 언어를 선택할 수 있습니다.',
        'firstPostInCategory': '“{category}”에 첫 {language}\n게시물을 작성해 보세요.',
        'publishLanguagePost': '{language} 게시물 작성', 'channelDisplay': '{flag} {language} 채널',
        'selectLearningLanguageOptional': '학습 언어 선택(선택 사항)',
        'learningLanguageOptionalDesc': '학습법, 언어학, 다언어 주제라면 특정 언어를 선택하지 않고 게시할 수 있습니다.',
        'chooseFromLanguageLibrary': '언어 라이브러리에서 선택 · {count}개 언어',
        'selectLearningLanguage': '학습 언어 선택',
        'languageLibraryDesc': '언어 목록은 Glyphora Language Core에서 가져옵니다. 뒤로 가면 일반 언어 학습 주제로 유지됩니다.',
        'searchLanguageNameOrCode': '언어 이름 또는 코드 검색', 'noLanguagesFound': '언어를 찾을 수 없습니다',
        'continueSelectCategory': '카테고리 계속 선택', 'untitled': '제목 없음',
        'otherLanguage': '기타 언어', 'channelBadge': '{language} 채널',
    },
    'ms': {
        'selectWritingSystem': 'Pilih sistem tulisan', 'nomWritingSystem': 'Chữ Nôm',
        'recommendedForYou': 'Untuk anda', 'recommendedOnlyInterests': 'Hanya kandungan yang anda tandakan sebagai minat',
        'interestHomeTitle': 'Suapan minat anda', 'interestHomeDesc': 'Pilih minat dalam saluran kategori untuk membentuk suapan ini',
        'languageCommunity': 'Komuniti bahasa', 'languageCommunityTagline': 'Menghubungkan bahasa, minat dan orang',
        'recommendedHome': 'Cadangan', 'recommendedHomeDesc': 'Hanya minat yang dipilih',
        'categoryChannels': 'Saluran kategori', 'categoryChannelsDesc': 'Pilih bahasa, teroka topik dan tetapkan minat',
        'exploreLanguageContent': 'Teroka kandungan dalam pelbagai bahasa', 'selectTopics': 'Teroka topik',
        'interestsLoading': 'Memuatkan minat…', 'signInFirst': 'Log masuk untuk mengurus minat anda.',
        'interestUpdateFailed': 'Minat tidak dapat dikemas kini', 'interestCardLabel': 'topik yang membentuk cadangan anda',
        'following': 'Diminati', 'addInterest': 'Tambah sebagai minat', 'removeInterest': 'Buang daripada minat',
        'interestSummary': '{selected} daripada {total} topik membentuk cadangan anda',
        'publishGeneralLanguageLearning': 'Siarkan topik pembelajaran bahasa umum', 'publishPost': 'Terbitkan siaran',
        'noLanguagePosts': 'Belum ada siaran {language}',
        'languageLearningRootEmpty': 'Anda boleh menyiarkan topik pembelajaran bahasa umum,\natau pilih bahasa tertentu dahulu.',
        'firstPostInCategory': 'Jadilah yang pertama menyiarkan dalam “{category}”\ndalam {language}.',
        'publishLanguagePost': 'Siarkan dalam {language}', 'channelDisplay': '{flag} Saluran {language}',
        'selectLearningLanguageOptional': 'Pilih bahasa pembelajaran (pilihan)',
        'learningLanguageOptionalDesc': 'Anda boleh menyiarkan tanpa memilih bahasa tertentu untuk kaedah belajar, linguistik atau topik berbilang bahasa.',
        'chooseFromLanguageLibrary': 'Pilih daripada pustaka · {count} bahasa',
        'selectLearningLanguage': 'Pilih bahasa pembelajaran',
        'languageLibraryDesc': 'Bahasa datang daripada Glyphora Language Core. Kembali untuk kekal sebagai topik pembelajaran bahasa umum.',
        'searchLanguageNameOrCode': 'Cari nama atau kod bahasa', 'noLanguagesFound': 'Tiada bahasa ditemui',
        'continueSelectCategory': 'Terus pilih kategori', 'untitled': 'Tanpa tajuk',
        'otherLanguage': 'Bahasa lain', 'channelBadge': 'Saluran {language}',
    },
    'th': {
        'selectWritingSystem': 'เลือกระบบอักษร', 'nomWritingSystem': 'Chữ Nôm',
        'recommendedForYou': 'แนะนำสำหรับคุณ', 'recommendedOnlyInterests': 'แสดงเฉพาะเนื้อหาที่คุณทำเครื่องหมายว่าสนใจ',
        'interestHomeTitle': 'ฟีดความสนใจของคุณ', 'interestHomeDesc': 'เลือกความสนใจในช่องหมวดหมู่เพื่อปรับฟีดนี้',
        'languageCommunity': 'ชุมชนภาษา', 'languageCommunityTagline': 'เชื่อมโยงภาษา ความสนใจ และผู้คน',
        'recommendedHome': 'หน้าแนะนำ', 'recommendedHomeDesc': 'แสดงเฉพาะความสนใจที่เลือก',
        'categoryChannels': 'ช่องหมวดหมู่', 'categoryChannelsDesc': 'เลือกภาษา สำรวจหัวข้อ และตั้งค่าความสนใจ',
        'exploreLanguageContent': 'สำรวจเนื้อหาในภาษาต่าง ๆ', 'selectTopics': 'สำรวจหัวข้อ',
        'interestsLoading': 'กำลังโหลดความสนใจ…', 'signInFirst': 'เข้าสู่ระบบเพื่อจัดการความสนใจของคุณ',
        'interestUpdateFailed': 'อัปเดตความสนใจไม่สำเร็จ', 'interestCardLabel': 'หัวข้อที่ใช้ปรับคำแนะนำของคุณ',
        'following': 'สนใจอยู่', 'addInterest': 'เพิ่มเป็นความสนใจ', 'removeInterest': 'นำออกจากความสนใจ',
        'interestSummary': '{selected} จาก {total} หัวข้อใช้ปรับคำแนะนำของคุณ',
        'publishGeneralLanguageLearning': 'โพสต์หัวข้อการเรียนภาษาทั่วไป', 'publishPost': 'เผยแพร่โพสต์',
        'noLanguagePosts': 'ยังไม่มีโพสต์ภาษา {language}',
        'languageLearningRootEmpty': 'คุณสามารถโพสต์หัวข้อการเรียนภาษาทั่วไปได้โดยตรง\nหรือเลือกภาษาเฉพาะก่อน',
        'firstPostInCategory': 'เป็นคนแรกที่โพสต์ภาษา {language}\nใน “{category}”',
        'publishLanguagePost': 'โพสต์ภาษา {language}', 'channelDisplay': '{flag} ช่อง {language}',
        'selectLearningLanguageOptional': 'เลือกภาษาที่กำลังเรียน (ไม่บังคับ)',
        'learningLanguageOptionalDesc': 'คุณสามารถโพสต์โดยไม่เลือกภาษาเฉพาะสำหรับวิธีเรียน ภาษาศาสตร์ หรือหัวข้อหลายภาษา',
        'chooseFromLanguageLibrary': 'เลือกจากคลังภาษา · {count} ภาษา',
        'selectLearningLanguage': 'เลือกภาษาที่กำลังเรียน',
        'languageLibraryDesc': 'รายชื่อภาษามาจาก Glyphora Language Core ย้อนกลับเพื่อใช้เป็นหัวข้อการเรียนภาษาทั่วไป',
        'searchLanguageNameOrCode': 'ค้นหาชื่อหรือรหัสภาษา', 'noLanguagesFound': 'ไม่พบภาษา',
        'continueSelectCategory': 'เลือกหมวดหมู่ต่อ', 'untitled': 'ไม่มีชื่อเรื่อง',
        'otherLanguage': 'ภาษาอื่น', 'channelBadge': 'ช่อง {language}',
    },
}

# Complete existing UI strings for previously advertised-but-missing locales.
# These files intentionally contain the same key set as English so selecting
# Korean/Malay/Thai never silently turns the entire app into English.
EXISTING_LOCALE = {
    'ko': {
        'appTitle':'Glyphora','forumCategories':'포럼 카테고리','currentChannel':'현재 채널','currentLanguage':'현재 언어','switchLanguage':'언어 변경','selectLanguage':'언어 선택','home':'홈','messages':'메시지','profile':'내 프로필','post':'게시물','publish':'게시','title':'제목','content':'내용','selectImage':'이미지 선택','addMoreImages':'이미지 추가','uploading':'업로드 중...','noPosts':'게시물 없음','loadFailed':'불러오기 실패','refresh':'새로고침','cancel':'취소','confirm':'확인','search':'검색','settings':'설정','midnightMode':'심야 모드','midnightModeDesc':'야간 및 OLED 화면을 위한 순수 검정·저휘도 UI','logout':'로그아웃','login':'로그인','register':'가입','email':'이메일','password':'비밀번호','username':'사용자 이름','send':'보내기','reply':'답글','like':'좋아요','comment':'댓글','share':'공유','delete':'삭제','edit':'편집','save':'저장','justNow':'방금','minutesAgo':'분 전','hoursAgo':'시간 전','daysAgo':'일 전','setNickname':'닉네임 설정','setBirthday':'생일 설정','selectBirthDate':'생년월일 선택','clearBirthday':'생일 지우기','showAge':'나이 공개','showAgeDesc':'끄면 본인에게만 표시','posts':'게시물','likesCount':'받은 좋아요','introYourself':'✨ 자신을 소개해 보세요...','addTagsHint':'관심 태그 추가...','languageAbility':'언어 능력','add':'추가','nativeLanguage':'모국어','native':'모국어','changeLevel':'수준 변경','quickSelect':'빠른 선택','myPosts':'내 게시물','editTags':'태그 편집','editNickname':'닉네임 편집','newNickname':'새 닉네임','nicknameHint':'멋진 이름을 정해 보세요','editUsername':'사용자 이름 편집','newUsername':'새 사용자 이름','usernameHint':'사용자 이름은 고유 ID입니다','editBio':'소개 편집','bioHint':'자신을 소개해 보세요...','done':'완료','addTag':'추가','selectedTags':'선택됨','recommendTags':'추천','customTagHint':'사용자 지정 태그 입력','tagExists':'이미 추가된 태그입니다','tagMax':'태그는 최대 10개입니다','tagsUpdated':'태그가 업데이트되었습니다','birthdayUpdated':'생일이 업데이트되었습니다','updateFailed':'업데이트 실패','avatarUpdated':'프로필 사진이 업데이트되었습니다','avatarFailed':'프로필 사진 업데이트 실패','permissionDenied':'사진 접근 권한이 필요합니다','nicknameUpdated':'닉네임이 업데이트되었습니다','usernameUpdated':'사용자 이름이 업데이트되었습니다','usernameUsed':'이미 사용 중인 사용자 이름입니다','bioUpdated':'소개가 업데이트되었습니다','languageUpdated':'언어가 업데이트되었습니다','languageExists':'이미 존재합니다','languageName':'언어 이름','notLoggedIn':'로그인하지 않음','noDynamic':'아직 게시물이 없습니다','error':'오류','securitySettings':'보안','securitySettingsDesc':'보안 질문 설정','changePassword':'비밀번호 변경','changePasswordDesc':'비밀번호 변경','blockList':'차단 목록','blockListDesc':'차단한 사용자 관리','logoutConfirm':'로그아웃 확인','logoutConfirmDesc':'로그아웃하시겠습니까?','developing':'개발 중...','discover':'사용자 찾기','addFriend':'친구 추가','startChat':'채팅 시작','friendRequestSent':'친구 요청을 보냈습니다','noOtherUsers':'다른 사용자가 없습니다','createChatFailed':'채팅 생성 실패','editTagsTitle':'태그 편집','editAgeTitle':'생일 설정','year':'년','month':'월','day':'일','editNicknameTitle':'닉네임 편집','newNicknameLabel':'새 닉네임','editUsernameTitle':'사용자 이름 편집','newUsernameLabel':'새 사용자 이름','editBioTitle':'소개 편집','languagesTitle':'언어 능력','languagesUpdated':'언어가 업데이트되었습니다','addLanguage':'언어 추가','ageUpdated':'생일이 업데이트되었습니다','galleryPermission':'사진 접근 권한이 필요합니다','tagUpdated':'태그가 업데이트되었습니다','tagInputHint':'사용자 지정 태그 입력',
    },
    'ms': {
        'appTitle':'Glyphora','forumCategories':'Kategori Forum','currentChannel':'Saluran semasa','currentLanguage':'Bahasa semasa','switchLanguage':'Tukar bahasa','selectLanguage':'Pilih bahasa','home':'Laman utama','messages':'Mesej','profile':'Profil','post':'Siaran','publish':'Terbitkan','title':'Tajuk','content':'Kandungan','selectImage':'Pilih imej','addMoreImages':'Tambah imej','uploading':'Memuat naik...','noPosts':'Tiada siaran','loadFailed':'Gagal dimuatkan','refresh':'Muat semula','cancel':'Batal','confirm':'Sahkan','search':'Cari','settings':'Tetapan','midnightMode':'Mod tengah malam','midnightModeDesc':'Antara muka hitam tulen dan kecerahan rendah untuk waktu malam serta skrin OLED','logout':'Log keluar','login':'Log masuk','register':'Daftar','email':'E-mel','password':'Kata laluan','username':'Nama pengguna','send':'Hantar','reply':'Balas','like':'Suka','comment':'Komen','share':'Kongsi','delete':'Padam','edit':'Edit','save':'Simpan','justNow':'Baru sahaja','minutesAgo':' min lalu','hoursAgo':' jam lalu','daysAgo':' hari lalu','setNickname':'Tetapkan nama panggilan','setBirthday':'Tetapkan hari lahir','selectBirthDate':'Pilih tarikh lahir','clearBirthday':'Kosongkan hari lahir','showAge':'Paparkan umur','showAgeDesc':'Hanya anda boleh melihatnya apabila dimatikan','posts':'Siaran','likesCount':'Suka diterima','introYourself':'✨ Perkenalkan diri...','addTagsHint':'Tambah tag minat...','languageAbility':'Kemahiran bahasa','add':'Tambah','nativeLanguage':'Bahasa ibunda','native':'Ibunda','changeLevel':'Tukar tahap','quickSelect':'Pilih pantas','myPosts':'Siaran saya','editTags':'Edit tag','editNickname':'Edit nama panggilan','newNickname':'Nama panggilan baharu','nicknameHint':'Pilih nama yang sesuai','editUsername':'Edit nama pengguna','newUsername':'Nama pengguna baharu','usernameHint':'Nama pengguna ialah ID unik anda','editBio':'Edit bio','bioHint':'Perkenalkan diri...','done':'Selesai','addTag':'Tambah','selectedTags':'Dipilih','recommendTags':'Disyorkan','customTagHint':'Masukkan tag tersuai','tagExists':'Tag sudah ditambah','tagMax':'Maksimum 10 tag','tagsUpdated':'Tag dikemas kini','birthdayUpdated':'Hari lahir dikemas kini','updateFailed':'Kemas kini gagal','avatarUpdated':'Avatar dikemas kini','avatarFailed':'Kemas kini avatar gagal','permissionDenied':'Kebenaran galeri diperlukan','nicknameUpdated':'Nama panggilan dikemas kini','usernameUpdated':'Nama pengguna dikemas kini','usernameUsed':'Nama pengguna sudah digunakan','bioUpdated':'Bio dikemas kini','languageUpdated':'Bahasa dikemas kini','languageExists':'Sudah wujud','languageName':'Nama bahasa','notLoggedIn':'Belum log masuk','noDynamic':'Belum ada siaran','error':'Ralat','securitySettings':'Keselamatan','securitySettingsDesc':'Tetapkan soalan keselamatan','changePassword':'Tukar kata laluan','changePasswordDesc':'Tukar kata laluan anda','blockList':'Senarai sekatan','blockListDesc':'Urus pengguna yang disekat','logoutConfirm':'Sahkan log keluar','logoutConfirmDesc':'Adakah anda pasti mahu log keluar?','developing':'Sedang dibangunkan...','discover':'Teroka pengguna','addFriend':'Tambah kawan','startChat':'Mulakan sembang','friendRequestSent':'Permintaan kawan dihantar','noOtherUsers':'Tiada pengguna lain','createChatFailed':'Gagal mencipta sembang','editTagsTitle':'Edit tag','editAgeTitle':'Tetapkan hari lahir','year':'Tahun','month':'Bulan','day':'Hari','editNicknameTitle':'Edit nama panggilan','newNicknameLabel':'Nama panggilan baharu','editUsernameTitle':'Edit nama pengguna','newUsernameLabel':'Nama pengguna baharu','editBioTitle':'Edit bio','languagesTitle':'Kemahiran bahasa','languagesUpdated':'Bahasa dikemas kini','addLanguage':'Tambah bahasa','ageUpdated':'Hari lahir dikemas kini','galleryPermission':'Kebenaran galeri diperlukan','tagUpdated':'Tag dikemas kini','tagInputHint':'Masukkan tag tersuai',
    },
    'th': {
        'appTitle':'Glyphora','forumCategories':'หมวดหมู่ฟอรัม','currentChannel':'ช่องปัจจุบัน','currentLanguage':'ภาษาปัจจุบัน','switchLanguage':'เปลี่ยนภาษา','selectLanguage':'เลือกภาษา','home':'หน้าหลัก','messages':'ข้อความ','profile':'โปรไฟล์','post':'โพสต์','publish':'เผยแพร่','title':'หัวข้อ','content':'เนื้อหา','selectImage':'เลือกรูปภาพ','addMoreImages':'เพิ่มรูปภาพ','uploading':'กำลังอัปโหลด...','noPosts':'ยังไม่มีโพสต์','loadFailed':'โหลดไม่สำเร็จ','refresh':'รีเฟรช','cancel':'ยกเลิก','confirm':'ยืนยัน','search':'ค้นหา','settings':'การตั้งค่า','midnightMode':'โหมดกลางคืนลึก','midnightModeDesc':'พื้นหลังดำสนิทและความสว่างต่ำ เหมาะกับกลางคืนและหน้าจอ OLED','logout':'ออกจากระบบ','login':'เข้าสู่ระบบ','register':'สมัครสมาชิก','email':'อีเมล','password':'รหัสผ่าน','username':'ชื่อผู้ใช้','send':'ส่ง','reply':'ตอบกลับ','like':'ถูกใจ','comment':'ความคิดเห็น','share':'แชร์','delete':'ลบ','edit':'แก้ไข','save':'บันทึก','justNow':'เมื่อสักครู่','minutesAgo':' นาทีที่แล้ว','hoursAgo':' ชั่วโมงที่แล้ว','daysAgo':' วันที่แล้ว','setNickname':'ตั้งชื่อเล่น','setBirthday':'ตั้งวันเกิด','selectBirthDate':'เลือกวันเกิด','clearBirthday':'ล้างวันเกิด','showAge':'แสดงอายุ','showAgeDesc':'เมื่อปิดจะเห็นได้เฉพาะคุณ','posts':'โพสต์','likesCount':'ยอดถูกใจ','introYourself':'✨ แนะนำตัวเอง...','addTagsHint':'เพิ่มแท็กความสนใจ...','languageAbility':'ความสามารถด้านภาษา','add':'เพิ่ม','nativeLanguage':'ภาษาแม่','native':'ภาษาแม่','changeLevel':'เปลี่ยนระดับ','quickSelect':'เลือกด่วน','myPosts':'โพสต์ของฉัน','editTags':'แก้ไขแท็ก','editNickname':'แก้ไขชื่อเล่น','newNickname':'ชื่อเล่นใหม่','nicknameHint':'ตั้งชื่อที่คุณชอบ','editUsername':'แก้ไขชื่อผู้ใช้','newUsername':'ชื่อผู้ใช้ใหม่','usernameHint':'ชื่อผู้ใช้คือ ID เฉพาะของคุณ','editBio':'แก้ไขประวัติ','bioHint':'แนะนำตัวเอง...','done':'เสร็จสิ้น','addTag':'เพิ่ม','selectedTags':'เลือกแล้ว','recommendTags':'แนะนำ','customTagHint':'กรอกแท็กกำหนดเอง','tagExists':'เพิ่มแท็กนี้แล้ว','tagMax':'สูงสุด 10 แท็ก','tagsUpdated':'อัปเดตแท็กแล้ว','birthdayUpdated':'อัปเดตวันเกิดแล้ว','updateFailed':'อัปเดตไม่สำเร็จ','avatarUpdated':'อัปเดตรูปโปรไฟล์แล้ว','avatarFailed':'อัปเดตรูปโปรไฟล์ไม่สำเร็จ','permissionDenied':'ต้องอนุญาตการเข้าถึงรูปภาพ','nicknameUpdated':'อัปเดตชื่อเล่นแล้ว','usernameUpdated':'อัปเดตชื่อผู้ใช้แล้ว','usernameUsed':'ชื่อผู้ใช้นี้ถูกใช้แล้ว','bioUpdated':'อัปเดตประวัติแล้ว','languageUpdated':'อัปเดตภาษาแล้ว','languageExists':'มีอยู่แล้ว','languageName':'ชื่อภาษา','notLoggedIn':'ยังไม่ได้เข้าสู่ระบบ','noDynamic':'ยังไม่มีโพสต์','error':'ข้อผิดพลาด','securitySettings':'ความปลอดภัย','securitySettingsDesc':'ตั้งคำถามความปลอดภัย','changePassword':'เปลี่ยนรหัสผ่าน','changePasswordDesc':'เปลี่ยนรหัสผ่านของคุณ','blockList':'รายการบล็อก','blockListDesc':'จัดการผู้ใช้ที่ถูกบล็อก','logoutConfirm':'ยืนยันออกจากระบบ','logoutConfirmDesc':'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?','developing':'กำลังพัฒนา...','discover':'ค้นหาผู้ใช้','addFriend':'เพิ่มเพื่อน','startChat':'เริ่มแชต','friendRequestSent':'ส่งคำขอเป็นเพื่อนแล้ว','noOtherUsers':'ไม่มีผู้ใช้อื่น','createChatFailed':'สร้างแชตไม่สำเร็จ','editTagsTitle':'แก้ไขแท็ก','editAgeTitle':'ตั้งวันเกิด','year':'ปี','month':'เดือน','day':'วัน','editNicknameTitle':'แก้ไขชื่อเล่น','newNicknameLabel':'ชื่อเล่นใหม่','editUsernameTitle':'แก้ไขชื่อผู้ใช้','newUsernameLabel':'ชื่อผู้ใช้ใหม่','editBioTitle':'แก้ไขประวัติ','languagesTitle':'ความสามารถด้านภาษา','languagesUpdated':'อัปเดตภาษาแล้ว','addLanguage':'เพิ่มภาษา','ageUpdated':'อัปเดตวันเกิดแล้ว','galleryPermission':'ต้องอนุญาตการเข้าถึงรูปภาพ','tagUpdated':'อัปเดตแท็กแล้ว','tagInputHint':'กรอกแท็กกำหนดเอง',
    },
}

LANGUAGE_TRANSLATIONS = {
    'ko': {'zh':'중국어','en':'영어','ja':'일본어','ko':'한국어','fr':'프랑스어','de':'독일어','es':'스페인어','pt':'포르투갈어','ru':'러시아어','it':'이탈리아어','ar':'아랍어','th':'태국어','vi':'베트남어','ms':'말레이어','id':'인도네시아어','hi':'힌디어','tr':'터키어'},
    'ms': {'zh':'Bahasa Cina','en':'Bahasa Inggeris','ja':'Bahasa Jepun','ko':'Bahasa Korea','fr':'Bahasa Perancis','de':'Bahasa Jerman','es':'Bahasa Sepanyol','pt':'Bahasa Portugis','ru':'Bahasa Rusia','it':'Bahasa Itali','ar':'Bahasa Arab','th':'Bahasa Thai','vi':'Bahasa Vietnam','ms':'Bahasa Melayu','id':'Bahasa Indonesia','hi':'Bahasa Hindi','tr':'Bahasa Turki'},
    'th': {'zh':'ภาษาจีน','en':'ภาษาอังกฤษ','ja':'ภาษาญี่ปุ่น','ko':'ภาษาเกาหลี','fr':'ภาษาฝรั่งเศส','de':'ภาษาเยอรมัน','es':'ภาษาสเปน','pt':'ภาษาโปรตุเกส','ru':'ภาษารัสเซีย','it':'ภาษาอิตาลี','ar':'ภาษาอาหรับ','th':'ภาษาไทย','vi':'ภาษาเวียดนาม','ms':'ภาษามลายู','id':'ภาษาอินโดนีเซีย','hi':'ภาษาฮินดี','tr':'ภาษาตุรกี'},
}

for code in ['en', 'zh', 'ja', 'vi']:
    path = L10N / f'{code}.json'
    data = json.loads(path.read_text(encoding='utf-8'))
    data.update(NEW_UI[code])
    data['categoryTranslations'] = CATEGORY_TRANSLATIONS[code]
    data['categoryNames'] = [CATEGORY_TRANSLATIONS[code][item] for item in ROOT_CATEGORY_IDS]
    data.setdefault('languageTranslations', {})['chunom'] = NEW_UI[code]['nomWritingSystem']
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

# Chữ Nôm remains a partial overlay. Existing verified/curated strings stay;
# new keys and uncovered categories inherit from Vietnamese at runtime.
nom_path = L10N / 'chunom.json'
nom = json.loads(nom_path.read_text(encoding='utf-8'))
nom_roots = nom.get('categoryNames', [])
nom['categoryTranslations'] = {
    category_id: nom_roots[index]
    for index, category_id in enumerate(ROOT_CATEGORY_IDS[:len(nom_roots)])
}
nom.setdefault('languageTranslations', {})['chunom'] = '𡨸喃'
nom_path.write_text(json.dumps(nom, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

# Missing locale files were a real bug: they were advertised as supported but
# AppLocalizations silently loaded English because the assets did not exist.
en = json.loads((L10N / 'en.json').read_text(encoding='utf-8'))
for code in ['ko', 'ms', 'th']:
    data = dict(en)
    data.update(EXISTING_LOCALE[code])
    data.update(NEW_UI[code])
    data['categoryTranslations'] = CATEGORY_TRANSLATIONS[code]
    data['categoryNames'] = [CATEGORY_TRANSLATIONS[code][item] for item in ROOT_CATEGORY_IDS]
    data['languageTranslations'] = LANGUAGE_TRANSLATIONS[code]
    data['languageTranslations']['chunom'] = NEW_UI[code]['nomWritingSystem']
    (L10N / f'{code}.json').write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )


# ---------------------------------------------------------------------------
# Home: remove hard-coded Chinese UI strings and positional category labels.
# ---------------------------------------------------------------------------
path = 'apps/mobile-flutter/lib/features/home/presentation/screens/home_tab.dart'
text = read(path)
text = replace_once(text, "            categoryNames: l10n.categoryNames,\n", '', label='home categoryNames arg')
text = replace_once(
    text,
    "              isRecommended ? '为你推荐' : l10n.forumCategories,",
    "              isRecommended ? l10n.get('recommendedForYou') : l10n.forumCategories,",
    label='home recommended title',
)
text = replace_once(
    text,
    "                  ? '仅显示你主动设为感兴趣的内容'\n                  : '$currentLanguageName · ${l10n.currentChannel}',",
    "                  ? l10n.get('recommendedOnlyInterests')\n                  : '$currentLanguageName · ${l10n.currentChannel}',",
    label='home recommended subtitle',
)
text = replace_once(
    text,
    "    final colorScheme = Theme.of(context).colorScheme;\n\n    return Column(\n      children: [",
    "    final colorScheme = Theme.of(context).colorScheme;\n    final l10n = AppLocalizations.of(context)!;\n\n    return Column(\n      children: [",
    label='recommended l10n',
)
text = replace_once(text, "                      const Text(\n                        '你的兴趣主页',", "                      Text(\n                        l10n.get('interestHomeTitle'),", label='interest title')
text = replace_once(text, "                        '先到分类频道，把语言频道中的分类设为感兴趣',", "                        l10n.get('interestHomeDesc'),", label='interest desc')
# Drawer l10n is the second colorScheme occurrence after drawer build; insert by class-scoped regex.
text = re.sub(
    r"(class _HomeDrawer[\s\S]*?Widget build\(BuildContext context\) \{\n    final colorScheme = Theme\.of\(context\)\.colorScheme;)\n",
    r"\1\n    final l10n = AppLocalizations.of(context)!;\n",
    text,
    count=1,
)
for old, new, label in [
    ("                    const Text(\n                      '语言社区',", "                    Text(\n                      l10n.get('languageCommunity'),", 'drawer community'),
    ("                      '连接语言、兴趣与世界',", "                      l10n.get('languageCommunityTagline'),", 'drawer tagline'),
    ("                    title: '推荐主页',", "                    title: l10n.get('recommendedHome'),", 'drawer recommended'),
    ("                    subtitle: '只显示已选择的兴趣',", "                    subtitle: l10n.get('recommendedHomeDesc'),", 'drawer recommended desc'),
    ("                    title: '分类频道',", "                    title: l10n.get('categoryChannels'),", 'drawer category'),
    ("                    subtitle: '选择语言、浏览和设置兴趣',", "                    subtitle: l10n.get('categoryChannelsDesc'),", 'drawer category desc'),
    ("                    '探索不同语言的内容',", "                    l10n.get('exploreLanguageContent'),", 'drawer footer'),
]:
    text = replace_once(text, old, new, label=label)
text = replace_all_checked(text, "  final List<String> categoryNames;\n", '', label='home categoryNames fields', minimum=2)
text = replace_all_checked(text, "    required this.categoryNames,\n", '', label='home categoryNames ctor', minimum=2)
text = replace_once(text, "                categoryNames: categoryNames,\n", '', label='home grid arg')
# Give grid access to l10n and use stable id-based translations.
text = replace_once(
    text,
    "  Widget build(BuildContext context) {\n    return LayoutBuilder(\n      builder: (context, constraints) {\n        final isTablet = constraints.maxWidth >= 600;",
    "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n\n    return LayoutBuilder(\n      builder: (context, constraints) {\n        final isTablet = constraints.maxWidth >= 600;",
    label='grid l10n',
)
text = replace_once(
    text,
    "                final categoryName = index < categoryNames.length\n                    ? categoryNames[index]\n                    : ForumCategories.nameOf(\n                        category.id,\n                        Localizations.localeOf(context).languageCode,\n                      );",
    "                final categoryName = l10n.categoryName(\n                  category.id,\n                  fallback: ForumCategories.nameOf(\n                    category.id,\n                    Localizations.localeOf(context).languageCode,\n                  ),\n                );",
    label='grid category localization',
)
# Centralize CategoryCopy in JSON localization so vi-Hani does not collapse to an ad-hoc vi switch.
copy_start = text.index('  static _CategoryCopy of(BuildContext context) {', text.index('class _CategoryCopy'))
copy_end_marker = '\n  }\n}'
copy_end = text.index(copy_end_marker, copy_start) + len('\n  }')
new_copy = r'''  static _CategoryCopy of(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _CategoryCopy(
      selectTopics: l10n.get('selectTopics'),
      interestsLoading: l10n.get('interestsLoading'),
      signInFirst: l10n.get('signInFirst'),
      updateFailed: l10n.get('interestUpdateFailed'),
      interestCardLabel: l10n.get('interestCardLabel'),
      following: l10n.get('following'),
      addInterest: l10n.get('addInterest'),
      removeInterest: l10n.get('removeInterest'),
      interestSummary: (selected, total) => l10n.getWithArgs(
        'interestSummary',
        <String, String>{
          'selected': '$selected',
          'total': '$total',
        },
      ),
    );
  }'''
text = text[:copy_start] + new_copy + text[copy_end:]
write(path, text)


# ---------------------------------------------------------------------------
# Feed: central l10n + id-based category names + language-library copy.
# ---------------------------------------------------------------------------
path = 'apps/mobile-flutter/lib/features/feed/presentation/screens/feed_screen.dart'
text = read(path)
text = replace_once(text, "import '../../../../app/router/app_routes.dart';", "import '../../../../app/l10n/app_localizations.dart';\nimport '../../../../app/router/app_routes.dart';", label='feed l10n import')
text = replace_once(text, 'return _buildErrorState(snapshot.error);', 'return _buildErrorState(context, snapshot.error);', label='feed error call')
text = replace_once(text, '  Widget _buildErrorState(Object? error) {', '  Widget _buildErrorState(BuildContext context, Object? error) {\n    final l10n = AppLocalizations.of(context)!;', label='feed error signature')
text = replace_once(text, "          const Text(\n            '加载失败',", "          Text(\n            l10n.loadFailed,", label='feed error label')
# AppBar category + language display + tooltip.
text = replace_once(
    text,
    "    final uiLanguageCode = Localizations.localeOf(context).languageCode;\n    final categoryName = ForumCategories.nameOf(\n      _selectedCategoryId,\n      uiLanguageCode,\n    );",
    "    final uiLanguageCode = Localizations.localeOf(context).languageCode;\n    final l10n = AppLocalizations.of(context)!;\n    final categoryName = l10n.categoryName(\n      _selectedCategoryId,\n      fallback: ForumCategories.nameOf(_selectedCategoryId, uiLanguageCode),\n    );",
    label='feed appbar category',
)
text = replace_once(text, '            _getLanguageDisplay(),', '            _getLanguageDisplay(context),', label='feed channel display call')
text = replace_once(text, "            tooltip: _isLanguageLearningRoot ? '发布综合语言学习话题' : '发布帖子',", "            tooltip: _isLanguageLearningRoot\n                ? l10n.get('publishGeneralLanguageLearning')\n                : l10n.get('publishPost'),", label='feed publish tooltip')
# Empty state.
old = "    final uiLanguageCode = Localizations.localeOf(context).languageCode;\n    final categoryName = ForumCategories.nameOf(\n      _selectedCategoryId,\n      uiLanguageCode,\n    );\n\n    return EmptyState(\n      icon: Icons.article_outlined,\n      title: '暂无$languageName帖子',\n      subtitle: _isLanguageLearningRoot\n          ? '可以直接发布语言学习综合话题，\\n也可以先选择一门具体语言'\n          : '成为第一个在「$categoryName」下\\n发布$languageName帖子的人吧',"
new = "    final uiLanguageCode = Localizations.localeOf(context).languageCode;\n    final l10n = AppLocalizations.of(context)!;\n    final categoryName = l10n.categoryName(\n      _selectedCategoryId,\n      fallback: ForumCategories.nameOf(_selectedCategoryId, uiLanguageCode),\n    );\n\n    return EmptyState(\n      icon: Icons.article_outlined,\n      title: l10n.getWithArgs(\n        'noLanguagePosts',\n        <String, String>{'language': languageName},\n      ),\n      subtitle: _isLanguageLearningRoot\n          ? l10n.get('languageLearningRootEmpty')\n          : l10n.getWithArgs(\n              'firstPostInCategory',\n              <String, String>{\n                'category': categoryName,\n                'language': languageName,\n              },\n            ),"
text = replace_once(text, old, new, label='feed empty state')
text = replace_once(text, "      actionLabel: _isLanguageLearningRoot ? '发布综合语言学习话题' : '发布$languageName帖子',", "      actionLabel: _isLanguageLearningRoot\n          ? l10n.get('publishGeneralLanguageLearning')\n          : l10n.getWithArgs(\n              'publishLanguagePost',\n              <String, String>{'language': languageName},\n            ),", label='feed empty action')
text = replace_once(
    text,
    "  String _getLanguageDisplay() {\n    final flag = _getFlag(languageCode);\n    return '$flag $languageName频道';\n  }",
    "  String _getLanguageDisplay(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n    final flag = _getFlag(languageCode);\n    return l10n.getWithArgs(\n      'channelDisplay',\n      <String, String>{'flag': flag, 'language': languageName},\n    );\n  }",
    label='feed language display',
)
# Breadcrumb category names.
text = replace_once(text, "    final uiLanguageCode = Localizations.localeOf(context).languageCode;\n    final path = ForumCategories.pathOf(categoryId);", "    final uiLanguageCode = Localizations.localeOf(context).languageCode;\n    final l10n = AppLocalizations.of(context)!;\n    final path = ForumCategories.pathOf(categoryId);", label='breadcrumb l10n')
text = replace_once(text, "                  ForumCategories.nameOf(path[index], uiLanguageCode),", "                  l10n.categoryName(\n                    path[index],\n                    fallback: ForumCategories.nameOf(path[index], uiLanguageCode),\n                  ),", label='breadcrumb name')
# Learning language panel.
text = replace_once(text, "    final colorScheme = Theme.of(context).colorScheme;\n\n    return Container(\n      width: double.infinity,\n      color: colorScheme.surface,\n      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),", "    final colorScheme = Theme.of(context).colorScheme;\n    final l10n = AppLocalizations.of(context)!;\n\n    return Container(\n      width: double.infinity,\n      color: colorScheme.surface,\n      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),", label='learning panel l10n')
text = replace_once(text, "                    Text(\n                      '选择学习语言（可选）',", "                    Text(\n                      l10n.get('selectLearningLanguageOptional'),", label='learning optional title')
text = replace_once(text, "                      '不选择具体语言也可以发帖，适合讨论学习方法、语言学或多语言话题。',", "                      l10n.get('learningLanguageOptionalDesc'),", label='learning optional desc')
text = replace_once(text, "              label: Text('从语言库选择 · ${children.length} 种语言'),", "              label: Text(\n                l10n.getWithArgs(\n                  'chooseFromLanguageLibrary',\n                  <String, String>{'count': '${children.length}'},\n                ),\n              ),", label='language library button')
# Picker copy and translated language labels.
text = replace_once(text, "    final colorScheme = Theme.of(context).colorScheme;\n    final uiLanguageCode = Localizations.localeOf(context).languageCode;\n    final normalizedQuery", "    final colorScheme = Theme.of(context).colorScheme;\n    final uiLanguageCode = Localizations.localeOf(context).languageCode;\n    final l10n = AppLocalizations.of(context)!;\n    final normalizedQuery", label='picker l10n')
text = replace_once(text, "                  '选择学习语言',", "                  l10n.get('selectLearningLanguage'),", label='picker title')
text = replace_once(text, "                  '语言来自 Glyphora Language Core。返回上一层即可继续使用“综合语言学习”，不要求指定语言。',", "                  l10n.get('languageLibraryDesc'),", label='picker desc')
text = replace_once(text, "                  decoration: const InputDecoration(\n                    prefixIcon: Icon(Icons.search_rounded),\n                    hintText: '搜索语言名称或代码',\n                  ),", "                  decoration: InputDecoration(\n                    prefixIcon: const Icon(Icons.search_rounded),\n                    hintText: l10n.get('searchLanguageNameOrCode'),\n                  ),", label='picker search')
text = replace_once(text, "                      '没有找到语言',", "                      l10n.get('noLanguagesFound'),", label='picker empty')
text = replace_once(
    text,
    "                        title: Text(\n                          category.nameOf(uiLanguageCode),\n                          style: const TextStyle(fontWeight: FontWeight.w600),\n                        ),",
    "                        title: Text(\n                          l10n.translateLanguage(code) == code\n                              ? category.nameOf(uiLanguageCode)\n                              : l10n.translateLanguage(code),\n                          style: const TextStyle(fontWeight: FontWeight.w600),\n                        ),",
    label='picker language label',
)
# Generic child bar.
text = replace_once(text, "    final colorScheme = Theme.of(context).colorScheme;\n    final uiLanguageCode = Localizations.localeOf(context).languageCode;\n\n    return Container(", "    final colorScheme = Theme.of(context).colorScheme;\n    final uiLanguageCode = Localizations.localeOf(context).languageCode;\n    final l10n = AppLocalizations.of(context)!;\n\n    return Container(", label='children bar l10n')
text = replace_once(text, "            '继续选择分类',", "            l10n.get('continueSelectCategory'),", label='children bar title')
text = replace_once(text, "                final childName = child.nameOf(uiLanguageCode);", "                final childName = l10n.categoryName(\n                  child.id,\n                  fallback: child.nameOf(uiLanguageCode),\n                );", label='children category name')
write(path, text)


# ---------------------------------------------------------------------------
# Post cards: localized relative time, title fallback, and channel badge.
# ---------------------------------------------------------------------------
path = 'apps/mobile-flutter/lib/features/post/presentation/widgets/post_item_card.dart'
text = read(path)
text = replace_once(text, "import '../../../../app/router/app_routes.dart';", "import '../../../../app/l10n/app_localizations.dart';\nimport '../../../../app/router/app_routes.dart';\nimport 'package:glyphora_language_core/glyphora_language_core.dart';", label='post card imports')
old_method = r'''  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inHours < 1) return '${difference.inMinutes} 分钟前';
    if (difference.inDays < 1) return '${difference.inHours} 小时前';
    if (difference.inDays < 7) return '${difference.inDays} 天前';

    return '${dateTime.month}月${dateTime.day}日';
  }'''
new_method = r'''  String _formatTimestamp(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return '';

    final l10n = AppLocalizations.of(context)!;
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) return l10n.justNow;
    if (difference.inHours < 1) {
      return '${difference.inMinutes}${l10n.minutesAgo}';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}${l10n.hoursAgo}';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}${l10n.daysAgo}';
    }

    return MaterialLocalizations.of(context).formatShortDate(dateTime);
  }'''
text = replace_once(text, old_method, new_method, label='timestamp method')
text = replace_once(text, "    final colorScheme = Theme.of(context).colorScheme;\n\n    return Row(", "    final colorScheme = Theme.of(context).colorScheme;\n    final l10n = AppLocalizations.of(context)!;\n\n    return Row(", label='post title l10n')
text = replace_once(text, "            title.isNotEmpty ? title : '无标题',", "            title.isNotEmpty ? title : l10n.get('untitled'),", label='post untitled')
text = replace_once(text, "              _getLanguageName(postLanguageCode),", "              _getLanguageName(context, postLanguageCode),", label='post badge call')
text = replace_once(text, "          _formatTimestamp(post.createdAt),", "          _formatTimestamp(context, post.createdAt),", label='post timestamp call')
start = text.index('  String _getLanguageName(String code) {')
end = text.index('\n  }\n}', start) + len('\n  }')
new_lang = r'''  String _getLanguageName(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;
    final normalized = code.trim();
    final lower = normalized.replaceAll('_', '-').toLowerCase();
    final uiLanguageCode = Localizations.localeOf(context).languageCode;

    if (lower == 'chunom' ||
        lower == 'vi-hani' ||
        lower == 'vi-hnom' ||
        lower == 'vi-nom') {
      final vietnamese = LanguageConfig.findByCode('vi');
      final languageName = l10n.translateLanguage('vi');
      final scriptName = vietnamese?.scriptNameOf('Hnom', uiLanguageCode) ??
          l10n.get('nomWritingSystem');
      return l10n.getWithArgs(
        'channelBadge',
        <String, String>{'language': '$languageName · $scriptName'},
      );
    }

    if (normalized.contains(':')) {
      final parts = normalized.split(':');
      if (parts.length == 2) {
        final language = LanguageConfig.findByCode(parts.first);
        final languageName = language == null
            ? l10n.translateLanguage(parts.first)
            : l10n.translateLanguage(parts.first) == parts.first
            ? language.nameOf(uiLanguageCode)
            : l10n.translateLanguage(parts.first);
        final scriptName = language?.scriptNameOf(parts.last, uiLanguageCode) ??
            ScriptConfig.findByCode(parts.last)?.nameOf(uiLanguageCode) ??
            parts.last;
        return l10n.getWithArgs(
          'channelBadge',
          <String, String>{'language': '$languageName · $scriptName'},
        );
      }
    }

    final language = LanguageConfig.findByCode(normalized);
    final translated = l10n.translateLanguage(normalized);
    final languageName = translated != normalized
        ? translated
        : language?.nameOf(uiLanguageCode) ?? l10n.get('otherLanguage');

    return l10n.getWithArgs(
      'channelBadge',
      <String, String>{'language': languageName},
    );
  }'''
text = text[:start] + new_lang + text[end:]
write(path, text)


# ---------------------------------------------------------------------------
# Notes: root-category lists now come from ForumCategories (Medicine included),
# names are id-based, and the most obvious light-only surfaces follow Theme.
# ---------------------------------------------------------------------------
for path in [
    'apps/mobile-flutter/lib/features/notes/presentation/screens/all_notes_screen.dart',
    'apps/mobile-flutter/lib/features/notes/presentation/screens/note_editor_screen.dart',
]:
    text = read(path)
    if "../../../../core/constants/forum_categories.dart" not in text:
        text = replace_once(
            text,
            "import '../../../../app/router/app_routes.dart';" if 'all_notes_screen' in path else "import '../../../../app/l10n/app_localizations.dart';",
            ("import '../../../../app/router/app_routes.dart';\nimport '../../../../core/constants/forum_categories.dart';" if 'all_notes_screen' in path else "import '../../../../app/l10n/app_localizations.dart';\nimport '../../../../core/constants/forum_categories.dart';"),
            label=f'{path} category import',
        )
    field_name = '_categoryIds' if 'all_notes_screen' in path else '_publishCategoryIds'
    pattern = rf"  static const List<String> {field_name} = \[[\s\S]*?\n  \];"
    replacement = f"  List<String> get {field_name} => ForumCategories.roots\n      .map((category) => category.id)\n      .toList(growable: false);"
    text, count = re.subn(pattern, replacement, text, count=1)
    if count != 1:
        raise RuntimeError(f'failed category getter rewrite for {path}')
    write(path, text)

# AllNotes category labels.
path = 'apps/mobile-flutter/lib/features/notes/presentation/screens/all_notes_screen.dart'
text = read(path)
old = r'''    final index = _categoryIds.indexOf(category);

    if (index == -1) {
      return category;
    }

    final l10n = AppLocalizations.of(context)!;

    if (index >= l10n.categoryNames.length) {
      return category;
    }

    return l10n.categoryNames[index];'''
new = r'''    final l10n = AppLocalizations.of(context)!;
    final uiLanguageCode = Localizations.localeOf(context).languageCode;
    return l10n.categoryName(
      category,
      fallback: ForumCategories.nameOf(category, uiLanguageCode),
    );'''
text = replace_once(text, old, new, label='all notes category name')
text = replace_all_checked(
    text,
    "index < l10n.categoryNames.length\n                                ? l10n.categoryNames[index]\n                                : _categoryIds[index]",
    "_categoryName(_categoryIds[index])",
    label='all notes picker category names',
    minimum=2,
)
text = replace_once(text, '      backgroundColor: const Color(0xFFF4F4F4),', '      backgroundColor: Theme.of(context).scaffoldBackgroundColor,', label='all notes scaffold theme')
text = replace_once(text, '      color: Colors.white,\n      child: Column(', '      color: Theme.of(context).colorScheme.surface,\n      child: Column(', label='all notes filter theme')
text = replace_once(text, '      color: Colors.white,\n      borderRadius: BorderRadius.circular(16),', '      color: Theme.of(context).colorScheme.surfaceContainerLowest,\n      borderRadius: BorderRadius.circular(16),', label='all notes card theme')
text = replace_once(text, "                            : const Color(0xFF666666),", "                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),", label='all notes content theme')
write(path, text)

# NoteEditor category labels.
path = 'apps/mobile-flutter/lib/features/notes/presentation/screens/note_editor_screen.dart'
text = read(path)
text = replace_once(
    text,
    "                      final categoryName = index < l10n.categoryNames.length\n                          ? l10n.categoryNames[index]\n                          : category;",
    "                      final categoryName = l10n.categoryName(\n                        category,\n                        fallback: ForumCategories.nameOf(\n                          category,\n                          Localizations.localeOf(context).languageCode,\n                        ),\n                      );",
    label='note editor picker category',
)
old = r'''    final categoryId = category.trim();
    final index = _publishCategoryIds.indexOf(categoryId);

    if (index == -1) {
      return categoryId;
    }

    final l10n = AppLocalizations.of(context)!;

    if (index >= l10n.categoryNames.length) {
      return categoryId;
    }

    return l10n.categoryNames[index];'''
new = r'''    final categoryId = category.trim();
    final l10n = AppLocalizations.of(context)!;
    return l10n.categoryName(
      categoryId,
      fallback: ForumCategories.nameOf(
        categoryId,
        Localizations.localeOf(context).languageCode,
      ),
    );'''
text = replace_once(text, old, new, label='note editor category name')
write(path, text)


# ---------------------------------------------------------------------------
# Tests: canonical aliases/race guard + asset/key/category coverage.
# ---------------------------------------------------------------------------
write(
    'apps/mobile-flutter/test/app/cubit/app_language_cubit_test.dart',
    r'''import 'package:flutter/material.dart';
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

  test('changeLanguageByCode updates state and persists language code', () async {
    final cubit = AppLanguageCubit();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);
    await cubit.changeLanguageByCode('ms');

    final prefs = await SharedPreferences.getInstance();
    expect(cubit.locale, const Locale('ms'));
    expect(cubit.currentCode, 'ms');
    expect(prefs.getString('languageCode'), 'ms');
  });

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

  test('accepts hyphenated Hani and Hnom aliases and persists canonical code', () async {
    final cubit = AppLanguageCubit();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    await cubit.changeLanguageByCode('vi-Hani');
    expect(cubit.locale, AppLanguageCubit.chunomLocale);

    await cubit.changeLanguageByCode('vi-Hnom');
    final prefs = await SharedPreferences.getInstance();
    expect(cubit.currentCode, 'chunom');
    expect(prefs.getString('languageCode'), 'chunom');
  });

  test('an explicit language change wins over the asynchronous saved load', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'languageCode': 'en',
    });

    final cubit = AppLanguageCubit();
    addTearDown(cubit.close);
    await cubit.changeLanguageByCode('vi');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.locale, const Locale('vi'));
    expect(cubit.currentCode, 'vi');
  });
}
''',
)

write(
    'apps/mobile-flutter/test/app/l10n/localization_assets_test.dart',
    r'''import 'dart:convert';
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
''',
)

print('Applied interface-language grouping and localization audit.')
