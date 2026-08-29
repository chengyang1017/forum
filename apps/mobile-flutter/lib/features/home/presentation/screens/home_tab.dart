import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart' as auth_prov;

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/forum_categories.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';
import '../../../language/presentation/screens/language_select_screen.dart';
import '../widgets/recommended_posts_view.dart';

import '../../../language/data/forum_languages.dart';

enum _HomeSection { recommended, categories }

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  _HomeSection _currentSection = _HomeSection.recommended;
  String _selectedChannelKey = 'zh';
  static const List<CategoryConfig> _categories = [
    CategoryConfig(id: 'language_learning', icon: Icons.translate_rounded),
    CategoryConfig(id: 'programming', icon: Icons.code_rounded),
    CategoryConfig(id: 'ai', icon: Icons.smart_toy_rounded),
    CategoryConfig(id: 'technology', icon: Icons.devices_rounded),
    CategoryConfig(id: 'gaming', icon: Icons.sports_esports_rounded),
    CategoryConfig(id: 'music', icon: Icons.music_note_rounded),
    CategoryConfig(id: 'movies', icon: Icons.movie_rounded),
    CategoryConfig(id: 'campus', icon: Icons.school_rounded),
    CategoryConfig(id: 'startup', icon: Icons.rocket_launch_rounded),
    CategoryConfig(id: 'friends', icon: Icons.people_alt_rounded),
    CategoryConfig(id: 'travel', icon: Icons.flight_takeoff_rounded),
    CategoryConfig(id: 'chat', icon: Icons.forum_rounded),
    CategoryConfig(id: 'love', icon: Icons.favorite_rounded),
    CategoryConfig(id: 'food', icon: Icons.restaurant_rounded),
    CategoryConfig(id: 'medicine', icon: Icons.medical_services_rounded),
  ];

  ForumLanguageChannel get _currentChannel {
    return ForumLanguages.channels.firstWhere(
      (channel) => channel.key == _selectedChannelKey,
      orElse: () {
        return ForumLanguages.channels.firstWhere(
          (channel) => channel.language.code == 'zh',
        );
      },
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

  Future<void> _openLanguageSelect(String uiLanguageCode) async {
    final selectedChannel = await Navigator.of(context)
        .push<ForumLanguageChannel>(
          MaterialPageRoute<ForumLanguageChannel>(
            builder: (_) => LanguageSelectScreen(
              currentChannel: _currentChannel,
              currentUiLanguageCode: uiLanguageCode,
            ),
          ),
        );

    if (!mounted || selectedChannel == null) {
      return;
    }

    if (selectedChannel.key == _selectedChannelKey) {
      return;
    }

    setState(() {
      _selectedChannelKey = selectedChannel.key;
    });
  }

  void _openCategory({required CategoryConfig category}) {
    final channel = _currentChannel;

    context.push(
      AppRoutes.feedLocation(channelKey: channel.key, categoryId: category.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final uiLanguageCode = Localizations.localeOf(context).languageCode;

    final currentChannel = _currentChannel;

    final currentLanguage = currentChannel.language;

    final currentLanguageName = currentChannel.nameOf(uiLanguageCode);

    final isRecommended = _currentSection == _HomeSection.recommended;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRecommended ? '为你推荐' : l10n.forumCategories,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            Text(
              isRecommended
                  ? '仅显示你主动设为感兴趣的内容'
                  : '$currentLanguageName · ${l10n.currentChannel}',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.58),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (!isRecommended)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _ChannelSelectorButton(
                flag: currentLanguage.flag,
                languageName: currentLanguageName,
                onPressed: () {
                  _openLanguageSelect(uiLanguageCode);
                },
              ),
            ),
        ],
      ),
      drawer: _HomeDrawer(
        currentSection: _currentSection,
        onSectionSelected: _selectSection,
      ),
      body: IndexedStack(
        index: _currentSection.index,
        children: [
          const _RecommendedSection(),
          _CategorySection(
            language: currentLanguage,
            channelKey: currentChannel.key,
            languageName: currentLanguageName,
            categories: _categories,
            categoryNames: l10n.categoryNames,
            onChangeLanguage: () {
              _openLanguageSelect(uiLanguageCode);
            },
            onCategorySelected: (category) {
              _openCategory(category: category);
            },
          ),
        ],
      ),
    );
  }
}

