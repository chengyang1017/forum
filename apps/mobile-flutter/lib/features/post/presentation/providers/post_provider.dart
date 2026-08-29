import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart'; // ✅ 导入 XFile
import '../../data/repositories/post_repository.dart';
import '../../domain/models/post_model.dart';

class PostProvider extends ChangeNotifier {
  final PostRepository _postRepo = PostRepository();

  bool _isLoading = false;
  String? _error;

  final Map<String, bool> _bookmarkStates = <String, bool>{};

  bool get isLoading => _isLoading;
  String? get error => _error;

  bool bookmarkState(String postId, {required bool fallback}) {
    return _bookmarkStates[postId] ?? fallback;
  }

  void seedBookmarkState(String postId, bool bookmarked) {
    _bookmarkStates.putIfAbsent(postId, () => bookmarked);
  }

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
  Future<int> toggleLike(String postId, {required bool liked}) {
    return _postRepo.toggleLike(postId, liked: liked);
  }

  // ========== 收藏/取消收藏 ==========
  Future<bool> toggleBookmark(String postId, {required bool bookmarked}) async {
    final hadPrevious = _bookmarkStates.containsKey(postId);

    final previous = _bookmarkStates[postId];

    // 全局乐观更新。
    // 所有正在监听 PostProvider 的页面立即同步。
    _bookmarkStates[postId] = bookmarked;
    notifyListeners();

    try {
      final confirmed = await _postRepo.toggleBookmark(
        postId,
        bookmarked: bookmarked,
      );

      _bookmarkStates[postId] = confirmed;
      notifyListeners();

      return confirmed;
    } catch (_) {
      if (hadPrevious) {
        _bookmarkStates[postId] = previous!;
      } else {
        _bookmarkStates.remove(postId);
      }

      notifyListeners();
      rethrow;
    }
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
    _bookmarkStates.clear();
    notifyListeners();
  }
}
