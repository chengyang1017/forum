import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/post/application/models/post_edit_media_cleanup_plan.dart';

void main() {
  group('PostEditMediaCleanupPlan', () {
    test('cleans removed persisted top and inline images after save', () {
      final plan = PostEditMediaCleanupPlan.fromEdit(
        originalTopImageUrls: const [
          'https://example.test/top-kept.png',
          'https://example.test/top-removed.png',
        ],
        originalBodyDelta: const [
          {
            'insert': {'image': 'https://example.test/inline-removed.png'},
          },
          {'insert': 'text\n'},
        ],
        currentTopImageUrls: const ['https://example.test/top-kept.png'],
        currentBodyDelta: const [
          {'insert': 'text\n'},
        ],
        newUploadUrls: const [],
      );

      expect(plan.cleanupAfterSaveUrls.toSet(), {
        'https://example.test/top-removed.png',
        'https://example.test/inline-removed.png',
      });
    });

    test('keeps referenced new uploads and cleans discarded ones', () {
      final plan = PostEditMediaCleanupPlan.fromEdit(
        originalTopImageUrls: const [],
        originalBodyDelta: const [],
        currentTopImageUrls: const ['https://example.test/new-top.png'],
        currentBodyDelta: const [
          {
            'insert': {'image': 'https://example.test/new-inline.png'},
          },
        ],
        newUploadUrls: const [
          'https://example.test/new-top.png',
          'https://example.test/new-inline.png',
          'https://example.test/discarded.png',
        ],
      );

      expect(plan.newUploadUrls.toSet(), {
        'https://example.test/new-top.png',
        'https://example.test/new-inline.png',
        'https://example.test/discarded.png',
      });
      expect(plan.cleanupAfterSaveUrls, ['https://example.test/discarded.png']);
    });

    test('ignores malformed delta entries and blank urls', () {
      final plan = PostEditMediaCleanupPlan.fromEdit(
        originalTopImageUrls: const ['', '   '],
        originalBodyDelta: const [
          'invalid',
          {'insert': 7},
          {
            'insert': {'image': 42},
          },
          {
            'insert': {'image': '  https://example.test/image.png  '},
          },
        ],
        currentTopImageUrls: const [],
        currentBodyDelta: const [],
        newUploadUrls: const ['', '   '],
      );

      expect(plan.cleanupAfterSaveUrls, ['https://example.test/image.png']);
      expect(plan.newUploadUrls, isEmpty);
    });
  });
}
