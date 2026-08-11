import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../post/domain/models/post_model.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../../core/services/storage_service.dart';

class ProfileProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        _userProfile = UserModel.fromJson({
          'uid': doc.id,
          ...?doc.data(),
        });
      }
    } catch (e) {
      debugPrint('加载资料失败: $e');
    } finally {
      loadingProfile = false;
      notifyListeners();
    }
  }

  Stream<List<PostModel>> watchUserPosts(String uid) {
    return _firestore
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  int totalLikesOf(List<PostModel> posts) {
    return posts.fold<int>(0, (total, post) {
      return total + (post.likes?.length ?? post.likeCount);
    });
  }

  Future<void> updateTags(String uid, List<String> newTags) async {
    await _firestore.collection('users').doc(uid).update({'tags': newTags});

    _userProfile = _userProfile.copyWith(
      tags: List<String>.from(newTags),
    );
    notifyListeners();
  }

  Future<void> updateLanguages(
    String uid,
    List<Map<String, dynamic>> newLanguages,
  ) async {
    final copiedLanguages = newLanguages
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    await _firestore.collection('users').doc(uid).update({
      'languages': copiedLanguages,
    });

    _userProfile = _userProfile.copyWith(languages: copiedLanguages);
    notifyListeners();
  }

  Future<void> updateBirthday(
    String uid,
    DateTime? newBirthday,
    bool newShowAge,
  ) async {
    await _firestore.collection('users').doc(uid).update({
      'birthday': newBirthday == null
          ? FieldValue.delete()
          : Timestamp.fromDate(newBirthday),
      'showAge': newShowAge,
    });

    _userProfile = _userProfile.copyWith(
      birthday: newBirthday,
      clearBirthday: newBirthday == null,
      showAge: newShowAge,
    );
    notifyListeners();
  }

  Future<void> updateAvatar(String uid, File imageFile) async {
    uploadingAvatar = true;
    notifyListeners();

    try {
      if (avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
        await _storageService.deleteOldAvatar(avatarUrl);
      }

      final downloadUrl = await _storageService.uploadAvatar(imageFile);

      await _firestore.collection('users').doc(uid).update({
        'avatar': downloadUrl,
      });

      _userProfile = _userProfile.copyWith(avatar: downloadUrl);
    } finally {
      uploadingAvatar = false;
      notifyListeners();
    }
  }

  Future<void> updateNickname(String uid, String newNickname) async {
    await _firestore.collection('users').doc(uid).update({
      'nickname': newNickname.isNotEmpty ? newNickname : FieldValue.delete(),
    });

    final posts = await _firestore
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .get();

    for (final doc in posts.docs) {
      await doc.reference.update({
        'nickname': newNickname.isNotEmpty ? newNickname : FieldValue.delete(),
      });
    }

    _userProfile = _userProfile.copyWith(nickname: newNickname);
    notifyListeners();
  }

  Future<void> updateUsername(String uid, String newUsername) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: newUsername)
        .get();

    if (query.docs.isNotEmpty && query.docs.first.id != uid) {
      throw Exception('该用户名已被使用');
    }

    await _firestore.collection('users').doc(uid).update({
      'username': newUsername,
    });

    final posts = await _firestore
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .get();

    for (final doc in posts.docs) {
      await doc.reference.update({'username': newUsername});
    }

    _userProfile = _userProfile.copyWith(username: newUsername);
    notifyListeners();
  }

  Future<void> updateBio(String uid, String newBio) async {
    await _firestore.collection('users').doc(uid).update({'bio': newBio});

    _userProfile = _userProfile.copyWith(bio: newBio);
    notifyListeners();
  }
}
