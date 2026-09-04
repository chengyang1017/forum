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
      final state = AuthState(interests: {'flutter'});

      expect(
        () => state.interests.add('firebase'),
        throwsUnsupportedError,
      );
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
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.isLoading, isFalse);
    });

    test('loadUser completes initialization when no session exists', () async {
      await cubit.loadUser();

      expect(cubit.state.isInitialized, isTrue);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.user, isNull);
    });

    test('login exposes loading then authenticated state', () async {
      final completer = Completer<UserModel>();
      authRepository.onLogin = (_, _) => completer.future;

      final loginFuture = cubit.login('alice@example.com', 'password');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isLoading, isTrue);
      expect(cubit.state.isInitialized, isTrue);

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
              (failure) => failure.code,
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
        authRepository.registerResult = user;

        await cubit.register('alice@example.com', 'password', '  alice  ');

        expect(userRepository.checkedUsernames, ['alice']);
        expect(authRepository.registerUsernames, ['alice']);
        expect(cubit.state.user, same(user));
        expect(cubit.state.isAuthenticated, isTrue);
      },
    );

    test('loadUser merges backend profile into authenticated identity', () async {
      const authUser = UserModel(
        id: 'user-1',
        username: 'alice',
        email: 'alice@example.com',
      );
      const backendUser = UserModel(
        id: 'user-1',
        username: 'alice-new',
        email: 'alice@example.com',
        nickname: 'Alice',
      );
      authRepository.currentUser = authUser;
      userRepository.currentUser = backendUser;

      await cubit.loadUser();

      expect(cubit.state.user, backendUser);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.isInitialized, isTrue);
    });

    test('loadUser migrates legacy interests when backend state is legacy', () async {
      authRepository.currentUser = user;
      userRepository.currentUser = user;
      userRepository.interests = <String>{};
      userRepository.interestsSource = 'legacy';
      userRepository.legacyInterests = <String>{'flutter', 'dart'};

      await cubit.loadUser();

      expect(userRepository.updatedInterests, <String>{'flutter', 'dart'});
      expect(cubit.state.interests, <String>{'flutter', 'dart'});
      expect(cubit.state.interestsSource, 'db');
    });

    test('toggleInterest rolls back optimistic state when persistence fails', () async {
      cubit.seedInterestsForTest(<String>{'flutter'});
      userRepository.updateInterestsError = StateError('save failed');

      await expectLater(
        cubit.toggleInterest('dart'),
        throwsA(isA<StateError>()),
      );

      expect(cubit.state.interests, <String>{'flutter'});
      expect(cubit.state.interestsError, isNotNull);
    });

    test('password reset delegates to repository', () async {
      await cubit.sendPasswordResetEmail('alice@example.com');

      expect(authRepository.passwordResetEmails, ['alice@example.com']);
    });

    test('logout clears user and keeps auth initialized', () async {
      authRepository.currentUser = user;
      await cubit.loadUser();

      await cubit.logout();

      expect(cubit.state.user, isNull);
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.isInitialized, isTrue);
      expect(authRepository.logoutCalls, 1);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  UserModel? currentUser;
  UserModel? registerResult;
  Future<UserModel> Function(String email, String password)? onLogin;

  int registerCalls = 0;
  int logoutCalls = 0;
  final List<String> registerUsernames = [];
  final List<String> passwordResetEmails = [];

  @override
  UserModel? getCurrentUser() => currentUser;

  @override
  Future<UserModel> login(String email, String password) async {
    if (onLogin != null) {
      currentUser = await onLogin!(email, password);
      return currentUser!;
    }
    if (currentUser == null) {
      throw StateError('No login result configured');
    }
    return currentUser!;
  }

  @override
  Future<UserModel> register(
    String email,
    String password,
    String username,
  ) async {
    registerCalls++;
    registerUsernames.add(username);
    if (registerResult == null) {
      throw StateError('No register result configured');
    }
    currentUser = registerResult;
    return registerResult!;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    currentUser = null;
  }

  @override
  Future<void> deleteCurrentUser() async {
    currentUser = null;
  }

  @override
  Future<void> reauthenticate(String currentPassword) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    passwordResetEmails.add(email);
  }
}

class _FakeUserBackendRepository implements UserBackendRepository {
  bool usernameAvailable = true;
  UserModel? currentUser;
  Set<String> interests = <String>{};
  Set<String> legacyInterests = <String>{};
  String interestsSource = 'db';
  Object? updateInterestsError;

  final List<String> checkedUsernames = [];
  Set<String>? updatedInterests;

  @override
  Future<bool> isUsernameAvailable(String username) async {
    checkedUsernames.add(username);
    return usernameAvailable;
  }

  @override
  Future<UserModel> syncCurrentUser({
    required String username,
    String? email,
  }) async {
    return currentUser ??
        UserModel(id: 'user-1', username: username, email: email ?? '');
  }

  @override
  Future<UserModel?> getCurrentUser() async => currentUser;

  @override
  Future<UserModel> updateCurrentUser(Map<String, dynamic> updates) async {
    final base = currentUser ?? user;
    currentUser = base.copyWith(
      username: updates['username'] as String? ?? base.username,
      nickname: updates['nickname'] as String? ?? base.nickname,
    );
    return currentUser!;
  }

  @override
  Future<UserInterestsSnapshot> getInterests() async {
    return UserInterestsSnapshot(
      interests: interests,
      source: interestsSource,
    );
  }

  @override
  Future<Set<String>> updateInterests(Set<String> interests) async {
    if (updateInterestsError != null) {
      throw updateInterestsError!;
    }
    updatedInterests = Set<String>.from(interests);
    this.interests = Set<String>.from(interests);
    return Set<String>.from(interests);
  }

  @override
  Future<Set<String>> migrateLegacyInterests(Set<String> interests) async {
    updatedInterests = Set<String>.from(interests);
    this.interests = Set<String>.from(interests);
    interestsSource = 'db';
    return Set<String>.from(interests);
  }
}
