import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String ownerId;
  final List<String> participantIds;
  final List<String> sharedUserIds;
  final String title;
  final String content;
  final List<dynamic> bodyDelta;
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
    required this.allowOthersEdit,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory NoteModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

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
      allowOthersEdit: data['allowOthersEdit'] as bool? ?? false,
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(
        data['updatedAt'] ?? data['createdAt'],
      ),
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
