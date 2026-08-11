import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/chat_service.dart';

class ChatRepository {
  final ChatService _chatService;

  ChatRepository({
    ChatService? chatService,
  }) : _chatService =
           chatService ?? ChatService();

  // ============================================================
  // 1. 聊天室管理
  // ============================================================

  Future<String> getOrCreateChat(
    String otherUserId,
  ) {
    return _chatService.getOrCreateChat(
      otherUserId,
    );
  }

  Future<List<QueryDocumentSnapshot>> getChats(
    String userId,
  ) async {
    final snapshot =
        await _chatService.getChats(userId);

    return snapshot.docs;
  }

  Stream<QuerySnapshot> watchChats(
    String userId,
  ) {
    return _chatService.watchChats(userId);
  }

  Stream<int> watchTotalUnread(
    String userId,
  ) {
    return _chatService.watchTotalUnread(
      userId,
    );
  }

  Future<List<String>> getChatParticipants(
    String chatId,
  ) {
    return _chatService.getChatParticipants(
      chatId,
    );
  }

  Future<void> markAsRead(
    String chatId,
    String userId,
  ) {
    return _chatService.markAsRead(
      chatId,
      userId,
    );
  }

  // ============================================================
  // 2. 消息管理
  // ============================================================

  Future<void> sendMessage(
    String chatId,
    String senderId,
    String content,
  ) {
    return _chatService.sendMessage(
      chatId,
      senderId,
      content,
    );
  }

  Future<String> uploadChatImage(
    File imageFile,
  ) {
    return _chatService.uploadChatImage(
      imageFile,
    );
  }

  Future<void> sendImageMessage(
    String chatId,
    String senderId,
    String imageUrl,
  ) {
    return _chatService.sendImageMessage(
      chatId,
      senderId,
      imageUrl,
    );
  }

  Stream<QuerySnapshot> watchMessages(
    String chatId,
  ) {
    return _chatService.watchMessages(
      chatId,
    );
  }

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String currentUserId,
    required String newContent,
  }) {
    return _chatService.editMessage(
      chatId: chatId,
      messageId: messageId,
      currentUserId: currentUserId,
      newContent: newContent,
    );
  }

  Future<void> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String currentUserId,
  }) {
    return _chatService.deleteMessageForMe(
      chatId: chatId,
      messageId: messageId,
      currentUserId: currentUserId,
    );
  }

  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
    required String currentUserId,
  }) {
    return _chatService
        .deleteMessageForEveryone(
      chatId: chatId,
      messageId: messageId,
      currentUserId: currentUserId,
    );
  }
}