import 'package:image_picker/image_picker.dart';

import '../models/post_model.dart';

/// Domain boundary for post operations used by the Flutter client.
///
/// Presentation code depends on this contract instead of constructing data
/// services directly. The concrete implementation lives in the data layer.
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

  Future<List<String>> uploadImages(String postId, List<XFile> images);

  Future<void> updateImages(String postId, List<String> imageUrls);

  Future<void> deleteImageFromStorage(String imageUrl);

  Future<void> removeImage(String postId, List<String> imageUrls);
}
