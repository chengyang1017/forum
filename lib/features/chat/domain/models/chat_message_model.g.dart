// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessageModel _$ChatMessageModelFromJson(Map<String, dynamic> json) =>
    ChatMessageModel(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String),
      read: json['read'] as bool? ?? false,
    );

Map<String, dynamic> _$ChatMessageModelToJson(ChatMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomId': instance.roomId,
      'senderId': instance.senderId,
      'content': instance.content,
      'sentAt': instance.sentAt?.toIso8601String(),
      'read': instance.read,
    };
