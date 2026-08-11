import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/discover_service.dart';

class DiscoverRepository {
  final DiscoverService _discoverService = DiscoverService();

  // ========== 获取所有用户列表（排除自己） ==========
  Stream<QuerySnapshot> watchAllUsers(String currentUserId) {
    return _discoverService.watchAllUsers(currentUserId);
  }

  // ========== 获取或创建聊天室 ==========
  Future<String> getOrCreateChat(String otherUserId) {
    return _discoverService.getOrCreateChat(otherUserId);
  }

  // ========== 发送好友请求 ==========
  Future<void> sendFriendRequest(String targetUserId) {
    return _discoverService.sendFriendRequest(targetUserId);
  }
}