import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../post/data/services/post_node_service.dart';
import '../../../post/domain/models/post_model.dart';
import '../../../post/presentation/widgets/post_item_card.dart';

class RecommendedPostsView extends StatelessWidget {
  const RecommendedPostsView({super.key});

  Set<String> _readInterests(Object? value) {
    if (value is! Iterable) {
      return {};
    }

    return value.whereType<String>().toSet();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const _InterestEmptyState(
        icon: Icons.login_rounded,
        title: '登录后使用推荐主页',
        description: '登录后可以选择感兴趣的语言频道和分类。',
      );
    }

    // 兴趣设置暂时仍属于用户偏好数据，继续由 Firestore 管理。
    // 帖子内容本身已经全部从 Node/PostgreSQL 读取。
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return _InterestEmptyState(
            icon: Icons.error_outline_rounded,
            title: '无法读取兴趣设置',
            description: '${userSnapshot.error}',
          );
        }

        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final interests = _readInterests(
          userSnapshot.data?.data()?['interests'],
        );

        if (interests.isEmpty) {
          return const _InterestEmptyState(
            icon: Icons.favorite_border_rounded,
            title: '还没有感兴趣的分类',
            description: '进入分类频道，选择一个语言，再点击分类右侧的心形。',
          );
        }

        return _InterestedPostList(interests: interests);
      },
    );
  }
}

class _InterestedPostList extends StatelessWidget {
  final Set<String> interests;

  const _InterestedPostList({required this.interests});

  Future<List<PostModel>> _loadPosts() async {
    final service = PostService();
    final orderedInterests = interests.toList()..sort();

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
        service.getPosts(
          category: category,
          languageCode: languageCode,
        ),
      );
    }

    if (requests.isEmpty) {
      return const [];
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

  Stream<List<PostModel>> _watchPosts() async* {
    while (true) {
      yield await _loadPosts();

      await Future<void>.delayed(
        const Duration(seconds: 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: _watchPosts(),
      builder: (context, postSnapshot) {
        if (postSnapshot.hasError) {
          return _InterestEmptyState(
            icon: Icons.error_outline_rounded,
            title: '帖子加载失败',
            description: '${postSnapshot.error}',
          );
        }

        if (!postSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = postSnapshot.data!;

        if (posts.isEmpty) {
          return const _InterestEmptyState(
            icon: Icons.inbox_outlined,
            title: '这些兴趣暂时没有帖子',
            description: '已选择的语言频道和分类中，目前还没有可显示的内容。',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return PostItemCard(
              post: posts[index],
              showUserInfo: true,
              showLanguageBadge: true,
            );
          },
        );
      },
    );
  }
}

class _InterestEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InterestEmptyState({
    required this.icon,
    required this.title,
    required this.description,
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
                color: colorScheme.primary.withOpacity(0.09),
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
                color: colorScheme.onSurface.withOpacity(0.56),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
