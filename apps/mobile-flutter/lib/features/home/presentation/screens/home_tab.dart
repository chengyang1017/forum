import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart' as auth_cubit;

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
                color: colorScheme.onSurface.withValues(alpha: 0.58),
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
                  colorScheme.primary.withValues(alpha: 0.14),
                  colorScheme.secondary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
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
                          color: colorScheme.onSurface.withValues(alpha: 0.62),
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
                      colorScheme.primary.withValues(alpha: 0.72),
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
                        color: Colors.white.withValues(alpha: 0.18),
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
                        color: Colors.white.withValues(alpha: 0.78),
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
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '探索不同语言的内容',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
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
          ? colorScheme.primary.withValues(alpha: 0.10)
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
                      : colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  selected ? icon : outlineIcon,
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.65),
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
                        color: colorScheme.onSurface.withValues(alpha: 0.48),
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

  String _interestKey(String categoryId) => '$channelKey::$categoryId';

  Future<void> _toggleInterest({
    required BuildContext context,
    required auth_cubit.AuthCubit authProvider,
    required CategoryConfig category,
  }) async {
    final copy = _CategoryCopy.of(context);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.signInFirst)));
      return;
    }

    if (!authProvider.interestsLoaded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.interestsLoading)));
      return;
    }

    try {
      await authProvider.toggleInterest(_interestKey(category.id));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${copy.updateFailed}: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<auth_cubit.AuthCubit>();
    final interests = authProvider.interests;
    final copy = _CategoryCopy.of(context);
    final interestedCount = categories.where((category) {
      return interests.contains(_interestKey(category.id));
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final horizontalPadding = isTablet ? 24.0 : 16.0;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isTablet ? 14 : 10,
                horizontalPadding,
                0,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: _CategoryOverview(
                    language: language,
                    languageName: languageName,
                    interestedCount: interestedCount,
                    totalCount: categories.length,
                    interestsLoaded: authProvider.interestsLoaded,
                    onChangeLanguage: onChangeLanguage,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isTablet ? 18 : 16,
                horizontalPadding,
                10,
              ),
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: _CategorySectionHeading(
                    title: copy.selectTopics,
                    subtitle: authProvider.interestsLoaded
                        ? copy.interestSummary(
                            interestedCount,
                            categories.length,
                          )
                        : copy.interestsLoading,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _CategoryGrid(
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
      },
    );
  }
}

class _CategoryOverview extends StatelessWidget {
  final LanguageConfig language;
  final String languageName;
  final int interestedCount;
  final int totalCount;
  final bool interestsLoaded;
  final VoidCallback onChangeLanguage;

  const _CategoryOverview({
    required this.language,
    required this.languageName,
    required this.interestedCount,
    required this.totalCount,
    required this.interestsLoaded,
    required this.onChangeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;

    if (!isTablet) {
      return _LanguageChannelCard(
        language: language,
        languageName: languageName,
        onChangeLanguage: onChangeLanguage,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _LanguageChannelCard(
            language: language,
            languageName: languageName,
            onChangeLanguage: onChangeLanguage,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _InterestOverviewCard(
            interestedCount: interestedCount,
            totalCount: totalCount,
            interestsLoaded: interestsLoaded,
          ),
        ),
      ],
    );
  }
}

class _LanguageChannelCard extends StatelessWidget {
  final LanguageConfig language;
  final String languageName;
  final VoidCallback onChangeLanguage;

  const _LanguageChannelCard({
    required this.language,
    required this.languageName,
    required this.onChangeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isTablet ? 22 : 20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onChangeLanguage,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.13),
                colorScheme.secondary.withValues(alpha: 0.055),
              ],
            ),
            borderRadius: BorderRadius.circular(isTablet ? 22 : 20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.10),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 18 : 16,
              vertical: isTablet ? 16 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 54 : 50,
                  height: isTablet ? 54 : 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Text(
                    language.flag,
                    style: TextStyle(fontSize: isTablet ? 28 : 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.currentChannel,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        languageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: isTablet ? 18 : 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.75),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.switchLanguage,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InterestOverviewCard extends StatelessWidget {
  final int interestedCount;
  final int totalCount;
  final bool interestsLoaded;

  const _InterestOverviewCard({
    required this.interestedCount,
    required this.totalCount,
    required this.interestsLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final copy = _CategoryCopy.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interestsLoaded ? '$interestedCount / $totalCount' : '—',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  interestsLoaded
                      ? copy.interestCardLabel
                      : copy.interestsLoading,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.58),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CategorySectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            subtitle,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.48),
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final String channelKey;
  final List<CategoryConfig> categories;
  final List<String> categoryNames;
  final Set<String> interests;
  final ValueChanged<CategoryConfig> onCategorySelected;
  final void Function(CategoryConfig category, bool isInterested)
  onInterestPressed;

  const _CategoryGrid({
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
        final isTablet = constraints.maxWidth >= 600;
        final horizontalPadding = isTablet ? 24.0 : 16.0;
        final itemHeight = isTablet ? 92.0 : 108.0;
        final maxExtent = constraints.maxWidth >= 1000
            ? 210.0
            : isTablet
            ? 190.0
            : 220.0;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1088),
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                28,
              ),
              itemCount: categories.length,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxExtent,
                mainAxisExtent: itemHeight,
                crossAxisSpacing: isTablet ? 10 : 12,
                mainAxisSpacing: isTablet ? 10 : 12,
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
                  onTap: () => onCategorySelected(category),
                  onInterestPressed: () {
                    onInterestPressed(category, isInterested);
                  },
                );
              },
            ),
          ),
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
      color: colorScheme.primary.withValues(alpha: 0.08),
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
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final copy = _CategoryCopy.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isTablet ? 18 : 20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: isInterested
                ? colorScheme.primary.withValues(alpha: 0.055)
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(isTablet ? 18 : 20),
            border: Border.all(
              color: isInterested
                  ? colorScheme.primary.withValues(alpha: 0.42)
                  : colorScheme.outlineVariant.withValues(alpha: 0.82),
              width: isInterested ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 11 : 13,
              isTablet ? 10 : 12,
              isTablet ? 7 : 8,
              isTablet ? 10 : 12,
            ),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 40 : 44,
                  height: isTablet ? 40 : 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(isTablet ? 13 : 14),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: isTablet ? 21 : 23,
                  ),
                ),
                SizedBox(width: isTablet ? 9 : 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: isTablet ? 13 : 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (isInterested) ...[
                        const SizedBox(height: 4),
                        Text(
                          copy.following,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isInterested
                      ? copy.removeInterest
                      : copy.addInterest,
                  onPressed: onInterestPressed,
                  visualDensity: VisualDensity.compact,
                  constraints: BoxConstraints.tightFor(
                    width: isTablet ? 34 : 38,
                    height: isTablet ? 34 : 38,
                  ),
                  padding: EdgeInsets.zero,
                  iconSize: isTablet ? 19 : 21,
                  icon: Icon(
                    isInterested
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isInterested
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.32),
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

class _CategoryCopy {
  final String selectTopics;
  final String interestsLoading;
  final String signInFirst;
  final String updateFailed;
  final String interestCardLabel;
  final String following;
  final String addInterest;
  final String removeInterest;
  final String Function(int selected, int total) interestSummary;

  const _CategoryCopy({
    required this.selectTopics,
    required this.interestsLoading,
    required this.signInFirst,
    required this.updateFailed,
    required this.interestCardLabel,
    required this.following,
    required this.addInterest,
    required this.removeInterest,
    required this.interestSummary,
  });

  static _CategoryCopy of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();

    switch (code) {
      case 'en':
        return _CategoryCopy(
          selectTopics: 'Explore topics',
          interestsLoading: 'Loading interests…',
          signInFirst: 'Sign in to manage your interests.',
          updateFailed: 'Could not update interest',
          interestCardLabel: 'topics shaping your recommendations',
          following: 'Following',
          addInterest: 'Add to interests',
          removeInterest: 'Remove from interests',
          interestSummary: (selected, total) =>
              '$selected of $total topics shape your recommendations',
        );
      case 'vi':
        return _CategoryCopy(
          selectTopics: 'Khám phá chủ đề',
          interestsLoading: 'Đang tải sở thích…',
          signInFirst: 'Hãy đăng nhập để quản lý sở thích.',
          updateFailed: 'Không thể cập nhật sở thích',
          interestCardLabel: 'chủ đề đang định hình phần đề xuất',
          following: 'Đang quan tâm',
          addInterest: 'Thêm vào sở thích',
          removeInterest: 'Bỏ khỏi sở thích',
          interestSummary: (selected, total) =>
              '$selected/$total chủ đề đang ảnh hưởng đến đề xuất',
        );
      case 'ms':
        return _CategoryCopy(
          selectTopics: 'Teroka topik',
          interestsLoading: 'Memuatkan minat…',
          signInFirst: 'Log masuk untuk mengurus minat anda.',
          updateFailed: 'Minat tidak dapat dikemas kini',
          interestCardLabel: 'topik yang membentuk cadangan anda',
          following: 'Diminati',
          addInterest: 'Tambah sebagai minat',
          removeInterest: 'Buang daripada minat',
          interestSummary: (selected, total) =>
              '$selected daripada $total topik membentuk cadangan anda',
        );
      case 'id':
        return _CategoryCopy(
          selectTopics: 'Jelajahi topik',
          interestsLoading: 'Memuat minat…',
          signInFirst: 'Masuk untuk mengelola minat Anda.',
          updateFailed: 'Minat tidak dapat diperbarui',
          interestCardLabel: 'topik yang membentuk rekomendasi Anda',
          following: 'Diminati',
          addInterest: 'Tambahkan ke minat',
          removeInterest: 'Hapus dari minat',
          interestSummary: (selected, total) =>
              '$selected dari $total topik membentuk rekomendasi Anda',
        );
      case 'ru':
        return _CategoryCopy(
          selectTopics: 'Темы',
          interestsLoading: 'Загрузка интересов…',
          signInFirst: 'Войдите, чтобы управлять интересами.',
          updateFailed: 'Не удалось обновить интерес',
          interestCardLabel: 'тем, влияющих на рекомендации',
          following: 'В интересах',
          addInterest: 'Добавить в интересы',
          removeInterest: 'Убрать из интересов',
          interestSummary: (selected, total) =>
              '$selected из $total тем влияют на рекомендации',
        );
      case 'ja':
        return _CategoryCopy(
          selectTopics: 'トピックを探す',
          interestsLoading: '興味を読み込み中…',
          signInFirst: '興味を管理するにはログインしてください。',
          updateFailed: '興味を更新できませんでした',
          interestCardLabel: 'おすすめに反映されるトピック',
          following: '興味あり',
          addInterest: '興味に追加',
          removeInterest: '興味から削除',
          interestSummary: (selected, total) =>
              '$total 件中 $selected 件がおすすめに反映されます',
        );
      case 'ko':
        return _CategoryCopy(
          selectTopics: '주제 탐색',
          interestsLoading: '관심사를 불러오는 중…',
          signInFirst: '관심사를 관리하려면 로그인하세요.',
          updateFailed: '관심사를 업데이트하지 못했습니다',
          interestCardLabel: '추천에 반영되는 주제',
          following: '관심 있음',
          addInterest: '관심사에 추가',
          removeInterest: '관심사에서 제거',
          interestSummary: (selected, total) =>
              '$total개 중 $selected개 주제가 추천에 반영됩니다',
        );
      case 'th':
        return _CategoryCopy(
          selectTopics: 'สำรวจหัวข้อ',
          interestsLoading: 'กำลังโหลดความสนใจ…',
          signInFirst: 'เข้าสู่ระบบเพื่อจัดการความสนใจของคุณ',
          updateFailed: 'อัปเดตความสนใจไม่สำเร็จ',
          interestCardLabel: 'หัวข้อที่ใช้ปรับคำแนะนำของคุณ',
          following: 'สนใจอยู่',
          addInterest: 'เพิ่มเป็นความสนใจ',
          removeInterest: 'นำออกจากความสนใจ',
          interestSummary: (selected, total) =>
              '$selected จาก $total หัวข้อใช้ปรับคำแนะนำของคุณ',
        );
      case 'zh':
      default:
        return _CategoryCopy(
          selectTopics: '探索主题',
          interestsLoading: '正在加载兴趣设置…',
          signInFirst: '请先登录后再管理兴趣。',
          updateFailed: '更新兴趣失败',
          interestCardLabel: '个主题正在参与塑造你的推荐',
          following: '已设为感兴趣',
          addInterest: '设为感兴趣',
          removeInterest: '取消感兴趣',
          interestSummary: (selected, total) =>
              '已选择 $selected / $total · 点击心形调整推荐',
        );
    }
  }
}
