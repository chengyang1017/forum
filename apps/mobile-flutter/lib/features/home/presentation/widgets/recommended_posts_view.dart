import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart' as auth_prov;
import '../../../post/data/services/post_node_service.dart';
import '../../../post/domain/models/post_model.dart';
import '../../../post/presentation/widgets/post_item_card.dart';

class RecommendedPostsView extends StatelessWidget {
  const RecommendedPostsView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<auth_prov.AuthProvider>();

    if (authProvider.user == null) {
      return const _InterestEmptyState(
        icon: Icons.login_rounded,
        title: '登录后使用推荐主页',
        description: '登录后可以选择感兴趣的语言频道和分类。',
      );
    }

    if (!authProvider.interestsLoaded) {
      if (authProvider.interestsError != null) {
        return _InterestEmptyState(
          icon: Icons.error_outline_rounded,
          title: '兴趣加载失败',
          description: '无法加载你的兴趣设置，请检查网络或后端连接后重试。',
          actionLabel: '重试',
          onAction: authProvider.retryLoadInterests,
        );
      }

      return const Center(child: CircularProgressIndicator());
    }

    final interests = authProvider.interests;

    if (interests.isEmpty) {
      return const _InterestEmptyState(
        icon: Icons.favorite_border_rounded,
        title: '还没有感兴趣的分类',
        description: '进入分类频道，选择一个语言，再点击分类右侧的心形。',
      );
    }

    return _InterestedPostList(interests: interests);
  }
}

class _InterestedPostList extends StatefulWidget {
  final Set<String> interests;

  const _InterestedPostList({required this.interests});

  @override
  State<_InterestedPostList> createState() => _InterestedPostListState();
}

class _InterestedPostListState extends State<_InterestedPostList> {
  Timer? _refreshTimer;

  List<PostModel>? _posts;
  Object? _error;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _refresh(showLoading: true);

    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _refresh();
    });
  }

  @override
  void didUpdateWidget(covariant _InterestedPostList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final interestsChanged =
        oldWidget.interests.length != widget.interests.length ||
        !oldWidget.interests.containsAll(widget.interests);

    if (interestsChanged) {
      _refresh(showLoading: true);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<List<PostModel>> _loadPosts() async {
    final service = PostService();

    final orderedInterests = widget.interests.toList()..sort();

    final requests = <Future<List<PostModel>>>[];

    for (final interest in orderedInterests) {
      final separatorIndex = interest.indexOf('::');

      if (separatorIndex <= 0 || separatorIndex >= interest.length - 2) {
        continue;
      }

      final languageCode = interest.substring(0, separatorIndex).trim();

      final category = interest.substring(separatorIndex + 2).trim();

      if (languageCode.isEmpty || category.isEmpty) {
        continue;
      }

      requests.add(
        service.getPosts(category: category, languageCode: languageCode),
      );
    }

    if (requests.isEmpty) {
      return const <PostModel>[];
    }

    final batches = await Future.wait(requests);

    final byPostId = <String, PostModel>{};

    for (final batch in batches) {
      for (final post in batch) {
        byPostId.putIfAbsent(post.id, () => post);
      }
    }

    final posts = byPostId.values.toList();

    posts.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bTime.compareTo(aTime);
    });

    return posts;
  }

  Future<void> _refresh({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final posts = await _loadPosts();

      if (!mounted) {
        return;
      }

      setState(() {
        _posts = posts;
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Widget _refreshableState({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [SizedBox(height: constraints.maxHeight, child: child)],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _posts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _posts == null) {
      return _refreshableState(
        child: _InterestEmptyState(
          icon: Icons.error_outline_rounded,
          title: '帖子加载失败',
          description: '$_error',
        ),
      );
    }

    final posts = _posts ?? const <PostModel>[];

    if (posts.isEmpty) {
      return _refreshableState(
        child: const _InterestEmptyState(
          icon: Icons.inbox_outlined,
          title: '这些兴趣暂时没有帖子',
          description:
              '已选择的语言频道和分类中，目前还没有可显示的内容。\n'
              '你也可以下拉重新加载。',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        itemCount: posts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return PostItemCard(
            post: posts[index],
            showUserInfo: true,
            showLanguageBadge: true,
          );
        },
      ),
    );
  }
}

class _InterestEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InterestEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.56),
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
