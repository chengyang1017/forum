import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/models/note_model.dart';

class UploadedNoteImage {
  final String imageId;
  final String imageUrl;
  final String storagePath;

  const UploadedNoteImage({
    required this.imageId,
    required this.imageUrl,
    required this.storagePath,
  });
}

class NoteService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  NoteService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _notes {
    return _firestore.collection('notes');
  }

  DocumentReference<Map<String, dynamic>> noteReference(String noteId) {
    return _notes.doc(noteId);
  }

  Stream<NoteModel?> watchNote(String noteId) {
    return noteReference(noteId).snapshots().map((document) {
      if (!document.exists) {
        return null;
      }

      return NoteModel.fromDocument(document);
    });
  }

  Stream<List<NoteModel>> watchNotesForUser(String userId) {
    return _notes
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final notes = snapshot.docs.map(NoteModel.fromDocument).toList();

          notes.sort((first, second) {
            return second.updatedAt.compareTo(first.updatedAt);
          });

          return notes;
        });
  }

  Stream<List<NoteModel>> watchNotesWithUser({
    required String currentUserId,
    required String otherUserId,
  }) {
    return watchNotesForUser(currentUserId).map((notes) {
      return notes.where((note) => note.includesUser(otherUserId)).toList();
    });
  }

Future<String> createNote({
  required String ownerId,
  List<String> sharedUserIds = const [],
  String title = '',
  String content = '',
  List<dynamic>? bodyDelta,
  String sourceType = 'manual',
  String? sourceId,
  String? category,
  String? languageCode,
}) async {
  final cleanedSharedUserIds =
      sharedUserIds
          .where(
            (userId) =>
                userId.isNotEmpty &&
                userId != ownerId,
          )
          .toSet()
          .toList();

  final participantIds = <String>[
    ownerId,
    ...cleanedSharedUserIds,
  ];

  final reference = _notes.doc();

  final cleanedCategory =
      category?.trim();

  final cleanedLanguageCode =
      languageCode?.trim();

  await reference.set({
    'ownerId': ownerId,

    'participantIds':
        participantIds,

    'sharedUserIds':
        cleanedSharedUserIds,

    'title': title,

    'content': content,

    'bodyDelta':
        bodyDelta ??
        const [
          {
            'insert': '\n',
          },
        ],

    'sourceType':
        sourceType,

    'sourceId':
        sourceId,

    'category':
        cleanedCategory == null ||
                cleanedCategory.isEmpty
            ? null
            : cleanedCategory,

    'languageCode':
        cleanedLanguageCode == null ||
                cleanedLanguageCode.isEmpty
            ? null
            : cleanedLanguageCode,

    'allowOthersEdit':
        false,

    'createdAt':
        FieldValue.serverTimestamp(),

    'updatedAt':
        FieldValue.serverTimestamp(),

    'updatedBy':
        ownerId,
  });

  return reference.id;
}

