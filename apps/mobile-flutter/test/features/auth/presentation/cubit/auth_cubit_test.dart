import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
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
  int logoutCalls = 0;

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
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {}

  @override
  Future<(String uid, String question)?> getSecurityQuestion(
    String email,
  ) async {
    return null;
  }

  @override
  Future<bool> verifySecurityAnswer(String uid, String answer) async {
    return false;
  }

  @override
  Future<Set<String>> getLegacyInterests(String userId) async {
    return <String>{};
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

class _FakeUserBackendRepository implements UserBackendRepository {
  @override
  Future<void> syncCurrentUser(UserModel user) async {}

  @override
  Future<UserModel?> getCurrentUser() async {
    return null;
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
    return (interests: <String>{}, migrated: true);
  }

  @override
  Future<Set<String>> updateInterests(Set<String> interests) async {
    return Set<String>.from(interests);
  }

  @override
  Future<Set<String>> migrateInterests(Set<String> legacyInterests) async {
    return Set<String>.from(legacyInterests);
  }
}
