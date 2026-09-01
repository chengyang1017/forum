class NoteModel {
  final String id;
  final String ownerId;
  final List<String> participantIds;
  final List<String> sharedUserIds;

  final String title;
  final String content;
  final List<dynamic> bodyDelta;

  final String sourceType;
  final String? sourceId;

  /// Root category kept for compatibility with existing note filters.
  final String? category;

  /// Currently selected category node.
  final String? categoryId;

  /// Full path from root category to the selected node.
  final List<String> categoryPath;

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
    return ownerId == currentUserId ||
        (allowOthersEdit && participantIds.contains(currentUserId));
  }
}
