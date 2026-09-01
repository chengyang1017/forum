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
}
