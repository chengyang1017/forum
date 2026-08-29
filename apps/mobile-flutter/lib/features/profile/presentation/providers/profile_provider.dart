import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../post/domain/models/post_model.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../../auth/data/services/user_api.dart';
import '../../../post/data/services/post_node_service.dart';

class ProfileProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserApi _userApi = UserApi();
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
  final PostService _postService = PostService();
  // Future<void> loadProfile(String uid) async {
  //   loadingProfile = true;
  //   notifyListeners();

  //   try {
  //     final doc = await _firestore.collection('users').doc(uid).get();

  //     if (doc.exists) {
  //       _userProfile = UserModel.fromJson({'uid': doc.id, ...?doc.data()});
  //     }
  //   } catch (e) {
  //     debugPrint('加载资料失败: $e');
  //   } finally {
  //     loadingProfile = false;
  //     notifyListeners();
  //   }
  // }

  //   Future<void> loadProfile(String uid) async {
  //   loadingProfile = true;
  //   notifyListeners();

  //   try {
  //     final backendUser = await _userApi.getUser(uid);

  //     final doc =
  //         await _firestore
  //             .collection('users')
  //             .doc(uid)
  //             .get();

  //     if (backendUser == null) {
  //       return;
  //     }

  //     final legacyUser =
  //         doc.exists
  //             ? UserModel.fromJson({
  //                 'uid': doc.id,
  //                 ...?doc.data(),
  //               })
  //             : const UserModel(
  //                 id: '',
  //                 username: '',
  //               );

  //     _userProfile = legacyUser.copyWith(
  //       id: backendUser.id,
  //       username: backendUser.username,
  //       email: backendUser.email,
  //       nickname: backendUser.nickname,
  //       avatar: backendUser.avatar,
  //       bio: backendUser.bio,
  //       birthday: backendUser.birthday,
  //       clearBirthday: backendUser.birthday == null,
  //       showAge: backendUser.showAge,
  //       createdAt: backendUser.createdAt,
  //       lastActive: backendUser.lastActive,
  //     );
  //   } catch (e) {
  //     debugPrint('加载资料失败: $e');
  //   } finally {
  //     loadingProfile = false;
  //     notifyListeners();
  //   }
  // }
  //Firebase保底
  // Future<void> loadProfile(String uid) async {
  //   loadingProfile = true;
  //   notifyListeners();

  //   try {
  //     final doc = await _firestore
  //         .collection('users')
  //         .doc(uid)
  //         .get();

  //     if (!doc.exists) {
  //       return;
  //     }

  //     final legacyUser = UserModel.fromJson({
  //       'uid': doc.id,
  //       ...?doc.data(),
  //     });

  //     // 先保证旧系统资料一定能显示
  //     _userProfile = legacyUser;

  //     try {
  //       final backendUser = await _userApi.getUser(uid);

  //       if (backendUser != null) {
  //         _userProfile = legacyUser.copyWith(
  //           username: backendUser.username,
  //           email: backendUser.email,
  //           nickname: backendUser.nickname,
  //           avatar: backendUser.avatar,
  //           bio: backendUser.bio,
  //           birthday: backendUser.birthday,
  //           clearBirthday: backendUser.birthday == null,
  //           showAge: backendUser.showAge,
  //           createdAt: backendUser.createdAt,
  //           lastActive: backendUser.lastActive,
  //         );
  //       }
  //     } catch (e) {
  //       debugPrint('Node profile load failed, fallback Firestore: $e');
  //     }
  //   } catch (e) {
  //     debugPrint('加载资料失败: $e');
  //   } finally {
  //     loadingProfile = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> loadProfile(String uid) async {
    loadingProfile = true;
    notifyListeners();

    try {
      final backendUser = await _userApi.getUser(uid);

      if (backendUser == null) {
        return;
      }

      _userProfile = backendUser;
    } catch (e) {
      debugPrint('加载资料失败: $e');
    } finally {
      loadingProfile = false;
      notifyListeners();
    }
  }

  // Future<void> loadProfile(String uid) async {
  //   loadingProfile = true;
  //   notifyListeners();

  //   try {
  //     final results = await Future.wait([
  //       _userApi.getCurrentUser(),
  //       _firestore.collection('users').doc(uid).get(),
  //     ]);

  //     final backendUser = results[0] as UserModel?;
  //     final doc =
  //         results[1] as DocumentSnapshot<Map<String, dynamic>>;

  //     if (backendUser == null) {
  //       throw Exception('PostgreSQL user not found');
  //     }

  //     final legacyData = doc.data();

  //     _userProfile = backendUser.copyWith(
  //       tags: legacyData?['tags'] is List
  //           ? List<String>.from(legacyData!['tags'])
  //           : const [],
  //       languages: legacyData?['languages'] is List
  //           ? (legacyData!['languages'] as List)
  //               .whereType<Map>()
  //               .map(
  //                 (item) =>
  //                     Map<String, dynamic>.from(item),
  //               )
  //               .toList()
  //           : const [],
  //     );
  //   } catch (e) {
  //     debugPrint('加载资料失败: $e');
  //   } finally {
  //     loadingProfile = false;
  //     notifyListeners();
  //   }
  // }

  Stream<List<PostModel>> watchUserPosts(String uid) {
    return _postService.watchUserPosts(uid);
  }

  int totalLikesOf(List<PostModel> posts) {
    return posts.fold<int>(0, (total, post) => total + post.likeCount);
  }

  // Stream<List<PostModel>> watchUserPosts(String uid) {
  //   return _firestore
  //       .collection('posts')
  //       .where('uid', isEqualTo: uid)
  //       .orderBy('timestamp', descending: true)
  //       .snapshots()
  //       .map((snapshot) {
  //         return snapshot.docs.map((doc) {
  //           return PostModel.fromJson({'id': doc.id, ...doc.data()});
  //         }).toList();
  //       });
  // }

  // int totalLikesOf(List<PostModel> posts) {
  //   return posts.fold<int>(0, (total, post) {
  //     return total + (post.likes?.length ?? post.likeCount);
  //   });
  // }
  //旧的firebase
  // Future<void> updateTags(String uid, List<String> newTags) async {
  //   await _firestore.collection('users').doc(uid).update({'tags': newTags});

  //   _userProfile = _userProfile.copyWith(tags: List<String>.from(newTags));
  //   notifyListeners();
  // }

  Future<void> updateTags(String uid, List<String> newTags) async {
    final oldTags = _userProfile.tagsList;

    _userProfile = _userProfile.copyWith(tags: List<String>.from(newTags));
    notifyListeners();

    try {
      await _userApi.updateCurrentUser({'tags': newTags});
    } catch (e) {
      _userProfile = _userProfile.copyWith(tags: oldTags);
      notifyListeners();
      rethrow;
    }

    try {
      await _firestore.collection('users').doc(uid).update({'tags': newTags});
    } catch (e) {
      debugPrint('Firestore tags mirror failed: $e');
    }
  }

  Future<void> updateLanguages(
    String uid,
    List<Map<String, dynamic>> newLanguages,
  ) async {
    final oldLanguages = _userProfile.languageList;

    final copiedLanguages = newLanguages
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    _userProfile = _userProfile.copyWith(languages: copiedLanguages);
    notifyListeners();

    try {
      await _userApi.updateCurrentUser({'languages': copiedLanguages});
    } catch (e) {
      _userProfile = _userProfile.copyWith(languages: oldLanguages);
      notifyListeners();
      rethrow;
    }

    try {
      await _firestore.collection('users').doc(uid).update({
        'languages': copiedLanguages,
      });
    } catch (e) {
      debugPrint('Firestore languages mirror failed: $e');
    }
  }

  //旧的firebase
  // Future<void> updateLanguages(
  //   String uid,
  //   List<Map<String, dynamic>> newLanguages,
  // ) async {
  //   final copiedLanguages = newLanguages
  //       .map((item) => Map<String, dynamic>.from(item))
  //       .toList();

  //   await _firestore.collection('users').doc(uid).update({
  //     'languages': copiedLanguages,
  //   });

  //   _userProfile = _userProfile.copyWith(languages: copiedLanguages);
  //   notifyListeners();
  // }

  // Future<void> updateBirthday(
  //   String uid,
  //   DateTime? newBirthday,
  //   bool newShowAge,
  // ) async {
  //   await _firestore.collection('users').doc(uid).update({
  //     'birthday': newBirthday == null
  //         ? FieldValue.delete()
  //         : Timestamp.fromDate(newBirthday),
  //     'showAge': newShowAge,
  //   });

  //   _userProfile = _userProfile.copyWith(
  //     birthday: newBirthday,
  //     clearBirthday: newBirthday == null,
  //     showAge: newShowAge,
  //   );
  //   notifyListeners();
  // }

  Future<void> updateBirthday(
    String uid,
    DateTime? newBirthday,
    bool newShowAge,
  ) async {
    final oldBirthday = _userProfile.birthday;
    final oldShowAge = _userProfile.showAge;

    _userProfile = _userProfile.copyWith(
      birthday: newBirthday,
      clearBirthday: newBirthday == null,
      showAge: newShowAge,
    );
    notifyListeners();

    try {
      await _userApi.updateCurrentUser({
        'birthday': newBirthday?.toIso8601String(),
        'showAge': newShowAge,
      });

      await _firestore.collection('users').doc(uid).update({
        'birthday': newBirthday == null
            ? FieldValue.delete()
            : Timestamp.fromDate(newBirthday),
        'showAge': newShowAge,
      });
    } catch (e) {
      _userProfile = _userProfile.copyWith(
        birthday: oldBirthday,
        clearBirthday: oldBirthday == null,
        showAge: oldShowAge,
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateAvatar(String uid, File imageFile) async {
    uploadingAvatar = true;
    notifyListeners();

    final oldAvatarUrl = avatarUrl;

    try {
      final downloadUrl = await _storageService.uploadAvatar(imageFile);

      await _userApi.updateCurrentUser({'avatarUrl': downloadUrl});

      await _firestore.collection('users').doc(uid).update({
        'avatar': downloadUrl,
      });

      _userProfile = _userProfile.copyWith(avatar: downloadUrl);

      notifyListeners();

      if (oldAvatarUrl.isNotEmpty && oldAvatarUrl.startsWith('http')) {
        try {
          await _storageService.deleteOldAvatar(oldAvatarUrl);
        } catch (e) {
          debugPrint('删除旧头像失败: $e');
        }
      }
    } finally {
      uploadingAvatar = false;
      notifyListeners();
    }
  }

  // Future<void> updateAvatar(String uid, File imageFile) async {
  //   uploadingAvatar = true;
  //   notifyListeners();

  //   try {
  //     if (avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
  //       await _storageService.deleteOldAvatar(avatarUrl);
  //     }

  //     final downloadUrl = await _storageService.uploadAvatar(imageFile);

  //     await _firestore.collection('users').doc(uid).update({
  //       'avatar': downloadUrl,
  //     });

  //     _userProfile = _userProfile.copyWith(avatar: downloadUrl);
  //   } finally {
  //     uploadingAvatar = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> updateNickname(String uid, String newNickname) async {
    final oldNickname = _userProfile.nickname;

    _userProfile = _userProfile.copyWith(nickname: newNickname);
    notifyListeners();

    try {
      await _userApi.updateCurrentUser({
        'nickname': newNickname.isEmpty ? null : newNickname,
      });

      // Firebase 模块仍可能读取 users 文档，
      // 所以迁移期保留用户资料镜像。
      await _firestore.collection('users').doc(uid).update({
        'nickname': newNickname.isEmpty ? FieldValue.delete() : newNickname,
      });
    } catch (e) {
      _userProfile = _userProfile.copyWith(nickname: oldNickname ?? '');

      notifyListeners();
      rethrow;
    }
  }

  //   Future<void> updateNickname(
  //   String uid,
  //   String newNickname,
  // ) async {
  //   final oldNickname = _userProfile.nickname;

  //   _userProfile = _userProfile.copyWith(
  //     nickname: newNickname,
  //   );
  //   notifyListeners();

  //   try {
  //     await _userApi.updateCurrentUser({
  //       'nickname': newNickname.isEmpty ? null : newNickname,
  //     });

  //     await _firestore.collection('users').doc(uid).update({
  //       'nickname':
  //           newNickname.isEmpty
  //               ? FieldValue.delete()
  //               : newNickname,
  //     });

  //     final posts =
  //         await _firestore
  //             .collection('posts')
  //             .where('uid', isEqualTo: uid)
  //             .get();

  //     final batch = _firestore.batch();

  //     for (final doc in posts.docs) {
  //       batch.update(doc.reference, {
  //         'nickname':
  //             newNickname.isEmpty
  //                 ? FieldValue.delete()
  //                 : newNickname,
  //       });
  //     }

  //     await batch.commit();
  //   } catch (e) {
  //     _userProfile = _userProfile.copyWith(
  //       nickname: oldNickname ?? '',
  //     );
  //     notifyListeners();
  //     rethrow;
  //   }
  // }

  // Future<void> updateNickname(String uid, String newNickname) async {
  //   await _firestore.collection('users').doc(uid).update({
  //     'nickname': newNickname.isNotEmpty ? newNickname : FieldValue.delete(),
  //   });

  //   final posts = await _firestore
  //       .collection('posts')
  //       .where('uid', isEqualTo: uid)
  //       .get();

  //   for (final doc in posts.docs) {
  //     await doc.reference.update({
  //       'nickname': newNickname.isNotEmpty ? newNickname : FieldValue.delete(),
  //     });
  //   }

  //   _userProfile = _userProfile.copyWith(nickname: newNickname);
  //   notifyListeners();
  // }

  // Future<void> updateUsername(String uid, String newUsername) async {
  //   final query = await _firestore
  //       .collection('users')
  //       .where('username', isEqualTo: newUsername)
  //       .get();

  //   if (query.docs.isNotEmpty && query.docs.first.id != uid) {
  //     throw Exception('该用户名已被使用');
  //   }

  //   await _firestore.collection('users').doc(uid).update({
  //     'username': newUsername,
  //   });

  //   final posts = await _firestore
  //       .collection('posts')
  //       .where('uid', isEqualTo: uid)
  //       .get();

  //   for (final doc in posts.docs) {
  //     await doc.reference.update({'username': newUsername});
  //   }

  //   _userProfile = _userProfile.copyWith(username: newUsername);
  //   notifyListeners();
  // }

  Future<void> updateUsername(String uid, String newUsername) async {
    final oldUsername = _userProfile.username;

    _userProfile = _userProfile.copyWith(username: newUsername);

    notifyListeners();

    try {
      // PostgreSQL 负责唯一性约束。
      await _userApi.updateCurrentUser({'username': newUsername});

      // Firebase 模块仍可能读取 users 文档。
      await _firestore.collection('users').doc(uid).update({
        'username': newUsername,
      });
    } catch (e) {
      _userProfile = _userProfile.copyWith(username: oldUsername);

      notifyListeners();
      rethrow;
    }
  }

  // Future<void> updateUsername(
  //   String uid,
  //   String newUsername,
  // ) async {
  //   final oldUsername = _userProfile.username;

  //   // 先改 UI
  //   _userProfile = _userProfile.copyWith(
  //     username: newUsername,
  //   );
  //   notifyListeners();

  //   try {
  //     // 新后端负责唯一性判断
  //     await _userApi.updateCurrentUser({
  //       'username': newUsername,
  //     });

  //     // 迁移期暂时同步 Firestore
  //     await _firestore
  //         .collection('users')
  //         .doc(uid)
  //         .update({
  //       'username': newUsername,
  //     });

  //     final posts = await _firestore
  //         .collection('posts')
  //         .where('uid', isEqualTo: uid)
  //         .get();

  //     final batch = _firestore.batch();

  //     for (final doc in posts.docs) {
  //       batch.update(
  //         doc.reference,
  //         {'username': newUsername},
  //       );
  //     }

  //     await batch.commit();
  //   } catch (e) {
  //     // 后端失败，例如用户名重复 → 回滚
  //     _userProfile = _userProfile.copyWith(
  //       username: oldUsername,
  //     );
  //     notifyListeners();

  //     rethrow;
  //   }
  // }

  Future<void> updateBio(String uid, String newBio) async {
    await _userApi.updateCurrentUser({'bio': newBio});

    // 迁移期兼容：
    // 其他页面目前仍可能从 Firestore 读取用户资料。
    await _firestore.collection('users').doc(uid).update({'bio': newBio});

    _userProfile = _userProfile.copyWith(bio: newBio);

    notifyListeners();
  }
}
