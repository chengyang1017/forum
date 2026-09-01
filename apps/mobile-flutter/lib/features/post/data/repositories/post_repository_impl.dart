import '../../domain/models/post_model.dart';
import '../../domain/repositories/post_repository.dart';
import '../services/post_node_service.dart';

/// Data-layer implementation of [PostRepository].
///
/// This adapter keeps transport details behind the domain boundary so
/// presentation code can be tested without concrete API clients.
final class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({PostService? service})
    : _service = service ?? PostService();

  final PostService _service;

  @override
  Stream<List<PostModel>> watchPosts({
    required String category,
    required String languageCode,
  }) {
    return _service.watchPosts(category: category, languageCode: languageCode);
  }

  @override
  Future<void> refreshPosts({
    required String category,
    required String languageCode,
  }) {
    return _service.refreshPosts(
      category: category,
      languageCode: languageCode,
    );
  }

  @override
  Future<void> createPost(PostModel post) {
    return _service.createPost(post);
  }

  @override
  Future<PostModel> getPost(String postId) {
    return _service.getPost(postId);
  }

  @override
  Future<PostModel> updatePost(String postId, {required String content}) async {
    await _service.updatePost(postId, content: content);
    return _service.getPost(postId);
  }

  @override
  Future<int> toggleLike(String postId, {required bool liked}) {
    return _service.toggleLike(postId, liked: liked);
  }

  @override
  Future<bool> toggleBookmark(String postId, {required bool bookmarked}) {
    return _service.toggleBookmark(postId, bookmarked: bookmarked);
  }

  @override
  Future<void> deletePost(String postId) {
    return _service.deletePost(postId);
  }

  @override
  Future<void> updateImages(String postId, List<String> imageUrls) {
    return _service.updateImages(postId, imageUrls);
  }
}
