import 'package:flutter_test/flutter_test.dart';

import 'package:glyphora_mobile/core/network/api_client.dart';
import 'package:glyphora_mobile/features/auth/data/services/user_api.dart';
import 'package:glyphora_mobile/features/auth/domain/models/user_model.dart';

void main() {
  late _FakeApiClient client;
  late UserApi api;

  setUp(() {
    client = _FakeApiClient();
    api = UserApi(client: client);
  });

  test('trims username before availability request', () async {
    client.getResponses['/users/username-availability'] = <String, dynamic>{
      'available': true,
    };

    final available = await api.isUsernameAvailable('  alice  ');

    expect(available, isTrue);
    expect(client.lastGetPath, '/users/username-availability');
    expect(client.lastQueryParameters, <String, dynamic>{'username': 'alice'});
  });

  test('syncCurrentUser sends normalized backend payload', () async {
    const user = UserModel(
      id: 'user-1',
      username: 'alice',
      nickname: 'Alice',
      bio: 'Hello',
      showAge: false,
    );

    await api.syncCurrentUser(user);

    expect(client.lastPutPath, '/users/me');
    expect(client.lastPutData, <String, dynamic>{
      'username': 'alice',
      'nickname': 'Alice',
      'avatarUrl': null,
      'bio': 'Hello',
      'showAge': false,
    });
  });

  test('maps current user response to UserModel', () async {
    client.getResponses['/users/me'] = <String, dynamic>{
      'user': <String, dynamic>{
        'id': 'user-1',
        'username': 'alice',
        'email': 'alice@example.com',
        'avatarUrl': 'https://example.test/avatar.png',
      },
    };

    final user = await api.getCurrentUser();

    expect(user?.id, 'user-1');
    expect(user?.username, 'alice');
    expect(user?.email, 'alice@example.com');
    expect(user?.avatarUrl, 'https://example.test/avatar.png');
  });

  test('returns null when current user payload is missing', () async {
    client.getResponses['/users/me'] = <String, dynamic>{'user': null};

    expect(await api.getCurrentUser(), isNull);
  });

  test('throws when update response does not contain a user map', () async {
    client.patchResponses['/users/me'] = <String, dynamic>{'user': null};

    await expectLater(
      api.updateCurrentUser(<String, dynamic>{'nickname': 'Alice'}),
      throwsA(isA<Exception>()),
    );
  });

  test('normalizes interests returned by backend', () async {
    client.getResponses['/users/me/interests'] = <String, dynamic>{
      'interests': <Object>[' flutter ', '', 42, 'dart', 'flutter'],
      'migrated': true,
    };

    final state = await api.getInterestState();

    expect(state.migrated, isTrue);
    expect(state.interests, <String>{'flutter', 'dart'});
  });

  test('sends sorted interests when updating interests', () async {
    client.putResponses['/users/me/interests'] = <String, dynamic>{
      'interests': <String>['dart', 'flutter'],
    };

    final result = await api.updateInterests(<String>{'flutter', 'dart'});

    expect(client.lastPutPath, '/users/me/interests');
    expect(client.lastPutData, <String, dynamic>{
      'interests': <String>['dart', 'flutter'],
    });
    expect(result, <String>{'dart', 'flutter'});
  });

  test('sends sorted legacy interests during migration', () async {
    client.postResponses['/users/me/interests/migrate'] = <String, dynamic>{
      'interests': <String>['dart', 'flutter'],
    };

    final result = await api.migrateInterests(<String>{'flutter', 'dart'});

    expect(client.lastPostPath, '/users/me/interests/migrate');
    expect(client.lastPostData, <String, dynamic>{
      'interests': <String>['dart', 'flutter'],
    });
    expect(result, <String>{'dart', 'flutter'});
  });
}

final class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://example.test');

  final Map<String, Map<String, dynamic>> getResponses = {};
  final Map<String, Map<String, dynamic>> postResponses = {};
  final Map<String, Map<String, dynamic>> putResponses = {};
  final Map<String, Map<String, dynamic>> patchResponses = {};

  String? lastGetPath;
  Map<String, dynamic>? lastQueryParameters;
  String? lastPostPath;
  Object? lastPostData;
  String? lastPutPath;
  Map<String, dynamic>? lastPutData;
  String? lastPatchPath;
  Map<String, dynamic>? lastPatchData;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastGetPath = path;
    lastQueryParameters = queryParameters;
    return getResponses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> post(String path, {Object? data}) async {
    lastPostPath = path;
    lastPostData = data;
    return postResponses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> data,
  ) async {
    lastPutPath = path;
    lastPutData = data;
    return putResponses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> data,
  ) async {
    lastPatchPath = path;
    lastPatchData = data;
    return patchResponses[path] ?? <String, dynamic>{};
  }
}
