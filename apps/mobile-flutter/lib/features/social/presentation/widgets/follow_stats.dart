import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../domain/repositories/follow_repository.dart';

class FollowStats extends StatelessWidget {
  const FollowStats({
    super.key,
    required this.userId,
    required this.postCount,
    required this.totalLikes,
    this.postsLabel,
    this.followingLabel,
    this.followersLabel,
    this.likesLabel,
  });

  final String userId;
  final int postCount;
  final int totalLikes;
  final String? postsLabel;
  final String? followingLabel;
  final String? followersLabel;
  final String? likesLabel;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<FollowRepository>();
    final l10n = AppLocalizations.of(context)!;
    final resolvedPostsLabel = postsLabel ?? l10n.posts;
    final resolvedFollowingLabel = followingLabel ?? l10n.get('following');
    final resolvedFollowersLabel = followersLabel ?? l10n.get('followers');
    final resolvedLikesLabel = likesLabel ?? l10n.likesCount;

    return Row(
      children: [
        Expanded(
          child: _StatItem(
            label: resolvedPostsLabel,
            value: postCount.toString(),
          ),
        ),
        Expanded(
          child: StreamBuilder<int>(
            stream: repository.watchFollowingCount(userId),
            initialData: 0,
            builder: (context, snapshot) {
              return _StatItem(
                label: resolvedFollowingLabel,
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
                label: resolvedFollowersLabel,
                value: snapshot.hasError ? '—' : '${snapshot.data ?? 0}',
              );
            },
          ),
        ),
        Expanded(
          child: _StatItem(
            label: resolvedLikesLabel,
            value: totalLikes.toString(),
          ),
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
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
