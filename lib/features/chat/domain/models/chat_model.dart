import 'package:json_annotation/json_annotation.dart';

part 'chat_model.g.dart'; // ✅ 添加这一行

@JsonSerializable()
class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime? createdAt;

  ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.createdAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomModelToJson(this);
}
