import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/post/data/mappers/post_model_mapper.dart';
import 'package:glyphora_mobile/features/post/domain/models/post_model.dart';

void main() {
  group('PostModelMapper', () {
    test('maps Node API payload with ISO timestamps', () {
      final createdAt = DateTime.utc(2026, 9, 1, 10, 30);
      final updatedAt = DateTime.utc(2026, 9, 1, 11, 45);

      final post = PostModelMapper.fromMap({
        'id': 'post-1',
        'userId': 'user-1',
        'title': 'Hello',
        'content': 'World',
        'category': 'legacy-category',
        'languageCode': 'en',
        'availableLanguageCodes': ['en', 'zh'],
        'images': ['https://example.com/image.jpg'],
        'likeCount': 3,
        'commentCount': 2,
        'isBookmarked': true,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      });

      expect(post.id, 'post-1');
      expect(post.userId, 'user-1');
      expect(post.categoryId, 'legacy-category');
      expect(post.categoryPath, ['legacy-category']);
      expect(post.primaryLanguageCode, 'en');
      expect(post.availableLanguageCodes, ['en', 'zh']);
      expect(post.createdAt, createdAt);
      expect(post.updatedAt, updatedAt);
      expect(post.isBookmarked, isTrue);
    });

    test('normalizes legacy Firestore uid and Timestamp values', () {
      final createdAt = DateTime.utc(2025, 1, 2, 3, 4, 5);

      final post = PostModelMapper.fromMap({
        'id': 'legacy-post',
        'uid': 'firebase-user',
        'category': 'legacy-category',
        'languageCode': 'vi',
        'timestamp': Timestamp.fromDate(createdAt),
      });

      expect(post.userId, 'firebase-user');
      expect(post.categoryId, 'legacy-category');
      expect(post.categoryPath, ['legacy-category']);
      expect(post.availableLanguageCodes, ['vi']);
      expect(
        post.createdAt?.millisecondsSinceEpoch,
        createdAt.millisecondsSinceEpoch,
      );
    });

    test('keeps Firestore serialization inside the data mapper', () {
      final createdAt = DateTime.utc(2026, 2, 3, 4, 5, 6);
      final updatedAt = DateTime.utc(2026, 2, 4, 5, 6, 7);
      final post = PostModel(
        id: 'post-2',
        userId: 'user-2',
        title: 'Title',
        content: 'Content',
        category: 'technology',
        languageCode: 'en',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final data = PostModelMapper.toFirestoreMap(post);

      expect(data['uid'], 'user-2');
      expect(data['timestamp'], isA<Timestamp>());
      expect(
        (data['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch,
        createdAt.millisecondsSinceEpoch,
      );
      expect(data['updatedAt'], isA<Timestamp>());
      expect(
        (data['updatedAt'] as Timestamp).toDate().millisecondsSinceEpoch,
        updatedAt.millisecondsSinceEpoch,
      );
    });
  });
}
