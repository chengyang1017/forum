import 'package:flutter/material.dart';

import '../../../config/l10n/app_localizations.dart';
import '../../../config/languages.dart';

class ProfileLanguageSection extends StatelessWidget {
  final List<Map<String, dynamic>> languages;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const ProfileLanguageSection({
    super.key,
    required this.languages,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 当前 App 界面使用的语言。
    // 例如 zh、en、ms、vi。
    final uiLanguageCode =
        Localizations.localeOf(context).languageCode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // 标题
            // ======================================================
            Row(
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 18,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.languageAbility,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (languages.isEmpty)
                  Text(
                    l10n.add,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                  ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),

            // ======================================================
            // 语言列表
            // ======================================================
            if (languages.isNotEmpty) ...[
              const SizedBox(height: 16),

              ...languages.map((lang) {
                // Firestore 里面保存的是语言代码：
                // zh、en、vi、ru、kk 等。
                final languageCode =
                    (lang['name'] ?? '').toString();

                // 从 languages.dart 查找对应配置。
                final languageConfig =
                    _findLanguage(languageCode);

                // 根据当前 App 界面语言显示名称。
                // 例如：
                // ru -> 俄语
                // kk -> 哈萨克语
                // ko -> 韩语
                final displayName =
                    languageConfig?.nameOf(uiLanguageCode) ??
                    languageCode;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // ==================================================
                      // 语言名称
                      // ==================================================
                      SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            // 显示旗帜。
                            if (languageConfig != null) ...[
                              Text(
                                languageConfig.flag,
                                style: const TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],

                            Expanded(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ==================================================
                      // 母语标签或者熟练度进度条
                      // ==================================================
                      Expanded(
                        child: lang['level'] == 'native'
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n.nativeLanguage,
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _levelValue(lang) / 100,
                                  minHeight: 6,
                                  backgroundColor:
                                      Colors.grey.shade100,
                                  color: Colors.green.shade400,
                                ),
                              ),
                      ),

                      // ==================================================
                      // 百分比
                      // ==================================================
                      if (lang['level'] != 'native')
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            '${_levelValue(lang).toInt()}%',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 根据语言代码查找配置
  // ============================================================

  LanguageConfig? _findLanguage(String code) {
    final normalizedCode = code.trim().toLowerCase();

    for (final language in LanguageConfig.supportedLanguages) {
      if (language.code.toLowerCase() == normalizedCode) {
        return language;
      }
    }

    return null;
  }

  // ============================================================
  // 获取熟练度
  // ============================================================

  double _levelValue(Map<String, dynamic> lang) {
    final level = lang['level'];

    if (level is num) {
      return level.toDouble().clamp(0, 100);
    }

    return 70;
  }
}