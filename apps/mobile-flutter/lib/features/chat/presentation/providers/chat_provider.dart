import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart' as auth_cubit;

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepo = ChatRepository();

  List<QueryDocumentSnapshot>? _chats;
  bool _isLoading = false;
  String? _error;

  List<QueryDocumentSnapshot>? get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================================
  // 1. 聊天室管理
  // ============================================================

  /// 获取或创建聊天室
  Future<String> getOrCreateChat(String otherUserId) {
    return _chatRepo.getOrCreateChat(otherUserId);
  }

  /// 加载聊天列表（一次性）
  Future<void> loadChats(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chats = await _chatRepo.getChats(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 监听聊天列表（实时）
  Stream<QuerySnapshot> watchChats(String userId) {
    return _chatRepo.watchChats(userId);
  }

  /// 实时监听当前用户所有聊天室的未读消息总数
  Stream<int> watchTotalUnread(String userId) {
    return _chatRepo.watchTotalUnread(userId);
  }

  /// 获取聊天参与者
  Future<List<String>> getChatParticipants(String chatId) {
    return _chatRepo.getChatParticipants(chatId);
  }

  /// 标记已读
  Future<void> markAsRead(String chatId, String userId) async {
    await _chatRepo.markAsRead(chatId, userId);
  }

  /// 获取未读数量
  // int getUnreadCount(Map<String, dynamic> chatData, String userId) {
  //   final unreadMap = chatData['unreadCount'] as Map<String, dynamic>? ?? {};
  //   return (unreadMap[userId] ?? 0) as int;
  // }

  int getUnreadCount(Map<String, dynamic> chatData, String userId) {
    final rawUnreadCount = chatData['unreadCount'];

    if (rawUnreadCount is! Map) {
      return 0;
    }

    final rawCount = rawUnreadCount[userId];

    return rawCount is num ? rawCount.toInt() : 0;
  }

  // ============================================================
  // 2. 消息管理
  // ============================================================

  /// 发送文本消息
  Future<void> sendMessage(String chatId, String content) async {
    // 从 AuthCubit 获取当前用户 ID（需要在调用时传入）
    // 或通过其他方式获取
    // 这里建议在 UI 层传入 senderId，或者通过 AuthCubit 获取
    // 我们留到 UI 层处理
    throw UnimplementedError('请在 UI 层传入 senderId，或通过 AuthCubit 获取');
  }

  /// 发送文本消息（带 senderId）
  Future<void> sendMessageWithSender(
    String chatId,
    String senderId,
    String content,
  ) async {
    await _chatRepo.sendMessage(chatId, senderId, content);
  }

  /// 上传聊天图片
  Future<String> uploadChatImage(File imageFile) async {
    return _chatRepo.uploadChatImage(imageFile);
  }

  /// 发送图片消息
  Future<void> sendImageMessageWithSender(
    String chatId,
    String senderId,
    String imageUrl,
  ) async {
    await _chatRepo.sendImageMessage(chatId, senderId, imageUrl);
  }

  /// 发送图片消息（自动获取 senderId）
  /// 注意：需要在调用时传入 authProvider
  Future<void> sendImageMessage(
    String chatId,
    File imageFile,
    auth_cubit.AuthCubit authProvider,
  ) async {
    final senderId = authProvider.user?.id;
    if (senderId == null) throw Exception('未登录');

    final imageUrl = await _chatRepo.uploadChatImage(imageFile);
    await _chatRepo.sendImageMessage(chatId, senderId, imageUrl);
  }

  /// 监听消息
  Stream<QuerySnapshot> watchMessages(String chatId) {
    return _chatRepo.watchMessages(chatId);
  }

  // ============================================================
  // 3. 状态管理
  // ============================================================

  void clear() {
    _chats = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> sendVocabularyMessage({
    required String chatId,
    required String senderId,
    required String word,
    String? translation,
    String? languageCode,
  }) async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    final messageRef = chatRef.collection('messages').doc();

    final translations = <String, String>{};

    if (translation != null && translation.trim().isNotEmpty) {
      translations[senderId] = translation.trim();
    }

    final batch = FirebaseFirestore.instance.batch();

    batch.set(messageRef, {
      'type': 'vocab',
      'senderId': senderId,
      'word': word.trim(),
      'languageCode': languageCode,
      'translations': translations,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(chatRef, {
      'lastMessage': '[单词] ${word.trim()}',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> updateVocabularyTranslation({
    required String chatId,
    required String messageId,
    required String userId,
    required String translation,
  }) async {
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({'translations.$userId': translation.trim()});
  }

  Future<void> updateLiveDraftEnabled({
    required String chatId,
    required String userId,
    required bool enabled,
  }) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('memberSettings')
        .doc(userId)
        .set({'shareLiveDraft': enabled}, SetOptions(merge: true));
  }

  Future<bool> getLiveDraftEnabled({
    required String chatId,
    required String userId,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('memberSettings')
        .doc(userId)
        .get();

    return doc.data()?['shareLiveDraft'] == true;
  }

  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String currentUserId,
    required String newContent,
  }) {
    return _chatRepo.editMessage(
      chatId: chatId,
      messageId: messageId,
      currentUserId: currentUserId,
      newContent: newContent,
    );
  }

  Future<void> deleteMessageForMe({
    required String chatId,
    required String messageId,
    required String currentUserId,
  }) {
    return _chatRepo.deleteMessageForMe(
      chatId: chatId,
      messageId: messageId,
      currentUserId: currentUserId,
    );
  }

  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
    required String currentUserId,
  }) {
    return _chatRepo.deleteMessageForEveryone(
      chatId: chatId,
      messageId: messageId,
      currentUserId: currentUserId,
    );
  }
}
