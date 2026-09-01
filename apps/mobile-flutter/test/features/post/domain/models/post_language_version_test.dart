import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/post/domain/models/post_language_version.dart';

void main() {
  group('PostLanguageVersion', () {
    test('parses API payload into typed domain data', () {
      final version = PostLanguageVersion.fromJson({
        'languageCode': 'vi',
        'title': 'Xin chào',
        'content': 'Nội dung',
        'bodyDelta': [
          {'insert': 'Nội dung\n'},
        ],
        'type': 'manual',
        'createdAt': '2026-09-01T08:00:00.000Z',
        'updatedAt': '2026-09-01T09:00:00.000Z',
      });

      expect(version.languageCode, 'vi');
      expect(version.title, 'Xin chào');
      expect(version.content, 'Nội dung');
      expect(version.bodyDelta, hasLength(1));
      expect(version.type, 'manual');
      expect(version.createdAt, DateTime.utc(2026, 9, 1, 8));
      expect(version.updatedAt, DateTime.utc(2026, 9, 1, 9));
    });

    test('uses safe defaults for optional malformed fields', () {
      final version = PostLanguageVersion.fromJson({
        'languageCode': 'en',
        'bodyDelta': 'not-a-list',
        'createdAt': 'not-a-date',
      });

      expect(version.languageCode, 'en');
      expect(version.title, '');
      expect(version.content, '');
      expect(version.bodyDelta, isEmpty);
      expect(version.type, '');
      expect(version.createdAt, isNull);
      expect(version.updatedAt, isNull);
    });
  });
}
