import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:glyphora_mobile/features/auth/domain/errors/auth_failure.dart';
import 'package:glyphora_mobile/features/auth/domain/models/user_model.dart';
import 'package:glyphora_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:glyphora_mobile/features/auth/domain/repositories/user_backend_repository.dart';
import 'package:glyphora_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:glyphora_mobile/features/auth/presentation/cubit/auth_state.dart';

void main() {
  const user = UserModel(
    id: 'user-1',
    username: 'alice',
    email: 'alice@example.com',
  );

  group('AuthState', () {
    test('copyWith preserves nullable values when omitted', () {
      final state = AuthState(user: user, interestsError: 'load failed');

      final copied = state.copyWith();

      expect(copied.user, same(user));
      expect(copied.interestsError, 'load failed');
    });

    test('copyWith can explicitly clear nullable values', () {
      final state = AuthState(user: user, interestsError: 'load failed');

      final copied = state.copyWith(user: null, interestsError: null);

      expect(copied.user, isNull);
      expect(copied.interestsError, isNull);
    });

    test('interests cannot be mutated outside the state', () {
      final state = AuthState(interests: const {'flutter'});

      expect(() => state.interests.add('dart'), throwsUnsupportedError);
    });
  });

  group('AuthCubit', () {
    late _FakeAuthRepository authRepository;
    late _FakeUserBackendRepository userRepository;
    late AuthCubit cubit;

    setUp(() {
      authRepository = _FakeAuthRepository();
      userRepository = _FakeUserBackendRepository();

      cubit = AuthCubit(
        authRepository: authRepository,
        userRepository: userRepository,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('starts uninitialized and unauthenticated', () {
      expect(cubit.state.isInitialized, isFalse);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.user, isNull);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test('loadUser completes initialization when no session exists', () async {
      authRepository.currentUser = null;

      await cubit.loadUser();

      expect(cubit.state.isInitialized, isTrue);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.user, isNull);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test('login exposes loading then authenticated state', () async {
      final completer = Completer<UserModel>();

      authRepository.onLogin = (_, _) => completer.future;

      final loginFuture = cubit.login('alice@example.com', 'password');

      expect(cubit.state.isLoading, isTrue);

      completer.complete(user);
      await loginFuture;

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isInitialized, isTrue);
      expect(cubit.state.user, same(user));
      expect(cubit.state.isAuthenticated, isTrue);
    });

    test('login failure restores loading state and rethrows', () async {
      authRepository.onLogin = (_, _) async {
        throw StateError('login failed');
      };

      await expectLater(
        cubit.login('alice@example.com', 'bad-password'),
        throwsA(isA<StateError>()),
      );

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.user, isNull);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test(
      'register rejects an unavailable username before auth creation',
      () async {
        userRepository.usernameAvailable = false;

        await expectLater(
          cubit.register('alice@example.com', 'password', 'alice'),
          throwsA(
            isA<AuthFailure>().having(
              (error) => error.code,
              'code',
              AuthFailureCode.usernameTaken,
            ),
          ),
        );

        expect(userRepository.checkedUsernames, ['alice']);
        expect(authRepository.registerCalls, 0);
        expect(cubit.state.isLoading, isFalse);
      },
    );

    test(
      'register normalizes username before availability and auth calls',
      () async {
        await cubit.register('alice@example.com', 'password', '  alice  ');

        expect(userRepository.checkedUsernames, ['alice']);
        expect(authRepository.lastRegisteredUsername, 'alice');
        expect(cubit.state.user?.username, 'alice');
      },
    );

    test(
      'loadUser merges backend profile into authenticated identity',
      () async {
        final createdAt = DateTime(2026, 1, 2);
        final lastActive = DateTime(2026, 1, 3);

        authRepository.currentUser = user;
        userRepository.currentUser = UserModel(
          id: user.id,
          username: 'server-name',
          email: 'server@example.com',
          nickname: 'Server Nickname',
          avatar: 'https://example.test/avatar.png',
          bio: 'Server bio',
          birthday: DateTime(2000, 4, 5),
          showAge: false,
          createdAt: createdAt,
          lastActive: lastActive,
        );
        userRepository.interestState = (
          interests: <String>{'technology'},
          migrated: true,
        );

        await cubit.loadUser();

        expect(userRepository.lastSyncedUser, same(user));
        expect(cubit.state.user?.id, user.id);
        expect(cubit.state.user?.username, 'server-name');
        expect(cubit.state.user?.email, 'server@example.com');
        expect(cubit.state.user?.nickname, 'Server Nickname');
        expect(cubit.state.user?.bio, 'Server bio');
        expect(cubit.state.user?.showAge, isFalse);
        expect(cubit.state.user?.createdAt, createdAt);
        expect(cubit.state.user?.lastActive, lastActive);
        expect(cubit.state.interests, <String>{'technology'});
        expect(cubit.state.interestsLoaded, isTrue);
        expect(cubit.state.isInitialized, isTrue);
        expect(cubit.state.isLoading, isFalse);
      },
    );

    test(
      'loadUser migrates legacy interests when backend state is legacy',
      () async {
        authRepository.currentUser = user;
        authRepository.legacyInterests = <String>{'languages', 'technology'};
        userRepository.interestState = (interests: <String>{}, migrated: false);
        userRepository.migratedInterests = <String>{'languages', 'technology'};

        await cubit.loadUser();

        expect(authRepository.lastLegacyInterestUserId, user.id);
        expect(userRepository.lastLegacyInterests, <String>{
          'languages',
          'technology',
        });
        expect(cubit.state.interests, <String>{'languages', 'technology'});
        expect(cubit.state.interestsLoaded, isTrue);
      },
    );

    test(
      'toggleInterest rolls back optimistic state when persistence fails',
      () async {
        authRepository.currentUser = user;
        userRepository.interestState = (
          interests: <String>{'languages'},
          migrated: true,
        );

        await cubit.loadUser();
        userRepository.updateInterestsError = StateError('save failed');

        await expectLater(
          cubit.toggleInterest('technology'),
          throwsA(isA<StateError>()),
        );

        expect(cubit.state.interests, <String>{'languages'});
      },
    );

    test('password reset delegates to repository', () async {
      await cubit.sendPasswordResetEmail('alice@example.com');

      expect(authRepository.passwordResetEmails, ['alice@example.com']);
    });

    test(
      'deleteAccount reauthenticates, deletes backend account and logs out',
      () async {
        authRepository.onLogin = (_, _) async => user;
        await cubit.login('alice@example.com', 'password');

        await cubit.deleteAccount('current-password');

        expect(authRepository.reauthenticatedPasswords, ['current-password']);
        expect(userRepository.deleteCurrentAccountCalls, 1);
        expect(authRepository.logoutCalls, 1);
        expect(cubit.state.user, isNull);
        expect(cubit.state.isAuthenticated, isFalse);
        expect(cubit.state.isInitialized, isTrue);
        expect(cubit.state.isLoading, isFalse);
      },
    );

    test(
      'deleteAccount stops before deletion when reauthentication fails',
      () async {
        authRepository.onLogin = (_, _) async => user;
        authRepository.reauthenticateError = StateError('wrong password');
        await cubit.login('alice@example.com', 'password');

        await expectLater(
          cubit.deleteAccount('bad-password'),
          throwsA(isA<StateError>()),
        );

        expect(userRepository.deleteCurrentAccountCalls, 0);
        expect(authRepository.logoutCalls, 0);
        expect(cubit.state.user, same(user));
        expect(cubit.state.isLoading, isFalse);
      },
    );

    test('logout clears user and keeps auth initialized', () async {
      authRepository.onLogin = (_, _) async => user;

      await cubit.login('alice@example.com', 'password');
      await cubit.logout();

      expect(authRepository.logoutCalls, 1);
      expect(cubit.state.user, isNull);
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.isInitialized, isTrue);
      expect(cubit.state.interests, isEmpty);
      expect(cubit.state.interestsLoaded, isFalse);
      expect(cubit.state.interestsError, isNull);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  Future<UserModel> Function(String email, String password)? onLogin;

  UserModel? currentUser;
  Set<String> legacyInterests = const <String>{};
  int logoutCalls = 0;
  int registerCalls = 0;
  String? lastRegisteredUsername;
  String? lastLegacyInterestUserId;
  Object? reauthenticateError;
  final List<String> reauthenticatedPasswords = [];
  final List<String> passwordResetEmails = [];

  @override
  Future<UserModel> login(String email, String password) {
    final handler = onLogin;

    if (handler == null) {
      throw StateError('onLogin was not configured');
    }

    return handler(email, password);
  }

  @override
  Future<UserModel> register(
    String email,
    String password,
    String username,
  ) async {
    registerCalls++;
    lastRegisteredUsername = username;
    return UserModel(id: 'registered-user', username: username, email: email);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return currentUser;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    return user;
  }

  @override
  Future<void> reauthenticate(String password) async {
    reauthenticatedPasswords.add(password);
    final error = reauthenticateError;
    if (error != null) throw error;
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    passwordResetEmails.add(email);
  }

  @override
  Future<Set<String>> getLegacyInterests(String userId) async {
    lastLegacyInterestUserId = userId;
    return Set<String>.from(legacyInterests);
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

class _FakeUserBackendRepository implements UserBackendRepository {
  bool usernameAvailable = true;
  UserModel? currentUser;
  ({Set<String> interests, bool migrated}) interestState = (
    interests: const <String>{},
    migrated: true,
  );
  Set<String>? migratedInterests;
  Object? updateInterestsError;
  int deleteCurrentAccountCalls = 0;

  final List<String> checkedUsernames = [];
  UserModel? lastSyncedUser;
  Set<String>? lastLegacyInterests;

  @override
  Future<bool> isUsernameAvailable(String username) async {
    checkedUsernames.add(username);
    return usernameAvailable;
  }

  @override
  Future<void> syncCurrentUser(UserModel user) async {
    lastSyncedUser = user;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return currentUser;
  }

  @override
  Future<UserModel> updateCurrentUser(Map<String, dynamic> data) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    return null;
  }

  @override
  Future<({Set<String> interests, bool migrated})> getInterestState() async {
    return (
      interests: Set<String>.from(interestState.interests),
      migrated: interestState.migrated,
    );
  }

  @override
  Future<Set<String>> updateInterests(Set<String> interests) async {
    final error = updateInterestsError;
    if (error != null) {
      throw error;
    }

    return Set<String>.from(interests);
  }

  @override
  Future<Set<String>> migrateInterests(Set<String> legacyInterests) async {
    lastLegacyInterests = Set<String>.from(legacyInterests);
    return Set<String>.from(migratedInterests ?? legacyInterests);
  }

  @override
  Future<void> deleteCurrentAccount() async {
    deleteCurrentAccountCalls++;
  }
}
