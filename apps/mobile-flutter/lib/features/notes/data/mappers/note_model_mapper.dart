import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/forum_categories.dart';
import '../../domain/models/note_model.dart';

final class NoteModelMapper {
  const NoteModelMapper._();

  static NoteModel fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    final legacyCategory = data['category']?.toString();
    final categoryId = data['categoryId']?.toString() ?? legacyCategory;

    final rawCategoryPath =
        (data['categoryPath'] as List<dynamic>?)
            ?.map((value) => value.toString())
            .where((value) => value.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];

    final derivedCategoryPath = categoryId == null || categoryId.isEmpty
        ? const <String>[]
        : ForumCategories.pathOf(categoryId);

    return NoteModel(
      id: document.id,
      ownerId: data['ownerId']?.toString() ?? '',
      participantIds: _stringList(data['participantIds']),
      sharedUserIds: _stringList(data['sharedUserIds']),
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      bodyDelta: data['bodyDelta'] is List
          ? List<dynamic>.from(data['bodyDelta'] as List)
          : const <dynamic>[
              <String, dynamic>{'insert': '\n'},
            ],
      sourceType: data['sourceType']?.toString() ?? 'manual',
      sourceId: data['sourceId']?.toString(),
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
      allowOthersEdit: data['allowOthersEdit'] as bool? ?? false,
      createdAt: _dateTime(data['createdAt']),
      updatedAt: _dateTime(data['updatedAt'] ?? data['createdAt']),
      updatedBy: data['updatedBy']?.toString() ?? '',
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const <String>[];
    }

    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
