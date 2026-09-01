import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/repositories/chat_repository.dart';
import '../services/chat_service.dart';

final class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({ChatService? chatService, FirebaseFirestore? firestore})
    : _chatService = chatService ?? ChatService(),
      _firestore = firestore ?? FirebaseFirestore.instance;

  final ChatService _chatService;
  final FirebaseFirestore _firestore;

  @override
  Future<String> getOrCreateChat(String otherUserId) {
    return _chatService.getOrCreateChat(otherUserId);
  }

  @override
  Future<List<ChatThread>> getChats(String userId) async {
    final snapshot = await _chatService.getChats(userId);
    return snapshot.docs.map(_threadFromDocument).toList(growable: false);
  }

  @override
  Stream<List<ChatThread>> watchChats(String userId) {
    return _chatService
        .watchChats(userId)
        .map(
          (snapshot) =>
              snapshot.docs.map(_threadFromDocument).toList(growable: false),
        );
  }

  @override
  Stream<int> watchTotalUnread(String userId) {
    return watchChats(userId)
        .map(
          (threads) => threads.fold<int>(
            0,
            (total, thread) => total + thread.unreadCountFor(userId),
          ),
        )
        .distinct();
  }

  @override
  Future<List<String>> getChatParticipants(String chatId) {
    return _chatService.getChatParticipants(chatId);
  }

  @override
  Future<void> markAsRead(String chatId, String userId) {
    return _chatService.markAsRead(chatId, userId);
  }

  @override
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) {
    return _chatService.sendMessage(chatId, senderId, content);
  }

  @override
  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String imageUrl,
  }) {
    return _chatService.sendImageMessage(chatId, senderId, imageUrl);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _chatService
        .watchMessages(chatId)
        .map(
          (snapshot) =>
              snapshot.docs.map(_messageFromDocument).toList(growable: false),
        );
  }

  @override
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

  @override
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

  @override
  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
    required String currentUserId,
  }) {
    return _chatService.deleteMessageForEveryone(
      chatId: chatId,
      messageId: messageId,
      currentUserId: currentUserId,
    );
  }

  @override
  Future<void> sendVocabularyMessage({
    required String chatId,
    required String senderId,
    required String word,
    String? translation,
    String? languageCode,
  }) async {
    final cleanWord = word.trim();
    if (cleanWord.isEmpty) {
      throw ArgumentError('word cannot be empty');
    }

    final participants = await _chatService.getChatParticipants(chatId);
    if (!participants.contains(senderId)) {
      throw StateError('当前用户不是聊天室成员');
    }

    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    final translations = <String, String>{};
    final cleanTranslation = translation?.trim() ?? '';
    if (cleanTranslation.isNotEmpty) {
      translations[senderId] = cleanTranslation;
    }

    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();

    batch.set(messageRef, {
      'type': 'vocab',
      'senderId': senderId,
      'content': '',
      'word': cleanWord,
      'languageCode': languageCode,
      'translations': translations,
      'imageUrl': null,
      'imagePath': null,
      'timestamp': now,
      'editedAt': null,
      'hiddenFor': <String>[],
      'status': 'active',
      'deletedBy': null,
      'deletedAt': null,
      'cleanupAt': null,
    });

    final chatUpdates = <String, dynamic>{
      'lastMessage': '[单词] $cleanWord',
      'lastMessageId': messageRef.id,
      'lastSenderId': senderId,
      'updatedAt': now,
    };
    for (final participantId in participants) {
      chatUpdates['unreadCount.$participantId'] = participantId == senderId
          ? 0
          : FieldValue.increment(1);
    }
    batch.update(chatRef, chatUpdates);

    await batch.commit();
  }

  @override
  Future<void> updateVocabularyTranslation({
    required String chatId,
    required String messageId,
    required String userId,
    required String translation,
  }) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'translations.$userId': translation.trim()});
  }

  @override
  Future<void> updateLiveDraftEnabled({
    required String chatId,
    required String userId,
    required bool enabled,
  }) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('memberSettings')
        .doc(userId)
        .set({'shareLiveDraft': enabled}, SetOptions(merge: true));
  }

  @override
  Future<bool> getLiveDraftEnabled({
    required String chatId,
    required String userId,
  }) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('memberSettings')
        .doc(userId)
        .get();
    return snapshot.data()?['shareLiveDraft'] == true;
  }

  ChatThread _threadFromDocument(QueryDocumentSnapshot document) {
    final rawData = document.data();
    final data = rawData is Map<String, dynamic>
        ? rawData
        : const <String, dynamic>{};
    final unreadCount = <String, int>{};
    final rawUnreadCount = data['unreadCount'];
    if (rawUnreadCount is Map) {
      for (final entry in rawUnreadCount.entries) {
        final value = entry.value;
        if (entry.key is String && value is num) {
          unreadCount[entry.key as String] = value.toInt();
        }
      }
    }

    return ChatThread(
      id: document.id,
      participantIds: List<String>.from(data['users'] ?? const <String>[]),
      lastMessage: data['lastMessage']?.toString() ?? '',
      updatedAt: _dateTimeFrom(data['updatedAt']),
      unreadCountByUser: Map.unmodifiable(unreadCount),
    );
  }

  ChatMessage _messageFromDocument(QueryDocumentSnapshot document) {
    final rawData = document.data();
    final data = rawData is Map<String, dynamic>
        ? rawData
        : const <String, dynamic>{};

    return ChatMessage(
      id: document.id,
      type: data['type'] as String? ?? 'text',
      senderId: data['senderId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      word: data['word'] as String?,
      timestamp: _dateTimeFrom(data['timestamp']),
      editedAt: _dateTimeFrom(data['editedAt']),
      hiddenFor: Set<String>.from(data['hiddenFor'] ?? const <String>[]),
      status: data['status'] as String? ?? 'active',
    );
  }

  DateTime? _dateTimeFrom(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
