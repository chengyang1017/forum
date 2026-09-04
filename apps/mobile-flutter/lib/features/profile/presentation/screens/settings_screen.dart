import 'package:flutter/material.dart';
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

  Future<void> _deleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteAccountDialog(l10n: l10n),
    );

    if (password == null || password.isEmpty || !context.mounted) {
      return;
    }

    try {
      await context.read<auth_cubit.AuthCubit>().deleteAccount(password);
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('deleteAccountFailed')),
          backgroundColor: Colors.red,
        ),
      );
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
            onTap: () => context.push(AppRoutes.blockedUsers),
          ),
          const Divider(height: 32, thickness: 1),
          _buildDangerItem(
            context,
            icon: Icons.delete_forever_outlined,
            title: l10n.get('deleteAccount'),
            subtitle: l10n.get('deleteAccountDesc'),
            onTap: () => _deleteAccount(context),
          ),
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
                children: _languages
                    .map((language) {
                      final isSelected = language.hasWritingSystems
                          ? appLanguage.currentCode == 'vi' ||
                                appLanguage.currentCode ==
                                    AppLanguageCubit.chunomCode
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
                                ? Border.all(
                                    color: colorScheme.primary,
                                    width: 1.5,
                                  )
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
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.52),
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
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.45,
                                        ),
                                )
                              else if (isSelected)
                                _selectedIcon(colorScheme),
                            ],
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
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

  Widget _buildDangerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.error),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.error),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.62),
        ),
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

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return AlertDialog(
      title: Text(l10n.get('deleteAccountConfirmTitle')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.get('deleteAccountConfirmDesc')),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.password,
              hintText: l10n.get('deleteAccountPasswordHint'),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
            onSubmitted: (value) {
              final password = value.trim();
              if (password.isNotEmpty) {
                Navigator.pop(context, password);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () {
            final password = _passwordController.text.trim();
            if (password.isNotEmpty) {
              Navigator.pop(context, password);
            }
          },
          child: Text(l10n.get('deleteAccountAction')),
        ),
      ],
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
