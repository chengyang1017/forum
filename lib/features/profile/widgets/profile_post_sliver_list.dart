import 'package:flutter/material.dart';

import '../../../config/l10n/app_localizations.dart';
import '../../../data/models/post_model.dart';
import '../../../shared/widgets/post_item_card.dart';

class ProfilePostSliverList extends StatelessWidget {
  final AsyncSnapshot<List<PostModel>> snapshot;
  final AppLocalizations l10n;

  const ProfilePostSliverList({
    super.key,
    required this.snapshot,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return SliverToBoxAdapter(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(32),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (snapshot.hasError) {
      return SliverToBoxAdapter(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              '${l10n.error}：${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    final posts = snapshot.data ?? <PostModel>[];

    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.article_outlined,
                size: 44,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.noDynamic,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = posts[index];

          return Container(
            color: Colors.white,
            child: Column(
              children: [
                PostItemCard(
                  post: post,
                  showUserInfo: false,
                  showLanguageBadge: true,
                ),
                if (index < posts.length - 1)
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
              ],
            ),
          );
        },
        childCount: posts.length,
      ),
    );
  }
}
