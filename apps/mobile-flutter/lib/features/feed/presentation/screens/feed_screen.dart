import 'package:flutter/material.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/forum_categories.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart' as auth_prov;
import '../../../post/domain/models/post_model.dart';
import '../../../post/presentation/widgets/post_item_card.dart';
import '../providers/feed_provider.dart' as feed_prov;

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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<auth_prov.AuthProvider>();
    final currentUserId = authProvider.user?.id;

    final children = ForumCategories.childrenOf(_selectedCategoryId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _CategoryBreadcrumbBar(
            categoryId: _selectedCategoryId,
            channelKey: channelKey,
          ),
          if (children.isNotEmpty)
            _CategoryChildrenBar(
              parentCategoryId: _selectedCategoryId,
              children: children,
              onSelected: (child) {
                context.push(
                  AppRoutes.feedLocation(
                    channelKey: channelKey,
                    categoryId: child.id,
                  ),
                );
              },
            ),
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: context.read<feed_prov.FeedProvider>().watchPosts(
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
                    await context.read<feed_prov.FeedProvider>().refreshPosts(
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
                      color: Colors.grey.shade100,
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontSize: 18,
            ),
          ),
          Text(
            _getLanguageDisplay(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: Colors.blueAccent,
              size: 28,
            ),
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
      subtitle: '成为第一个在「$categoryName」下\n发布$languageName帖子的人吧',
      onAction: () {
        context.push(
          AppRoutes.createPostLocation(
            channelKey: channelKey,
            categoryId: _selectedCategoryId,
          ),
        );
      },
      actionLabel: '发布$languageName帖子',
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
                      context.push(
                        AppRoutes.feedLocation(
                          channelKey: channelKey,
                          categoryId: path[index],
                        ),
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
