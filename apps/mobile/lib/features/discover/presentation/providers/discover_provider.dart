import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/discover_repository.dart';

class DiscoverProvider extends ChangeNotifier {
  final DiscoverRepository _discoverRepo = DiscoverRepository();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========== 获取所有用户列表（排除自己） ==========
  Stream<QuerySnapshot> watchAllUsers(String currentUserId) {
    return _discoverRepo.watchAllUsers(currentUserId);
  }

  // ========== 获取或创建聊天室 ==========
  Future<String> getOrCreateChat(String otherUserId) {
    return _discoverRepo.getOrCreateChat(otherUserId);
  }

  // ========== 发送好友请求 ==========
  Future<void> sendFriendRequest(String targetUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _discoverRepo.sendFriendRequest(targetUserId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
