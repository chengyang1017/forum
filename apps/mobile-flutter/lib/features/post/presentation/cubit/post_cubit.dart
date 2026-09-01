import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/models/local_post_image.dart';
import '../../application/ports/post_media_repository.dart';
import '../../domain/models/post_model.dart';
import '../../domain/repositories/post_repository.dart';
import 'post_state.dart';

class PostCubit extends Cubit<PostState> {
  PostCubit({
    required PostRepository repository,
    required PostMediaRepository mediaRepository,
  }) : _repository = repository,
       _mediaRepository = mediaRepository,
       super(const PostState());

  final PostRepository _repository;
  final PostMediaRepository _mediaRepository;

  bool bookmarkState(String postId, {required bool fallback}) {
    return state.bookmarkStates[postId] ?? fallback;
  }

  void seedBookmarkState(String postId, bool bookmarked) {
    if (state.bookmarkStates.containsKey(postId)) {
      return;
    }

    final next = Map<String, bool>.from(state.bookmarkStates)
      ..[postId] = bookmarked;
    emit(state.copyWith(bookmarkStates: next));
  }

  Future<PostModel> getPost(String postId) {
    return _repository.getPost(postId);
  }

  Future<PostModel> updatePost(String postId, {required String content}) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      return await _repository.updatePost(postId, content: content);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
      rethrow;
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<int> toggleLike(String postId, {required bool liked}) {
    return _repository.toggleLike(postId, liked: liked);
  }

  Future<bool> toggleBookmark(String postId, {required bool bookmarked}) async {
    final previousStates = state.bookmarkStates;
    final optimisticStates = Map<String, bool>.from(previousStates)
      ..[postId] = bookmarked;
    emit(state.copyWith(bookmarkStates: optimisticStates));

    try {
      final confirmed = await _repository.toggleBookmark(
        postId,
        bookmarked: bookmarked,
      );
      final confirmedStates = Map<String, bool>.from(state.bookmarkStates)
        ..[postId] = confirmed;
      emit(state.copyWith(bookmarkStates: confirmedStates));
      return confirmed;
    } catch (_) {
      emit(state.copyWith(bookmarkStates: previousStates));
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _repository.deletePost(postId);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
      rethrow;
    } finally {
      emit(state.copyWith(isLoading: false));
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
    emit(const PostState());
  }
}
