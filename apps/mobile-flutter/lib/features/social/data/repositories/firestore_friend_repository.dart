import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/friend_relationship_status.dart';
import '../../domain/models/friend_request.dart';
import '../../domain/repositories/friend_repository.dart';

/// Firestore adapter for friendship data during the current migration phase.
final class FirestoreFriendRepository implements FriendRepository {
  FirestoreFriendRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _currentUserId {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw StateError('An authenticated user is required.');
    }
    return userId;
  }

  @override
  Stream<List<String>> watchFriends() {
    final userId = _currentUserId;
    return _firestore.collection('friends').doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return const <String>[];
      }

      final friends = data.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList(growable: false);
      friends.sort();
      return friends;
    });
  }

  @override
  Future<List<String>> getFriends() async {
    final userId = _currentUserId;
    final doc = await _firestore.collection('friends').doc(userId).get();
    final data = doc.data();
    if (data == null) {
      return const <String>[];
    }

    final friends = data.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList(growable: false);
    friends.sort();
    return friends;
  }

  @override
  Future<FriendRelationshipStatus> getRelationship(String otherUserId) async {
    final userId = _currentUserId;
    if (otherUserId == userId) {
      return FriendRelationshipStatus.none;
    }

    final friendDoc = _firestore.collection('friends').doc(userId);
    final sentRequest = _firestore
        .collection('friend_requests')
        .doc('${userId}_$otherUserId');
    final receivedRequest = _firestore
        .collection('friend_requests')
        .doc('${otherUserId}_$userId');

    final results = await Future.wait([
      friendDoc.get(),
      sentRequest.get(),
      receivedRequest.get(),
    ]);

    final friendData = results[0].data();
    if (friendData?[otherUserId] == true) {
      return FriendRelationshipStatus.friends;
    }

    if (results[1].data()?['status'] == 'pending') {
      return FriendRelationshipStatus.requestSent;
    }

    if (results[2].data()?['status'] == 'pending') {
      return FriendRelationshipStatus.requestReceived;
    }

    return FriendRelationshipStatus.none;
  }

  @override
  Stream<List<FriendRequest>> watchIncomingRequests() {
    final userId = _currentUserId;
    return _firestore
        .collection('friend_requests')
        .where('to', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data())
              .map(
                (data) => FriendRequest(
                  fromUserId: data['from'] as String,
                  toUserId: data['to'] as String,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<int> watchIncomingRequestCount() {
    return watchIncomingRequests().map((requests) => requests.length);
  }

  @override
  Future<void> sendRequest(String otherUserId) async {
    final userId = _currentUserId;
    if (otherUserId == userId) {
      throw ArgumentError.value(otherUserId, 'otherUserId', 'Cannot add self.');
    }

    await _firestore
        .collection('friend_requests')
        .doc('${userId}_$otherUserId')
        .set({
          'from': userId,
          'to': otherUserId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> acceptRequest(String fromUserId) async {
    final userId = _currentUserId;
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('friend_requests').doc('${fromUserId}_$userId'),
      {'status': 'accepted'},
    );
    batch.set(_firestore.collection('friends').doc(userId), {
      fromUserId: true,
    }, SetOptions(merge: true));
    batch.set(_firestore.collection('friends').doc(fromUserId), {
      userId: true,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  @override
  Future<void> rejectRequest(String fromUserId) async {
    final userId = _currentUserId;
    await _firestore
        .collection('friend_requests')
        .doc('${fromUserId}_$userId')
        .update({'status': 'rejected'});
  }
}
