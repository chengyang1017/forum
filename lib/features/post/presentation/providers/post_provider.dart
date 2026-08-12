import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart'; // ✅ 导入 XFile
import '../../data/repositories/post_repository.dart';
import '../../domain/models/post_model.dart';

class PostProvider extends ChangeNotifier {
  final PostRepository _postRepo = PostRepository();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========== 获取单篇帖子 ==========
  Future<PostModel> getPost(String postId) async {
    return _postRepo.getPost(postId);
  }

  // ========== 更新帖子 ==========
  Future<PostModel> updatePost(String postId, {required String content}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final post = await _postRepo.updatePost(postId, content: content);
      return post;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== 点赞/取消点赞 ==========
  Future<void> toggleLike(String postId, String userId) async {
    await _postRepo.toggleLike(postId, userId);
  }

  // ========== 删除帖子 ==========
  Future<void> deletePost(String postId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _postRepo.deletePost(postId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== 上传图片 ==========
  Future<List<String>> uploadImages(String postId, List<XFile> images) async {
    return _postRepo.uploadImages(postId, images);
  }

  // ========== 更新图片列表 ==========
  Future<void> updateImages(String postId, List<String> imageUrls) async {
    await _postRepo.updateImages(postId, imageUrls);
  }

  // ========== 移除图片（存储） ==========
  Future<void> deleteImageFromStorage(String imageUrl) async {
    await _postRepo.deleteImageFromStorage(imageUrl);
  }

  // ========== 移除图片（Firestore） ==========
  Future<void> removeImage(String postId, List<String> imageUrls) async {
    await _postRepo.removeImage(postId, imageUrls);
  }

  void clear() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
