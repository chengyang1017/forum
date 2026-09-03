enum AuthFailureCode {
  invalidCredentials,
  invalidEmail,
  emailAlreadyInUse,
  weakPassword,
  usernameTaken,
  userDataMissing,
  accountBanned,
  accountDisabled,
  tooManyRequests,
  wrongCurrentPassword,
  loginFailed,
  registerFailed,
  changePasswordFailed,
  resetEmailFailed,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code, {this.cause});

  final AuthFailureCode code;
  final Object? cause;

  @override
  String toString() => 'AuthFailure(${code.name})';
}
