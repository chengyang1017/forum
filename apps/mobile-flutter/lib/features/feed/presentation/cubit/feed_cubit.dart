import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../post/domain/models/post_model.dart';
import '../../../post/domain/repositories/post_repository.dart';
import 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  FeedCubit({required PostRepository repository})
    : _repository = repository,
      super(const FeedState());

  final PostRepository _repository;

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
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _repository.refreshPosts(
        category: category,
        languageCode: languageCode,
      );
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<PostModel> getPost(String postId) {
    return _repository.getPost(postId);
  }

  Future<void> createPost(PostModel post) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      await _repository.createPost(post);
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
      rethrow;
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  void clear() {
    emit(const FeedState());
  }
}
