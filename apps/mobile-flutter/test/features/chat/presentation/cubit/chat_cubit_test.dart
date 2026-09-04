import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/chat/application/ports/chat_media_repository.dart';
import 'package:glyphora_mobile/features/chat/domain/models/chat_message.dart';
import 'package:glyphora_mobile/features/chat/domain/models/chat_thread.dart';
import 'package:glyphora_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:glyphora_mobile/features/chat/presentation/cubit/chat_cubit.dart';

void main() {
  group('ChatCubit', () {
    late _FakeChatRepository repository;
    late _FakeChatMediaRepository mediaRepository;
    late ChatCubit cubit;

    setUp(() {
      repository = _FakeChatRepository();
      mediaRepository = _FakeChatMediaRepository();
      cubit = ChatCubit(
        repository: repository,
        mediaRepository: mediaRepository,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('delegates getOrCreateChat to repository', () async {
      repository.chatIdResult = 'chat-1';

      final chatId = await cubit.getOrCreateChat('user-2');

      expect(chatId, 'chat-1');
      expect(repository.lastOtherUserId, 'user-2');
    });

    test('loads chats and clears loading state', () async {
      final thread = ChatThread(
        id: 'chat-1',
        participantIds: const ['user-1', 'user-2'],
        lastMessage: 'hello',
        updatedAt: DateTime(2026),
        unreadCountByUser: const {'user-1': 3},
      );
      repository.chatResults = [thread];

      await cubit.loadChats('user-1');

      expect(cubit.isLoading, isFalse);
      expect(cubit.error, isNull);
      expect(cubit.chats, [thread]);
      expect(repository.lastChatsUserId, 'user-1');
    });

    test('stores load error and clears loading state', () async {
      repository.getChatsError = StateError('load failed');

      await cubit.loadChats('user-1');

      expect(cubit.isLoading, isFalse);
      expect(cubit.error, contains('load failed'));
    });

    test('delegates total unread stream to repository', () async {
      repository.totalUnreadValues = const [2, 5];

      await expectLater(
        cubit.watchTotalUnread('user-1'),
        emitsInOrder(<Object>[2, 5, emitsDone]),
      );

      expect(repository.lastUnreadUserId, 'user-1');
    });

    test('reads unread count from chat thread', () {
      final thread = ChatThread(
        id: 'chat-1',
        participantIds: const ['user-1', 'user-2'],
        lastMessage: 'hello',
        updatedAt: null,
        unreadCountByUser: const {'user-1': 4},
      );

      expect(cubit.getUnreadCount(thread, 'user-1'), 4);
      expect(cubit.getUnreadCount(thread, 'user-2'), 0);
    });

    test('delegates text message sending', () async {
      await cubit.sendMessageWithSender('chat-1', 'user-1', 'hello');

      expect(repository.lastTextChatId, 'chat-1');
      expect(repository.lastTextSenderId, 'user-1');
      expect(repository.lastTextContent, 'hello');
    });

    test('uploads image then sends image message', () async {
      mediaRepository.uploadResult = 'https://example.test/chat.png';
      final bytes = Uint8List.fromList(const [1, 2, 3]);

      await cubit.sendImageMessage(
        chatId: 'chat-1',
        senderId: 'user-1',
        imageBytes: bytes,
      );

      expect(mediaRepository.lastOwnerId, 'user-1');
      expect(mediaRepository.lastBytes, bytes);
      expect(repository.lastImageChatId, 'chat-1');
      expect(repository.lastImageSenderId, 'user-1');
      expect(repository.lastImageUrl, 'https://example.test/chat.png');
      expect(mediaRepository.lastDeletedUrl, isNull);
    });

    test(
      'deletes uploaded image when image message persistence fails',
      () async {
        mediaRepository.uploadResult = 'https://example.test/chat.png';
        repository.sendImageError = StateError('send failed');

        await expectLater(
          cubit.sendImageMessage(
            chatId: 'chat-1',
            senderId: 'user-1',
            imageBytes: Uint8List.fromList(const [7, 8, 9]),
          ),
          throwsA(isA<StateError>()),
        );

        expect(mediaRepository.lastDeletedUrl, 'https://example.test/chat.png');
      },
    );
  });
}

final class _FakeChatRepository implements ChatRepository {
  String chatIdResult = 'chat';
  String? lastOtherUserId;
  List<ChatThread> chatResults = const [];
  Object? getChatsError;
  String? lastChatsUserId;
  List<int> totalUnreadValues = const [];
  String? lastUnreadUserId;
  String? lastTextChatId;
  String? lastTextSenderId;
  String? lastTextContent;
  String? lastImageChatId;
  String? lastImageSenderId;
  String? lastImageUrl;
  Object? sendImageError;

  @override
  Future<String> getOrCreateChat(String otherUserId) async {
    lastOtherUserId = otherUserId;
    return chatIdResult;
  }

  @override
  Future<List<ChatThread>> getChats(String userId) async {
    lastChatsUserId = userId;
    final error = getChatsError;
    if (error != null) throw error;
    return chatResults;
  }

  @override
  Stream<List<ChatThread>> watchChats(String userId) {
    return Stream<List<ChatThread>>.value(chatResults);
  }

  @override
  Stream<int> watchTotalUnread(String userId) {
    lastUnreadUserId = userId;
    return Stream<int>.fromIterable(totalUnreadValues);
  }

  @override
  Future<List<String>> getChatParticipants(String chatId) async {
    return const ['user-1', 'user-2'];
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {}

  @override
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    lastTextChatId = chatId;
    lastTextSenderId = senderId;
    lastTextContent = content;
  }

  @override
  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String imageUrl,
  }) async {
    lastImageChatId = chatId;
    lastImageSenderId = senderId;
    lastImageUrl = imageUrl;

    final error = sendImageError;
    if (error != null) throw error;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return const Stream<List<ChatMessage>>.empty();
  }

  @override
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String currentUserId,
    required String newContent,
  }) async {}

  @override
  Future<void> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String currentUserId,
  }) async {}

  @override
  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
    required String currentUserId,
  }) async {}

  @override
  Future<void> sendVocabularyMessage({
    required String chatId,
    required String senderId,
    required String word,
    String? translation,
    String? languageCode,
  }) async {}

  @override
  Future<void> updateVocabularyTranslation({
    required String chatId,
    required String messageId,
    required String userId,
    required String translation,
  }) async {}

  @override
  Future<void> updateLiveDraftEnabled({
    required String chatId,
    required String userId,
    required bool enabled,
  }) async {}

  @override
  Future<bool> getLiveDraftEnabled({
    required String chatId,
    required String userId,
  }) async {
    return false;
  }
}

final class _FakeChatMediaRepository implements ChatMediaRepository {
  String uploadResult = 'https://example.test/image.png';
  String? lastOwnerId;
  Uint8List? lastBytes;
  String? lastDeletedUrl;

  @override
  Future<String> uploadImage({
    required String ownerId,
    required Uint8List bytes,
  }) async {
    lastOwnerId = ownerId;
    lastBytes = bytes;
    return uploadResult;
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    lastDeletedUrl = imageUrl;
  }
}
