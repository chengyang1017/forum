import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/errors/auth_failure.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_backend_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository authRepository,
    required UserBackendRepository userRepository,
  }) : _authRepository = authRepository,
       _userRepository = userRepository,
       super(AuthState());

  final AuthRepository _authRepository;
  final UserBackendRepository _userRepository;

  UserModel? get user => state.user;

  bool get isLoading => state.isLoading;

  Set<String> get interests => state.interests;

  bool get interestsLoaded => state.interestsLoaded;

  String? get interestsError => state.interestsError;

  bool isInterested(String key) {
    return state.isInterested(key);
  }

  Future<void> _syncBackendUser() async {
    final user = state.user;

    if (user == null) {
      return;
    }

    try {
      await _userRepository.syncCurrentUser(user);
    } catch (error) {
      debugPrint('Node.js user sync failed: $error');
    }
  }

  Future<void> _loadInterests() async {
    emit(state.copyWith(interestsError: null));

    final user = state.user;

    if (user == null) {
      emit(
        state.copyWith(
          interests: <String>{},
          interestsLoaded: false,
          interestsError: null,
        ),
      );
      return;
    }

    try {
      final interestState = await _userRepository.getInterestState();

      if (interestState.migrated) {
        emit(
          state.copyWith(
            interests: interestState.interests,
            interestsLoaded: true,
            interestsError: null,
          ),
        );
        return;
      }

      final legacyInterests = await _authRepository.getLegacyInterests(user.id);
      final migratedInterests = await _userRepository.migrateInterests(
        legacyInterests,
      );

      emit(
        state.copyWith(
          interests: migratedInterests,
          interestsLoaded: true,
          interestsError: null,
        ),
      );
    } catch (error) {
      debugPrint('Load interests failed: $error');

      emit(
        state.copyWith(
          interestsLoaded: false,
          interestsError: error.toString(),
        ),
      );
    }
  }

  Future<void> toggleInterest(String key) async {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      return;
    }

    final previous = Set<String>.from(state.interests);
    final next = Set<String>.from(state.interests);

    if (!next.add(normalizedKey)) {
      next.remove(normalizedKey);
    }

    emit(state.copyWith(interests: next));

    try {
      final confirmedInterests = await _userRepository.updateInterests(next);
      emit(
        state.copyWith(interests: confirmedInterests, interestsLoaded: true),
      );
    } catch (error) {
      emit(state.copyWith(interests: previous));
      rethrow;
    }
  }

  Future<void> retryLoadInterests() async {
    emit(state.copyWith(interestsError: null, interestsLoaded: false));
    await _loadInterests();
  }

  Future<void> refreshInterests() async {
    final interestState = await _userRepository.getInterestState();

    emit(
      state.copyWith(interests: interestState.interests, interestsLoaded: true),
    );
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(isLoading: true));

    try {
      final user = await _authRepository.login(email, password);
      emit(state.copyWith(user: user, isLoading: false, isInitialized: true));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
      rethrow;
    }
  }

  Future<void> register(String email, String password, String username) async {
    emit(state.copyWith(isLoading: true));

    try {
      final normalizedUsername = username.trim();
      final isAvailable = await _userRepository.isUsernameAvailable(
        normalizedUsername,
      );

      if (!isAvailable) {
        throw const AuthFailure(AuthFailureCode.usernameTaken);
      }

      final user = await _authRepository.register(
        email,
        password,
        normalizedUsername,
      );
      emit(state.copyWith(user: user, isLoading: false, isInitialized: true));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
      rethrow;
    }
  }

  Future<void> loadUser() async {
    emit(state.copyWith(isLoading: true));

    try {
      final legacyUser = await _authRepository.getCurrentUser();
      emit(state.copyWith(user: legacyUser));

      if (legacyUser == null) {
        emit(
          state.copyWith(
            interests: <String>{},
            interestsLoaded: false,
            interestsError: null,
          ),
        );
        return;
      }

      await _syncBackendUser();

      final backendUser = await _userRepository.getCurrentUser();

      if (backendUser != null) {
        emit(
          state.copyWith(
            user: legacyUser.copyWith(
              username: backendUser.username,
              email: backendUser.email,
              nickname: backendUser.nickname,
              avatar: backendUser.avatar,
              bio: backendUser.bio,
              birthday: backendUser.birthday,
              showAge: backendUser.showAge,
              createdAt: backendUser.createdAt,
              lastActive: backendUser.lastActive,
            ),
          ),
        );
      }

      await _loadInterests();
    } catch (error) {
      debugPrint('Load backend user failed: $error');
    } finally {
      emit(state.copyWith(isLoading: false, isInitialized: true));
    }
  }

  Future<void> updateUser(UserModel newUser) async {
    final updatedUser = await _authRepository.updateProfile(newUser);
    emit(state.copyWith(user: updatedUser));
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _authRepository.changePassword(currentPassword, newPassword);
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _authRepository.sendPasswordResetEmail(email);
  }

  Future<void> logout() async {
    await _authRepository.logout();

    emit(
      AuthState(
        user: null,
        isInitialized: true,
        interests: const <String>{},
        interestsLoaded: false,
        interestsError: null,
      ),
    );
  }
}
