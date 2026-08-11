import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String? userId; // Firestore 字段: uid
  final String? title;
  final String? content;
  final List<dynamic> bodyDelta;
  final String? category;
  final String? languageCode;
  final String? primaryLanguageCode;
  final List<String> availableLanguageCodes;
  final List<String>? imageUrls;
  final List<String>? likes;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PostModel({
    required this.id,
    this.userId,
    this.title,
    this.content,
    this.bodyDelta = const [],
    this.category,
    this.languageCode,
    this.primaryLanguageCode,
    this.availableLanguageCodes = const [],
    this.imageUrls,
    this.likes,
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
  return PostModel(
    id: json['id']?.toString() ?? '',
    userId: json['uid']?.toString() ?? json['userId']?.toString(),

    title: json['title']?.toString() ?? '',
    content: json['content']?.toString() ?? '',

    bodyDelta:
        (json['bodyDelta'] as List<dynamic>?)
            ?.map((e) => e)
            .toList() ??
        const [],

    category: json['category']?.toString(),
    languageCode: json['languageCode']?.toString(),
    primaryLanguageCode:
    json['primaryLanguageCode']
        ?.toString() ??
    json['languageCode']
        ?.toString(),

availableLanguageCodes:
    (json['availableLanguageCodes']
            as List<dynamic>?)
        ?.map(
          (e) => e.toString(),
        )
        .toList() ??
    [
      if (json['languageCode'] != null)
        json['languageCode'].toString(),
    ],
    imageUrls: (json['images'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList(),
    likes: (json['likes'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList(),
    likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
    createdAt: _toDateTime(json['timestamp'] ?? json['createdAt']),
    updatedAt: _toDateTime(json['updatedAt']),
  );
}

  Map<String, dynamic> toJson() {
    return {
      'uid': userId,
      'title': title,
      'content': content,
      'bodyDelta': bodyDelta,
      'category': category,
      'languageCode': languageCode,
      'primaryLanguageCode':
    primaryLanguageCode,

'availableLanguageCodes':
    availableLanguageCodes,
      'images': imageUrls,
      'likes': likes,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'timestamp': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    }..removeWhere((key, value) => value == null);
  }

  PostModel copyWith({
  String? id,
  String? userId,
  String? title,
  String? content,
  List<dynamic>? bodyDelta,
  String? category,
  String? languageCode,

  String? primaryLanguageCode,
  List<String>? availableLanguageCodes,

  List<String>? imageUrls,
  List<String>? likes,
  int? likeCount,
  int? commentCount,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return PostModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    content: content ?? this.content,
    bodyDelta:
    bodyDelta ?? this.bodyDelta,
    category: category ?? this.category,
    languageCode: languageCode ?? this.languageCode,

    primaryLanguageCode:
        primaryLanguageCode ??
        this.primaryLanguageCode,

    availableLanguageCodes:
        availableLanguageCodes ??
        this.availableLanguageCodes,

    imageUrls: imageUrls ?? this.imageUrls,
    likes: likes ?? this.likes,
    likeCount: likeCount ?? this.likeCount,
    commentCount:
        commentCount ?? this.commentCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}