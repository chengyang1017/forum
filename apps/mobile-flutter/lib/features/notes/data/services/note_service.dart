import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../repositories/firebase_note_repository.dart';

/// Temporary compatibility wrapper while remaining note screens migrate to
/// the injected NoteRepository contract.
class NoteService extends FirebaseNoteRepository {
  NoteService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : super(firestore: firestore, storage: storage);
}
