import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/post/domain/models/post_edit_history_entry.dart';

void main() {
  group('PostEditHistoryEntry', () {
    test('parses a complete API history payload', () {
      final entry = PostEditHistoryEntry.fromJson({
        'languageCode': 'vi',
        'title': 'Tiêu đề',
        'content': 'Nội dung',
        'bodyDelta': [
          {'insert': 'Nội dung\n'},
        ],
        'imageUrls': ['https://example.test/image.png'],
        'editedAt': '2026-09-01T08:00:00.000Z',
      });

      expect(entry.languageCode, 'vi');
      expect(entry.title, 'Tiêu đề');
      expect(entry.content, 'Nội dung');
      expect(entry.bodyDelta, hasLength(1));
      expect(entry.imageUrls, ['https://example.test/image.png']);
      expect(entry.editedAt, DateTime.utc(2026, 9, 1, 8));
    });

    test('uses safe defaults for incomplete payloads', () {
      final entry = PostEditHistoryEntry.fromJson(const <String, dynamic>{});

      expect(entry.languageCode, isEmpty);
      expect(entry.title, isEmpty);
      expect(entry.content, isEmpty);
      expect(entry.bodyDelta, isEmpty);
      expect(entry.imageUrls, isEmpty);
      expect(entry.editedAt, isNull);
    });
  });
}
