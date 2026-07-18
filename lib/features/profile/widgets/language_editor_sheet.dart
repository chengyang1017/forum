import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/languages.dart';

Future<List<Map<String, dynamic>>?> showLanguageEditorSheet({
  required BuildContext context,
  required List<Map<String, dynamic>> selectedLanguages,
}) {
  return showModalBottomSheet<List<Map<String, dynamic>>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (context) {
      return _LanguageEditorSheet(
        selectedLanguages: selectedLanguages,
      );
    },
  );
}

class _LanguageEditorSheet extends StatefulWidget {
  final List<Map<String, dynamic>> selectedLanguages;

  const _LanguageEditorSheet({
    required this.selectedLanguages,
  });

  @override
  State<_LanguageEditorSheet> createState() =>
      _LanguageEditorSheetState();
}

class _LanguageEditorSheetState
    extends State<_LanguageEditorSheet> {
  final TextEditingController _searchController =
      TextEditingController();

  Timer? _searchDebounce;

  late final List<LanguageConfig> _allLanguages;
  late final Map<String, LanguageConfig> _languageByCode;

  late final List<Map<String, dynamic>> _selectedLanguages;
  late final Set<String> _selectedLanguageCodes;

  List<LanguageConfig> _visibleLanguages = [];

  String _uiLanguageCode = 'zh';
  String? _expandedLanguageCode;
  @override
  void initState() {
    super.initState();

    // 完整语言库。
    _allLanguages = List<LanguageConfig>.from(
      LanguageConfig.supportedLanguages,
    );

    // 使用 Map 通过语言代码快速查找。
    // 几千种语言时比每次循环查找更合适。
    _languageByCode = {
      for (final language in _allLanguages)
        language.code.toLowerCase(): language,
    };

    final validCodes = _languageByCode.keys.toSet();

    // 过滤旧的中文写死数据。
    // 只保留仍存在于语言库中的语言代码。
    _selectedLanguages = widget.selectedLanguages
        .where((language) {
          final code = (language['name'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          return validCodes.contains(code);
        })
        .map(
          (language) =>
              Map<String, dynamic>.from(language),
        )
        .toList();

    _selectedLanguageCodes = _selectedLanguages
        .map(
          (language) => (language['name'] ?? '')
              .toString()
              .trim()
              .toLowerCase(),
        )
        .toSet();

    _visibleLanguages = List<LanguageConfig>.from(
      _allLanguages,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newUiLanguageCode =
        Localizations.localeOf(context).languageCode;

    if (_uiLanguageCode != newUiLanguageCode) {
      _uiLanguageCode = newUiLanguageCode;
      _sortLanguages();
      _visibleLanguages = _filterLanguages(
        _searchController.text,
      );
    } else {
      _sortLanguages();
    }
  }

  void _sortLanguages() {
    _allLanguages.sort(
      (first, second) {
        return first
            .sortKeyOf(_uiLanguageCode)
            .compareTo(
              second.sortKeyOf(_uiLanguageCode),
            );
      },
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 120),
      () {
        if (!mounted) return;

        setState(() {
          _visibleLanguages = _filterLanguages(value);
        });
      },
    );
  }

  List<LanguageConfig> _filterLanguages(
    String query,
  ) {
    final normalizedQuery =
        query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return List<LanguageConfig>.from(
        _allLanguages,
      );
    }

    return _allLanguages.where((language) {
      // 搜索语言代码。
      if (language.code
          .toLowerCase()
          .contains(normalizedQuery)) {
        return true;
      }

      // 搜索所有界面语言下的语言名称。
      final matchesName = language.names.values.any(
        (name) {
          return name
              .toLowerCase()
              .contains(normalizedQuery);
        },
      );

      if (matchesName) {
        return true;
      }

      // 搜索排序关键词。
      // 例如用户输入不带声调的越南语名称时也能匹配。
      return language.sortKeys.values.any(
        (sortKey) {
          return sortKey
              .toLowerCase()
              .contains(normalizedQuery);
        },
      );
    }).toList();
  }

  void _addLanguage(LanguageConfig language) {
    final code = language.code.toLowerCase();

    if (!_selectedLanguageCodes.add(code)) {
      return;
    }

    setState(() {
      _selectedLanguages.add({
        'name': language.code,
        'level': 70,
      });
    });
  }

  void _removeLanguageAt(int index) {
  final language = _selectedLanguages[index];

  final code = (language['name'] ?? '')
      .toString()
      .trim()
      .toLowerCase();

  setState(() {
    _selectedLanguages.removeAt(index);
    _selectedLanguageCodes.remove(code);

    if (_expandedLanguageCode == code) {
      _expandedLanguageCode = null;
    }
  });
}

  void _removeLanguageByCode(String code) {
    final normalizedCode = code.toLowerCase();

    final index = _selectedLanguages.indexWhere(
      (language) {
        return (language['name'] ?? '')
                .toString()
                .toLowerCase() ==
            normalizedCode;
      },
    );

    if (index == -1) return;

    _removeLanguageAt(index);
  }

  void _updateLanguageLevel(
    int index,
    dynamic level,
  ) {
    setState(() {
      _selectedLanguages[index]['level'] = level;
    });
  }

  void _save() {
    final result = _selectedLanguages
        .map(
          (language) =>
              Map<String, dynamic>.from(language),
        )
        .toList();

    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: screenHeight * 0.94,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(26),
        ),
        clipBehavior: Clip.antiAlias,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const SizedBox(height: 9),

              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),

              _buildHeader(context),

              Divider(
                height: 1,
                color: colors.outlineVariant,
              ),

              TabBar(
                labelColor: colors.primary,
                unselectedLabelColor:
                    colors.onSurfaceVariant,
                indicatorColor: colors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: colors.outlineVariant,
                tabs: [
                  Tab(
                    text:
                        '已选择 (${_selectedLanguages.length})',
                  ),
                  const Tab(
                    text: '添加语言',
                  ),
                ],
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    _buildSelectedLanguagesTab(context),
                    _buildLanguageLibraryTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        12,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  '语言能力',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _selectedLanguages.isEmpty
                      ? '选择你掌握的语言'
                      : '已选择 ${_selectedLanguages.length} 门语言',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _save,
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            child: const Text(
              '完成',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildSelectedLanguagesTab(
  BuildContext context,
) {
  final colors = Theme.of(context).colorScheme;

  if (_selectedLanguages.isEmpty) {
    return _buildEmptySelectedState(context);
  }

  return ListView.separated(
    padding: const EdgeInsets.only(
      top: 6,
      bottom: 32,
    ),
    itemCount: _selectedLanguages.length,
    separatorBuilder: (context, index) {
      return Divider(
        height: 1,
        thickness: 1,
        indent: 64,
        color: colors.outlineVariant.withOpacity(0.55),
      );
    },
    itemBuilder: (context, index) {
      final languageData = _selectedLanguages[index];

      final languageCode = (languageData['name'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      final languageConfig =
          _languageByCode[languageCode];

      final isExpanded =
          _expandedLanguageCode == languageCode;

      return _buildSelectedLanguageItem(
        context: context,
        languageData: languageData,
        languageConfig: languageConfig,
        isExpanded: isExpanded,
        onToggleExpanded: () {
          setState(() {
            _expandedLanguageCode =
                isExpanded ? null : languageCode;
          });
        },
        onLevelChanged: (value) {
          _updateLanguageLevel(
            index,
            value.round(),
          );
        },
        onSetNative: () {
          _updateLanguageLevel(
            index,
            'native',
          );
        },
        onUsePercentage: () {
          _updateLanguageLevel(
            index,
            70,
          );
        },
        onRemove: () {
          _removeLanguageAt(index);
        },
      );
    },
  );
}

  Widget _buildLanguageLibraryTab(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            14,
            14,
            8,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '搜索语言名称或代码',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon:
                  _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清除',
                          onPressed: () {
                            _searchController.clear();

                            setState(() {
                              _visibleLanguages =
                                  List<LanguageConfig>.from(
                                _allLanguages,
                              );
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                        ),
              filled: true,
              fillColor: colors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colors.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            18,
            4,
            18,
            8,
          ),
          child: Row(
            children: [
              Text(
                _searchController.text.trim().isEmpty
                    ? '全部语言'
                    : '搜索结果',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${_visibleLanguages.length} 门',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _visibleLanguages.isEmpty
              ? _buildNoSearchResult(context)
              : ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .onDrag,
                  padding: const EdgeInsets.only(
                    bottom: 30,
                  ),

                  // ListView.builder 只创建当前屏幕附近的项目。
                  // 即使有几千种语言也不会一次全部创建。
                  itemCount: _visibleLanguages.length,

                  itemBuilder: (context, index) {
                    final language =
                        _visibleLanguages[index];

                    final isSelected =
                        _selectedLanguageCodes.contains(
                      language.code.toLowerCase(),
                    );

                    return _buildLanguageLibraryItem(
                      context: context,
                      language: language,
                      isSelected: isSelected,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLanguageLibraryItem({
    required BuildContext context,
    required LanguageConfig language,
    required bool isSelected,
  }) {
    final colors = Theme.of(context).colorScheme;

    final displayName =
        language.nameOf(_uiLanguageCode);

    final englishName =
        language.names['en'] ?? language.code;

    final showEnglishSubtitle =
        _uiLanguageCode != 'en' &&
        englishName.toLowerCase() !=
            displayName.toLowerCase();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 3,
      ),
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Text(
          language.flag,
          style: const TextStyle(
            fontSize: 22,
          ),
        ),
      ),
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      subtitle: showEnglishSubtitle
          ? Text(
              englishName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            )
          : null,
      trailing: isSelected
          ? IconButton(
              tooltip: '移除',
              onPressed: () {
                _removeLanguageByCode(
                  language.code,
                );
              },
              icon: Icon(
                Icons.check_circle_rounded,
                color: colors.primary,
              ),
            )
          : IconButton(
              tooltip: '添加',
              onPressed: () {
                _addLanguage(language);
              },
              icon: const Icon(
                Icons.add_circle_outline_rounded,
              ),
            ),
      onTap: () {
        if (isSelected) {
          _removeLanguageByCode(language.code);
        } else {
          _addLanguage(language);
        }
      },
    );
  }

  Widget _buildSelectedLanguageItem({
  required BuildContext context,
  required Map<String, dynamic> languageData,
  required LanguageConfig? languageConfig,
  required bool isExpanded,
  required VoidCallback onToggleExpanded,
  required ValueChanged<double> onLevelChanged,
  required VoidCallback onSetNative,
  required VoidCallback onUsePercentage,
  required VoidCallback onRemove,
}) {
  final colors = Theme.of(context).colorScheme;

  final languageCode =
      (languageData['name'] ?? '').toString();

  final displayName =
      languageConfig?.nameOf(_uiLanguageCode) ??
      languageCode;

  final flag = languageConfig?.flag ?? '🌐';

  final level = languageData['level'];
  final isNative = level == 'native';

  final levelValue = level is num
      ? level
          .toDouble()
          .clamp(10.0, 100.0)
          .toDouble()
      : 70.0;

  return Material(
    color: colors.surface,
    child: Column(
      children: [
        // ==========================================================
        // 默认显示的紧凑行
        // ==========================================================

        InkWell(
          onTap: onToggleExpanded,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              8,
              10,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer
                        .withOpacity(0.65),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    flag,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // 当前状态
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isNative
                        ? Colors.orange.withOpacity(0.12)
                        : colors.primary.withOpacity(0.09),
                    borderRadius:
                        BorderRadius.circular(100),
                  ),
                  child: Text(
                    isNative
                        ? '母语'
                        : '${levelValue.round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isNative
                          ? Colors.orange.shade700
                          : colors.primary,
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: colors.onSurfaceVariant,
                ),

                IconButton(
                  tooltip: '删除',
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ==========================================================
        // 点击后才展开的编辑区域
        // ==========================================================

        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    68,
                    0,
                    16,
                    12,
                  ),
                  child: isNative
                      ? Row(
                          children: [
                            Text(
                              '当前设置为母语',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    colors.onSurfaceVariant,
                              ),
                            ),

                            const Spacer(),

                            OutlinedButton.icon(
                              onPressed: onUsePercentage,
                              icon: const Icon(
                                Icons.tune_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                '改为熟练度',
                              ),
                              style: OutlinedButton.styleFrom(
                                visualDensity:
                                    VisualDensity.compact,
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  '熟练度',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors
                                        .onSurfaceVariant,
                                  ),
                                ),

                                const Spacer(),

                                Text(
                                  '${levelValue.round()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),

                            SliderTheme(
                              data: SliderTheme.of(context)
                                  .copyWith(
                                trackHeight: 3,
                                thumbShape:
                                    const RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
                                overlayShape:
                                    const RoundSliderOverlayShape(
                                  overlayRadius: 15,
                                ),
                              ),
                              child: Slider(
                                value: levelValue,
                                min: 10,
                                max: 100,
                                divisions: 9,
                                label:
                                    '${levelValue.round()}%',
                                onChanged: onLevelChanged,
                              ),
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: onSetNative,
                                icon: Icon(
                                  Icons.home_rounded,
                                  size: 16,
                                  color:
                                      Colors.orange.shade700,
                                ),
                                label: Text(
                                  '设为母语',
                                  style: TextStyle(
                                    color:
                                        Colors.orange.shade700,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  visualDensity:
                                      VisualDensity.compact,
                                ),
                              ),
                            ),
                          ],
                        ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

  Widget _buildEmptySelectedState(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 48,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text(
              '还没有选择语言',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '前往“添加语言”搜索并选择',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResult(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            const Text(
              '没有找到相关语言',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '尝试搜索其他名称或语言代码',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}