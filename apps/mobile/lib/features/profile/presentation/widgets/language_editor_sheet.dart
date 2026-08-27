import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';

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
      return _LanguageEditorSheet(selectedLanguages: selectedLanguages);
    },
  );
}

class _LanguageEditorSheet extends StatefulWidget {
  final List<Map<String, dynamic>> selectedLanguages;

  const _LanguageEditorSheet({required this.selectedLanguages});

  @override
  State<_LanguageEditorSheet> createState() {
    return _LanguageEditorSheetState();
  }
}

class _LanguageEditorSheetState extends State<_LanguageEditorSheet> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  late final List<LanguageConfig> _allLanguages;

  late final Map<String, LanguageConfig> _languageByCode;

  late final List<Map<String, dynamic>> _selectedLanguages;

  late final Set<String> _selectedLanguageKeys;

  List<LanguageConfig> _visibleLanguages = [];

  String _uiLanguageCode = 'zh';

  String? _expandedLanguageKey;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // 完整语言库
    // ============================================================

    _allLanguages = List<LanguageConfig>.from(LanguageConfig.allLanguages);

    _languageByCode = {
      for (final language in _allLanguages)
        language.code.trim().toLowerCase(): language,
    };

    // ============================================================
    // 兼容旧语言能力数据
    //
    // 旧：
    // {
    //   'name': 'chunom',
    //   'level': 70,
    // }
    //
    // 新：
    // {
    //   'name': 'vi',
    //   'scriptCode': 'Hnom',
    //   'level': 70,
    // }
    // ============================================================

    _selectedLanguages = _normalizeSelectedLanguages(widget.selectedLanguages);

    _selectedLanguageKeys = _selectedLanguages.map(_languageKeyOf).toSet();

    _visibleLanguages = List<LanguageConfig>.from(_allLanguages);
  }

  String _languageKey(String languageCode, String? scriptCode) {
    final language = languageCode.trim().toLowerCase();

    final script = scriptCode?.trim().toLowerCase();

    if (script == null || script.isEmpty) {
      return language;
    }

    return '$language:$script';
  }

  String _languageKeyOf(Map<String, dynamic> data) {
    return _languageKey(
      (data['name'] ?? '').toString(),
      data['scriptCode']?.toString(),
    );
  }

  // ============================================================
  // 读取保存的语言代码
  // ============================================================

  String _languageCodeOf(Map<String, dynamic> data) {
    return (data['code'] ?? data['name'] ?? '').toString().trim().toLowerCase();
  }

  // ============================================================
  // 读取文字系统代码
  // ============================================================

  String? _scriptCodeOf(Map<String, dynamic> data) {
    final value = data['scriptCode']?.toString().trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  // ============================================================
  // 兼容一整组旧数据
  //
  // 同一个语言最终只保留一条。
  // 如果旧数据里同时存在：
  //
  // vi
  // chunom
  //
  // 优先保留带 scriptCode 的版本。
  // ============================================================

  List<Map<String, dynamic>> _normalizeSelectedLanguages(
    List<Map<String, dynamic>> source,
  ) {
    final result = <Map<String, dynamic>>[];

    final seenKeys = <String>{};

    for (final sourceItem in source) {
      final normalized = _normalizeSelectedLanguage(sourceItem);

      if (normalized == null) {
        continue;
      }

      final key = _languageKeyOf(normalized);

      if (key.isEmpty) {
        continue;
      }

      if (!seenKeys.add(key)) {
        continue;
      }

      result.add(normalized);
    }

    return result;
  }

  // ============================================================
  // 单条旧数据转换
  // ============================================================

  Map<String, dynamic>? _normalizeSelectedLanguage(
    Map<String, dynamic> source,
  ) {
    final result = Map<String, dynamic>.from(source);

    final savedCode = (result['code'] ?? result['name'] ?? '')
        .toString()
        .trim();

    if (savedCode.isEmpty) {
      return null;
    }

    // ==========================================================
    // 正常语言代码
    //
    // vi / en / zh ...
    // ==========================================================

    final language = LanguageConfig.findByCode(savedCode);

    if (language != null) {
      result['name'] = language.code;

      result.remove('code');

      final savedScriptCode = _scriptCodeOf(result);

      if (savedScriptCode == null && language.scriptCodes.isNotEmpty) {
        result['scriptCode'] = language.scriptCodes.first;
      } else if (savedScriptCode != null) {
        final script = ScriptConfig.findByCode(savedScriptCode);

        final belongsToLanguage =
            script != null &&
            language.scriptCodes.any((code) {
              return code.toLowerCase() == script.code.toLowerCase();
            });

        if (!belongsToLanguage) {
          result.remove('scriptCode');
        } else {
          result['scriptCode'] = script.code;
        }
      }

      return result;
    }

    // ==========================================================
    // 旧文字系统代码
    //
    // 例如：
    // chunom
    //
    // ScriptConfig.findByCode('chunom')
    // 通过 alias 找到 Hnom。
    // ==========================================================

    final script = ScriptConfig.findByCode(savedCode);

    if (script == null) {
      return null;
    }

    LanguageConfig? ownerLanguage;

    for (final languageCode in script.languageCodes) {
      final candidate = LanguageConfig.findByCode(languageCode);

      if (candidate != null) {
        ownerLanguage = candidate;
        break;
      }
    }

    if (ownerLanguage == null) {
      return null;
    }

    result['name'] = ownerLanguage.code;

    result['scriptCode'] = script.code;

    result.remove('code');

    return result;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newUiLanguageCode = Localizations.localeOf(context).languageCode;

    _uiLanguageCode = newUiLanguageCode;

    _sortLanguages();

    _visibleLanguages = _filterLanguages(_searchController.text);
  }

  // ============================================================
  // 排序
  // ============================================================

  void _sortLanguages() {
    _allLanguages.sort((first, second) {
      return first
          .sortKeyOf(_uiLanguageCode)
          .compareTo(second.sortKeyOf(_uiLanguageCode));
    });
  }

  // ============================================================
  // 搜索
  // ============================================================

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _visibleLanguages = _filterLanguages(value);
      });
    });
  }

  List<LanguageConfig> _filterLanguages(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return List<LanguageConfig>.from(_allLanguages);
    }

    return _allLanguages.where((language) {
      // ========================================================
      // 搜索语言代码
      // ========================================================

      if (language.code.toLowerCase().contains(normalizedQuery)) {
        return true;
      }

      // ========================================================
      // 搜索语言名称
      // ========================================================

      final matchesName = language.names.values.any((name) {
        return name.toLowerCase().contains(normalizedQuery);
      });

      if (matchesName) {
        return true;
      }

      // ========================================================
      // 搜索语言排序关键词
      // ========================================================

      final matchesSortKey = language.sortKeys.values.any((sortKey) {
        return sortKey.toLowerCase().contains(normalizedQuery);
      });

      if (matchesSortKey) {
        return true;
      }

      // ========================================================
      // 搜索文字系统
      //
      // 搜索：
      // 喃字
      // Chữ Nôm
      // Hnom
      //
      // 都会找到“越南语”这一条。
      // ========================================================

      for (final scriptCode in language.scriptCodes) {
        final script = ScriptConfig.findByCode(scriptCode);

        if (script == null) {
          continue;
        }

        if (script.code.toLowerCase().contains(normalizedQuery)) {
          return true;
        }

        final matchesScriptName = script.names.values.any((name) {
          return name.toLowerCase().contains(normalizedQuery);
        });

        if (matchesScriptName) {
          return true;
        }
      }

      // ========================================================
      // 搜索旧 alias
      //
      // 例如输入 chunom
      // ScriptConfig 会找到 Hnom，
      // 再判断这个 script 是否属于当前语言。
      // ========================================================

      final matchedScript = ScriptConfig.findByCode(normalizedQuery);

      if (matchedScript != null) {
        final belongs = language.scriptCodes.any((scriptCode) {
          return scriptCode.toLowerCase() == matchedScript.code.toLowerCase();
        });

        if (belongs) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  // ============================================================
  // 添加语言
  // ============================================================

  void _addLanguage(LanguageConfig language, {String? scriptCode}) {
    final key = _languageKey(language.code, scriptCode);

    if (!_selectedLanguageKeys.add(key)) {
      return;
    }

    setState(() {
      final data = <String, dynamic>{'name': language.code, 'level': 70};

      if (scriptCode != null && scriptCode.isNotEmpty) {
        data['scriptCode'] = scriptCode;
      }

      _selectedLanguages.add(data);
    });
  }

  // ============================================================
  // 点击添加语言
  //
  // 普通语言：
  // 直接添加
  //
  // 多文字系统语言：
  // 先选择文字系统
  // ============================================================

  Future<void> _handleAddLanguage(LanguageConfig language) async {
    final scripts = language.scriptCodes
        .map(ScriptConfig.findByCode)
        .whereType<ScriptConfig>()
        .toList(growable: false);

    if (scripts.isEmpty) {
      final key = _languageKey(language.code, null);

      if (_selectedLanguageKeys.contains(key)) {
        _removeLanguageByKey(key);
      } else {
        _addLanguage(language);
      }

      return;
    }

    if (scripts.length == 1) {
      final script = scripts.first;

      final key = _languageKey(language.code, script.code);

      if (_selectedLanguageKeys.contains(key)) {
        _removeLanguageByKey(key);
      } else {
        _addLanguage(language, scriptCode: script.code);
      }

      return;
    }

    final selectedScripts = await _selectLanguageScripts(language, scripts);

    if (!mounted || selectedScripts == null) {
      return;
    }

    _syncLanguageScripts(language, selectedScripts);
  }

  Future<Set<String>?> _selectLanguageScripts(
    LanguageConfig language,
    List<ScriptConfig> scripts,
  ) async {
    final selectedCodes = <String>{};

    for (final script in scripts) {
      final key = _languageKey(language.code, script.code);

      if (_selectedLanguageKeys.contains(key)) {
        selectedCodes.add(script.code);
      }
    }

    return showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colors = Theme.of(context).colorScheme;

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '选择文字系统',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                              Set<String>.from(selectedCodes),
                            );
                          },
                          child: const Text('完成'),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: colors.outlineVariant),

                  ...scripts.map((script) {
                    final selected = selectedCodes.any(
                      (code) => code.toLowerCase() == script.code.toLowerCase(),
                    );

                    return CheckboxListTile(
                      value: selected,
                      controlAffinity: ListTileControlAffinity.trailing,
                      title: Text(_scriptOptionName(language, script)),
                      subtitle: Text(
                        '${script.nameOf(_uiLanguageCode)} · ${script.code}',
                      ),
                      onChanged: (_) {
                        setSheetState(() {
                          if (selected) {
                            selectedCodes.removeWhere(
                              (code) =>
                                  code.toLowerCase() ==
                                  script.code.toLowerCase(),
                            );
                          } else {
                            selectedCodes.add(script.code);
                          }
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _syncLanguageScripts(
    LanguageConfig language,
    Set<String> selectedScriptCodes,
  ) {
    final languageCode = language.code.toLowerCase();

    final oldLevels = <String, dynamic>{};

    for (final item in _selectedLanguages) {
      if (_languageCodeOf(item) != languageCode) {
        continue;
      }

      final scriptCode = _scriptCodeOf(item);

      if (scriptCode != null) {
        oldLevels[scriptCode.toLowerCase()] = item['level'];
      }
    }

    setState(() {
      _selectedLanguages.removeWhere(
        (item) => _languageCodeOf(item) == languageCode,
      );

      _selectedLanguageKeys.removeWhere(
        (key) => key == languageCode || key.startsWith('$languageCode:'),
      );

      for (final scriptCode in selectedScriptCodes) {
        final key = _languageKey(language.code, scriptCode);

        _selectedLanguageKeys.add(key);

        _selectedLanguages.add({
          'name': language.code,
          'scriptCode': scriptCode,
          'level': oldLevels[scriptCode.toLowerCase()] ?? 70,
        });
      }
    });
  }

  // ============================================================
  // 文字系统在选择窗口中的显示名
  //
  // 第一文字系统视为语言默认文字系统。
  //
  // vi:
  // Latn -> 越南语-国语字
  // Hnom -> 喃字
  //
  // 不需要在 UI 写死 vi / Hnom。
  // ============================================================

  String _scriptOptionName(LanguageConfig language, ScriptConfig script) {
    return language.scriptNameOf(script.code, _uiLanguageCode);
  }

  // ============================================================
  // 删除
  // ============================================================

  void _removeLanguageAt(int index) {
    final language = _selectedLanguages[index];

    final key = _languageKeyOf(language);

    setState(() {
      _selectedLanguages.removeAt(index);

      _selectedLanguageKeys.remove(key);

      if (_expandedLanguageKey == key) {
        _expandedLanguageKey = null;
      }
    });
  }

  void _removeLanguageByCode(String code) {
    final normalizedCode = code.trim().toLowerCase();

    final index = _selectedLanguages.indexWhere((language) {
      return _languageCodeOf(language) == normalizedCode;
    });

    if (index == -1) {
      return;
    }

    _removeLanguageAt(index);
  }

  void _removeLanguageByKey(String key) {
    final index = _selectedLanguages.indexWhere(
      (language) => _languageKeyOf(language) == key,
    );

    if (index == -1) {
      return;
    }

    _removeLanguageAt(index);
  }

  // ============================================================
  // 熟练度
  // ============================================================

  void _updateLanguageLevel(int index, dynamic level) {
    setState(() {
      _selectedLanguages[index]['level'] = level;
    });
  }

  // ============================================================
  // 保存
  // ============================================================

  void _save() {
    final result = _selectedLanguages
        .map((language) => Map<String, dynamic>.from(language))
        .toList();

    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // 页面
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final screenHeight = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: screenHeight * 0.94,
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
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

              Divider(height: 1, color: colors.outlineVariant),

              TabBar(
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurfaceVariant,
                indicatorColor: colors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: colors.outlineVariant,
                tabs: [
                  Tab(text: '已选择 (${_selectedLanguages.length})'),
                  const Tab(text: '添加语言'),
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

  // ============================================================
  // 顶部
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              '完成',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 已选择
  // ============================================================

  Widget _buildSelectedLanguagesTab(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_selectedLanguages.isEmpty) {
      return _buildEmptySelectedState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 6, bottom: 32),
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

        final languageCode = _languageCodeOf(languageData);

        final languageConfig = _languageByCode[languageCode];

        final languageKey = _languageKeyOf(languageData);

        final isExpanded = _expandedLanguageKey == languageKey;

        return _buildSelectedLanguageItem(
          context: context,
          languageData: languageData,
          languageConfig: languageConfig,
          isExpanded: isExpanded,
          onToggleExpanded: () {
            setState(() {
              _expandedLanguageKey = isExpanded ? null : languageKey;
            });
          },
          onLevelChanged: (value) {
            _updateLanguageLevel(index, value.round());
          },
          onSetNative: () {
            _updateLanguageLevel(index, 'native');
          },
          onUsePercentage: () {
            _updateLanguageLevel(index, 70);
          },
          onRemove: () {
            _removeLanguageAt(index);
          },
        );
      },
    );
  }

  // ============================================================
  // 添加语言页面
  //
  // 这里只有语言。
  //
  // 不会出现：
  // 喃字
  // 拉丁字母
  //
  // 只会出现：
  // 越南语
  // ============================================================

  Widget _buildLanguageLibraryTab(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '搜索语言名称或代码',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清除',
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _visibleLanguages = List<LanguageConfig>.from(
                            _allLanguages,
                          );
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: colors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          child: Row(
            children: [
              Text(
                _searchController.text.trim().isEmpty ? '全部语言' : '搜索结果',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                '${_visibleLanguages.length} 门',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),

        Expanded(
          child: _visibleLanguages.isEmpty
              ? _buildNoSearchResult(context)
              : ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 30),
                  itemCount: _visibleLanguages.length,
                  itemBuilder: (context, index) {
                    final language = _visibleLanguages[index];

                    final isSelected = _selectedLanguages.any(
                      (item) =>
                          _languageCodeOf(item) == language.code.toLowerCase(),
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

  // ============================================================
  // 添加语言列表中的一项
  // ============================================================

  Widget _buildLanguageLibraryItem({
    required BuildContext context,
    required LanguageConfig language,
    required bool isSelected,
  }) {
    final hasMultipleScripts = language.scriptCodes.length > 1;
    final colors = Theme.of(context).colorScheme;

    final displayName = language.nameOf(_uiLanguageCode);

    final englishName = language.names['en'] ?? language.code;

    final showEnglishSubtitle =
        _uiLanguageCode != 'en' &&
        englishName.toLowerCase() != displayName.toLowerCase();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Text(language.flag, style: const TextStyle(fontSize: 22)),
      ),
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: showEnglishSubtitle
          ? Text(
              englishName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            )
          : null,
      trailing: hasMultipleScripts
          ? IconButton(
              tooltip: '选择文字系统',
              onPressed: () {
                _handleAddLanguage(language);
              },
              icon: Icon(
                isSelected
                    ? Icons.tune_rounded
                    : Icons.add_circle_outline_rounded,
                color: isSelected ? colors.primary : null,
              ),
            )
          : isSelected
          ? IconButton(
              tooltip: '移除',
              onPressed: () {
                _removeLanguageByCode(language.code);
              },
              icon: Icon(Icons.check_circle_rounded, color: colors.primary),
            )
          : IconButton(
              tooltip: '添加',
              onPressed: () {
                _handleAddLanguage(language);
              },
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
      onTap: () {
        if (hasMultipleScripts) {
          _handleAddLanguage(language);

          return;
        }

        if (isSelected) {
          _removeLanguageByCode(language.code);
        } else {
          _handleAddLanguage(language);
        }
      },
    );
  }

  // ============================================================
  // 已选择语言显示名
  //
  // vi + Latn
  // -> 越南语-国语字
  //
  // vi + Hnom
  // -> 喃字
  // ============================================================

  String _selectedDisplayName(
    Map<String, dynamic> languageData,
    LanguageConfig? languageConfig,
  ) {
    final languageCode = _languageCodeOf(languageData);

    if (languageConfig == null) {
      return languageCode;
    }

    final scriptCode = _scriptCodeOf(languageData);

    if (scriptCode == null) {
      return languageConfig.nameOf(_uiLanguageCode);
    }

    final scriptName = languageConfig.scriptNameOf(scriptCode, _uiLanguageCode);

    return '${languageConfig.nameOf(_uiLanguageCode)}-$scriptName';
  }

  // ============================================================
  // 已选择语言
  // ============================================================

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

    final displayName = _selectedDisplayName(languageData, languageConfig);

    final flag = languageConfig?.flag ?? '🌐';

    final level = languageData['level'];

    final isNative = level == 'native';

    final levelValue = level is num
        ? level.toDouble().clamp(10.0, 100.0).toDouble()
        : 70.0;

    return Material(
      color: colors.surface,
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withOpacity(0.65),
                      shape: BoxShape.circle,
                    ),
                    child: Text(flag, style: const TextStyle(fontSize: 20)),
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

                  Container(
                    constraints: const BoxConstraints(minWidth: 48),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isNative
                          ? Colors.orange.withOpacity(0.12)
                          : colors.primary.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isNative ? '母语' : '${levelValue.round()}%',
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

          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
                    child: isNative
                        ? Row(
                            children: [
                              Text(
                                '当前设置为母语',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),

                              const Spacer(),

                              OutlinedButton.icon(
                                onPressed: onUsePercentage,
                                icon: const Icon(Icons.tune_rounded, size: 16),
                                label: const Text('改为熟练度'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
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
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),

                                  const Spacer(),

                                  Text(
                                    '${levelValue.round()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),

                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 15,
                                  ),
                                ),
                                child: Slider(
                                  value: levelValue,
                                  min: 10,
                                  max: 100,
                                  divisions: 9,
                                  label: '${levelValue.round()}%',
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
                                    color: Colors.orange.shade700,
                                  ),
                                  label: Text(
                                    '设为母语',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
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

  // ============================================================
  // 空状态
  // ============================================================

  Widget _buildEmptySelectedState(BuildContext context) {
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '前往“添加语言”搜索并选择',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResult(BuildContext context) {
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
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              '尝试搜索其他名称、语言代码或文字系统',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
