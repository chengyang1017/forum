// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  Future<String> uploadAvatar(File imageFile) async {
    final uid = _auth.currentUser!.uid;
    final ref = _storage.ref().child('avatars').child('$uid.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // ✅ 添加这个方法
  Future<void> deleteOldAvatar(String oldUrl) async {
    try {
      if (oldUrl.isNotEmpty) {
        final ref = _storage.refFromURL(oldUrl);
        await ref.delete();
      }
    } catch (e) {
      // 删除失败不影响上传
      print('删除旧头像失败: $e');
    }
  }
}