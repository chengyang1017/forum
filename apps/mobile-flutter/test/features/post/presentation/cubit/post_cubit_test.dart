import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:glyphora_mobile/features/post/application/models/local_post_image.dart';
import 'package:glyphora_mobile/features/post/application/ports/post_media_repository.dart';
import 'package:glyphora_mobile/features/post/domain/models/post_edit_history_entry.dart';
import 'package:glyphora_mobile/features/post/domain/models/post_language_version.dart';
import 'package:glyphora_mobile/features/post/domain/models/post_model.dart';
import 'package:glyphora_mobile/features/post/domain/repositories/post_repository.dart';
import 'package:glyphora_mobile/features/post/presentation/cubit/post_cubit.dart';

void main() {
  group('PostCubit', () {
    late _FakePostRepository repository;
    late _FakePostMediaRepository mediaRepository;
    late PostCubit cubit;

    setUp(() {
      repository = _FakePostRepository();
      mediaRepository = _FakePostMediaRepository();
      cubit = PostCubit(
        repository: repository,
        mediaRepository: mediaRepository,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test(
      'rolls back optimistic bookmark state when persistence fails',
      () async {
        cubit.seedBookmarkState('post-1', false);
        repository.bookmarkError = StateError('failed');

        await expectLater(
          cubit.toggleBookmark('post-1', bookmarked: true),
          throwsA(isA<StateError>()),
        );

        expect(cubit.bookmarkState('post-1', fallback: true), isFalse);
      },
    );

    test('uses the bookmark state confirmed by the repository', () async {
      cubit.seedBookmarkState('post-1', false);
      repository.bookmarkResult = false;

      final result = await cubit.toggleBookmark('post-1', bookmarked: true);

      expect(result, isFalse);
      expect(cubit.bookmarkState('post-1', fallback: true), isFalse);
    });

    test('maps plugin files to framework-neutral media requests', () async {
      final source = XFile('/tmp/example.png');

      final urls = await cubit.uploadImages('post-1', [source]);

      expect(urls, ['https://example.test/image.png']);
      expect(mediaRepository.lastPostId, 'post-1');
      expect(mediaRepository.lastImages, hasLength(1));
      expect(mediaRepository.lastImages.single.path, source.path);
      expect(mediaRepository.lastImages.single.name, source.name);
    });

    test('delegates storage deletion to the media repository', () async {
      await cubit.deleteImageFromStorage('https://example.test/image.png');

      expect(
        mediaRepository.lastDeletedImageUrl,
        'https://example.test/image.png',
      );
    });
  });
}

final class _FakePostRepository implements PostRepository {
  bool? bookmarkResult;
  Object? bookmarkError;

  @override
  Stream<List<PostModel>> watchPosts({
    required String category,
    required String languageCode,
  }) {
    return const Stream.empty();
  }

  @override
  Stream<List<PostModel>> watchUserPosts(String userId) {
    return const Stream.empty();
  }

  @override
  Future<List<PostModel>> getPosts({
    required String category,
    required String languageCode,
  }) async {
    return const <PostModel>[];
  }

  @override
  Future<void> refreshPosts({
    required String category,
    required String languageCode,
  }) async {}

  @override
  Future<void> createPost(PostModel post) {
    throw UnimplementedError();
  }

  @override
  Future<PostModel> getPost(String postId) {
    throw UnimplementedError();
  }

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
  }) {
    throw UnimplementedError();
  }

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
  Future<PostModel> updatePost(String postId, {required String content}) {
    throw UnimplementedError();
  }

  @override
  Future<int> toggleLike(String postId, {required bool liked}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> toggleBookmark(String postId, {required bool bookmarked}) async {
    final error = bookmarkError;

    if (error != null) {
      throw error;
    }

    return bookmarkResult ?? bookmarked;
  }

  @override
  Future<List<PostModel>> getBookmarkedPosts() async {
    return const <PostModel>[];
  }

  @override
  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {}

  @override
  Future<List<PostEditHistoryEntry>> getEditHistory(String postId) async {
    return const <PostEditHistoryEntry>[];
  }

  @override
  Future<void> deletePost(String postId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateImages(String postId, List<String> imageUrls) async {}
}

final class _FakePostMediaRepository implements PostMediaRepository {
  String? lastPostId;
  List<LocalPostImage> lastImages = const [];
  String? lastDeletedImageUrl;

  @override
  Future<List<String>> uploadImages(
    String postId,
    List<LocalPostImage> images, {
    PostUploadProgress? onProgress,
  }) async {
    lastPostId = postId;
    lastImages = List.unmodifiable(images);
    onProgress?.call(1);
    return const ['https://example.test/image.png'];
  }

  @override
  Future<String> uploadTopImage(String postId, LocalPostImage image) async {
    return 'https://example.test/top.png';
  }

  @override
  Future<String> uploadInlineImage(String postId, LocalPostImage image) async {
    return 'https://example.test/inline.png';
  }

  @override
  Future<String> copyInlineImageToPost(
    String postId,
    String sourceImageUrl, {
    int maxBytes = 15 * 1024 * 1024,
  }) async {
    return 'https://example.test/copied-inline.png';
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    lastDeletedImageUrl = imageUrl;
  }
}
