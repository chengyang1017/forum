/// Domain boundary for one-way follow relationships.
///
/// Following is intentionally separate from friendship: a user can follow
/// another user's public content without creating a mutual friend relation.
abstract interface class FollowRepository {
  Stream<bool> watchIsFollowing(String otherUserId);

  Stream<int> watchFollowerCount(String userId);

  Stream<int> watchFollowingCount(String userId);

  Stream<List<String>> watchFollowerIds(String userId);

  Stream<List<String>> watchFollowingIds(String userId);

  Future<void> follow(String otherUserId);

  Future<void> unfollow(String otherUserId);
}
