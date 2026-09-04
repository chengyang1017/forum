import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/features/chat/data/repositories/firebase_chat_media_repository.dart';

void main() {
  group('FirebaseChatMediaRepository', () {
    late _FakeFirebaseStorage storage;
    late FirebaseChatMediaRepository repository;

    setUp(() {
      storage = _FakeFirebaseStorage();
      repository = FirebaseChatMediaRepository(storage: storage);
    });

    test('uploadImage rejects a blank owner id before touching storage', () async {
      await expectLater(
        repository.uploadImage(
          ownerId: '   ',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(storage.refCalls, 0);
    });

    test('uploadImage rejects empty bytes before touching storage', () async {
      await expectLater(
        repository.uploadImage(ownerId: 'user-1', bytes: Uint8List(0)),
        throwsA(isA<ArgumentError>()),
      );

      expect(storage.refCalls, 0);
    });

    test('deleteImage ignores a blank url without touching storage', () async {
      await repository.deleteImage('   ');

      expect(storage.refFromUrlCalls, isEmpty);
    });

    test('deleteImage delegates deletion for a valid url', () async {
      const url = 'https://example.test/chat-image.jpg';

      await repository.deleteImage(url);

      expect(storage.refFromUrlCalls, [url]);
      expect(storage.reference.deleteCalls, 1);
    });

    test('deleteImage ignores object-not-found errors', () async {
      storage.reference.deleteError = FirebaseException(
        plugin: 'firebase_storage',
        code: 'object-not-found',
      );

      await repository.deleteImage('https://example.test/missing.jpg');

      expect(storage.reference.deleteCalls, 1);
    });

    test('deleteImage rethrows other Firebase errors', () async {
      storage.reference.deleteError = FirebaseException(
        plugin: 'firebase_storage',
        code: 'unauthorized',
      );

      await expectLater(
        repository.deleteImage('https://example.test/protected.jpg'),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'unauthorized',
          ),
        ),
      );
    });
  });
}

final class _FakeFirebaseStorage implements FirebaseStorage {
  final _FakeReference reference = _FakeReference();
  final List<String> refFromUrlCalls = <String>[];
  int refCalls = 0;

  @override
  Reference ref([String? path]) {
    refCalls++;
    return reference;
  }

  @override
  Reference refFromURL(String url) {
    refFromUrlCalls.add(url);
    return reference;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeReference implements Reference {
  int deleteCalls = 0;
  Object? deleteError;

  @override
  Future<void> delete() async {
    deleteCalls++;
    final error = deleteError;
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
