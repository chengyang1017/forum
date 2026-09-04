import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:glyphora_mobile/features/discover/domain/models/discover_user.dart';
import 'package:glyphora_mobile/features/discover/domain/repositories/discover_repository.dart';
import 'package:glyphora_mobile/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:glyphora_mobile/features/social/domain/repositories/friend_repository.dart';

void main() {
  group('DiscoverCubit', () {
    late _FakeDiscoverRepository repository;
    late _FakeChatRepository chatRepository;
    late _FakeFriendRepository friendRepository;
    late DiscoverCubit cubit;

    setUp(() {
      repository = _FakeDiscoverRepository();
      chatRepository = _FakeChatRepository();
      friendRepository = _FakeFriendRepository();
      cubit = DiscoverCubit(
        repository: repository,
        chatRepository: chatRepository,
        friendRepository: friendRepository,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('watchAllUsers delegates current user id', () async {
      const user = DiscoverUser(
        id: 'user-2',
        username: 'bob',
        nickname: 'Bob',
        avatarUrl: '',
      );
      repository.users = const [user];

      final result = await cubit.watchAllUsers('user-1').first;

      expect(result, const [user]);
      expect(repository.lastCurrentUserId, 'user-1');
    });

    test('getOrCreateChat delegates to ChatRepository', () async {
      chatRepository.chatId = 'chat-1';

      final result = await cubit.getOrCreateChat('user-2');

      expect(result, 'chat-1');
      expect(chatRepository.lastOtherUserId, 'user-2');
    });

    test('sendFriendRequest delegates and returns to idle', () async {
      await cubit.sendFriendRequest('user-2');

      expect(friendRepository.lastTargetUserId, 'user-2');
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);
    });

    test('sendFriendRequest stores error, returns to idle, and rethrows', () async {
      friendRepository.sendError = StateError('request failed');

      await expectLater(
        cubit.sendFriendRequest('user-2'),
        throwsA(isA<StateError>()),
      );

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, contains('request failed'));
    });

    test('clear restores initial state after an error', () async {
      friendRepository.sendError = StateError('request failed');
      await expectLater(
        cubit.sendFriendRequest('user-2'),
        throwsA(isA<StateError>()),
      );

      cubit.clear();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);
    });
  });
}

final class _FakeDiscoverRepository implements DiscoverRepository {
  List<DiscoverUser> users = const <DiscoverUser>[];
  String? lastCurrentUserId;

  @override
  Stream<List<DiscoverUser>> watchAllUsers(String currentUserId) {
    lastCurrentUserId = currentUserId;
    return Stream.value(users);
  }
}

final class _FakeChatRepository implements ChatRepository {
  String chatId = 'chat';
  String? lastOtherUserId;

  @override
  Future<String> getOrCreateChat(String otherUserId) async {
    lastOtherUserId = otherUserId;
    return chatId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeFriendRepository implements FriendRepository {
  String? lastTargetUserId;
  Object? sendError;

  @override
  Future<void> sendRequest(String otherUserId) async {
    lastTargetUserId = otherUserId;
    final error = sendError;
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
