// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: UserModel._readUid(json, 'id') as String? ?? '',
  username: json['username'] as String? ?? '',
  email: json['email'] as String?,
  displayName: json['displayName'] as String?,
  photoUrl: json['photoUrl'] as String?,
  nickname: json['nickname'] as String?,
  avatar: UserModel._readAvatar(json, 'avatar') as String?,
  bio: json['bio'] as String?,
  friends: (json['friends'] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList(),
  friendRequests: (json['friendRequests'] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList(),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
  languages: UserModel._languagesFromJson(json['languages']),
  birthday: UserModel._dateTimeFromJson(json['birthday']),
  showAge: json['showAge'] as bool? ?? true,
  createdAt: UserModel._dateTimeFromJson(json['createdAt']),
  lastActive: UserModel._dateTimeFromJson(json['lastActive']),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'uid': instance.id,
  'username': instance.username,
  'email': instance.email,
  'displayName': instance.displayName,
  'photoUrl': instance.photoUrl,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'bio': instance.bio,
  'friends': instance.friends,
  'friendRequests': instance.friendRequests,
  'tags': instance.tags,
  'languages': UserModel._languagesToJson(instance.languages),
  'birthday': UserModel._dateTimeToJson(instance.birthday),
  'showAge': instance.showAge,
  'createdAt': UserModel._dateTimeToJson(instance.createdAt),
  'lastActive': UserModel._dateTimeToJson(instance.lastActive),
}..removeWhere((key, value) => value == null);
