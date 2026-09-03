// lib/screens/language_select_screen.dart

import 'package:flutter/material.dart';

import '../../data/forum_languages.dart';

class LanguageSelectScreen extends StatefulWidget {
  final ForumLanguageChannel currentChannel;
  final String currentUiLanguageCode;

  const LanguageSelectScreen({
    super.key,
    required this.currentChannel,
    this.currentUiLanguageCode = 'zh',
  });

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  final Map<String, int> _alphaIndex = {};
  final ScrollController _scrollController = ScrollController();

  late List<ForumLanguageGroup> _sortedGroups;
  late List<_GroupedSection> _sections;

  String _currentLetter = '';

  @override
  void initState() {
    super.initState();
    _buildSections();
  }

  void _buildSections() {
    _alphaIndex.clear();

    final uiCode = widget.currentUiLanguageCode;

    _sortedGroups = List<ForumLanguageGroup>.from(ForumLanguages.channelGroups);
    _sortedGroups.sort(
      (a, b) => a.nameOf(uiCode).compareTo(b.nameOf(uiCode)),
    );

    final Map<String, List<ForumLanguageGroup>> grouped = {};

    for (final group in _sortedGroups) {
      final firstLetter = group.language.firstLetterOf(uiCode);
      grouped.putIfAbsent(firstLetter, () => []);
      grouped[firstLetter]!.add(group);
    }

    final keys = grouped.keys.toList()..sort();
    _sections = [];

    var itemIndex = 0;

    for (final key in keys) {
      _alphaIndex[key] = itemIndex;
      _sections.add(_GroupedSection(letter: key, isTitle: true));
      itemIndex++;

      for (final group in grouped[key]!) {
        _sections.add(_GroupedSection(group: group, isTitle: false));
        itemIndex++;
      }
    }
  }

  List<String> get _alphaKeys {
    final keys = _alphaIndex.keys.toList()..sort();
    return keys;
  }

  void _scrollToLetter(String letter) {
    if (_alphaIndex.containsKey(letter)) {
      final index = _alphaIndex[letter]!;
      _scrollController.jumpTo(index * 60.0);
    }
  }

  int _getTouchedIndex(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(globalPosition);
    final totalHeight = _alphaKeys.length * 20.0;
    final startY = (renderBox.size.height - totalHeight) / 2;
    final relativeY = localPosition.dy - startY;

    return (relativeY / 20).floor();
  }

  String _scriptMark(ForumLanguageChannel channel) {
    switch (channel.scriptCode) {
      case 'Hnom':
        return '𡨸';
      case 'Latn':
        return 'Aa';
      case 'Hans':
        return '简';
      case 'Hant':
        return '繁';
      default:
        final code = channel.scriptCode;
        if (code == null || code.isEmpty) {
          return 'Aa';
        }
        return code.length <= 3 ? code : code.substring(0, 3);
    }
  }

  Future<void> _openWritingSystemPicker(ForumLanguageGroup group) async {
    final uiCode = widget.currentUiLanguageCode;

    final selected = await showModalBottomSheet<ForumLanguageChannel>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.nameOf(uiCode),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ForumLanguages.scriptSelectTitleOf(uiCode),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 18),
                ...group.channels.map((channel) {
                  final isSelected = channel.key == widget.currentChannel.key;
                  final scriptName = channel.scriptNameOf(uiCode);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.withValues(alpha: 0.07)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.withValues(alpha: 0.35)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withValues(alpha: 0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _scriptMark(channel),
                          style: TextStyle(
                            fontSize: channel.scriptCode == 'Hnom' ? 22 : 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.blue.shade700
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      title: Text(
                        scriptName.isEmpty ? group.nameOf(uiCode) : scriptName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      subtitle: Text(
                        channel.displayNameOf(uiCode),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                              size: 22,
                            )
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                              color: Color(0xFF94A3B8),
                            ),
                      onTap: () {
                        Navigator.pop(sheetContext, channel);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    Navigator.pop(context, selected);
  }

  void _selectGroup(ForumLanguageGroup group) {
    if (group.hasScriptChoices) {
      _openWritingSystemPicker(group);
      return;
    }

    Navigator.pop(context, group.channels.first);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiCode = widget.currentUiLanguageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          ForumLanguages.languageSelectTitleOf(uiCode),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];

                if (section.isTitle) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    color: Colors.white,
                    child: Text(
                      section.letter!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                final group = section.group!;
                final language = group.language;
                final selectedChannel = group.selectedChannelForKey(
                  widget.currentChannel.key,
                );
                final isSelected = selectedChannel != null;
                final selectedScriptName = selectedChannel?.scriptNameOf(uiCode) ?? '';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 2,
                  ),
                  leading: Text(
                    language.flag,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    group.nameOf(uiCode),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? Colors.blue : const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: group.hasScriptChoices
                      ? Text(
                          selectedScriptName.isNotEmpty && isSelected
                              ? selectedScriptName
                              : ForumLanguages.scriptSelectTitleOf(uiCode),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isSelected
                                ? Colors.blue.shade600
                                : Colors.grey.shade500,
                          ),
                        )
                      : null,
                  trailing: group.hasScriptChoices
                      ? const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                        )
                      : isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                              size: 22,
                            )
                          : null,
                  onTap: () {
                    _selectGroup(group);
                  },
                );
              },
            ),
            if (_currentLetter.isNotEmpty)
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _currentLetter,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onVerticalDragDown: (details) {
                  final idx = _getTouchedIndex(details.globalPosition);

                  if (idx >= 0 && idx < _alphaKeys.length) {
                    setState(() {
                      _currentLetter = _alphaKeys[idx];
                    });
                    _scrollToLetter(_alphaKeys[idx]);
                  }
                },
                onVerticalDragUpdate: (details) {
                  final idx = _getTouchedIndex(details.globalPosition);

                  if (idx >= 0 && idx < _alphaKeys.length) {
                    setState(() {
                      _currentLetter = _alphaKeys[idx];
                    });
                    _scrollToLetter(_alphaKeys[idx]);
                  }
                },
                onVerticalDragEnd: (_) {
                  setState(() {
                    _currentLetter = '';
                  });
                },
                child: Container(
                  width: 30,
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _alphaKeys.map((char) {
                      return SizedBox(
                        height: 20,
                        child: Center(
                          child: Text(
                            char,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _currentLetter == char
                                  ? Colors.blue
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedSection {
  final String? letter;
  final ForumLanguageGroup? group;
  final bool isTitle;

  _GroupedSection({this.letter, this.group, required this.isTitle});
}
