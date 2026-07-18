import 'package:flutter/material.dart';

import '../../../config/l10n/app_localizations.dart';
import '../../../config/languages.dart';
import '../../feed/screens/feed_screen.dart';
import '../../profile/screens/language_select_screen.dart';
import 'recommended_posts_view.dart';

enum _HomeSection {
  recommended,
  categories,
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  _HomeSection _currentSection = _HomeSection.recommended;

  String _selectedChannelCode = 'zh';

  static const List<CategoryConfig> _categories = [
    CategoryConfig(
      id: 'language_learning',
      icon: Icons.language,
    ),
    CategoryConfig(
      id: 'programming',
      icon: Icons.code,
    ),
    CategoryConfig(
      id: 'ai',
      icon: Icons.smart_toy,
    ),
    CategoryConfig(
      id: 'technology',
      icon: Icons.computer,
    ),
    CategoryConfig(
      id: 'gaming',
      icon: Icons.sports_esports,
    ),
    CategoryConfig(
      id: 'music',
      icon: Icons.music_note,
    ),
    CategoryConfig(
      id: 'movies',
      icon: Icons.movie,
    ),
    CategoryConfig(
      id: 'campus',
      icon: Icons.school,
    ),
    CategoryConfig(
      id: 'startup',
      icon: Icons.business,
    ),
    CategoryConfig(
      id: 'friends',
      icon: Icons.people,
    ),
    CategoryConfig(
      id: 'travel',
      icon: Icons.flight,
    ),
    CategoryConfig(
      id: 'chat',
      icon: Icons.chat,
    ),
    CategoryConfig(
      id: 'love',
      icon: Icons.favorite_border,
    ),
    CategoryConfig(
      id: 'food',
      icon: Icons.restaurant,
    ),
  ];

  LanguageConfig get _currentChannelLanguage {
    return LanguageConfig.supportedLanguages.firstWhere(
      (language) => language.code == _selectedChannelCode,
      orElse: LanguageConfig.getDefaultLanguage,
    );
  }

  void _selectSection(_HomeSection section) {
    if (_currentSection == section) {
      return;
    }

    setState(() {
      _currentSection = section;
    });
  }

  Future<void> _openLanguageSelect(
    String uiLanguageCode,
  ) async {
    final selectedLanguage =
        await Navigator.of(context).push<LanguageConfig>(
      MaterialPageRoute<LanguageConfig>(
        builder: (_) => LanguageSelectScreen(
          currentLanguage: _currentChannelLanguage,
          currentUiLanguageCode: uiLanguageCode,
        ),
      ),
    );

    if (!mounted || selectedLanguage == null) {
      return;
    }

    if (selectedLanguage.code == _selectedChannelCode) {
      return;
    }

    setState(() {
      _selectedChannelCode = selectedLanguage.code;
    });
  }

  void _openCategory({
    required CategoryConfig category,
    required String uiLanguageCode,
  }) {
    final channelLanguage = _currentChannelLanguage;
    final languageName =
        channelLanguage.nameOf(uiLanguageCode);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedScreen(
          category: category.id,
          languageCode: channelLanguage.code,
          languageName: languageName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final uiLanguageCode =
        Localizations.localeOf(context).languageCode;

    final currentLanguage = _currentChannelLanguage;
    final currentLanguageName =
        currentLanguage.nameOf(uiLanguageCode);

    final pageTitle = switch (_currentSection) {
      _HomeSection.recommended => '推荐',
      _HomeSection.categories => l10n.forumCategories,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: _currentSection == _HomeSection.categories
            ? [
                Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: _ChannelSelectorButton(
                    flag: currentLanguage.flag,
                    languageName: currentLanguageName,
                    currentChannelLabel:
                        l10n.currentChannel,
                    onPressed: () {
                      _openLanguageSelect(
                        uiLanguageCode,
                      );
                    },
                  ),
                ),
              ]
            : null,
      ),
      drawer: _HomeDrawer(
        currentSection: _currentSection,
        onSectionSelected: _selectSection,
      ),
      body: IndexedStack(
        index: _currentSection.index,
        children: [
          const RecommendedPostsView(),
          _CategoryGrid(
            categories: _categories,
            categoryNames: l10n.categoryNames,
            onCategorySelected: (category) {
              _openCategory(
                category: category,
                uiLanguageCode: uiLanguageCode,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  final _HomeSection currentSection;
  final ValueChanged<_HomeSection> onSectionSelected;

  const _HomeDrawer({
    required this.currentSection,
    required this.onSectionSelected,
  });

  void _select(
    BuildContext context,
    _HomeSection section,
  ) {
    onSectionSelected(section);
    Navigator.of(context).pop();
  }

  @override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  final isRecommendedSelected =
      currentSection == _HomeSection.recommended;

  final isCategoriesSelected =
      currentSection == _HomeSection.categories;

  return Drawer(
    child: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.forum,
                  size: 42,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  '语言社区',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            selected: isRecommendedSelected,
            leading: Icon(
              isRecommendedSelected
                  ? Icons.home
                  : Icons.home_outlined,
            ),
            title: const Text('推荐主页'),
            subtitle: const Text('根据关注和兴趣推荐'),
            onTap: () {
              _select(
                context,
                _HomeSection.recommended,
              );
            },
          ),

          ListTile(
            selected: isCategoriesSelected,
            leading: Icon(
              isCategoriesSelected
                  ? Icons.grid_view
                  : Icons.grid_view_outlined,
            ),
            title: const Text('分类频道'),
            subtitle: const Text('按语言和主题浏览'),
            onTap: () {
              _select(
                context,
                _HomeSection.categories,
              );
            },
          ),
        ],
      ),
    ),
  );
}
}

class _CategoryGrid extends StatelessWidget {
  final List<CategoryConfig> categories;
  final List<String> categoryNames;
  final ValueChanged<CategoryConfig>
      onCategorySelected;

  const _CategoryGrid({
    required this.categories,
    required this.categoryNames,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: categories.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];

        final categoryName =
            index < categoryNames.length
            ? categoryNames[index]
            : category.id;

        return _CategoryCard(
          icon: category.icon,
          name: categoryName,
          onTap: () {
            onCategorySelected(category);
          },
        );
      },
    );
  }
}

class CategoryConfig {
  final String id;
  final IconData icon;

  const CategoryConfig({
    required this.id,
    required this.icon,
  });
}

class _ChannelSelectorButton
    extends StatelessWidget {
  final String flag;
  final String languageName;
  final String currentChannelLabel;
  final VoidCallback onPressed;

  const _ChannelSelectorButton({
    required this.flag,
    required this.languageName,
    required this.currentChannelLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Text(
        flag,
        style: const TextStyle(
          fontSize: 18,
        ),
      ),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            languageName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            currentChannelLabel,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 42,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
              ),
              child: Text(
                name,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      colorScheme.onPrimaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}