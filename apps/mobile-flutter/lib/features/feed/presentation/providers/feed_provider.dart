import 'package:flutter/foundation.dart';

import '../../../post/domain/models/post_model.dart';
import '../../../post/domain/repositories/post_repository.dart';

class FeedProvider extends ChangeNotifier {
  FeedProvider({required PostRepository repository})
    : _repository = repository;

  final PostRepository _repository;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<PostModel>> watchPosts({
    required String category,
    required String languageCode,
    String? currentUserId,
  }) {
    return _repository.watchPosts(
      category: category,
      languageCode: languageCode,
    );
  }

  Future<void> refreshPosts({
    required String category,
    required String languageCode,
    String? currentUserId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.refreshPosts(
        category: category,
        languageCode: languageCode,
      );
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PostModel> getPost(String postId) {
    return _repository.getPost(postId);
  }

  Future<void> createPost(PostModel post) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createPost(post);
    } catch (error) {
      _error = error.toString();
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
