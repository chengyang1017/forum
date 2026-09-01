import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/ports/chat_media_repository.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_thread.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required ChatRepository repository,
    required ChatMediaRepository mediaRepository,
  }) : _repository = repository,
       _mediaRepository = mediaRepository,
       super(const ChatState());

  final ChatRepository _repository;
  final ChatMediaRepository _mediaRepository;

  List<ChatThread>? get chats => state.chats;
  bool get isLoading => state.isLoading;
  String? get error => state.error;

  Future<String> getOrCreateChat(String otherUserId) {
    return _repository.getOrCreateChat(otherUserId);
  }

  Future<void> loadChats(String userId) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final chats = await _repository.getChats(userId);
      emit(state.copyWith(chats: chats));
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Stream<List<ChatThread>> watchChats(String userId) {
    return _repository.watchChats(userId);
  }

  Stream<int> watchTotalUnread(String userId) {
    return _repository.watchTotalUnread(userId);
  }

  Future<List<String>> getChatParticipants(String chatId) {
    return _repository.getChatParticipants(chatId);
  }

  Future<void> markAsRead(String chatId, String userId) {
    return _repository.markAsRead(chatId, userId);
  }

  int getUnreadCount(ChatThread thread, String userId) {
    return thread.unreadCountFor(userId);
  }

  Future<void> sendMessageWithSender(
    String chatId,
    String senderId,
    String content,
  ) {
    return _repository.sendTextMessage(
      chatId: chatId,
      senderId: senderId,
      content: content,
    );
  }

  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required Uint8List imageBytes,
  }) async {
    final imageUrl = await _mediaRepository.uploadImage(
      ownerId: senderId,
      bytes: imageBytes,
    );

    try {
      await _repository.sendImageMessage(
        chatId: chatId,
        senderId: senderId,
        imageUrl: imageUrl,
      );
    } catch (_) {
      await _mediaRepository.deleteImage(imageUrl);
      rethrow;
    }
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _repository.watchMessages(chatId);
  }

  Future<void> sendVocabularyMessage({
    required String chatId,
    required String senderId,
    required String word,
    String? translation,
    String? languageCode,
  }) {
    return _repository.sendVocabularyMessage(
      chatId: chatId,
      senderId: senderId,
      word: word,
      translation: translation,
      languageCode: languageCode,
    );
  }

  Future<void> updateVocabularyTranslation({
    required String chatId,
    required String messageId,
    required String userId,
    required String translation,
  }) {
    return _repository.updateVocabularyTranslation(
      chatId: chatId,
      messageId: messageId,
      userId: userId,
      translation: translation,
    );
  }

  Future<void> updateLiveDraftEnabled({
    required String chatId,
    required String userId,
    required bool enabled,
  }) {
    return _repository.updateLiveDraftEnabled(
      chatId: chatId,
      userId: userId,
      enabled: enabled,
    );
  }

  Future<bool> getLiveDraftEnabled({
    required String chatId,
    required String userId,
  }) {
    return _repository.getLiveDraftEnabled(chatId: chatId, userId: userId);
  }

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String currentUserId,
    required String newContent,
  }) {
    return _repository.editMessage(
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
    return _repository.deleteMessageForMe(
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
    return _repository.deleteMessageForEveryone(
      chatId: chatId,
      messageId: messageId,
      currentUserId: currentUserId,
    );
  }

  void clear() {
    emit(const ChatState());
  }
}
