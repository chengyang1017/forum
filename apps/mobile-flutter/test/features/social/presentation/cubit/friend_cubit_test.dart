import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/social/domain/models/friend_relationship_status.dart';
import 'package:glyphora_mobile/features/social/domain/models/friend_request.dart';
import 'package:glyphora_mobile/features/social/domain/repositories/friend_repository.dart';
import 'package:glyphora_mobile/features/social/presentation/cubit/friend_cubit.dart';

void main() {
  group('FriendCubit', () {
    late _FakeFriendRepository repository;
    late FriendCubit cubit;

    setUp(() {
      repository = _FakeFriendRepository();
      cubit = FriendCubit(repository: repository);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('loadFriends stores friend ids and returns to idle', () async {
      repository.friends = const ['user-1', 'user-2'];

      await cubit.loadFriends();

      expect(cubit.friendUids, const ['user-1', 'user-2']);
      expect(cubit.isLoading, isFalse);
      expect(cubit.error, isNull);
      expect(repository.getFriendsCalls, 1);
    });

    test('loadFriends stores repository errors without rethrowing', () async {
      repository.getFriendsError = StateError('load failed');

      await cubit.loadFriends();

      expect(cubit.friendUids, isNull);
      expect(cubit.isLoading, isFalse);
      expect(cubit.error, contains('load failed'));
    });

    test('watchFriends delegates to the repository stream', () async {
      repository.friends = const ['user-3'];

      final result = await cubit.watchFriends().first;

      expect(result, const ['user-3']);
      expect(repository.watchFriendsCalls, 1);
    });

    test('clear restores the initial state', () async {
      repository.friends = const ['user-1'];
      await cubit.loadFriends();

      cubit.clear();

      expect(cubit.friendUids, isNull);
      expect(cubit.isLoading, isFalse);
      expect(cubit.error, isNull);
    });
  });
}

final class _FakeFriendRepository implements FriendRepository {
  List<String> friends = const <String>[];
  List<String> blockedUsers = const <String>[];
  Object? getFriendsError;
  int getFriendsCalls = 0;
  int watchFriendsCalls = 0;

  @override
  Future<List<String>> getFriends() async {
    getFriendsCalls += 1;
    final error = getFriendsError;
    if (error != null) throw error;
    return friends;
  }

  @override
  Stream<List<String>> watchFriends() {
    watchFriendsCalls += 1;
    return Stream.value(friends);
  }

  @override
  Future<FriendRelationshipStatus> getRelationship(String otherUserId) =>
      throw UnimplementedError();

  @override
  Stream<List<FriendRequest>> watchIncomingRequests() => const Stream.empty();

  @override
  Stream<int> watchIncomingRequestCount() => const Stream.empty();

  @override
  Future<void> sendRequest(String otherUserId) async {}

  @override
  Future<void> acceptRequest(String fromUserId) async {}

  @override
  Future<void> rejectRequest(String fromUserId) async {}

  @override
  Stream<List<String>> watchBlockedUsers() => Stream.value(blockedUsers);

  @override
  Future<List<String>> getBlockedUsers() async => blockedUsers;

  @override
  Future<bool> isBlockedByMe(String otherUserId) async =>
      blockedUsers.contains(otherUserId);

  @override
  Future<bool> isInteractionBlocked(String otherUserId) async =>
      blockedUsers.contains(otherUserId);

  @override
  Future<void> blockUser(String otherUserId) async {
    blockedUsers = <String>{...blockedUsers, otherUserId}.toList();
  }

  @override
  Future<void> unblockUser(String otherUserId) async {
    blockedUsers = blockedUsers.where((id) => id != otherUserId).toList();
  }
}
