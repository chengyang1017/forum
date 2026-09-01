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

  Future<void> refreshPosts({
    required String category,
    required String languageCode,
  });

  Future<void> createPost(PostModel post);

  Future<PostModel> getPost(String postId);

  Future<PostModel> updatePost(String postId, {required String content});

  Future<int> toggleLike(String postId, {required bool liked});

  Future<bool> toggleBookmark(String postId, {required bool bookmarked});

  Future<void> deletePost(String postId);

  Future<void> updateImages(String postId, List<String> imageUrls);
}
