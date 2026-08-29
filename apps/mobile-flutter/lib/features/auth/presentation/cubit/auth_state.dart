import '../../domain/models/user_model.dart';

const _unset = Object();

class AuthState {
  AuthState({
    this.user,
    this.isLoading = false,
    Set<String> interests = const <String>{},
    this.interestsLoaded = false,
    this.interestsError,
  }) : interests = Set<String>.unmodifiable(interests);

  final UserModel? user;
  final bool isLoading;
  final Set<String> interests;
  final bool interestsLoaded;
  final String? interestsError;

  bool get isAuthenticated => user != null;

  bool isInterested(String key) {
    return interests.contains(key);
  }

  AuthState copyWith({
    Object? user = _unset,
    bool? isLoading,
    Set<String>? interests,
    bool? interestsLoaded,
    Object? interestsError = _unset,
  }) {
    return AuthState(
      user: identical(user, _unset) ? this.user : user as UserModel?,
      isLoading: isLoading ?? this.isLoading,
      interests: interests ?? this.interests,
      interestsLoaded: interestsLoaded ?? this.interestsLoaded,
      interestsError: identical(interestsError, _unset)
          ? this.interestsError
          : interestsError as String?,
    );
  }
}
