import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // ✅ 导入 XFile
import '../../data/models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ========== 监听帖子列表（实时） ==========
  Stream<List<PostModel>> watchPosts({
    required String category,
    required String languageCode,
  }) {
    return _firestore
        .collection('posts')
        .where('category', isEqualTo: category)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final docLang = data['languageCode'] as String?;
            if (docLang != null && docLang != languageCode) {
              return null;
            }
            return PostModel.fromJson({
              'id': doc.id,
              ...data,
            });
          }).whereType<PostModel>().toList();
        });
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
  Future<void> createPost(PostModel post) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) throw Exception('未登录');

    await _firestore.collection('posts').add({
      'uid': currentUid,
      'content': post.content,
      'images': post.imageUrls ?? [],
      'category': post.category,
      'languageCode': post.languageCode,
      'timestamp': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'commentCount': 0,
      'likes': [],
    });
  }

  // ========== 获取单篇帖子 ==========
  Future<Map<String, dynamic>> getPost(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (!doc.exists) throw Exception('帖子不存在');
    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  // ========== 更新帖子 ==========
  Future<void> updatePost(String postId, {required String content}) async {
    await _firestore.collection('posts').doc(postId).update({
      'content': content,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== 点赞/取消点赞 ==========
  Future<void> toggleLike(String postId, String userId) async {
    final doc = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      if (!snapshot.exists) return;
      final likes = List<String>.from(snapshot.data()?['likes'] ?? []);
      if (likes.contains(userId)) {
        transaction.update(doc, {
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        transaction.update(doc, {
          'likes': FieldValue.arrayUnion([userId]),
        });
      }
    });
  }

  // ========== 删除帖子 ==========
  Future<void> deletePost(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    final images = List<String>.from(doc.data()?['images'] ?? []);
    for (final url in images) {
      try { await _storage.refFromURL(url).delete(); } catch (_) {}
    }
    await _firestore.collection('posts').doc(postId).delete();
  }

  // ========== 上传图片 ==========
  Future<List<String>> uploadImages(String postId, List<XFile> images) async {
    List<String> urls = [];
    for (final file in images) {
      final ref = _storage
          .ref()
          .child('posts/$postId/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // ========== 更新图片列表 ==========
  Future<void> updateImages(String postId, List<String> imageUrls) async {
    await _firestore.collection('posts').doc(postId).update({
      'images': imageUrls,
    });
  }

  // ========== 删除图片（存储） ==========
  Future<void> deleteImageFromStorage(String imageUrl) async {
    try { await _storage.refFromURL(imageUrl).delete(); } catch (_) {}
  }

  // ========== 移除图片（Firestore） ==========
  Future<void> removeImage(String postId, List<String> imageUrls) async {
    await _firestore.collection('posts').doc(postId).update({
      'images': imageUrls,
    });
  }
}