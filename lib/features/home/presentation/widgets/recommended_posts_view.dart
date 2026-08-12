import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../post/presentation/widgets/post_item_card.dart';
import '../../../post/domain/models/post_model.dart';

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

        // 没有主动选择任何兴趣时，不监听 posts，也不展示任何帖子。
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

  String _postInterestKey(Map<String, dynamic> data) {
    final languageCode = data['languageCode'] as String? ?? '';

    final category = data['category'] as String? ?? '';

    return '$languageCode::$category';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
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

        final matchingPosts = postSnapshot.data!.docs.where((document) {
          final key = _postInterestKey(document.data());

          return interests.contains(key);
        }).toList();

        if (matchingPosts.isEmpty) {
          return const _InterestEmptyState(
            icon: Icons.inbox_outlined,
            title: '这些兴趣暂时没有帖子',
            description: '已选择的语言频道和分类中，目前还没有可显示的内容。',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          itemCount: matchingPosts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final document = matchingPosts[index];
            //final post = PostModel.fromDocument(document);

            //测试数据
            final data = document.data();
            debugPrint('帖子原始数据：$data');
            //测试数据

            final post = PostModel.fromJson({
              ...document.data(),
              'id': document.id,
            });
            return PostItemCard(
              post: post,
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
