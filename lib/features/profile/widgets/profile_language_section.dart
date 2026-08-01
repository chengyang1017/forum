import 'package:flutter/material.dart';

import '../../../config/l10n/app_localizations.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';

class ProfileLanguageSection extends StatefulWidget {
  final List<Map<String, dynamic>> languages;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  const ProfileLanguageSection({
    super.key,
    required this.languages,
    required this.l10n,
    this.onTap,
  });

  @override
  State<ProfileLanguageSection> createState() => _ProfileLanguageSectionState();
}

class _ProfileLanguageSectionState extends State<ProfileLanguageSection> {
  static const int _collapsedCount = 5;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final uiLanguageCode = Localizations.localeOf(context).languageCode;

    final hasMoreLanguages = widget.languages.length > _collapsedCount;

    final visibleLanguages = hasMoreLanguages && !_expanded
        ? widget.languages.take(_collapsedCount)
        : widget.languages;

    return GestureDetector(
      onTap: widget.onTap,
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
                  widget.l10n.languageAbility,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),

                if (widget.languages.isEmpty)
                  Text(
                    widget.l10n.add,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                  ),

                if (widget.onTap != null)
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
            if (widget.languages.isNotEmpty) ...[
              const SizedBox(height: 16),

              ...visibleLanguages.map((lang) {
                final languageConfig = _findLanguage(lang);

                final savedName = lang['name']?.toString() ?? '';

                final displayName =
                    languageConfig?.nameOf(uiLanguageCode) ?? savedName;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // ==========================================
                      // 国旗和语言名称
                      // ==========================================
                      SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            if (languageConfig != null) ...[
                              Text(
                                languageConfig.flag,
                                style: const TextStyle(fontSize: 15),
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

                      // ==========================================
                      // 母语或熟练度
                      // ==========================================
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
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.l10n.nativeLanguage,
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _levelValue(lang) / 100,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade100,
                                  color: Colors.green.shade400,
                                ),
                              ),
                      ),

                      // ==========================================
                      // 百分比
                      // ==========================================
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

              // ====================================================
              // 展开 / 收起
              // ====================================================
              if (hasMoreLanguages)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _expanded = !_expanded;
                        });
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.green.shade700,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      icon: Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                      ),
                      label: Text(_expanded ? '收起' : '查看更多'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 从 LanguageConfig 查找语言
  // ============================================================

  LanguageConfig? _findLanguage(Map<String, dynamic> data) {
    final code = data['code']?.toString().trim();

    if (code != null && code.isNotEmpty) {
      final normalizedCode = code.toLowerCase();

      for (final language in LanguageConfig.allLanguages) {
        if (language.code.toLowerCase() == normalizedCode) {
          return language;
        }
      }
    }

    /*
     * 兼容旧数据：
     * 以前可能把语言代码保存在 name，
     * 例如 name: "vi"。
     */
    final savedName = data['name']?.toString().trim();

    if (savedName == null || savedName.isEmpty) {
      return null;
    }

    final normalizedName = savedName.toLowerCase();

    for (final language in LanguageConfig.allLanguages) {
      if (language.code.toLowerCase() == normalizedName) {
        return language;
      }

      final nameMatched = language.names.values.any(
        (name) => name.toLowerCase() == normalizedName,
      );

      if (nameMatched) {
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
