import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  /// Firestore 可能存 uid，也可能只用 document id。
  /// Provider 会把 doc.id 塞进 uid，所以这里统一映射成 id。
  @JsonKey(readValue: _readUid, defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String username;

  final String? email;

  /// 旧字段：如果以前有 displayName，可以继续兼容。
  final String? displayName;

  /// 旧字段：如果以前有 photoUrl，可以继续兼容。
  final String? photoUrl;

  /// 个人主页昵称字段。
  final String? nickname;

  /// Firestore 里你之前用的是 avatar。
  /// 同时兼容 avatarUrl。
  @JsonKey(readValue: _readAvatar)
  final String? avatar;

  final String? bio;

  final List<String>? friends;
  final List<String>? friendRequests;

  final List<String>? tags;

  @JsonKey(fromJson: _languagesFromJson, toJson: _languagesToJson)
  final List<Map<String, dynamic>>? languages;

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? birthday;

  @JsonKey(defaultValue: true)
  final bool showAge;

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createdAt;

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? lastActive;

  const UserModel({
    required this.id,
    required this.username,
    this.email,
    this.displayName,
    this.photoUrl,
    this.nickname,
    this.avatar,
    this.bio,
    this.friends,
    this.friendRequests,
    this.tags,
    this.languages,
    this.birthday,
    this.showAge = true,
    this.createdAt,
    this.lastActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// 个人主页头像统一用这个 getter。
  String get avatarUrl {
    final avatarValue = avatar ?? '';
    if (avatarValue.isNotEmpty) return avatarValue;
    return photoUrl ?? '';
  }

  /// 个人主页名字统一用这个 getter。
  String get profileDisplayName {
    final nicknameValue = nickname ?? '';
    if (nicknameValue.isNotEmpty) return nicknameValue;

    final displayNameValue = displayName ?? '';
    if (displayNameValue.isNotEmpty) return displayNameValue;

    return username;
  }

  String get nicknameText => nickname ?? '';
  String get bioText => bio ?? '';
  List<String> get tagsList => tags ?? const [];
  List<Map<String, dynamic>> get languageList => languages ?? const [];

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? photoUrl,
    String? nickname,
    String? avatar,
    String? bio,
    List<String>? friends,
    List<String>? friendRequests,
    List<String>? tags,
    List<Map<String, dynamic>>? languages,
    DateTime? birthday,
    bool clearBirthday = false,
    bool? showAge,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      tags: tags ?? this.tags,
      languages: languages ?? this.languages,
      birthday: clearBirthday ? null : birthday ?? this.birthday,
      showAge: showAge ?? this.showAge,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  static Object? _readUid(Map json, String key) {
    return json['uid'] ?? json['id'];
  }

  static Object? _readAvatar(Map json, String key) {
    return json['avatar'] ?? json['avatarUrl'] ?? json['photoUrl'];
  }

  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static dynamic _dateTimeToJson(DateTime? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value);
  }

  static List<Map<String, dynamic>>? _languagesFromJson(dynamic value) {
    if (value is! List) return null;

    final result = value
        .map<Map<String, dynamic>>((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          if (item is String) {
            return {'name': item, 'level': 70};
          }
          return <String, dynamic>{};
        })
        .where((item) => item.isNotEmpty)
        .toList();

    return result;
  }

  static dynamic _languagesToJson(List<Map<String, dynamic>>? value) {
    return value;
  }
}
