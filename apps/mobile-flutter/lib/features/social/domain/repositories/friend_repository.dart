import '../models/friend_relationship_status.dart';
import '../models/friend_request.dart';

/// Domain boundary for the current user's friendship graph.
///
/// Authentication and Firestore details stay in the data-layer adapter.
abstract interface class FriendRepository {
  Stream<List<String>> watchFriends();

  Future<List<String>> getFriends();

  Future<FriendRelationshipStatus> getRelationship(String otherUserId);

  Stream<List<FriendRequest>> watchIncomingRequests();

  Stream<int> watchIncomingRequestCount();

  Future<void> sendRequest(String otherUserId);

  Future<void> acceptRequest(String fromUserId);

  Future<void> rejectRequest(String fromUserId);

  /// Users explicitly blocked by the current account.
  Stream<List<String>> watchBlockedUsers();

  Future<List<String>> getBlockedUsers();

  /// Whether the current account has blocked [otherUserId].
  Future<bool> isBlockedByMe(String otherUserId);

  /// Whether either side has blocked the other, in which case social
  /// interaction must not be started from the normal client.
  Future<bool> isInteractionBlocked(String otherUserId);

  Future<void> blockUser(String otherUserId);

  Future<void> unblockUser(String otherUserId);
}
