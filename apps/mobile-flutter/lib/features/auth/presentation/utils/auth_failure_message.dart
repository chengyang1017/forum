import '../../../../app/l10n/app_localizations.dart';
import '../../domain/errors/auth_failure.dart';

String authFailureMessage(
  Object error,
  AppLocalizations l10n, {
  String? fallbackKey,
}) {
  if (error is AuthFailure) {
    return switch (error.code) {
      AuthFailureCode.invalidCredentials => l10n.get('authInvalidCredentials'),
      AuthFailureCode.invalidEmail => l10n.get('authInvalidEmail'),
      AuthFailureCode.emailAlreadyInUse => l10n.get('authEmailAlreadyInUse'),
      AuthFailureCode.weakPassword => l10n.get('authWeakPassword'),
      AuthFailureCode.usernameTaken => l10n.get('authUsernameTaken'),
      AuthFailureCode.userDataMissing => l10n.get('authUserDataMissing'),
      AuthFailureCode.accountBanned => l10n.get('authAccountBanned'),
      AuthFailureCode.accountDisabled => l10n.get('authAccountDisabled'),
      AuthFailureCode.tooManyRequests => l10n.get('authTooManyRequests'),
      AuthFailureCode.wrongCurrentPassword =>
        l10n.get('authWrongCurrentPassword'),
      AuthFailureCode.loginFailed => l10n.get('authLoginFailed'),
      AuthFailureCode.registerFailed => l10n.get('authRegisterFailed'),
      AuthFailureCode.changePasswordFailed =>
        l10n.get('authChangePasswordFailed'),
      AuthFailureCode.resetEmailFailed => l10n.get('authResetEmailFailed'),
    };
  }

  return l10n.get(fallbackKey ?? 'authUnexpectedError');
}
