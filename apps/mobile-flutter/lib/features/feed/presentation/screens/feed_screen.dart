import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/forum_categories.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart' as auth_cubit;
import '../../../post/domain/models/post_model.dart';
import '../../../post/presentation/widgets/post_item_card.dart';
import '../cubit/feed_cubit.dart';

class FeedScreen extends StatelessWidget {
  final String channelKey;
  final String categoryId;
  final String languageCode;
  final String languageName;

  const FeedScreen({
    super.key,
    required this.channelKey,
    required this.categoryId,
    required this.languageCode,
    required this.languageName,
  });

  String get _selectedCategoryId => categoryId;

  String get _rootCategoryId {
    return ForumCategories.rootIdOf(_selectedCategoryId);
  }

  bool get _isLanguageLearningRoot {
    return _selectedCategoryId == ForumCategories.languageLearningCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authCubit = context.watch<auth_cubit.AuthCubit>();
    final currentUserId = authCubit.user?.id;
    final children = ForumCategories.childrenOf(_selectedCategoryId);

    void openChild(ForumCategory child) {
      context.push(
        AppRoutes.feedLocation(channelKey: channelKey, categoryId: child.id),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _CategoryBreadcrumbBar(
            categoryId: _selectedCategoryId,
            channelKey: channelKey,
          ),
          if (children.isNotEmpty)
            if (_isLanguageLearningRoot)
              _LanguageLearningChildrenPanel(
                children: children,
                onSelected: openChild,
              )
            else
              _CategoryChildrenBar(
                parentCategoryId: _selectedCategoryId,
                children: children,
                onSelected: openChild,
              ),
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: context.read<FeedCubit>().watchPosts(
                category: _rootCategoryId,
                languageCode: languageCode,
                currentUserId: currentUserId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error);
                }

                final allPosts = snapshot.data ?? const <PostModel>[];
                final posts = _filterPostsForCurrentNode(allPosts);

                if (posts.isEmpty) {
                  return _buildEmptyState(context);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await context.read<FeedCubit>().refreshPosts(
                      category: _rootCategoryId,
                      languageCode: languageCode,
                      currentUserId: currentUserId,
                    );
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: posts.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      return PostItemCard(
                        post: post,
                        showUserInfo: true,
                        showLanguageBadge: true,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<PostModel> _filterPostsForCurrentNode(List<PostModel> posts) {
    if (_selectedCategoryId == _rootCategoryId) {
      return posts;
    }

    return posts
        .where((post) {
          return post.categoryPath.contains(_selectedCategoryId);
        })
        .toList(growable: false);
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uiLanguageCode = Localizations.localeOf(context).languageCode;
    final categoryName = ForumCategories.nameOf(
      _selectedCategoryId,
      uiLanguageCode,
    );

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            categoryName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: 18,
            ),
          ),
          Text(
            _getLanguageDisplay(),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: _isLanguageLearningRoot ? '发布综合语言学习话题' : '发布帖子',
            icon: Icon(Icons.add_rounded, color: colorScheme.primary, size: 28),
            onPressed: () {
              context.push(
                AppRoutes.createPostLocation(
                  channelKey: channelKey,
                  categoryId: _selectedCategoryId,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final uiLanguageCode = Localizations.localeOf(context).languageCode;
    final categoryName = ForumCategories.nameOf(
      _selectedCategoryId,
      uiLanguageCode,
    );

    return EmptyState(
      icon: Icons.article_outlined,
      title: '暂无$languageName帖子',
      subtitle: _isLanguageLearningRoot
          ? '可以直接发布语言学习综合话题，\n也可以先选择一门具体语言'
          : '成为第一个在「$categoryName」下\n发布$languageName帖子的人吧',
      onAction: () {
        context.push(
          AppRoutes.createPostLocation(
            channelKey: channelKey,
            categoryId: _selectedCategoryId,
          ),
        );
      },
      actionLabel: _isLanguageLearningRoot ? '发布综合语言学习话题' : '发布$languageName帖子',
    );
  }

  String _getLanguageDisplay() {
    final flag = _getFlag(languageCode);
    return '$flag $languageName频道';
  }

  String _getFlag(String code) {
    final language = LanguageConfig.findByCode(code);

    if (language != null) {
      return language.flag;
    }

    final script = ScriptConfig.findByCode(code);

    if (script != null) {
      for (final ownerLanguageCode in script.languageCodes) {
        final ownerLanguage = LanguageConfig.findByCode(ownerLanguageCode);

        if (ownerLanguage != null) {
          return ownerLanguage.flag;
        }
      }
    }

    return '🌐';
  }
}

class _CategoryBreadcrumbBar extends StatelessWidget {
  final String categoryId;
  final String channelKey;

  const _CategoryBreadcrumbBar({
    required this.categoryId,
    required this.channelKey,
  });

  void _navigateToAncestor(
    BuildContext context, {
    required List<String> path,
    required int targetIndex,
  }) {
    final router = GoRouter.of(context);
    final targetLocation = AppRoutes.feedLocation(
      channelKey: channelKey,
      categoryId: path[targetIndex],
    );
    final popCount = path.length - 1 - targetIndex;

    for (var index = 0; index < popCount; index++) {
      if (!router.canPop()) {
        router.go(targetLocation);
        return;
      }
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiLanguageCode = Localizations.localeOf(context).languageCode;
    final path = ForumCategories.pathOf(categoryId);

    if (path.length <= 1) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      color: colorScheme.surface,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var index = 0; index < path.length; index++) ...[
            if (index > 0)
              Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: index == path.length - 1
                  ? null
                  : () {
                      _navigateToAncestor(
                        context,
                        path: path,
                        targetIndex: index,
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Text(
                  ForumCategories.nameOf(path[index], uiLanguageCode),
                  style: TextStyle(
                    color: index == path.length - 1
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.60),
                    fontSize: 12,
                    fontWeight: index == path.length - 1
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageLearningChildrenPanel extends StatelessWidget {
  const _LanguageLearningChildrenPanel({
    required this.children,
    required this.onSelected,
  });

  final List<ForumCategory> children;
  final ValueChanged<ForumCategory> onSelected;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<ForumCategory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _LanguageLearningPickerSheet(children: children),
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.translate_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择学习语言（可选）',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '不选择具体语言也可以发帖，适合讨论学习方法、语言学或多语言话题。',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.58),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openPicker(context),
              icon: const Icon(Icons.search_rounded, size: 19),
              label: Text('从语言库选择 · ${children.length} 种语言'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageLearningPickerSheet extends StatefulWidget {
  const _LanguageLearningPickerSheet({required this.children});

  final List<ForumCategory> children;

  @override
  State<_LanguageLearningPickerSheet> createState() =>
      _LanguageLearningPickerSheetState();
}

class _LanguageLearningPickerSheetState
    extends State<_LanguageLearningPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final uiLanguageCode = Localizations.localeOf(context).languageCode;
    final normalizedQuery = _query.trim().toLowerCase();
    final languages = List<ForumCategory>.from(widget.children)
      ..sort((first, second) {
        final firstCode = ForumCategories.languageCodeOf(first.id) ?? '';
        final secondCode = ForumCategories.languageCodeOf(second.id) ?? '';
        final firstLanguage = LanguageConfig.findByCode(firstCode);
        final secondLanguage = LanguageConfig.findByCode(secondCode);
        final firstKey =
            firstLanguage?.sortKeyOf(uiLanguageCode) ??
            first.nameOf(uiLanguageCode);
        final secondKey =
            secondLanguage?.sortKeyOf(uiLanguageCode) ??
            second.nameOf(uiLanguageCode);
        return firstKey.compareTo(secondKey);
      });

    final visibleLanguages = normalizedQuery.isEmpty
        ? languages
        : languages
              .where((category) {
                final code = ForumCategories.languageCodeOf(category.id) ?? '';
                if (code.toLowerCase().contains(normalizedQuery)) {
                  return true;
                }

                return category.names.values.any(
                  (name) => name.toLowerCase().contains(normalizedQuery),
                );
              })
              .toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.86,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择学习语言',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '语言来自 Glyphora Language Core。返回上一层即可继续使用“综合语言学习”，不要求指定语言。',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.58),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  autofocus: false,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: '搜索语言名称或代码',
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          Expanded(
            child: visibleLanguages.isEmpty
                ? Center(
                    child: Text(
                      '没有找到语言',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: visibleLanguages.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: 64,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                    itemBuilder: (context, index) {
                      final category = visibleLanguages[index];
                      final code =
                          ForumCategories.languageCodeOf(category.id) ?? '';
                      final language = LanguageConfig.findByCode(code);
                      final flag = language?.flag ?? '🌐';

                      return ListTile(
                        leading: SizedBox(
                          width: 36,
                          child: Center(
                            child: Text(
                              flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        title: Text(
                          category.nameOf(uiLanguageCode),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(code.toUpperCase()),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pop(context, category),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChildrenBar extends StatelessWidget {
  final String parentCategoryId;
  final List<ForumCategory> children;
  final ValueChanged<ForumCategory> onSelected;

  const _CategoryChildrenBar({
    required this.parentCategoryId,
    required this.children,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final uiLanguageCode = Localizations.localeOf(context).languageCode;

    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '继续选择分类',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final child = children[index];
                final childName = child.nameOf(uiLanguageCode);

                return ActionChip(
                  label: Text(childName),
                  avatar: ForumCategories.hasChildren(child.id)
                      ? const Icon(Icons.account_tree_outlined, size: 17)
                      : null,
                  onPressed: () {
                    onSelected(child);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
