import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/cubit/app_language_cubit.dart';
import '../../../../app/cubit/app_theme_cubit.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart' as auth_cubit;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.updateFailed}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  static const List<_LanguageItem> _languages = [
    _LanguageItem(code: 'zh', flag: '🇨🇳', name: '中文', native: '中文'),
    _LanguageItem(code: 'en', flag: '🇺🇸', name: 'English', native: 'English'),
    _LanguageItem(code: 'ja', flag: '🇯🇵', name: '日本語', native: '日本語'),
    _LanguageItem(code: 'ko', flag: '🇰🇷', name: '한국어', native: '한국어'),
    _LanguageItem(
      code: 'ms',
      flag: '🇲🇾',
      name: 'Bahasa Melayu',
      native: 'Bahasa Melayu',
    ),
    _LanguageItem(
      code: 'vi',
      flag: '🇻🇳',
      name: 'Tiếng Việt',
      native: 'Tiếng Việt',
    ),
    _LanguageItem(code: 'th', flag: '🇹🇭', name: 'ภาษาไทย', native: 'ภาษาไทย'),

    // 注意：显示给用户是 chunom，但真正 Locale 会在 AppLanguageCubit 里转成 vi-Hani
    _LanguageItem(code: 'chunom', flag: '🇻🇳', name: '㗂越', native: '㗂越'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final appLanguage = context.watch<AppLanguageCubit>();
    final appTheme = context.watch<AppThemeCubit>();
    final currentLangName = _getLangName(appLanguage.currentCode);

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
            onTap: () {
              context.push(AppRoutes.securitySettings);
            },
          ),
          _buildItem(
            context,
            icon: Icons.lock,
            title: l10n.changePassword,
            subtitle: l10n.changePasswordDesc,
            onTap: () {
              context.push(AppRoutes.changePassword);
            },
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

  void _showLanguagePicker(
    BuildContext context,
    AppLanguageCubit appLanguage,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                children: _languages.map((lang) {
                  final isSelected = appLanguage.currentCode == lang.code;

                  return InkWell(
                    onTap: () async {
                      await appLanguage.changeLanguageByCode(lang.code);

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
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
                          Text(lang.flag, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.native,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                if (lang.name != lang.native)
                                  Text(
                                    lang.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.52,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: colorScheme.onPrimary,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLangName(String code) {
    for (final lang in _languages) {
      if (lang.code == code) return lang.native;
    }

    return code;
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
  final String code;
  final String flag;
  final String name;
  final String native;

  const _LanguageItem({
    required this.code,
    required this.flag,
    required this.name,
    required this.native,
  });
}
