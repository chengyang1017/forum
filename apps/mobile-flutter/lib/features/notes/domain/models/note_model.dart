import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String ownerId;
  final List<String> participantIds;
  final List<String> sharedUserIds;

  final String title;
  final String content;
  final List<dynamic> bodyDelta;

  // 来源
  final String sourceType;
  final String? sourceId;

  // 一级分类。继续保留，兼容当前笔记筛选和旧数据。
  final String? category;

  // 当前真正选中的分类节点。
  final String? categoryId;

  // 从一级分类到当前节点的完整路径。
  final List<String> categoryPath;

  // 笔记主语言
  // 可不选择
  final String? languageCode;

  final bool allowOthersEdit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedBy;

  const NoteModel({
    required this.id,
    required this.ownerId,
    required this.participantIds,
    required this.sharedUserIds,
    required this.title,
    required this.content,
    required this.bodyDelta,
    this.sourceType = 'manual',
    this.sourceId,
    this.category,
    this.categoryId,
    this.categoryPath = const [],
    this.languageCode,
    required this.allowOthersEdit,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory NoteModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    final legacyCategory = data['category']?.toString();
    final categoryId = data['categoryId']?.toString() ?? legacyCategory;

    final rawCategoryPath = (data['categoryPath'] as List<dynamic>?)
            ?.map((value) => value.toString())
            .where((value) => value.isNotEmpty)
            .toList() ??
        const <String>[];

    return NoteModel(
      id: document.id,
      ownerId: data['ownerId']?.toString() ?? '',
      participantIds: List<String>.from(
        data['participantIds'] ?? const <String>[],
      ),
      sharedUserIds: List<String>.from(
        data['sharedUserIds'] ?? const <String>[],
      ),
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
          : [if (legacyCategory != null && legacyCategory.isNotEmpty) legacyCategory],
      languageCode: data['languageCode']?.toString(),
      allowOthersEdit: data['allowOthersEdit'] as bool? ?? false,
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt'] ?? data['createdAt']),
      updatedBy: data['updatedBy']?.toString() ?? '',
    );
  }

  String? otherUserId(String currentUserId) {
    for (final userId in participantIds) {
      if (userId != currentUserId) {
        return userId;
      }
    }

    return null;
  }

  bool includesUser(String userId) {
    return participantIds.contains(userId);
  }

  bool canEdit(String currentUserId) {
    return ownerId == currentUserId || allowOthersEdit;
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
