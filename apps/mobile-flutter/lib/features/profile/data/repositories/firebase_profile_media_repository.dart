import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../application/models/local_profile_image.dart';
import '../../application/ports/profile_media_repository.dart';

/// Firebase Storage adapter for profile media.
final class FirebaseProfileMediaRepository implements ProfileMediaRepository {
  FirebaseProfileMediaRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> uploadAvatar({
    required String userId,
    required LocalProfileImage image,
  }) async {
    final objectName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('avatars').child(userId).child(objectName);

    await ref.putFile(File(image.path));
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteAvatar(String avatarUrl) async {
    if (avatarUrl.trim().isEmpty) {
      return;
    }

    await _storage.refFromURL(avatarUrl).delete();
  }
}
