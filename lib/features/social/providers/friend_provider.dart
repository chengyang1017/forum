import 'package:flutter/foundation.dart';
import '../../../shared/services/friend_service.dart';

class FriendProvider extends ChangeNotifier {
  final FriendService _friendService = FriendService();

  List<String>? _friendUids;
  bool _isLoading = false;
  String? _error;

  List<String>? get friendUids => _friendUids;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========== 加载好友列表（一次性） ==========
  Future<void> loadFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _friendUids = await _friendService.myFriends().first;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== 监听实时好友列表 ==========
  Stream<List<String>> watchFriends() {
    return _friendService.myFriends();
  }

  // ========== 清除状态 ==========
  void clear() {
    _friendUids = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}