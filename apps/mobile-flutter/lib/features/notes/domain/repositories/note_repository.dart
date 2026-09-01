import '../models/note_model.dart';

abstract interface class NoteRepository {
  Stream<NoteModel?> watchNote(String noteId);

  Stream<List<NoteModel>> watchNotesForUser(String userId);

  Stream<List<NoteModel>> watchNotesWithUser({
    required String currentUserId,
    required String otherUserId,
  });

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
  });

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
  });

  Future<void> updateEditPermission({
    required String noteId,
    required String ownerId,
    required bool allowOthersEdit,
  });

  Future<void> updateSharedUsers({
    required String noteId,
    required String ownerId,
    required List<String> sharedUserIds,
  });

  Future<void> deleteNote(String noteId);
}
