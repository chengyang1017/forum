import 'package:flutter/foundation.dart';
import '../../domain/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/user_api.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  final UserApi _userApi = UserApi();

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

  // ========== 登录 ==========
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

  // ========== 注册 ==========
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

  // ========== 加载当前用户 ==========
Future<void> loadUser() async {
  _isLoading = true;
  notifyListeners();

  try {
    final legacyUser =
        await _authRepo.getCurrentUser();

    _user = legacyUser;

    if (legacyUser == null) {
      return;
    }

    await _syncBackendUser();

    final backendUser =
        await _userApi.getCurrentUser();

    if (backendUser == null) {
      return;
    }

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
  } catch (error) {
    debugPrint(
      'Load backend user failed: $error',
    );
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // ========== 更新用户资料 ==========
  Future<void> updateUser(UserModel newUser) async {
    _user = await _authRepo.updateProfile(newUser);
    notifyListeners();
  }

  // ========== 修改密码 ==========
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

  // ========== 密保问题（找回密码用） ==========
  Future<(String uid, String question)?> getSecurityQuestion(
    String email,
  ) async {
    return _authRepo.getSecurityQuestion(email);
  }

  Future<bool> verifySecurityAnswer(String uid, String answer) async {
    return _authRepo.verifySecurityAnswer(uid, answer);
  }

  // ========== 登出 ==========
  Future<void> logout() async {
    await _authRepo.logout();
    _user = null;
    notifyListeners();
  }
}
