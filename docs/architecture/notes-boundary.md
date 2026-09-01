# Notes architecture boundary

The Flutter Notes feature now uses explicit boundaries instead of letting presentation code depend on Firebase services directly.

```text
Notes UI
  -> NoteRepository
     -> FirebaseNoteRepository
        -> Firestore

Notes UI
  -> NoteMediaRepository
     -> FirebaseNoteMediaRepository
        -> Firebase Storage + note image metadata

Shared-user pickers
  -> DiscoverRepository

Shared-user profile display
  -> ProfileRepository
```

`NoteModel` remains framework-independent. Firebase document mapping stays in the data layer. The former `NoteService` compatibility wrapper has been removed after all active presentation call sites migrated to repository contracts.
