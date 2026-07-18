import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../auth/providers/auth_provider.dart' as authProv;

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

  int getUnreadCount(
    Map<String, dynamic> chatData,
    String userId,
  ) {
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
    // 从 AuthProvider 获取当前用户 ID（需要在调用时传入）
    // 或通过其他方式获取
    // 这里建议在 UI 层传入 senderId，或者通过 AuthProvider 获取
    // 我们留到 UI 层处理
    throw UnimplementedError('请在 UI 层传入 senderId，或通过 AuthProvider 获取');
  }

  /// 发送文本消息（带 senderId）
  Future<void> sendMessageWithSender(String chatId, String senderId, String content) async {
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
    authProv.AuthProvider authProvider,
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


}