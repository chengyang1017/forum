import '../models/chat_message.dart';
import '../models/chat_thread.dart';

/// Domain boundary for chat rooms, messages, and per-member chat settings.
///
/// Firebase-specific snapshots, timestamps, authentication, and transport
/// details belong to the data layer and must not cross this contract.
abstract interface class ChatRepository {
  Future<String> getOrCreateChat(String otherUserId);

  Future<List<ChatThread>> getChats(String userId);

  Stream<List<ChatThread>> watchChats(String userId);

  Stream<int> watchTotalUnread(String userId);

  Future<List<String>> getChatParticipants(String chatId);

  Future<void> markAsRead(String chatId, String userId);

  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String content,
  });

  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String imageUrl,
  });

  Stream<List<ChatMessage>> watchMessages(String chatId);

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String currentUserId,
    required String newContent,
  });

  Future<void> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String currentUserId,
  });

  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
    required String currentUserId,
  });

  Future<void> sendVocabularyMessage({
    required String chatId,
    required String senderId,
    required String word,
    String? translation,
    String? languageCode,
  });

  Future<void> updateVocabularyTranslation({
    required String chatId,
    required String messageId,
    required String userId,
    required String translation,
  });

  Future<void> updateLiveDraftEnabled({
    required String chatId,
    required String userId,
    required bool enabled,
  });

  Future<bool> getLiveDraftEnabled({
    required String chatId,
    required String userId,
  });
}
