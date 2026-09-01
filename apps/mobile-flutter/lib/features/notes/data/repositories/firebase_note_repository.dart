import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/forum_categories.dart';
import '../../domain/models/note_model.dart';
import '../../domain/repositories/note_repository.dart';
import '../mappers/note_model_mapper.dart';

class FirebaseNoteRepository implements NoteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseNoteRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _notes {
    return _firestore.collection('notes');
  }

  DocumentReference<Map<String, dynamic>> noteReference(String noteId) {
    return _notes.doc(noteId);
  }

  @override
  Stream<NoteModel?> watchNote(String noteId) {
    return noteReference(noteId).snapshots().map((document) {
      if (!document.exists) {
        return null;
      }

      return NoteModelMapper.fromDocument(document);
    });
  }

  @override
  Stream<List<NoteModel>> watchNotesForUser(String userId) {
    return _notes
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final notes = snapshot.docs
              .map(NoteModelMapper.fromDocument)
              .toList(growable: false);

          notes.sort((first, second) {
            return second.updatedAt.compareTo(first.updatedAt);
          });

          return notes;
        });
  }

  @override
  Stream<List<NoteModel>> watchNotesWithUser({
    required String currentUserId,
    required String otherUserId,
  }) {
    return watchNotesForUser(currentUserId).map((notes) {
      return notes
          .where((note) => note.includesUser(otherUserId))
          .toList(growable: false);
    });
  }

  @override
  Future<String> createNote({
    required String ownerId,
    List<String> sharedUserIds = const [],
    String title = '',
    String content = '',
    List<dynamic>? bodyDelta,
    String sourceType = 'manual',
    String? sourceId,
    String? category,
    String? categoryId,
    List<String>? categoryPath,
    String? languageCode,
  }) async {
    final cleanedSharedUserIds = sharedUserIds
        .where((userId) => userId.isNotEmpty && userId != ownerId)
        .toSet()
        .toList(growable: false);

    final participantIds = <String>[ownerId, ...cleanedSharedUserIds];
    final reference = _notes.doc();
    final cleanedLanguageCode = languageCode?.trim();
    final categoryData = _resolveCategoryData(
      category: category,
      categoryId: categoryId,
      categoryPath: categoryPath,
    );

    await reference.set({
      'ownerId': ownerId,
      'participantIds': participantIds,
      'sharedUserIds': cleanedSharedUserIds,
      'title': title,
      'content': content,
      'bodyDelta':
          bodyDelta ??
          const [
            {'insert': '\n'},
          ],
      'sourceType': sourceType,
      'sourceId': sourceId,
      'category': categoryData.rootCategoryId,
      'categoryId': categoryData.categoryId,
      'categoryPath': categoryData.categoryPath,
      'languageCode': cleanedLanguageCode == null || cleanedLanguageCode.isEmpty
          ? null
          : cleanedLanguageCode,
      'allowOthersEdit': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': ownerId,
    });

    return reference.id;
  }

  @override
  Future<void> updateNote({
    required String noteId,
    required String userId,
    String? title,
    String? content,
    List<dynamic>? bodyDelta,
    String? category,
    String? categoryId,
    List<String>? categoryPath,
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

    if (category != null || categoryId != null || categoryPath != null) {
      final categoryData = _resolveCategoryData(
        category: category,
        categoryId: categoryId,
        categoryPath: categoryPath,
      );

      updates['category'] = categoryData.rootCategoryId;
      updates['categoryId'] = categoryData.categoryId;
      updates['categoryPath'] = categoryData.categoryPath;
    }

    if (languageCode != null) {
      final cleanedLanguageCode = languageCode.trim();
      updates['languageCode'] = cleanedLanguageCode.isEmpty
          ? null
          : cleanedLanguageCode;
    }

    if (updates.isEmpty) {
      return;
    }

    updates['updatedAt'] = FieldValue.serverTimestamp();
    updates['updatedBy'] = userId;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('笔记不存在');
      }

      final data = snapshot.data() ?? const <String, dynamic>{};
      final ownerId = data['ownerId']?.toString() ?? '';
      final allowOthersEdit = data['allowOthersEdit'] as bool? ?? false;
      final participantIds = List<String>.from(
        data['participantIds'] ?? const <String>[],
      );

      final isOwner = ownerId == userId;
      final isParticipant = participantIds.contains(userId);
      final canEdit = isOwner || (isParticipant && allowOthersEdit);

      if (!canEdit) {
        throw StateError('无权编辑这条笔记');
      }

      transaction.update(reference, updates);
    });
  }

  @override
  Future<void> updateEditPermission({
    required String noteId,
    required String ownerId,
    required bool allowOthersEdit,
  }) async {
    final reference = noteReference(noteId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('笔记不存在');
      }

      final data = snapshot.data() ?? const <String, dynamic>{};
      if (data['ownerId'] != ownerId) {
        throw StateError('只有创建者可以修改编辑权限');
      }

      transaction.update(reference, {
        'allowOthersEdit': allowOthersEdit,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': ownerId,
      });
    });
  }

  @override
  Future<void> updateSharedUsers({
    required String noteId,
    required String ownerId,
    required List<String> sharedUserIds,
  }) async {
    final cleanedSharedUserIds = sharedUserIds
        .where((userId) => userId.isNotEmpty && userId != ownerId)
        .toSet()
        .toList(growable: false);

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

  @override
  Future<void> deleteNote(String noteId) async {
    final reference = noteReference(noteId);
    final imageSnapshot = await reference.collection('images').get();

    final storagePaths = imageSnapshot.docs
        .map((document) {
          return document.data()['storagePath']?.toString() ?? '';
        })
        .where((path) => path.isNotEmpty)
        .toList(growable: false);

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
        // Firestore is authoritative; orphan cleanup must not undo deletion.
      }
    }
  }

  _ResolvedCategoryData _resolveCategoryData({
    String? category,
    String? categoryId,
    List<String>? categoryPath,
  }) {
    final cleanedCategory = category?.trim();
    final cleanedCategoryId = categoryId?.trim();
    final suppliedPath = categoryPath
        ?.map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final selectedCategoryId =
        cleanedCategoryId != null && cleanedCategoryId.isNotEmpty
        ? cleanedCategoryId
        : cleanedCategory != null && cleanedCategory.isNotEmpty
        ? cleanedCategory
        : suppliedPath != null && suppliedPath.isNotEmpty
        ? suppliedPath.last
        : null;

    if (selectedCategoryId == null) {
      return const _ResolvedCategoryData(
        rootCategoryId: null,
        categoryId: null,
        categoryPath: <String>[],
      );
    }

    final derivedPath = ForumCategories.pathOf(selectedCategoryId);
    final resolvedPath = suppliedPath != null && suppliedPath.isNotEmpty
        ? suppliedPath
        : derivedPath.isNotEmpty
        ? derivedPath
        : <String>[selectedCategoryId];

    final rootCategoryId = resolvedPath.isNotEmpty
        ? resolvedPath.first
        : ForumCategories.rootIdOf(selectedCategoryId);

    return _ResolvedCategoryData(
      rootCategoryId: rootCategoryId,
      categoryId: selectedCategoryId,
      categoryPath: resolvedPath,
    );
  }
}

class _ResolvedCategoryData {
  final String? rootCategoryId;
  final String? categoryId;
  final List<String> categoryPath;

  const _ResolvedCategoryData({
    required this.rootCategoryId,
    required this.categoryId,
    required this.categoryPath,
  });
}
