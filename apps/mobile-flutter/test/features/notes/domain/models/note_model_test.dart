import 'package:flutter_test/flutter_test.dart';
import 'package:glyphora_mobile/features/notes/domain/models/note_model.dart';

void main() {
  NoteModel note({required bool allowOthersEdit}) {
    return NoteModel(
      id: 'note-1',
      ownerId: 'owner',
      participantIds: const ['owner', 'member'],
      sharedUserIds: const ['member'],
      title: 'Shared note',
      content: 'Body',
      bodyDelta: const [
        {'insert': 'Body\n'},
      ],
      allowOthersEdit: allowOthersEdit,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      updatedBy: 'owner',
    );
  }

  group('NoteModel.canEdit', () {
    test('owner can always edit', () {
      expect(note(allowOthersEdit: false).canEdit('owner'), isTrue);
    });

    test('shared participant can edit only when enabled', () {
      expect(note(allowOthersEdit: false).canEdit('member'), isFalse);
      expect(note(allowOthersEdit: true).canEdit('member'), isTrue);
    });

    test(
      'non-participant cannot edit when collaborative editing is enabled',
      () {
        expect(note(allowOthersEdit: true).canEdit('outsider'), isFalse);
      },
    );
  });
}
