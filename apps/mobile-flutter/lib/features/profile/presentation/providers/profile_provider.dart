import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../auth/domain/models/user_model.dart';
import '../../../post/domain/models/post_model.dart';
import '../../../post/domain/repositories/post_repository.dart';
import '../../application/models/local_profile_image.dart';
import '../../application/ports/profile_media_repository.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    required PostRepository postRepository,
    required ProfileRepository profileRepository,
    required ProfileMediaRepository mediaRepository,
  })  : _postRepository = postRepository,
        _profileRepository = profileRepository,
        _mediaRepository = mediaRepository;

  final PostRepository _postRepository;
  final ProfileRepository _profileRepository;
  final ProfileMediaRepository _mediaRepository;

  UserModel _userProfile = const UserModel(id: '', username: '');

  bool loadingProfile = true;
  bool uploadingAvatar = false;

  UserModel get userProfile => _userProfile;
  String get avatarUrl => _userProfile.avatarUrl;
  String get username => _userProfile.username;
  String get nickname => _userProfile.nicknameText;
  String get bio => _userProfile.bioText;
  List<String> get tags => _userProfile.tagsList;
  List<Map<String, dynamic>> get languages => _userProfile.languageList;
  DateTime? get birthday => _userProfile.birthday;
  bool get showAge => _userProfile.showAge;
  String get displayName => _userProfile.profileDisplayName;

  Future<void> loadProfile(String uid) async {
    loadingProfile = true;
    notifyListeners();

    try {
      final profile = await _profileRepository.getProfile(uid);
      if (profile != null) {
        _userProfile = profile;
      }
    } catch (error) {
      debugPrint('加载资料失败: $error');
    } finally {
      loadingProfile = false;
      notifyListeners();
    }
  }

  Stream<List<PostModel>> watchUserPosts(String uid) {
    return _postRepository.watchUserPosts(uid);
  }

  int totalLikesOf(List<PostModel> posts) {
    return posts.fold<int>(0, (total, post) => total + post.likeCount);
  }

  Future<void> updateTags(String uid, List<String> newTags) {
    final copiedTags = List<String>.from(newTags);
    return _commitOptimistic(
      optimistic: _userProfile.copyWith(tags: copiedTags),
      persist: () => _profileRepository.updateTags(
        userId: uid,
        tags: copiedTags,
      ),
    );
  }

  Future<void> updateLanguages(
    String uid,
    List<Map<String, dynamic>> newLanguages,
  ) {
    final copiedLanguages = newLanguages
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);

    return _commitOptimistic(
      optimistic: _userProfile.copyWith(languages: copiedLanguages),
      persist: () => _profileRepository.updateLanguages(
        userId: uid,
        languages: copiedLanguages,
      ),
    );
  }

  Future<void> updateBirthday(
    String uid,
    DateTime? newBirthday,
    bool newShowAge,
  ) {
    return _commitOptimistic(
      optimistic: _userProfile.copyWith(
        birthday: newBirthday,
        clearBirthday: newBirthday == null,
        showAge: newShowAge,
      ),
      persist: () => _profileRepository.updateBirthday(
        userId: uid,
        birthday: newBirthday,
        showAge: newShowAge,
      ),
    );
  }

  Future<void> updateAvatar(String uid, File imageFile) async {
    if (uploadingAvatar) {
      return;
    }

    uploadingAvatar = true;
    notifyListeners();

    final previousProfile = _userProfile;
    final oldAvatarUrl = previousProfile.avatarUrl;
    String? uploadedAvatarUrl;

    try {
      uploadedAvatarUrl = await _mediaRepository.uploadAvatar(
        userId: uid,
        image: LocalProfileImage(path: imageFile.path),
      );

      _userProfile = await _profileRepository.updateAvatarUrl(
        userId: uid,
        avatarUrl: uploadedAvatarUrl,
      );
      notifyListeners();

      if (_isRemoteAvatar(oldAvatarUrl) && oldAvatarUrl != uploadedAvatarUrl) {
        try {
          await _mediaRepository.deleteAvatar(oldAvatarUrl);
        } catch (error) {
          debugPrint('删除旧头像失败: $error');
        }
      }
    } catch (error) {
      _userProfile = previousProfile;
      notifyListeners();

      if (uploadedAvatarUrl != null) {
        try {
          await _mediaRepository.deleteAvatar(uploadedAvatarUrl);
        } catch (cleanupError) {
          debugPrint('清理未提交头像失败: $cleanupError');
        }
      }
      rethrow;
    } finally {
      uploadingAvatar = false;
      notifyListeners();
    }
  }

  Future<void> updateNickname(String uid, String newNickname) {
    return _commitOptimistic(
      optimistic: _userProfile.copyWith(nickname: newNickname),
      persist: () => _profileRepository.updateNickname(
        userId: uid,
        nickname: newNickname,
      ),
    );
  }

  Future<void> updateUsername(String uid, String newUsername) {
    return _commitOptimistic(
      optimistic: _userProfile.copyWith(username: newUsername),
      persist: () => _profileRepository.updateUsername(
        userId: uid,
        username: newUsername,
      ),
    );
  }

  Future<void> updateBio(String uid, String newBio) {
    return _commitOptimistic(
      optimistic: _userProfile.copyWith(bio: newBio),
      persist: () => _profileRepository.updateBio(
        userId: uid,
        bio: newBio,
      ),
    );
  }

  Future<void> _commitOptimistic({
    required UserModel optimistic,
    required Future<UserModel> Function() persist,
  }) async {
    final previous = _userProfile;
    _userProfile = optimistic;
    notifyListeners();

    try {
      _userProfile = await persist();
      notifyListeners();
    } catch (_) {
      _userProfile = previous;
      notifyListeners();
      rethrow;
    }
  }

  bool _isRemoteAvatar(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }
}
