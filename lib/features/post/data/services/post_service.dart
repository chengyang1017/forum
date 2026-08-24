import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // ✅ 导入 XFile
import '../../domain/models/post_model.dart';
import 'post_api.dart';
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final PostApi _postApi = PostApi();
  // ========== 监听帖子列表（实时） ==========
  // Stream<List<PostModel>> watchPosts({
  //   required String category,
  //   required String languageCode,
  // }) {
  //   return _firestore
  //       .collection('posts')
  //       .where('category', isEqualTo: category)
  //       .orderBy('timestamp', descending: true)
  //       .limit(50)
  //       .snapshots()
  //       .asyncMap((snapshot) async {
  //         final posts = await Future.wait(
  //           snapshot.docs.map((doc) async {
  //             final data = doc.data();

  //             final availableLanguageCodes =
  //                 (data['availableLanguageCodes'] as List<dynamic>?)
  //                     ?.map((e) => e.toString())
  //                     .toList() ??
  //                 [];

  //             final oldLanguageCode = data['languageCode']?.toString();

  //             // 兼容旧帖子
  //             final hasLanguage = availableLanguageCodes.isNotEmpty
  //                 ? availableLanguageCodes.contains(languageCode)
  //                 : oldLanguageCode == languageCode;

  //             if (!hasLanguage) {
  //               return null;
  //             }

  //             final post = PostModel.fromJson({'id': doc.id, ...data});

  //             final primaryLanguage =
  //                 post.primaryLanguageCode ?? post.languageCode;

  //             // 主语言直接使用根帖子内容
  //             if (languageCode == primaryLanguage) {
  //               return post;
  //             }

  //             // 其他语言读取 versions/{languageCode}
  //             final versionDoc = await doc.reference
  //                 .collection('versions')
  //                 .doc(languageCode)
  //                 .get();

  //             if (!versionDoc.exists) {
  //               return null;
  //             }

  //             final version = versionDoc.data()!;

  //             return post.copyWith(
  //               title: version['title']?.toString() ?? '',
  //               content: version['content']?.toString() ?? '',
  //               bodyDelta:
  //                   (version['bodyDelta'] as List<dynamic>?)
  //                       ?.map((e) => e)
  //                       .toList() ??
  //                   const [],
  //               languageCode: languageCode,
  //             );
  //           }),
  //         );

  //         return posts.whereType<PostModel>().toList();
  //       });
  // }

  Stream<List<PostModel>> watchPosts({
    required String category,
    required String languageCode,
  }) async* {
    // 帖子列表的数据已经全部从 Node/PostgreSQL 读取。
    //
    // 目前后端还没有 SSE / WebSocket，
    // 所以暂时每 15 秒刷新一次，替代原本用 Firestore
    // snapshot 充当“刷新触发器”的过渡方案。
    while (true) {
      yield await _postApi.getPosts(
        category: category,
        languageCode: languageCode,
      );

      await Future<void>.delayed(
        const Duration(seconds: 15),
      );
    }
  }

  // ========== 刷新帖子列表 ==========
  Future<void> refreshPosts({
    required String category,
    required String languageCode,
  }) async {
    // 实际项目中可添加缓存逻辑，这里仅占位
    return Future.value();
  }

  // ========== 创建帖子 ==========
  // Future<void> createPost(PostModel post) async {
  //   final currentUid = _auth.currentUser?.uid;
  //   if (currentUid == null) throw Exception('未登录');

  //   await _firestore.collection('posts').add({
  //     'uid': currentUid,
  //     'content': post.content,
  //     'images': post.imageUrls ?? [],
  //     'category': post.category,
  //     'languageCode': post.languageCode,
  //     'timestamp': FieldValue.serverTimestamp(),
  //     'likeCount': 0,
  //     'commentCount': 0,
  //     'likes': [],
  //   });
  // }

  Future<void> createPost(PostModel post) async {
  final currentUid = _auth.currentUser?.uid;

  if (currentUid == null) {
    throw Exception('未登录');
  }

  final title = post.title?.trim() ?? '';

  final category = post.category?.trim() ?? '';

  final languageCode =
      post.primaryLanguageCode?.trim().isNotEmpty == true
      ? post.primaryLanguageCode!.trim()
      : post.languageCode?.trim() ?? '';

  if (post.id.isEmpty) {
    throw Exception('帖子 ID 不能为空');
  }

  if (title.isEmpty) {
    throw Exception('标题不能为空');
  }

  if (category.isEmpty) {
    throw Exception('帖子分类不能为空');
  }

  if (languageCode.isEmpty) {
    throw Exception('帖子语言不能为空');
  }

  await _postApi.createPost(
    firestoreId: post.id,
    title: title,
    content: post.content ?? '',
    bodyDelta: post.bodyDelta,
    category: category,
    languageCode: languageCode,
    images: post.imageUrls ?? const [],
  );
}

  // ========== 获取单篇帖子 ==========
  // Future<Map<String, dynamic>> getPost(String postId) async {
  //   final doc = await _firestore.collection('posts').doc(postId).get();
  //   if (!doc.exists) throw Exception('帖子不存在');
  //   return {'id': doc.id, ...doc.data()!};
  // }

  Future<PostModel> getPost(String postId) {
    return _postApi.getPost(postId);
  }

  // ========== 添加语言版本 ==========
  // Future<void> addLanguageVersion({
  //   required String postId,
  //   required String languageCode,
  //   required String languageName,
  //   required String title,
  //   required String content,
  //   required String type,
  //   List<dynamic> bodyDelta = const [],
  // }) async {
  //   final currentUid = _auth.currentUser?.uid;

  //   if (currentUid == null) {
  //     throw Exception('未登录');
  //   }

  //   final postRef = _firestore.collection('posts').doc(postId);

  //   final versionRef = postRef.collection('versions').doc(languageCode);

  //   await _firestore.runTransaction((transaction) async {
  //     final postSnapshot = await transaction.get(postRef);

  //     if (!postSnapshot.exists) {
  //       throw Exception('帖子不存在');
  //     }

  //     final versionSnapshot = await transaction.get(versionRef);

  //     if (versionSnapshot.exists) {
  //       throw Exception('该语言版本已经存在');
  //     }

  //     transaction.set(versionRef, {
  //       'languageCode': languageCode,
  //       'languageName': languageName,
  //       'title': title.trim(),
  //       'content': content.trim(),
  //       'bodyDelta': bodyDelta,
  //       'authorId': currentUid,
  //       'type': type,
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'updatedAt': FieldValue.serverTimestamp(),
  //     });

  //     transaction.update(postRef, {
  //       'availableLanguageCodes': FieldValue.arrayUnion([languageCode]),
  //     });
  //   });
  // }

  Future<void> addLanguageVersion({
  required String postId,
  required String languageCode,
  required String languageName,
  required String title,
  required String content,
  required String type,
  List<dynamic> bodyDelta = const [],
}) async {
  final currentUid = _auth.currentUser?.uid;

  if (currentUid == null) {
    throw Exception('未登录');
  }

  // 1. PostgreSQL 主写入
  await _postApi.addLanguageVersion(
    postId: postId,
    languageCode: languageCode,
    title: title.trim(),
    content: content.trim(),
    type: type,
    bodyDelta: bodyDelta,
  );

  // 2. Firestore 迁移期镜像
  try {
    final postRef = _firestore.collection('posts').doc(postId);
    final versionRef = postRef.collection('versions').doc(languageCode);

    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);

      if (!postSnapshot.exists) {
        return;
      }

      transaction.set(versionRef, {
        'languageCode': languageCode,
        'languageName': languageName,
        'title': title.trim(),
        'content': content.trim(),
        'bodyDelta': bodyDelta,
        'authorId': currentUid,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(postRef, {
        'availableLanguageCodes': FieldValue.arrayUnion([
          languageCode,
        ]),
      });
    });
  } catch (e) {
    debugPrint(
      'Firestore post version mirror failed: $e',
    );
  }
}

  // ========== 获取指定语言版本 ==========
  Future<Map<String, dynamic>?> getLanguageVersion({
    required String postId,
    required String languageCode,
  }) async {
    final doc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('versions')
        .doc(languageCode)
        .get();

    if (!doc.exists) {
      return null;
    }

    return {'id': doc.id, ...doc.data()!};
  }

  // ========== 监听帖子所有语言版本 ==========
  Stream<List<Map<String, dynamic>>> watchLanguageVersions(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('versions')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // ========== 更新帖子 ==========
  Future<void> updatePost(String postId, {required String content}) async {
    await _firestore.collection('posts').doc(postId).update({
      'content': content,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== 点赞/取消点赞 ==========
  Future<int> toggleLike(
    String postId, {
    required bool liked,
  }) async {
    final result = liked
        ? await _postApi.likePost(postId)
        : await _postApi.unlikePost(postId);

    return result.likeCount;
  }

  // ========== 删除帖子 ==========
  // Future<void> deletePost(String postId) async {
  //   final postRef = _firestore.collection('posts').doc(postId);

  //   final doc = await postRef.get();

  //   final images = List<String>.from(doc.data()?['images'] ?? []);

  //   for (final url in images) {
  //     try {
  //       await _storage.refFromURL(url).delete();
  //     } catch (_) {}
  //   }

  //   final versions = await postRef.collection('versions').get();

  //   final batch = _firestore.batch();

  //   for (final version in versions.docs) {
  //     batch.delete(version.reference);
  //   }

  //   batch.delete(postRef);

  //   await batch.commit();
  // }

  Future<void> deletePost(String postId) async {
  // 1. PostgreSQL 主删除
  final imageUrls =
      await _postApi.deletePost(postId);

  // 2. 清理 Firebase Storage
  for (final url in imageUrls) {
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      debugPrint(
        'Delete post storage image failed: $e',
      );
    }
  }

  // 3. Firestore 迁移期清理
  try {
    final postRef =
        _firestore.collection('posts').doc(postId);

    final versions =
        await postRef.collection('versions').get();

    final batch = _firestore.batch();

    for (final version in versions.docs) {
      batch.delete(version.reference);
    }

    batch.delete(postRef);

    await batch.commit();
  } catch (e) {
    debugPrint(
      'Firestore post delete mirror failed: $e',
    );
  }
}

  // ========== 上传图片 ==========
  Future<List<String>> uploadImages(String postId, List<XFile> images) async {
    List<String> urls = [];
    for (final file in images) {
      final ref = _storage.ref().child(
        'posts/$postId/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
      );
      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // ========== 更新图片列表 ==========
  // Future<void> updateImages(String postId, List<String> imageUrls) async {
  //   await _firestore.collection('posts').doc(postId).update({
  //     'images': imageUrls,
  //   });
  // }

  Future<void> updateImages(
  String postId,
  List<String> imageUrls,
) async {
  // 1. PostgreSQL 主写入
  await _postApi.updateImages(
    postId: postId,
    images: imageUrls,
  );

  // 2. Firestore 镜像
  try {
    await _firestore
        .collection('posts')
        .doc(postId)
        .update({
      'images': imageUrls,
    });
  } catch (e) {
    debugPrint(
      'Firestore post images mirror failed: $e',
    );
  }
}

  // ========== 删除图片（存储） ==========
  Future<void> deleteImageFromStorage(String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (_) {}
  }

  // ========== 移除图片（Firestore） ==========
  // Future<void> removeImage(String postId, List<String> imageUrls) async {
  //   await _firestore.collection('posts').doc(postId).update({
  //     'images': imageUrls,
  //   });
  // }

  Future<void> removeImage(
  String postId,
  List<String> imageUrls,
) async {
  await updateImages(
    postId,
    imageUrls,
  );
}

  // Future<void> updateLanguageVersionContent({
  //   required String postId,
  //   required String languageCode,
  //   required String title,
  //   required String content,
  //   List<dynamic>? bodyDelta,
  // }) async {
  //   final currentUid = _auth.currentUser?.uid;

  //   if (currentUid == null) {
  //     throw Exception('未登录');
  //   }
  //   final trimmedTitle = title.trim();
  //   if (trimmedTitle.isEmpty) {
  //     throw Exception('标题不能为空');
  //   }
  //   final trimmedContent = content.trim();

  //   if (trimmedContent.isEmpty) {
  //     throw Exception('内容不能为空');
  //   }

  //   final postRef = _firestore.collection('posts').doc(postId);

  //   final versionRef = postRef.collection('versions').doc(languageCode);

  //   await _firestore.runTransaction((transaction) async {
  //     final postSnapshot = await transaction.get(postRef);

  //     if (!postSnapshot.exists) {
  //       throw Exception('帖子不存在');
  //     }

  //     final postData = postSnapshot.data()!;

  //     final ownerId = (postData['uid'] ?? postData['userId'])?.toString();

  //     if (ownerId != currentUid) {
  //       throw Exception('无权编辑该帖子');
  //     }

  //     final primaryLanguageCode =
  //         (postData['primaryLanguageCode'] ?? postData['languageCode'])
  //             ?.toString();

  //     final isPrimaryLanguage = languageCode == primaryLanguageCode;

  //     final versionSnapshot = await transaction.get(versionRef);

  //     if (versionSnapshot.exists) {
  //       transaction.update(versionRef, {
  //         'title': trimmedTitle,
  //         'content': trimmedContent,

  //         if (bodyDelta != null) 'bodyDelta': bodyDelta,

  //         'updatedAt': FieldValue.serverTimestamp(),
  //       });
  //     } else {
  //       // 兼容以前没有 versions/{主语言} 的旧帖子
  //       if (!isPrimaryLanguage) {
  //         throw Exception('该语言版本不存在');
  //       }

  //       transaction.set(versionRef, {
  //         'languageCode': languageCode,
  //         'languageName': postData['languageName'] ?? languageCode,
  //         'title': trimmedTitle,
  //         'content': trimmedContent,
  //         'bodyDelta': bodyDelta ?? const [],
  //         'authorId': currentUid,
  //         'type': 'original',
  //         'createdAt': FieldValue.serverTimestamp(),
  //         'updatedAt': FieldValue.serverTimestamp(),
  //       });
  //     }

  //     // 主语言同时更新 root。
  //     if (isPrimaryLanguage) {
  //       transaction.update(postRef, {
  //         'title': trimmedTitle,
  //         'content': trimmedContent,

  //         if (bodyDelta != null) 'bodyDelta': bodyDelta,

  //         'availableLanguageCodes': FieldValue.arrayUnion([languageCode]),

  //         'updatedAt': FieldValue.serverTimestamp(),
  //       });
  //     }
  //   });
  // }

  Future<void> updateLanguageVersionContent({
  required String postId,
  required String languageCode,
  required String title,
  required String content,
  List<dynamic>? bodyDelta,
}) async {
  final currentUid = _auth.currentUser?.uid;

  if (currentUid == null) {
    throw Exception('未登录');
  }

  final trimmedTitle = title.trim();
  final trimmedContent = content.trim();

  if (trimmedTitle.isEmpty) {
    throw Exception('标题不能为空');
  }

  if (trimmedContent.isEmpty) {
    throw Exception('内容不能为空');
  }

  // 1. PostgreSQL 主写入
  await _postApi.updateLanguageVersion(
    postId: postId,
    languageCode: languageCode,
    title: trimmedTitle,
    content: trimmedContent,
    bodyDelta: bodyDelta,
  );

  // 2. Firestore 迁移期镜像
  try {
    final postRef =
        _firestore.collection('posts').doc(postId);

    final versionRef =
        postRef.collection('versions').doc(languageCode);

    await _firestore.runTransaction((transaction) async {
      final postSnapshot =
          await transaction.get(postRef);

      if (!postSnapshot.exists) {
        return;
      }

      final postData = postSnapshot.data()!;

      final primaryLanguageCode =
          (
            postData['primaryLanguageCode'] ??
            postData['languageCode']
          )?.toString();

      final isPrimaryLanguage =
          languageCode == primaryLanguageCode;

      final versionSnapshot =
          await transaction.get(versionRef);

      if (versionSnapshot.exists) {
        transaction.update(versionRef, {
          'title': trimmedTitle,
          'content': trimmedContent,
          if (bodyDelta != null)
            'bodyDelta': bodyDelta,
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } else if (isPrimaryLanguage) {
        transaction.set(versionRef, {
          'languageCode': languageCode,
          'languageName':
              postData['languageName'] ??
              languageCode,
          'title': trimmedTitle,
          'content': trimmedContent,
          'bodyDelta':
              bodyDelta ?? const [],
          'authorId': currentUid,
          'type': 'original',
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      }

      if (isPrimaryLanguage) {
        transaction.update(postRef, {
          'title': trimmedTitle,
          'content': trimmedContent,
          if (bodyDelta != null)
            'bodyDelta': bodyDelta,
          'availableLanguageCodes':
              FieldValue.arrayUnion([
                languageCode,
              ]),
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      }
    });
  } catch (e) {
    debugPrint(
      'Firestore post edit mirror failed: $e',
    );
  }
}

  Future<void> ensureOriginalEditHistory({
    required String postId,
    required String languageCode,
    required String title,
    required String content,
    required List<dynamic> bodyDelta,
    required List<String> imageUrls,
    required String editedBy,
    DateTime? originalTime,
  }) async {
    final historyCollection = _firestore
        .collection('posts')
        .doc(postId)
        .collection('editHistory');

    final existing = await historyCollection
        .where('languageCode', isEqualTo: languageCode)
        .limit(1)
        .get();

    // 已经有历史，说明 original 已存在，
    // 或这个语言已经进入版本系统。
    if (existing.docs.isNotEmpty) {
      return;
    }

    await historyCollection.add({
      'type': 'original',
      'languageCode': languageCode,
      'title': title,
      'content': content,
      'bodyDelta': bodyDelta,
      'imageUrls': imageUrls,
      'editedBy': editedBy,

      // 旧帖子尽量使用真正的发布时间，
      // 而不是“今天补历史”的时间。
      'editedAt': originalTime != null
          ? Timestamp.fromDate(originalTime)
          : FieldValue.serverTimestamp(),
    });
  }

  Future<void> addEditHistory({
    required String postId,
    required String languageCode,
    required String title,
    required String content,
    required List<dynamic> bodyDelta,
    required List<String> imageUrls,
    required String editedBy,
  }) async {
    final historyCollection = _firestore
        .collection('posts')
        .doc(postId)
        .collection('editHistory');

    // 找这个语言已经存在的历史版本。
    final snapshot = await historyCollection
        .where('languageCode', isEqualTo: languageCode)
        .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? latestDoc;

    DateTime? latestTime;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final rawTime = data['editedAt'];

      final time = rawTime is Timestamp
          ? rawTime.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);

      if (latestTime == null || time.isAfter(latestTime)) {
        latestTime = time;
        latestDoc = doc;
      }
    }

    // ===== 防止第一次编辑重复保存 original =====

    if (latestDoc != null) {
      final latest = latestDoc.data();

      final latestTitle = latest['title']?.toString() ?? '';

      final latestContent = latest['content']?.toString() ?? '';

      final latestBodyDelta =
          (latest['bodyDelta'] as List<dynamic>?) ?? const [];

      final latestImageUrls =
          (latest['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];

      final sameTitle = latestTitle == title;

      final sameContent = latestContent == content;

      final sameBody = jsonEncode(latestBodyDelta) == jsonEncode(bodyDelta);

      final sameImages = jsonEncode(latestImageUrls) == jsonEncode(imageUrls);

      if (sameTitle && sameContent && sameBody && sameImages) {
        // 当前旧版本已经存在于历史。
        // 例如第一次编辑时，
        // original A 已经存在。
        return;
      }
    }

    // ===== 保存真正的新历史版本 =====

    await historyCollection.add({
      // 没有任何历史：
      // 说明是旧帖子/旧翻译版本，
      // 自动补成 original。
      'type': latestDoc == null ? 'original' : 'edit',

      'languageCode': languageCode,

      'title': title,

      'content': content,

      'bodyDelta': bodyDelta,

      'imageUrls': imageUrls,

      'editedBy': editedBy,

      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchEditHistory(String postId) {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('editHistory')
        .orderBy('editedAt', descending: true)
        .snapshots();
  }

  Future<bool> hasEditHistory({
    required String postId,
    required String languageCode,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('editHistory')
        .where('languageCode', isEqualTo: languageCode)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
