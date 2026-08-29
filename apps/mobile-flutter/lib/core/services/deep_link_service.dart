import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _subscription;
  Future<void> Function(String postId)? _openPostRoute;
  String? _openingPostId;

  void start({required Future<void> Function(String postId) openPostRoute}) {
    _openPostRoute = openPostRoute;

    _subscription ??= _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object error) {
        debugPrint('æŽ¥æ”¶å¸–å­é“¾æŽ¥å¤±è´¥ï¼š$error');
      },
    );
  }

  void _handleUri(Uri uri) {
    debugPrint('æ”¶åˆ°é“¾æŽ¥ï¼š$uri');

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

    final openPostRoute = _openPostRoute;

    if (openPostRoute == null) {
      debugPrint('å¸–å­é“¾æŽ¥è·¯ç”±å°šæœªåˆå§‹åŒ–');
      return;
    }

    _openingPostId = postId;

    try {
      await openPostRoute(postId);
    } catch (error) {
      debugPrint('æ‰“å¼€å¸–å­è·¯ç”±å¤±è´¥ï¼š$error');
    } finally {
      _openingPostId = null;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
