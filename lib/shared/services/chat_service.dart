import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============================================================
  // 1. 聊天室管理
  // ============================================================

  /// 获取或创建聊天室
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

  /// 获取聊天列表（一次性）
  Future<QuerySnapshot> getChats(String userId) {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .get();
  }

  /// 监听聊天列表（实时）
  Stream<QuerySnapshot> watchChats(String userId) {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// 实时监听当前用户所有聊天室的未读消息总数
Stream<int> watchTotalUnread(String userId) {
  return watchChats(userId)
      .map((snapshot) {
        var totalUnread = 0;

        for (final document in snapshot.docs) {
          final data = document.data();

          if (data is! Map<String, dynamic>) {
            continue;
          }

          final unreadCount = data['unreadCount'];

          if (unreadCount is! Map) {
            continue;
          }

          final userUnreadCount = unreadCount[userId];

          if (userUnreadCount is num) {
            totalUnread += userUnreadCount.toInt();
          }
        }

        return totalUnread;
      })
      .distinct();
}

  /// 获取聊天参与者
  Future<List<String>> getChatParticipants(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;
    return List<String>.from(data['users'] ?? []);
  }

  /// 标记已读
  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$userId': 0,
    });
  }

  // ============================================================
  // 2. 消息管理
  // ============================================================

  /// 发送文本消息
  Future<void> sendMessage(String chatId, String senderId, String content) async {
    final now = FieldValue.serverTimestamp();

    // 添加消息
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'content': content,
      'imageUrl': null,
      'timestamp': now,
    });

    // 更新聊天室
    final users = await getChatParticipants(chatId);
    final unreadCount = <String, dynamic>{};
    for (final uid in users) {
      unreadCount[uid] = uid == senderId ? 0 : FieldValue.increment(1);
    }

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': content,
      'updatedAt': now,
      'unreadCount': unreadCount,
    });
  }

  /// 上传图片到 Storage
  Future<String> uploadChatImage(File imageFile) async {
    final ref = _storage
        .ref()
        .child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(imageFile);
    return ref.getDownloadURL();
  }

  /// 发送图片消息
  Future<void> sendImageMessage(String chatId, String senderId, String imageUrl) async {
    final now = FieldValue.serverTimestamp();

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'content': '',
      'imageUrl': imageUrl,
      'timestamp': now,
    });

    final users = await getChatParticipants(chatId);
    final unreadCount = <String, dynamic>{};
    for (final uid in users) {
      unreadCount[uid] = uid == senderId ? 0 : FieldValue.increment(1);
    }

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': '[图片]',
      'updatedAt': now,
      'unreadCount': unreadCount,
    });
  }

  /// 监听消息（实时）
  Stream<QuerySnapshot> watchMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}