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

    final currentLanguageName = currentChannel.displayNameOf(uiLanguageCode);

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
                      Text(
                        '推荐只来自你的主动选择',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '点赞、收藏、关注标签与加入兴趣都会影响推荐；单纯浏览不会改变你的推荐。',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                          height: 1.45,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final user = context.watch<auth_cubit.AuthCubit>().state.user;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      _displayInitial(user?.displayName, user?.email),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName?.trim().isNotEmpty == true
                              ? user!.displayName!.trim()
                              : 'Glyphora',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 10),
            _DrawerDestination(
              icon: Icons.auto_awesome_rounded,
              label: '为你推荐',
              selected: currentSection == _HomeSection.recommended,
              onTap: () {
                onSectionSelected(_HomeSection.recommended);
                Navigator.pop(context);
              },
            ),
            _DrawerDestination(
              icon: Icons.grid_view_rounded,
              label: l10n.forumCategories,
              selected: currentSection == _HomeSection.categories,
              onTap: () {
                onSectionSelected(_HomeSection.categories);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Text(
                '万文社 · Glyphora',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _displayInitial(String? displayName, String? email) {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name.characters.first.toUpperCase();
    }

    final value = email?.trim();
    if (value != null && value.isNotEmpty) {
      return value.characters.first.toUpperCase();
    }

    return 'G';
  }
}

class _DrawerDestination extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerDestination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        leading: Icon(icon, size: 22),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        selected: selected,
        selectedColor: colorScheme.primary,
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
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
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 7),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 118),
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
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
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
  final Map<String, String> categoryNames;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: _LanguageHeroCard(
              flag: language.flag,
              title: languageName,
              subtitle: l10n.chooseCategorySubtitle,
              actionLabel: l10n.changeLanguage,
              onPressed: onChangeLanguage,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = categories[index];

                return _CategoryCard(
                  category: category,
                  title: categoryNames[category.id] ?? category.id,
                  colorScheme: colorScheme,
                  onTap: () {
                    onCategorySelected(category);
                  },
                );
              },
              childCount: categories.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageHeroCard extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  const _LanguageHeroCard({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(flag, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.56),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryConfig category;
  final String title;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.title,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  category.icon,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                channelKey,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.38),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
