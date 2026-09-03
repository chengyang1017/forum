import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/follow_repository.dart';

/// Firestore adapter for one-way follows during the current migration phase.
///
/// Each relationship is stored as follows/{followerUid}_{followingUid}. This
/// keeps follows independent from the existing mutual friendship graph and
/// supports follower/following queries without growing one document forever.
final class FirestoreFollowRepository implements FollowRepository {
  FirestoreFollowRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _follows =>
      _firestore.collection('follows');

  String get _currentUserId {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw StateError('An authenticated user is required.');
    }
    return userId;
  }

  DocumentReference<Map<String, dynamic>> _relationshipDoc(
    String followerId,
    String followingId,
  ) {
    return _follows.doc('${followerId}_$followingId');
  }

  @override
  Stream<bool> watchIsFollowing(String otherUserId) {
    final userId = _currentUserId;
    if (otherUserId == userId) {
      return Stream<bool>.value(false);
    }

    return _relationshipDoc(
      userId,
      otherUserId,
    ).snapshots().map((snapshot) => snapshot.exists);
  }

  @override
  Stream<int> watchFollowerCount(String userId) {
    return _follows
        .where('followingId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Stream<int> watchFollowingCount(String userId) {
    return _follows
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Stream<List<String>> watchFollowerIds(String userId) {
    return _follows
        .where('followingId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final ids = snapshot.docs
              .map((doc) => doc.data()['followerId'])
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toList(growable: false);
          ids.sort();
          return ids;
        });
  }

  @override
  Stream<List<String>> watchFollowingIds(String userId) {
    return _follows
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final ids = snapshot.docs
              .map((doc) => doc.data()['followingId'])
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toList(growable: false);
          ids.sort();
          return ids;
        });
  }

  @override
  Future<void> follow(String otherUserId) async {
    final userId = _currentUserId;
    if (otherUserId == userId) {
      throw ArgumentError.value(
        otherUserId,
        'otherUserId',
        'Cannot follow self.',
      );
    }

    await _relationshipDoc(userId, otherUserId).set({
      'followerId': userId,
      'followingId': otherUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unfollow(String otherUserId) async {
    final userId = _currentUserId;
    if (otherUserId == userId) {
      return;
    }

    await _relationshipDoc(userId, otherUserId).delete();
  }
}
