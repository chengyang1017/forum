import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:glyphora_mobile/features/post/domain/models/post_edit_history_entry.dart';
import 'package:glyphora_mobile/features/post/domain/models/post_language_version.dart';
import 'package:glyphora_mobile/features/post/domain/models/post_model.dart';
import 'package:glyphora_mobile/features/post/domain/repositories/post_repository.dart';

void main() {
  group('FeedCubit', () {
    late _FakePostRepository repository;
    late FeedCubit cubit;

    setUp(() {
      repository = _FakePostRepository();
      cubit = FeedCubit(repository: repository);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('delegates watchPosts with category and language', () async {
      final posts = [PostModel(id: 'post-1')];
      repository.watchResult = posts;

      final result = await cubit
          .watchPosts(category: 'technology', languageCode: 'zh')
          .first;

      expect(result, same(posts));
      expect(repository.lastCategory, 'technology');
      expect(repository.lastLanguageCode, 'zh');
    });

    test('refreshPosts returns to idle after repository success', () async {
      await cubit.refreshPosts(category: 'technology', languageCode: 'en');

      expect(repository.lastCategory, 'technology');
      expect(repository.lastLanguageCode, 'en');
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);
    });

    test('refreshPosts stores repository errors without rethrowing', () async {
      repository.refreshError = StateError('refresh failed');

      await cubit.refreshPosts(category: 'technology', languageCode: 'en');

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, contains('refresh failed'));
    });

    test('getPost returns the repository result', () async {
      final post = PostModel(id: 'post-2');
      repository.postResult = post;

      final result = await cubit.getPost('post-2');

      expect(result, same(post));
      expect(repository.lastPostId, 'post-2');
    });

    test('createPost delegates and returns to idle', () async {
      final post = PostModel(id: 'post-3');

      await cubit.createPost(post);

      expect(repository.lastCreatedPost, same(post));
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);
    });

    test('createPost stores errors, returns to idle, and rethrows', () async {
      repository.createError = StateError('create failed');
      final post = PostModel(id: 'post-4');

      await expectLater(cubit.createPost(post), throwsA(isA<StateError>()));

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, contains('create failed'));
    });
  });
}

final class _FakePostRepository implements PostRepository {
  List<PostModel> watchResult = const <PostModel>[];
  Object? refreshError;
  Object? createError;
  PostModel? postResult;
  String? lastCategory;
  String? lastLanguageCode;
  String? lastPostId;
  PostModel? lastCreatedPost;

  @override
  Stream<List<PostModel>> watchPosts({
    required String category,
    required String languageCode,
  }) {
    lastCategory = category;
    lastLanguageCode = languageCode;
    return Stream.value(watchResult);
  }

  @override
  Future<void> refreshPosts({
    required String category,
    required String languageCode,
  }) async {
    lastCategory = category;
    lastLanguageCode = languageCode;
    final error = refreshError;
    if (error != null) throw error;
  }

  @override
  Future<void> createPost(PostModel post) async {
    lastCreatedPost = post;
    final error = createError;
    if (error != null) throw error;
  }

  @override
  Future<PostModel> getPost(String postId) async {
    lastPostId = postId;
    return postResult ?? PostModel(id: postId);
  }

  @override
  Stream<List<PostModel>> watchUserPosts(String userId) => const Stream.empty();

  @override
  Future<List<PostModel>> getPosts({
    required String category,
    required String languageCode,
  }) async => const <PostModel>[];

  @override
  Future<void> addLanguageVersion({
    required String postId,
    required String languageCode,
    required String languageName,
    required String title,
    required String content,
    required String type,
    List<dynamic> bodyDelta = const [],
  }) async {}

  @override
  Future<PostLanguageVersion> getLanguageVersion({
    required String postId,
    required String languageCode,
  }) => throw UnimplementedError();

  @override
  Future<void> updateLanguageVersionContent({
    required String postId,
    required String languageCode,
    required String title,
    required String content,
    required List<String> imageUrls,
    List<dynamic>? bodyDelta,
  }) async {}

  @override
  Future<PostModel> updatePost(String postId, {required String content}) =>
      throw UnimplementedError();

  @override
  Future<int> toggleLike(String postId, {required bool liked}) async => 0;

  @override
  Future<bool> toggleBookmark(String postId, {required bool bookmarked}) async =>
      bookmarked;

  @override
  Future<List<PostModel>> getBookmarkedPosts() async => const <PostModel>[];

  @override
  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {}

  @override
  Future<List<PostEditHistoryEntry>> getEditHistory(String postId) async =>
      const <PostEditHistoryEntry>[];

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<void> updateImages(String postId, List<String> imageUrls) async {}
}
