import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/models/local_post_image.dart';
import '../../application/ports/post_media_repository.dart';
import '../../domain/models/post_model.dart';
import '../../domain/repositories/post_repository.dart';

class PostProvider extends ChangeNotifier {
  PostProvider({
    required PostRepository repository,
    required PostMediaRepository mediaRepository,
  }) : _repository = repository,
       _mediaRepository = mediaRepository;

  final PostRepository _repository;
  final PostMediaRepository _mediaRepository;

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

  Future<PostModel> getPost(String postId) {
    return _repository.getPost(postId);
  }

  Future<PostModel> updatePost(String postId, {required String content}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _repository.updatePost(postId, content: content);
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> toggleLike(String postId, {required bool liked}) {
    return _repository.toggleLike(postId, liked: liked);
  }

  Future<bool> toggleBookmark(String postId, {required bool bookmarked}) async {
    final hadPrevious = _bookmarkStates.containsKey(postId);
    final previous = _bookmarkStates[postId];

    _bookmarkStates[postId] = bookmarked;
    notifyListeners();

    try {
      final confirmed = await _repository.toggleBookmark(
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

  Future<void> deletePost(String postId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deletePost(postId);
    } catch (error) {
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> uploadImages(String postId, List<XFile> images) {
    final media = images
        .map((image) => LocalPostImage(path: image.path, name: image.name))
        .toList(growable: false);

    return _mediaRepository.uploadImages(postId, media);
  }

  Future<void> updateImages(String postId, List<String> imageUrls) {
    return _repository.updateImages(postId, imageUrls);
  }

  Future<void> deleteImageFromStorage(String imageUrl) {
    return _mediaRepository.deleteImage(imageUrl);
  }

  Future<void> removeImage(String postId, List<String> imageUrls) {
    return _repository.updateImages(postId, imageUrls);
  }

  void clear() {
    _isLoading = false;
    _error = null;
    _bookmarkStates.clear();
    notifyListeners();
  }
}
