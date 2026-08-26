import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/user_api.dart';
import '../../domain/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final UserApi _userApi = UserApi();

  UserModel? _user;
  bool _isLoading = false;

  Set<String> _interests = <String>{};
  bool _interestsLoaded = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Set<String> get interests => Set<String>.unmodifiable(_interests);

  bool get interestsLoaded => _interestsLoaded;

  bool isInterested(String key) {
    return _interests.contains(key);
  }

  Future<void> _syncBackendUser() async {
    final user = _user;

    if (user == null) {
      return;
    }

    try {
      await _userApi.syncCurrentUser(user);
    } catch (error) {
      debugPrint('Node.js user sync failed: $error');
    }
  }

  // ============================================================
  // Interests
  // ============================================================

  Set<String> _readLegacyInterests(Object? value) {
    if (value is! Iterable) {
      return <String>{};
    }

    return value
        .whereType<String>()
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toSet();
  }

  Future<void> _loadInterests() async {
    final user = _user;

    if (user == null) {
      _interests = <String>{};
      _interestsLoaded = false;
      return;
    }

    try {
      // --------------------------------------------
      // 1. 先问 PostgreSQL：
      //    这个用户以前迁移过 interests 没有？
      // --------------------------------------------

      final state = await _userApi.getInterestState();

      if (state.migrated) {
        _interests = state.interests;
        _interestsLoaded = true;

        return;
      }

      // --------------------------------------------
      // 2. 只有从未迁移过的旧用户
      //    才读取一次 Firestore。
      // --------------------------------------------

      final legacySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();

      final legacyInterests = _readLegacyInterests(
        legacySnapshot.data()?['interests'],
      );

      // --------------------------------------------
      // 3. 一次性导入 PostgreSQL。
      //
      // 后端 interestsMigratedAt 会阻止
      // 将来再次被旧 Firestore 覆盖。
      // --------------------------------------------

      _interests = await _userApi.migrateInterests(legacyInterests);

      _interestsLoaded = true;
    } catch (error) {
      debugPrint('Load interests failed: $error');

      _interestsLoaded = false;
    }
  }

  Future<void> toggleInterest(String key) async {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      return;
    }

    final previous = Set<String>.from(_interests);

    final next = Set<String>.from(_interests);

    if (!next.add(normalizedKey)) {
      next.remove(normalizedKey);
    }

    // 乐观更新
    _interests = next;
    notifyListeners();

    try {
      _interests = await _userApi.updateInterests(next);

      _interestsLoaded = true;
      notifyListeners();
    } catch (error) {
      // Node 写入失败 → 回滚
      _interests = previous;
      notifyListeners();

      rethrow;
    }
  }

  Future<void> refreshInterests() async {
    final state = await _userApi.getInterestState();

    _interests = state.interests;
    _interestsLoaded = true;

    notifyListeners();
  }

  // ============================================================
  // 登录
  // ============================================================

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authRepo.login(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // 注册
  // ============================================================

  Future<void> register(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authRepo.register(email, password, username);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // 加载当前用户
  // ============================================================

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final legacyUser = await _authRepo.getCurrentUser();

      _user = legacyUser;

      if (legacyUser == null) {
        _interests = <String>{};
        _interestsLoaded = false;
        return;
      }

      // Firestore 用户资料 → PostgreSQL 用户
      await _syncBackendUser();

      final backendUser = await _userApi.getCurrentUser();

      if (backendUser != null) {
        _user = legacyUser.copyWith(
          username: backendUser.username,
          email: backendUser.email,
          nickname: backendUser.nickname,
          avatar: backendUser.avatar,
          bio: backendUser.bio,
          birthday: backendUser.birthday,
          showAge: backendUser.showAge,
          createdAt: backendUser.createdAt,
          lastActive: backendUser.lastActive,
        );
      }

      // PostgreSQL User 已经确保存在，
      // 现在才能安全迁移 / 加载 interests。
      await _loadInterests();
    } catch (error) {
      debugPrint('Load backend user failed: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // 更新用户资料
  // ============================================================

  Future<void> updateUser(UserModel newUser) async {
    _user = await _authRepo.updateProfile(newUser);

    notifyListeners();
  }

  // ============================================================
  // 修改密码
  // ============================================================

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepo.changePassword(currentPassword, newPassword);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // 密保问题
  // ============================================================

  Future<(String uid, String question)?> getSecurityQuestion(
    String email,
  ) async {
    return _authRepo.getSecurityQuestion(email);
  }

  Future<bool> verifySecurityAnswer(String uid, String answer) async {
    return _authRepo.verifySecurityAnswer(uid, answer);
  }

  // ============================================================
  // 登出
  // ============================================================

  Future<void> logout() async {
    await _authRepo.logout();

    _user = null;
    _interests = <String>{};
    _interestsLoaded = false;

    notifyListeners();
  }
}
