import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/models/post_model.dart';
import '../../features/feed/screens/post_detail_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance =
      DeepLinkService._();

  final AppLinks _appLinks = AppLinks();

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

    if (uri.scheme != 'forum') {
      return;
    }

    if (uri.host != 'post') {
      return;
    }

    if (uri.pathSegments.isEmpty) {
      return;
    }

    final postId = uri.pathSegments.first.trim();

    if (postId.isEmpty) {
      return;
    }

    // 等 MaterialApp 和 Navigator 完成第一帧。
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
      final document = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      final data = document.data();

      if (!document.exists || data == null) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          const SnackBar(
            content: Text('这个帖子不存在或已经被删除'),
          ),
        );
        return;
      }

      final post = PostModel.fromJson({
        ...data,
        'id': document.id,
      });

      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => PostDetailScreen(
            postId: document.id,
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
          SnackBar(
            content: Text('打开帖子失败：$error'),
          ),
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