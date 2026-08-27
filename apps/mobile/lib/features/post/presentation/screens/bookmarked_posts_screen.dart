import 'package:flutter/material.dart';

import '../../data/services/post_node_service.dart';
import '../../domain/models/post_model.dart';
import '../widgets/post_item_card.dart';
import 'post_detail_screen.dart';

class BookmarkedPostsScreen extends StatefulWidget {
  const BookmarkedPostsScreen({super.key});

  @override
  State<BookmarkedPostsScreen> createState() =>
      _BookmarkedPostsScreenState();
}

class _BookmarkedPostsScreenState
    extends State<BookmarkedPostsScreen> {
  final PostService _postService = PostService();

  List<PostModel> _posts = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final posts =
          await _postService.getBookmarkedPosts();

      if (!mounted) {
        return;
      }

      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openPost(
    PostModel post,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          postId: post.id,
          post: post,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    // 从详情页返回时重新读取。
    // 如果刚刚取消收藏，这里会立刻从列表消失。
    await _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '我的收藏',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed:
                _loading
                    ? null
                    : _loadBookmarks,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _posts.isEmpty) {
      return _BookmarksMessage(
        icon: Icons.error_outline_rounded,
        title: '收藏加载失败',
        description: '$_error',
        actionText: '重新加载',
        onAction: _loadBookmarks,
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBookmarks,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _BookmarksMessage(
              icon:
                  Icons.bookmark_border_rounded,
              title: '还没有收藏',
              description:
                  '在帖子详情页点击收藏后，'
                  '会出现在这里。',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookmarks,
      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          12,
          10,
          12,
          24,
        ),
        itemCount: _posts.length,
        separatorBuilder:
            (_, __) =>
                const Divider(height: 1),
        itemBuilder: (context, index) {
          final post = _posts[index];

          return PostItemCard(
            post: post,
            showUserInfo: true,
            showLanguageBadge: true,
            onTap: () {
              _openPost(post);
            },
          );
        },
      ),
    );
  }
}

class _BookmarksMessage
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;

  const _BookmarksMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color:
                  colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (
              actionText != null &&
              onAction != null
            ) ...[
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
