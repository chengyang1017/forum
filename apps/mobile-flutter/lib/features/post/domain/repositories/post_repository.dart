import '../models/post_edit_history_entry.dart';
import '../models/post_language_version.dart';
import '../models/post_model.dart';

/// Domain boundary for post business operations used by the Flutter client.
///
/// Framework and infrastructure types must not leak through this contract.
/// Media upload concerns live behind a separate application port.
abstract interface class PostRepository {
  Stream<List<PostModel>> watchPosts({
    required String category,
    required String languageCode,
  });

  Stream<List<PostModel>> watchUserPosts(String userId);

  Future<List<PostModel>> getPosts({
    required String category,
    required String languageCode,
  });

  Future<void> refreshPosts({
    required String category,
    required String languageCode,
  });

  Future<void> createPost(PostModel post);

  Future<PostModel> getPost(String postId);

  Future<void> addLanguageVersion({
    required String postId,
    required String languageCode,
    required String languageName,
    required String title,
    required String content,
    required String type,
    List<dynamic> bodyDelta = const [],
  });

  Future<PostLanguageVersion> getLanguageVersion({
    required String postId,
    required String languageCode,
  });

  Future<void> updateLanguageVersionContent({
    required String postId,
    required String languageCode,
    required String title,
    required String content,
    required List<String> imageUrls,
    List<dynamic>? bodyDelta,
  });

  Future<PostModel> updatePost(String postId, {required String content});

  Future<int> toggleLike(String postId, {required bool liked});

  Future<bool> toggleBookmark(String postId, {required bool bookmarked});

  Future<List<PostModel>> getBookmarkedPosts();

  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  });

  Future<List<PostEditHistoryEntry>> getEditHistory(String postId);

  Future<void> deletePost(String postId);

  Future<void> updateImages(String postId, List<String> imageUrls);
}
