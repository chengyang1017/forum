// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomModel _$ChatRoomModelFromJson(Map<String, dynamic> json) =>
    ChatRoomModel(
      id: json['id'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] == null
          ? null
          : DateTime.parse(json['lastMessageTime'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ChatRoomModelToJson(ChatRoomModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participants': instance.participants,
      'lastMessage': instance.lastMessage,
      'lastMessageTime': instance.lastMessageTime?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };
