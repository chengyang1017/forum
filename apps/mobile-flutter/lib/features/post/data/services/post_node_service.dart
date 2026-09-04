import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/models/post_model.dart';
import 'post_api.dart';

/// Node/PostgreSQL-backed post service.
///
/// Firebase Auth remains the identity provider and Firebase Storage is used
/// only for cleanup that is part of deleting a post. New media uploads are
/// handled by the dedicated post-media adapter.
class PostService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final PostApi _postApi = PostApi();
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  Stream<List<PostModel>> watchPosts({
    required String category,
    required String languageCode,
  }) async* {
    while (true) {
      yield await getPosts(category: category, languageCode: languageCode);

      await for (final _
          in _refreshController.stream
              .timeout(
                const Duration(seconds: 15),
                onTimeout: (sink) {
                  sink.add(null);
                },
              )
              .take(1)) {
        break;
      }
    }
  }

  Future<List<PostModel>> getPosts({
    required String category,
    required String languageCode,
  }) async {
    final posts = await _postApi.getPosts(
      category: category,
      languageCode: languageCode,
    );
    return _filterBlockedAuthors(posts);
  }

  Stream<List<PostModel>> watchUserPosts(String firebaseUid) async* {
    while (true) {
      final blocked = await _blockedUserIds();
      if (blocked.contains(firebaseUid)) {
        yield const <PostModel>[];
      } else {
        final posts = await _postApi.getPostsByUser(firebaseUid);
        yield _filterWithBlockedSet(posts, blocked);
      }

      await Future<void>.delayed(const Duration(seconds: 15));
    }
  }

  Future<void> refreshPosts({
    required String category,
    required String languageCode,
  }) async {
    _refreshController.add(null);
  }

  Future<void> createPost(PostModel post) async {
    if (_auth.currentUser == null) {
      throw Exception('未登录');
    }

    final title = post.title?.trim() ?? '';
    final category = post.category?.trim() ?? '';
    final languageCode = post.primaryLanguageCode?.trim().isNotEmpty == true
        ? post.primaryLanguageCode!.trim()
        : post.languageCode?.trim() ?? '';

    if (post.id.isEmpty) {
      throw Exception('帖子 ID 不能为空');
    }

    if (title.isEmpty) {
      throw Exception('标题不能为空');
    }

    if (category.isEmpty) {
      throw Exception('帖子分类不能为空');
    }

    if (languageCode.isEmpty) {
      throw Exception('帖子语言不能为空');
    }

    await _postApi.createPost(
      firestoreId: post.id,
      title: title,
      content: post.content ?? '',
      bodyDelta: post.bodyDelta,
      category: category,
      languageCode: languageCode,
      images: post.imageUrls ?? const [],
    );
  }

  Future<PostModel> getPost(String postId) async {
    final post = await _postApi.getPost(postId);
    final blocked = await _blockedUserIds();
    if (post.userId != null && blocked.contains(post.userId)) {
      throw StateError('BLOCKED_USER_CONTENT');
    }
    return post;
  }

  Future<void> addLanguageVersion({
    required String postId,
    required String languageCode,
    required String languageName,
    required String title,
    required String content,
    required String type,
    List<dynamic> bodyDelta = const [],
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('未登录');
    }

    await _postApi.addLanguageVersion(
      postId: postId,
      languageCode: languageCode,
      title: title.trim(),
      content: content.trim(),
      type: type,
      bodyDelta: bodyDelta,
    );
  }

  Future<Map<String, dynamic>?> getLanguageVersion({
    required String postId,
    required String languageCode,
  }) async {
    return _postApi.getLanguageVersion(
      postId: postId,
      languageCode: languageCode,
    );
  }

  Future<void> updatePost(String postId, {required String content}) async {
    final post = await _postApi.getPost(postId);
    final languageCode = post.languageCode ?? post.primaryLanguageCode;

    if (languageCode == null || languageCode.isEmpty) {
      throw Exception('无法确定帖子语言');
    }

    await _postApi.updateLanguageVersion(
      postId: postId,
      languageCode: languageCode,
      title: post.title ?? '',
      content: content.trim(),
      bodyDelta: post.bodyDelta,
    );
  }

  Future<int> toggleLike(String postId, {required bool liked}) async {
    final result = liked
        ? await _postApi.likePost(postId)
        : await _postApi.unlikePost(postId);

    return result.likeCount;
  }

  Future<bool> toggleBookmark(String postId, {required bool bookmarked}) {
    return bookmarked
        ? _postApi.bookmarkPost(postId)
        : _postApi.removeBookmark(postId);
  }

  Future<List<PostModel>> getBookmarkedPosts() async {
    final posts = await _postApi.getBookmarkedPosts();
    return _filterBlockedAuthors(posts);
  }

  Future<PostReportResult> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) {
    return _postApi.reportPost(
      postId: postId,
      reason: reason,
      details: details,
    );
  }

  Future<void> deletePost(String postId) async {
    final imageUrls = await _postApi.deletePost(postId);

    for (final url in imageUrls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {
        // Metadata has already been deleted from PostgreSQL. A stale Storage
        // object should not make the post delete operation fail locally.
      }
    }
  }

  Future<void> updateImages(String postId, List<String> imageUrls) async {
    await _postApi.updateImages(postId: postId, images: imageUrls);
  }

  Future<void> updateLanguageVersionContent({
    required String postId,
    required String languageCode,
    required String title,
    required String content,
    required List<String> imageUrls,
    List<dynamic>? bodyDelta,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('未登录');
    }

    final trimmedTitle = title.trim();
    final trimmedContent = content.trim();

    if (trimmedTitle.isEmpty) {
      throw Exception('标题不能为空');
    }

    if (trimmedContent.isEmpty) {
      throw Exception('内容不能为空');
    }

    await _postApi.updateLanguageVersion(
      postId: postId,
      languageCode: languageCode,
      title: trimmedTitle,
      content: trimmedContent,
      bodyDelta: bodyDelta,
      images: imageUrls,
    );
  }

  Future<List<Map<String, dynamic>>> getEditHistory(String postId) {
    return _postApi.getEditHistory(postId);
  }

  Future<Set<String>> _blockedUserIds() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return const <String>{};
    }

    final snapshot = await _firestore.collection('blocks').doc(userId).get();
    final data = snapshot.data();
    if (data == null) {
      return const <String>{};
    }

    return data.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toSet();
  }

  Future<List<PostModel>> _filterBlockedAuthors(List<PostModel> posts) async {
    final blocked = await _blockedUserIds();
    return _filterWithBlockedSet(posts, blocked);
  }

  List<PostModel> _filterWithBlockedSet(
    List<PostModel> posts,
    Set<String> blocked,
  ) {
    if (blocked.isEmpty) {
      return posts;
    }

    return posts
        .where(
          (post) => post.userId == null || !blocked.contains(post.userId),
        )
        .toList(growable: false);
  }
}
