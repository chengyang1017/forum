import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/user_api.dart';
import '../../domain/models/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({AuthRepository? authRepository, UserApi? userApi})
    : _authRepo = authRepository ?? AuthRepository(),
      _userApi = userApi ?? UserApi(),
      super(AuthState());

  final AuthRepository _authRepo;
  final UserApi _userApi;

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
      await _userApi.syncCurrentUser(user);
    } catch (error) {
      debugPrint('Node.js user sync failed: $error');
    }
  }

  Set<String> _readLegacyInterests(Object? value) {
    if (value is! Iterable) {
      return <String>{};
    }

    return value
        .whereType<String>()
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toSet();
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
      final interestState = await _userApi.getInterestState();

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

      final legacySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();

      final legacyInterests = _readLegacyInterests(
        legacySnapshot.data()?['interests'],
      );

      final migratedInterests = await _userApi.migrateInterests(
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
      final confirmedInterests = await _userApi.updateInterests(next);

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
    final interestState = await _userApi.getInterestState();

    emit(
      state.copyWith(interests: interestState.interests, interestsLoaded: true),
    );
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(isLoading: true));

    try {
      final user = await _authRepo.login(email, password);

      emit(state.copyWith(user: user, isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false));

      rethrow;
    }
  }

  Future<void> register(String email, String password, String username) async {
    emit(state.copyWith(isLoading: true));

    try {
      final user = await _authRepo.register(email, password, username);

      emit(state.copyWith(user: user, isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false));

      rethrow;
    }
  }

  Future<void> loadUser() async {
    emit(state.copyWith(isLoading: true));

    try {
      final legacyUser = await _authRepo.getCurrentUser();

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

      final backendUser = await _userApi.getCurrentUser();

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
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> updateUser(UserModel newUser) async {
    final updatedUser = await _authRepo.updateProfile(newUser);

    emit(state.copyWith(user: updatedUser));
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _authRepo.changePassword(currentPassword, newPassword);
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<(String uid, String question)?> getSecurityQuestion(String email) {
    return _authRepo.getSecurityQuestion(email);
  }

  Future<bool> verifySecurityAnswer(String uid, String answer) {
    return _authRepo.verifySecurityAnswer(uid, answer);
  }

  Future<void> logout() async {
    await _authRepo.logout();

    emit(
      AuthState(
        user: null,
        interests: const <String>{},
        interestsLoaded: false,
        interestsError: null,
      ),
    );
  }
}