class _RecommendedSection extends StatelessWidget {
  const _RecommendedSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.14),
                  colorScheme.secondary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '你的兴趣主页',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '先到分类频道，把语言频道中的分类设为感兴趣',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.62),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Expanded(child: RecommendedPostsView()),
      ],
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

  void _select(BuildContext context, _HomeSection section) {
    Navigator.of(context).pop();
    onSectionSelected(section);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.72),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '语言社区',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '连接语言、兴趣与世界',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _DrawerNavigationItem(
                    selected: currentSection == _HomeSection.recommended,
                    icon: Icons.home_rounded,
                    outlineIcon: Icons.home_outlined,
                    title: '推荐主页',
                    subtitle: '只显示已选择的兴趣',
                    onTap: () {
                      _select(context, _HomeSection.recommended);
                    },
                  ),
                  const SizedBox(height: 6),
                  _DrawerNavigationItem(
                    selected: currentSection == _HomeSection.categories,
                    icon: Icons.grid_view_rounded,
                    outlineIcon: Icons.grid_view_outlined,
                    title: '分类频道',
                    subtitle: '选择语言、浏览和设置兴趣',
                    onTap: () {
                      _select(context, _HomeSection.categories);
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '探索不同语言的内容',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavigationItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final IconData outlineIcon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerNavigationItem({
    required this.selected,
    required this.icon,
    required this.outlineIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withOpacity(0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  selected ? icon : outlineIcon,
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withOpacity(0.65),
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.48),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final LanguageConfig language;
  final String channelKey;
  final String languageName;
  final List<CategoryConfig> categories;
  final List<String> categoryNames;
  final VoidCallback onChangeLanguage;
  final ValueChanged<CategoryConfig> onCategorySelected;

  const _CategorySection({
    required this.language,
    required this.channelKey,
    required this.languageName,
    required this.categories,
    required this.categoryNames,
    required this.onChangeLanguage,
    required this.onCategorySelected,
  });

  String _interestKey(String categoryId) {
    return '$channelKey::$categoryId';
  }

  Future<void> _toggleInterest({
    required BuildContext context,
    required auth_prov.AuthProvider authProvider,
    required CategoryConfig category,
  }) async {
    if (authProvider.user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先登录后再设置兴趣')));

      return;
    }

    if (!authProvider.interestsLoaded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('兴趣设置正在加载，请稍后再试')));

      return;
    }

    final key = _interestKey(category.id);

    try {
      await authProvider.toggleInterest(key);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新兴趣失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final authProvider = context.watch<auth_prov.AuthProvider>();

    final interests = authProvider.interests;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Material(
            color: colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onChangeLanguage,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        language.flag,
                        style: const TextStyle(fontSize: 27),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '当前频道 · 点击切换语言',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.56),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              const Text(
                '选择主题',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                authProvider.interestsLoaded ? '点击心形设为感兴趣' : '正在加载兴趣设置…',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.48),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _CategoryGrid(
            language: language,
            channelKey: channelKey,
            categories: categories,
            categoryNames: categoryNames,
            interests: interests,
            onCategorySelected: onCategorySelected,
            onInterestPressed: (category, _) {
              _toggleInterest(
                context: context,
                authProvider: authProvider,
                category: category,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final LanguageConfig language;
  final String channelKey;
  final List<CategoryConfig> categories;
  final List<String> categoryNames;
  final Set<String> interests;
  final ValueChanged<CategoryConfig> onCategorySelected;
  final void Function(CategoryConfig category, bool isInterested)
  onInterestPressed;

  const _CategoryGrid({
    required this.language,
    required this.channelKey,
    required this.categories,
    required this.categoryNames,
    required this.interests,
    required this.onCategorySelected,
    required this.onInterestPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 4 : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            final categoryName = index < categoryNames.length
                ? categoryNames[index]
                : ForumCategories.nameOf(
                    category.id,
                    Localizations.localeOf(context).languageCode,
                  );

            final key = '$channelKey::${category.id}';

            final isInterested = interests.contains(key);

            return _CategoryCard(
              index: index,
              icon: category.icon,
              name: categoryName,
              isInterested: isInterested,
              onTap: () {
                onCategorySelected(category);
              },
              onInterestPressed: () {
                onInterestPressed(category, isInterested);
              },
            );
          },
        );
      },
    );
  }
}

class CategoryConfig {
  final String id;
  final IconData icon;

  const CategoryConfig({required this.id, required this.icon});
}

class _ChannelSelectorButton extends StatelessWidget {
  final String flag;
  final String languageName;
  final VoidCallback onPressed;

  const _ChannelSelectorButton({
    required this.flag,
    required this.languageName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 7),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 90),
                child: Text(
                  languageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final String name;
  final bool isInterested;
  final VoidCallback onTap;
  final VoidCallback onInterestPressed;

  const _CategoryCard({
    required this.index,
    required this.icon,
    required this.name,
    required this.isInterested,
    required this.onTap,
    required this.onInterestPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _accentColor(colorScheme, index);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isInterested
                  ? colorScheme.primary
                  : accentColor.withOpacity(0.16),
              width: isInterested ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isInterested ? '取消感兴趣' : '设为感兴趣',
                  onPressed: onInterestPressed,
                  icon: Icon(
                    isInterested
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isInterested
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.34),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor(ColorScheme colorScheme, int index) {
    final colors = <Color>[
      colorScheme.primary,
      colorScheme.secondary,
      Colors.deepPurple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
    ];

    return colors[index % colors.length];
  }
}