Future<void> updateNote({
  required String noteId,
  required String userId,
  String? title,
  String? content,
  List<dynamic>? bodyDelta,
  String? category,
  String? languageCode,
}) async {
  final reference = noteReference(noteId);

  final updates = <String, dynamic>{};

  if (title != null) {
    updates['title'] = title;
  }

  if (content != null) {
    updates['content'] = content;
  }

  if (bodyDelta != null) {
    updates['bodyDelta'] = bodyDelta;
  }

  if (category != null) {
    final cleanedCategory =
        category.trim();

    updates['category'] =
        cleanedCategory.isEmpty
            ? null
            : cleanedCategory;
  }

  if (languageCode != null) {
    final cleanedLanguageCode =
        languageCode.trim();

    updates['languageCode'] =
        cleanedLanguageCode.isEmpty
            ? null
            : cleanedLanguageCode;
  }

  if (updates.isEmpty) {
    return;
  }

  updates['updatedAt'] =
      FieldValue.serverTimestamp();

  updates['updatedBy'] =
      userId;

  await _firestore.runTransaction(
    (transaction) async {
      final snapshot =
          await transaction.get(
            reference,
          );

      if (!snapshot.exists) {
        throw StateError(
          '笔记不存在',
        );
      }

      final data =
          snapshot.data() ??
          const <String, dynamic>{};

      final ownerId =
          data['ownerId']
                  ?.toString() ??
              '';

      final allowOthersEdit =
          data['allowOthersEdit']
                  as bool? ??
              false;

      final participantIds =
          List<String>.from(
            data['participantIds'] ??
                const <String>[],
          );

      final isOwner =
          ownerId == userId;

      final isParticipant =
          participantIds.contains(
            userId,
          );

      final canEdit =
          isOwner ||
          (isParticipant &&
              allowOthersEdit);

      if (!canEdit) {
        throw StateError(
          '无权编辑这条笔记',
        );
      }

      transaction.update(
        reference,
        updates,
      );
    },
  );
}

  Future<void> updateEditPermission({
    required String noteId,
    required String ownerId,
    required bool allowOthersEdit,
  }) async {
    await noteReference(noteId).update({
      'allowOthersEdit': allowOthersEdit,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': ownerId,
    });
  }

  Future<void> updateSharedUsers({
    required String noteId,
    required String ownerId,
    required List<String> sharedUserIds,
  }) async {
    final cleanedSharedUserIds = sharedUserIds
        .where((userId) => userId.isNotEmpty && userId != ownerId)
        .toSet()
        .toList();

    final reference = noteReference(noteId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('笔记不存在');
      }

      final data = snapshot.data() ?? const <String, dynamic>{};

      if (data['ownerId'] != ownerId) {
        throw StateError('只有创建者可以修改共享成员');
      }

      transaction.update(reference, {
        'participantIds': [ownerId, ...cleanedSharedUserIds],
        'sharedUserIds': cleanedSharedUserIds,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': ownerId,
      });
    });
  }

  Future<UploadedNoteImage> uploadInlineImage({
    required String noteId,
    required String userId,
    required File file,
  }) async {
    final imageReference = noteReference(noteId).collection('images').doc();

    final extension = _imageExtension(file.path);
    final storagePath = 'note_images/$noteId/${imageReference.id}.$extension';
    final storageReference = _storage.ref(storagePath);

    try {
      await storageReference.putFile(
        file,
        SettableMetadata(contentType: _contentType(extension)),
      );

      final imageUrl = await storageReference.getDownloadURL();

      await imageReference.set({
        'url': imageUrl,
        'storagePath': storagePath,
        'uploaderId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return UploadedNoteImage(
        imageId: imageReference.id,
        imageUrl: imageUrl,
        storagePath: storagePath,
      );
    } catch (_) {
      try {
        await imageReference.delete();
      } catch (_) {}

      try {
        await storageReference.delete();
      } catch (_) {}

      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    final reference = noteReference(noteId);
    final imageSnapshot = await reference.collection('images').get();

    final storagePaths = imageSnapshot.docs
        .map((document) {
          return document.data()['storagePath']?.toString() ?? '';
        })
        .where((path) => path.isNotEmpty)
        .toList();

    final batch = _firestore.batch();

    for (final imageDocument in imageSnapshot.docs) {
      batch.delete(imageDocument.reference);
    }

    batch.delete(reference);
    await batch.commit();

    for (final storagePath in storagePaths) {
      try {
        await _storage.ref(storagePath).delete();
      } catch (_) {
        // Firestore 已删除成功时，不因孤立 Storage 文件阻塞页面。
      }
    }
  }

  String _imageExtension(String path) {
    final parts = path.split('.');

    if (parts.length < 2) {
      return 'jpg';
    }

    final extension = parts.last.toLowerCase();

    const allowedExtensions = <String>{'jpg', 'jpeg', 'png', 'webp'};

    return allowedExtensions.contains(extension) ? extension : 'jpg';
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
