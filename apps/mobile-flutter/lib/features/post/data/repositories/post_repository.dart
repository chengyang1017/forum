import 'package:image_picker/image_picker.dart'; // ✅ 导入 XFile
import '../../domain/models/post_model.dart';
import '../services/post_node_service.dart';

class PostRepository {
  final PostService _postService = PostService();

  // ========== 监听帖子列表（实时） ==========
  Stream<List<PostModel>> watchPosts({
    required String category,
    required String languageCode,
  }) {
    return _postService.watchPosts(
      category: category,
      languageCode: languageCode,
    );
  }

  // ========== 刷新帖子列表 ==========
  Future<void> refreshPosts({
    required String category,
    required String languageCode,
  }) async {
    await _postService.refreshPosts(
      category: category,
      languageCode: languageCode,
    );
  }

  // ========== 创建帖子 ==========
  Future<void> createPost(PostModel post) async {
    await _postService.createPost(post);
  }

  // ========== 获取单篇帖子 ==========
  // Future<PostModel> getPost(String postId) async {
  //   final data = await _postService.getPost(postId);
  //   return PostModel.fromJson(data);
  // }

  Future<PostModel> getPost(String postId) {
    return _postService.getPost(postId);
  }

  // ========== 更新帖子 ==========
  // Future<PostModel> updatePost(String postId, {required String content}) async {
  //   await _postService.updatePost(postId, content: content);
  //   final data = await _postService.getPost(postId);
  //   return PostModel.fromJson(data);
  // }

  Future<PostModel> updatePost(String postId, {required String content}) async {
    await _postService.updatePost(postId, content: content);

    return _postService.getPost(postId);
  }

  // ========== 点赞/取消点赞 ==========
  Future<int> toggleLike(String postId, {required bool liked}) {
    return _postService.toggleLike(postId, liked: liked);
  }

  // ========== 收藏/取消收藏 ==========
  Future<bool> toggleBookmark(String postId, {required bool bookmarked}) {
    return _postService.toggleBookmark(postId, bookmarked: bookmarked);
  }

  // ========== 删除帖子 ==========
  Future<void> deletePost(String postId) async {
    await _postService.deletePost(postId);
  }

  // ========== 上传图片 ==========
  Future<List<String>> uploadImages(String postId, List<XFile> images) async {
    return _postService.uploadImages(postId, images);
  }

  // ========== 更新图片列表 ==========
  Future<void> updateImages(String postId, List<String> imageUrls) async {
    await _postService.updateImages(postId, imageUrls);
  }

  // ========== 移除图片（存储） ==========
  Future<void> deleteImageFromStorage(String imageUrl) async {
    await _postService.deleteImageFromStorage(imageUrl);
  }

  // ========== 移除图片 ==========
  Future<void> removeImage(String postId, List<String> imageUrls) async {
    await _postService.removeImage(postId, imageUrls);
  }
}
