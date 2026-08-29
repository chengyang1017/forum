import 'package:cloud_firestore/cloud_firestore.dart';

enum PostVersionType { original, manual, ai, aiAssisted }

class PostVersionModel {
  final String languageCode;
  final String title;
  final String content;
  final String authorId;
  final PostVersionType type;
  final DateTime? createdAt;

  final DateTime? updatedAt;

  const PostVersionModel({
    required this.languageCode,
    required this.title,
    required this.content,
    required this.authorId,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory PostVersionModel.fromJson(Map<String, dynamic> json) {
    return PostVersionModel(
      languageCode: json['languageCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      type: _typeFromString(json['type']?.toString()),
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languageCode': languageCode,
      'title': title,
      'content': content,
      'authorId': authorId,
      'type': _typeToString(type),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    }..removeWhere((key, value) => value == null);
  }

  static PostVersionType _typeFromString(String? value) {
    switch (value) {
      case 'manual':
        return PostVersionType.manual;

      case 'ai':
        return PostVersionType.ai;

      case 'ai_assisted':
        return PostVersionType.aiAssisted;

      default:
        return PostVersionType.original;
    }
  }

  static String _typeToString(PostVersionType type) {
    switch (type) {
      case PostVersionType.original:
        return 'original';

      case PostVersionType.manual:
        return 'manual';

      case PostVersionType.ai:
        return 'ai';

      case PostVersionType.aiAssisted:
        return 'ai_assisted';
    }
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
