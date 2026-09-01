import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/forum_categories.dart';
import '../../domain/models/post_model.dart';

/// Converts post transport/persistence maps into the pure domain model.
///
/// Node responses use ISO-8601 strings while legacy Firestore-backed data can
/// still contain [Timestamp] values. Both formats are normalized here so
/// transport details never leak into [PostModel].
final class PostModelMapper {
  const PostModelMapper._();

  static PostModel fromMap(Map<String, dynamic> data) {
    final legacyCategory = data['category']?.toString();
    final categoryId = data['categoryId']?.toString() ?? legacyCategory;

    final rawCategoryPath =
        (data['categoryPath'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList() ??
        const <String>[];

    final derivedCategoryPath = categoryId == null || categoryId.isEmpty
        ? const <String>[]
        : ForumCategories.pathOf(categoryId);

    return PostModel(
      id: data['id']?.toString() ?? '',
      userId: data['uid']?.toString() ?? data['userId']?.toString(),
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      bodyDelta:
          (data['bodyDelta'] as List<dynamic>?)?.map((item) => item).toList() ??
          const [],
      category: legacyCategory,
      categoryId: categoryId,
      categoryPath: rawCategoryPath.isNotEmpty
          ? rawCategoryPath
          : derivedCategoryPath.isNotEmpty
          ? derivedCategoryPath
          : [
              if (legacyCategory != null && legacyCategory.isNotEmpty)
                legacyCategory,
            ],
      languageCode: data['languageCode']?.toString(),
      primaryLanguageCode:
          data['primaryLanguageCode']?.toString() ??
          data['languageCode']?.toString(),
      availableLanguageCodes:
          (data['availableLanguageCodes'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [if (data['languageCode'] != null) data['languageCode'].toString()],
      imageUrls: (data['images'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
      likes: (data['likes'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      isBookmarked: data['isBookmarked'] == true,
      createdAt: _toDateTime(data['timestamp'] ?? data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  static Map<String, dynamic> toFirestoreMap(PostModel post) {
    return <String, dynamic>{
      'uid': post.userId,
      'title': post.title,
      'content': post.content,
      'bodyDelta': post.bodyDelta,
      'category': post.category,
      'categoryId': post.categoryId,
      'categoryPath': post.categoryPath,
      'languageCode': post.languageCode,
      'primaryLanguageCode': post.primaryLanguageCode,
      'availableLanguageCodes': post.availableLanguageCodes,
      'images': post.imageUrls,
      'likes': post.likes,
      'likeCount': post.likeCount,
      'commentCount': post.commentCount,
      'isBookmarked': post.isBookmarked,
      'timestamp': post.createdAt == null
          ? null
          : Timestamp.fromDate(post.createdAt!),
      'updatedAt': post.updatedAt == null
          ? null
          : Timestamp.fromDate(post.updatedAt!),
    }..removeWhere((key, value) => value == null);
  }

  static DateTime? _toDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
