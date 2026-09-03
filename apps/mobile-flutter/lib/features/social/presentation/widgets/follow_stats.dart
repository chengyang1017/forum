import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/repositories/follow_repository.dart';

class FollowStats extends StatelessWidget {
  const FollowStats({
    super.key,
    required this.userId,
    required this.postCount,
    required this.totalLikes,
    this.postsLabel = '动态',
    this.followingLabel = '关注',
    this.followersLabel = '粉丝',
    this.likesLabel = '获赞',
  });

  final String userId;
  final int postCount;
  final int totalLikes;
  final String postsLabel;
  final String followingLabel;
  final String followersLabel;
  final String likesLabel;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<FollowRepository>();

    return Row(
      children: [
        Expanded(
          child: _StatItem(label: postsLabel, value: postCount.toString()),
        ),
        Expanded(
          child: StreamBuilder<int>(
            stream: repository.watchFollowingCount(userId),
            initialData: 0,
            builder: (context, snapshot) {
              return _StatItem(
                label: followingLabel,
                value: snapshot.hasError ? '—' : '${snapshot.data ?? 0}',
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<int>(
            stream: repository.watchFollowerCount(userId),
            initialData: 0,
            builder: (context, snapshot) {
              return _StatItem(
                label: followersLabel,
                value: snapshot.hasError ? '—' : '${snapshot.data ?? 0}',
              );
            },
          ),
        ),
        Expanded(
          child: _StatItem(label: likesLabel, value: totalLikes.toString()),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
