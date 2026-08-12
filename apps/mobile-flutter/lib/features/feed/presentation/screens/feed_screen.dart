import 'package:flutter/material.dart';
import 'package:glyphora_language_core/glyphora_language_core.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/forum_categories.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart' as authProv;
import '../../../post/domain/models/post_model.dart';
import '../../../post/presentation/screens/create_post_screen.dart';
import '../../../post/presentation/widgets/post_item_card.dart';
import '../providers/feed_provider.dart' as feedProv;

class FeedScreen extends StatelessWidget {
  // 一级分类。继续用于旧 Firestore 查询。
  final String category;

  // 当前浏览到的分类节点。为空时等于 category。
  final String? categoryId;

  final String languageCode;
  final String languageName;

  const FeedScreen({
    super.key,
    required this.category,
    this.categoryId,
    required this.languageCode,
    required this.languageName,
  });

  String get _selectedCategoryId => categoryId ?? category;

  String get _rootCategoryId {
    return ForumCategories.rootIdOf(_selectedCategoryId);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<authProv.AuthProvider>();
    final currentUserId = authProvider.user?.id;

    final children = ForumCategories.childrenOf(_selectedCategoryId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          if (children.isNotEmpty)
            _CategoryChildrenBar(
              parentCategoryId: _selectedCategoryId,
              children: children,
              onSelected: (child) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FeedScreen(
                      category: _rootCategoryId,
                      categoryId: child.id,
                      languageCode: languageCode,
                      languageName: languageName,
                    ),
                  ),
                );
              },
            ),
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: context.read<feedProv.FeedProvider>().watchPosts(
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
                    await context.read<feedProv.FeedProvider>().refreshPosts(
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

    return posts.where((post) {
      return post.categoryPath.contains(_selectedCategoryId);
    }).toList(growable: false);
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
        child: Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.shade200,
        ),
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
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CreatePostScreen(
                    category: _rootCategoryId,
                    languageCode: languageCode,
                    languageName: languageName,
                  ),
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
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.redAccent,
          ),
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
            style: const TextStyle(
              fontSize: 12,
              color: Colors.redAccent,
            ),
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
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => CreatePostScreen(
              category: _rootCategoryId,
              languageCode: languageCode,
              languageName: languageName,
            ),
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
              color: colorScheme.onSurface.withOpacity(0.55),
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
              separatorBuilder: (_, __) => const SizedBox(width: 8),
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
