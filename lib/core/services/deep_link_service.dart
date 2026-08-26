import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../features/post/data/services/post_node_service.dart';
import '../../features/post/presentation/screens/post_detail_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  final PostService _postService = PostService();

  StreamSubscription<Uri>? _subscription;
  String? _openingPostId;

  void start() {
    _subscription ??= _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object error) {
        debugPrint('接收帖子链接失败：$error');
      },
    );
  }

  void _handleUri(Uri uri) {
    debugPrint('收到链接：$uri');

    if (uri.scheme != 'forum' || uri.host != 'post') {
      return;
    }

    if (uri.pathSegments.isEmpty) {
      return;
    }

    final postId = uri.pathSegments.first.trim();

    if (postId.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPost(postId);
    });
  }

  Future<void> _openPost(String postId) async {
    if (_openingPostId == postId) {
      return;
    }

    final navigator = rootNavigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    _openingPostId = postId;

    try {
      final post = await _postService.getPost(postId);

      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => PostDetailScreen(
            postId: post.id,
            post: post,
          ),
        ),
      );
    } catch (error) {
      debugPrint('打开帖子失败：$error');

      if (rootNavigatorKey.currentContext != null) {
        ScaffoldMessenger.of(
          rootNavigatorKey.currentContext!,
        ).showSnackBar(
          const SnackBar(content: Text('这个帖子不存在或已经被删除')),
        );
      }
    } finally {
      _openingPostId = null;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
