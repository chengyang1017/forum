import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../post/data/repositories/post_repository.dart';
import '../../../post/domain/models/post_model.dart';

class FeedProvider extends ChangeNotifier {
  final PostRepository _postRepo = PostRepository();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========== 监听帖子列表（实时） ==========
  Stream<List<PostModel>> watchPosts({
    required String category,
    required String languageCode,
    String? currentUserId,
  }) {
    return _postRepo.watchPosts(category: category, languageCode: languageCode);
  }

  // ========== 刷新帖子列表 ==========
  Future<void> refreshPosts({
    required String category,
    required String languageCode,
    String? currentUserId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _postRepo.refreshPosts(
        category: category,
        languageCode: languageCode,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== 获取单篇帖子 ==========
  Future<PostModel> getPost(String postId) {
    return _postRepo.getPost(postId);
  }

  // ========== 创建帖子 ==========
  Future<void> createPost(PostModel post) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _postRepo.createPost(post);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
