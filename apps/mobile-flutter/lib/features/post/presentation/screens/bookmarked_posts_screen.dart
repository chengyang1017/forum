import 'package:flutter/material.dart';
import 'package:glyphora_mobile/app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../domain/models/post_model.dart';
import '../../domain/repositories/post_repository.dart';
import '../widgets/post_item_card.dart';

class BookmarkedPostsScreen extends StatefulWidget {
  const BookmarkedPostsScreen({super.key});

  @override
  State<BookmarkedPostsScreen> createState() => _BookmarkedPostsScreenState();
}

class _BookmarkedPostsScreenState extends State<BookmarkedPostsScreen> {
  late PostRepository _repository;
  bool _dependenciesReady = false;

  List<PostModel> _posts = const [];
  bool _loading = true;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_dependenciesReady) {
      return;
    }

    _repository = context.read<PostRepository>();
    _dependenciesReady = true;
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
      final posts = await _repository.getBookmarkedPosts();

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

  Future<void> _openPost(PostModel post) async {
    await context.push<void>(
      AppRoutes.postDetailLocation(postId: post.id),
      extra: post,
    );

    if (!mounted) {
      return;
    }

    // Returning from details may have changed bookmark state.
    await _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.bookmarksTitle,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: context.l10n.refresh,
            onPressed: _loading ? null : _loadBookmarks,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _posts.isEmpty) {
      return _BookmarksMessage(
        icon: Icons.error_outline_rounded,
        title: context.l10n.bookmarksLoadFailed,
        description: '$_error',
        actionText: context.l10n.reload,
        onAction: _loadBookmarks,
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBookmarks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120),
            _BookmarksMessage(
              icon: Icons.bookmark_border_rounded,
              title: context.l10n.noBookmarks,
              description: context.l10n.noBookmarksDescription,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookmarks,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        itemCount: _posts.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
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

class _BookmarksMessage extends StatelessWidget {
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
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.45),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonal(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}
