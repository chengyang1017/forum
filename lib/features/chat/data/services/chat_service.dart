import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  static const Duration _messageCleanupDelay =
    Duration(days: 7);

  Timestamp _buildCleanupAt() {
    return Timestamp.fromDate(
      DateTime.now()
          .toUtc()
          .add(_messageCleanupDelay),
    );
  }
  
  String _requireCurrentUserId() {
  final currentUserId =
      _auth.currentUser?.uid;

  if (currentUserId == null) {
    throw StateError('未登录');
  }

  return currentUserId;
}

void _verifyCurrentUser(
  String providedUserId,
) {
  final actualUserId =
      _requireCurrentUserId();

  if (providedUserId != actualUserId) {
    throw StateError(
      '用户身份不一致',
    );
  }
}
  

  // ============================================================
  // 1. 聊天室管理
  // ============================================================

  /// 获取或创建私聊聊天室
  Future<String> getOrCreateChat(
    String otherUserId,
  ) async {
    final currentUid =
        _auth.currentUser?.uid;

    if (currentUid == null) {
      throw StateError('未登录');
    }

    final userIds = [
      currentUid,
      otherUserId,
    ]..sort();

    final chatRef = _firestore
        .collection('chats')
        .doc(userIds.join('_'));

    final snapshot = await chatRef.get();

    if (!snapshot.exists) {
      await chatRef.set({
        'users': userIds,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageId': null,
        'lastSenderId': null,
        'unreadCount': {
          currentUid: 0,
          otherUserId: 0,
        },
      });
    }

    return chatRef.id;
  }

  /// 获取聊天列表
  Future<QuerySnapshot> getChats(
    String userId,
  ) {
    return _firestore
        .collection('chats')
        .where(
          'users',
          arrayContains: userId,
        )
        .orderBy(
          'updatedAt',
          descending: true,
        )
        .get();
  }

  /// 实时监听聊天列表
  Stream<QuerySnapshot> watchChats(
    String userId,
  ) {
    return _firestore
        .collection('chats')
        .where(
          'users',
          arrayContains: userId,
        )
        .orderBy(
          'updatedAt',
          descending: true,
        )
        .snapshots();
  }

  /// 实时监听全部聊天室的未读总数
  Stream<int> watchTotalUnread(
    String userId,
  ) {
    return watchChats(userId)
        .map((snapshot) {
          var totalUnread = 0;

          for (final document
              in snapshot.docs) {
            final data = document.data();

            if (data
                is! Map<String, dynamic>) {
              continue;
            }

            final unreadCount =
                data['unreadCount'];

            if (unreadCount is! Map) {
              continue;
            }

            final count =
                unreadCount[userId];

            if (count is num) {
              totalUnread += count.toInt();
            }
          }

          return totalUnread;
        })
        .distinct();
  }

  /// 获取聊天参与者
  Future<List<String>>
      getChatParticipants(
    String chatId,
  ) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .get();

    final data = snapshot.data();

    if (data == null) {
      return [];
    }

    return List<String>.from(
      data['users'] ?? const [],
    );
  }

  /// 标记当前用户已读
  Future<void> markAsRead(
    String chatId,
    String userId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .update({
      'unreadCount.$userId': 0,
    });
  }

  // ============================================================
  // 2. 发送消息
  // ============================================================

  /// 发送文本消息
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String content,
  ) async {
    _verifyCurrentUser(senderId);
    final cleanContent = content.trim();

    if (cleanContent.isEmpty) {
      throw ArgumentError(
        '消息内容不能为空',
      );
    }

    final chatRef = _firestore
        .collection('chats')
        .doc(chatId);

    final messageRef = chatRef
        .collection('messages')
        .doc();

    final users =
        await getChatParticipants(chatId);

    if (!users.contains(senderId)) {
      throw StateError(
        '当前用户不是聊天室成员',
      );
    }

    final batch = _firestore.batch();
    final now =
        FieldValue.serverTimestamp();

    batch.set(messageRef, {
  'type': 'text',
  'senderId': senderId,
  'content': cleanContent,
  'imageUrl': null,
  'imagePath': null,
  'timestamp': now,

  'editedAt': null,

  'hiddenFor': <String>[],

  'status': 'active',
  'deletedBy': null,
  'deletedAt': null,
  'cleanupAt': null,
});

    final chatUpdates =
        <String, dynamic>{
      'lastMessage': cleanContent,
      'lastMessageId': messageRef.id,
      'lastSenderId': senderId,
      'updatedAt': now,
    };

    for (final userId in users) {
      chatUpdates['unreadCount.$userId'] =
          userId == senderId
              ? 0
              : FieldValue.increment(1);
    }

    batch.update(
      chatRef,
      chatUpdates,
    );

    await batch.commit();
  }

  /// 上传聊天图片
  Future<String> uploadChatImage(
    File imageFile,
  ) async {
    final currentUid =
        _auth.currentUser?.uid;

    if (currentUid == null) {
      throw StateError('未登录');
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final imageRef = _storage
        .ref()
        .child(
          'chat_images/$currentUid/$fileName',
        );

    await imageRef.putFile(imageFile);

    return imageRef.getDownloadURL();
  }

  /// 发送图片消息
  Future<void> sendImageMessage(
    String chatId,
    String senderId,
    String imageUrl,
  ) async {
    _verifyCurrentUser(senderId);
    final cleanImageUrl =
        imageUrl.trim();

    if (cleanImageUrl.isEmpty) {
      throw ArgumentError(
        '图片地址不能为空',
      );
    }

    final chatRef = _firestore
        .collection('chats')
        .doc(chatId);

    final messageRef = chatRef
        .collection('messages')
        .doc();

    final users =
        await getChatParticipants(chatId);

    if (!users.contains(senderId)) {
      throw StateError(
        '当前用户不是聊天室成员',
      );
    }

    final imagePath = _storage
    .refFromURL(cleanImageUrl)
    .fullPath;

    final batch = _firestore.batch();
    final now =
        FieldValue.serverTimestamp();

    batch.set(messageRef, {
  'type': 'image',
  'senderId': senderId,
  'content': '',
  'imageUrl': cleanImageUrl,
  'imagePath': imagePath,
  'timestamp': now,

  'editedAt': null,

  'hiddenFor': <String>[],

  'status': 'active',
  'deletedBy': null,
  'deletedAt': null,
  'cleanupAt': null,
});

    final chatUpdates =
        <String, dynamic>{
      'lastMessage': '[图片]',
      'lastMessageId': messageRef.id,
      'lastSenderId': senderId,
      'updatedAt': now,
    };

    for (final userId in users) {
      chatUpdates['unreadCount.$userId'] =
          userId == senderId
              ? 0
              : FieldValue.increment(1);
    }

    batch.update(
      chatRef,
      chatUpdates,
    );

    await batch.commit();
  }

  // ============================================================
  // 3. 监听消息
  // ============================================================

  /// 实时监听聊天消息
  Stream<QuerySnapshot> watchMessages(
    String chatId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy(
          'timestamp',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // 4. 编辑消息
  // ============================================================

  Future<void> editMessage({
  required String chatId,
  required String messageId,
  required String currentUserId,
  required String newContent,
}) async {
  _verifyCurrentUser(currentUserId);
  final cleanContent = newContent.trim();

  if (cleanContent.isEmpty) {
    throw ArgumentError('消息内容不能为空');
  }

  final messageRef = _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .doc(messageId);

  await _firestore.runTransaction(
    (transaction) async {
      final snapshot =
          await transaction.get(messageRef);

      final data = snapshot.data();

      if (data == null) {
        throw StateError('消息不存在');
      }

      if (data['senderId'] != currentUserId) {
        throw StateError('只能编辑自己发送的消息');
      }

      final status =
          data['status'] as String? ?? 'active';

      if (status != 'active') {
        throw StateError('已删除的消息不能编辑');
      }

      final imageUrl =
          data['imageUrl'] as String?;

      if (imageUrl != null &&
          imageUrl.trim().isNotEmpty) {
        throw StateError('图片消息暂不支持编辑');
      }

      transaction.update(messageRef, {
        'content': cleanContent,
        'editedAt':
            FieldValue.serverTimestamp(),
      });
    },
  );

  await _refreshChatPreview(chatId);
}

  // ============================================================
  // 5. 删除消息
  // ============================================================

  Future<void> deleteMessageForMe({
  required String chatId,
  required String messageId,
  required String currentUserId,
}) async {
  _verifyCurrentUser(
    currentUserId,
  );
  final chatRef = _firestore
      .collection('chats')
      .doc(chatId);

  final messageRef = chatRef
      .collection('messages')
      .doc(messageId);

  final hiddenForEveryone =
      await _firestore.runTransaction<bool>(
    (transaction) async {
      final chatSnapshot =
          await transaction.get(chatRef);

      final messageSnapshot =
          await transaction.get(messageRef);

      final chatData = chatSnapshot.data();
      final messageData =
          messageSnapshot.data();

      if (chatData == null) {
        throw StateError('聊天室不存在');
      }

      if (messageData == null) {
        throw StateError('消息不存在');
      }

      final participants =
          List<String>.from(
        chatData['users'] ?? const [],
      );

      if (!participants.contains(
        currentUserId,
      )) {
        throw StateError('当前用户不是聊天室成员');
      }

      final oldHiddenFor =
          List<String>.from(
        messageData['hiddenFor'] ??
            const [],
      );

      if (oldHiddenFor.contains(
        currentUserId,
      )) {
        return false;
      }

      final newHiddenFor = <String>{
        ...oldHiddenFor,
        currentUserId,
      }.toList();

      final allParticipantsHidden =
          participants.isNotEmpty &&
          participants.every(
            newHiddenFor.contains,
          );

      final updates = <String, dynamic>{
        'hiddenFor': newHiddenFor,
      };

      if (allParticipantsHidden) {
        updates['cleanupAt'] =
            _buildCleanupAt();
      }

      transaction.update(
        messageRef,
        updates,
      );

      return allParticipantsHidden;
    },
  );

  // 所有人都隐藏后，这条消息不应继续作为
  // 聊天列表的最后一条预览。
  if (hiddenForEveryone) {
    await _refreshChatPreview(chatId);
  }
}

  Future<void> deleteMessageForEveryone({
  required String chatId,
  required String messageId,
  required String currentUserId,
}) async {
  final messageRef = _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .doc(messageId);

  await _firestore.runTransaction(
    (transaction) async {
      final snapshot =
          await transaction.get(messageRef);

      final data = snapshot.data();

      if (data == null) {
        throw StateError('消息不存在');
      }

      if (data['senderId'] != currentUserId) {
        throw StateError('只能删除自己发送的消息');
      }

      final status =
          data['status'] as String? ?? 'active';

      if (status == 'deleted') {
        return;
      }

      final updates = <String, dynamic>{
        'status': 'deleted',
        'deletedBy': currentUserId,
        'deletedAt':
            FieldValue.serverTimestamp(),
        'cleanupAt': _buildCleanupAt(),

        // 清除用户内容，但保留消息占位。
        'content': '',
        'imageUrl': null,
        'editedAt': null,
      };

      // 兼容以前没有 imagePath 的图片消息。
      final existingImagePath =
          data['imagePath'] as String?;

      final oldImageUrl =
          data['imageUrl'] as String?;

      if ((existingImagePath == null ||
              existingImagePath.isEmpty) &&
          oldImageUrl != null &&
          oldImageUrl.isNotEmpty) {
        try {
          updates['imagePath'] = _storage
              .refFromURL(oldImageUrl)
              .fullPath;
        } catch (_) {
          // 无法解析旧地址时不阻止逻辑删除。
        }
      }

      transaction.update(
        messageRef,
        updates,
      );
    },
  );

  await _refreshChatPreview(chatId);
}

  // ============================================================
  // 6. 私有辅助方法
  // ============================================================

  Future<void> _refreshChatPreview(
  String chatId,
) async {
  final chatRef = _firestore
      .collection('chats')
      .doc(chatId);

  final chatSnapshot =
      await chatRef.get();

  final chatData =
      chatSnapshot.data();

  if (chatData == null) {
    return;
  }

  final participants =
      List<String>.from(
    chatData['users'] ?? const [],
  );

  final messagesSnapshot =
      await chatRef
          .collection('messages')
          .orderBy(
            'timestamp',
            descending: true,
          )
          .limit(50)
          .get();

  QueryDocumentSnapshot<
      Map<String, dynamic>>?
      latestVisibleDocument;

  for (final document
      in messagesSnapshot.docs) {
    final message = document.data();

    final hiddenFor =
        List<String>.from(
      message['hiddenFor'] ?? const [],
    );

    final hiddenForEveryone =
        participants.isNotEmpty &&
        participants.every(
          hiddenFor.contains,
        );

    if (hiddenForEveryone) {
      continue;
    }

    latestVisibleDocument = document;
    break;
  }

  if (latestVisibleDocument == null) {
    await chatRef.update({
      'lastMessage': '',
      'lastMessageId': null,
      'lastSenderId': null,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    return;
  }

  final latestData =
      latestVisibleDocument.data();

  await chatRef.update({
    'lastMessage':
        _buildMessagePreview(latestData),
    'lastMessageId':
        latestVisibleDocument.id,
    'lastSenderId':
        latestData['senderId'],
    'updatedAt':
        latestData['timestamp'] ??
        FieldValue.serverTimestamp(),
  });
}

  String _buildMessagePreview(
  Map<String, dynamic> message,
) {
  final status =
      message['status'] as String? ??
      'active';

  if (status == 'deleted') {
    return '此消息已删除';
  }

  final type =
      message['type'] as String?;

  final imageUrl =
      message['imageUrl'] as String?;

  if (imageUrl != null &&
      imageUrl.trim().isNotEmpty) {
    return '[图片]';
  }

  if (type == 'vocab') {
    final word =
        message['word'] as String? ?? '';

    return word.trim().isEmpty
        ? '[单词]'
        : '[单词] ${word.trim()}';
  }

  final content =
      message['content'] as String? ?? '';

  return content.trim().isEmpty
      ? '[消息]'
      : content.trim();
}
}