// lib/screens/language_select_screen.dart
import 'package:flutter/material.dart';
import '../../../config/languages.dart';

class LanguageSelectScreen extends StatefulWidget {
  final LanguageConfig currentLanguage;
  final String currentUiLanguageCode;

  const LanguageSelectScreen({
    super.key,
    required this.currentLanguage,
    this.currentUiLanguageCode = 'zh',
  });

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  final Map<String, int> _alphaIndex = {};
  final ScrollController _scrollController = ScrollController();
  late List<LanguageConfig> _sortedLanguages;
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

  _sortedLanguages = List<LanguageConfig>.from(
    LanguageConfig.channelLanguages,
  );

  _sortedLanguages.sort(
    (a, b) => a.sortKeyOf(uiCode).compareTo(b.sortKeyOf(uiCode)),
  );

  final Map<String, List<LanguageConfig>> grouped = {};

  for (final lang in _sortedLanguages) {
    final firstLetter = lang.firstLetterOf(uiCode);
    grouped.putIfAbsent(firstLetter, () => []);
    grouped[firstLetter]!.add(lang);
  }

  final keys = grouped.keys.toList()..sort();

  _sections = [];
  int itemIndex = 0;

  for (final key in keys) {
    _alphaIndex[key] = itemIndex;
    _sections.add(_GroupedSection(letter: key, isTitle: true));
    itemIndex++;

    for (final lang in grouped[key]!) {
      _sections.add(_GroupedSection(language: lang, isTitle: false));
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
    final index = (relativeY / 20).floor();
    return index;
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
          LanguageConfig.languageSelectTitleOf(uiCode),
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
      body: Stack(
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

              final language = section.language!;
              final isSelected = language.code == widget.currentLanguage.code;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 2,
                ),
                leading: Text(language.flag, style: const TextStyle(fontSize: 28)),
                title: Text(
                  language.nameOf(widget.currentUiLanguageCode),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.blue : const Color(0xFF1E293B),
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.blue, size: 22)
                    : null,
                onTap: () => Navigator.pop(context, language),
              );
            },
          ),
          if (_currentLetter.isNotEmpty)
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
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
                  setState(() => _currentLetter = _alphaKeys[idx]);
                  _scrollToLetter(_alphaKeys[idx]);
                }
              },
              onVerticalDragUpdate: (details) {
                final idx = _getTouchedIndex(details.globalPosition);
                if (idx >= 0 && idx < _alphaKeys.length) {
                  setState(() => _currentLetter = _alphaKeys[idx]);
                  _scrollToLetter(_alphaKeys[idx]);
                }
              },
              onVerticalDragEnd: (_) {
                setState(() => _currentLetter = '');
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
    );
  }
}

class _GroupedSection {
  final String? letter;
  final LanguageConfig? language;
  final bool isTitle;

  _GroupedSection({this.letter, this.language, required this.isTitle});
}
