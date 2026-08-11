import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiscoverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== 获取所有用户列表（排除自己） ==========
  Stream<QuerySnapshot> watchAllUsers(String currentUserId) {
    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .snapshots();
  }

  // ========== 获取或创建聊天室 ==========
  Future<String> getOrCreateChat(String otherUserId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) throw Exception('未登录');

    final chatId = [currentUid, otherUserId]..sort();
    final chatDoc = _firestore.collection('chats').doc(chatId.join('_'));

    final doc = await chatDoc.get();
    if (!doc.exists) {
      await chatDoc.set({
        'users': [currentUid, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'unreadCount': {
          currentUid: 0,
          otherUserId: 0,
        },
      });
    }
    return chatDoc.id;
  }

  // ========== 发送好友请求 ==========
  Future<void> sendFriendRequest(String targetUserId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) throw Exception('未登录');

    // 检查是否已经是好友
    final friendDoc = await _firestore
        .collection('friends')
        .doc(currentUid)
        .collection('userFriends')
        .doc(targetUserId)
        .get();

    if (friendDoc.exists) {
      throw Exception('已经是好友了');
    }

    // 检查是否已有待处理的好友请求
    final existingRequest = await _firestore
        .collection('friend_requests')
        .where('from', isEqualTo: currentUid)
        .where('to', isEqualTo: targetUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingRequest.docs.isNotEmpty) {
      throw Exception('已发送好友请求，请等待对方确认');
    }

    // 发送好友请求
    await _firestore.collection('friend_requests').add({
      'from': currentUid,
      'to': targetUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}