from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / 'apps' / 'mobile-flutter'


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')


def write(rel: str, text: str) -> None:
    (ROOT / rel).write_text(text, encoding='utf-8')


def once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f'missing marker: {label}')
    return text.replace(old, new, 1)


def replace_between(text: str, start: str, end: str, replacement: str, label: str) -> str:
    start_i = text.find(start)
    if start_i < 0:
        raise RuntimeError(f'missing start marker: {label}')
    end_i = text.find(end, start_i + len(start))
    if end_i < 0:
        raise RuntimeError(f'missing end marker: {label}')
    return text[:start_i] + replacement + text[end_i:]


# ---------------------------------------------------------------------------
# Repository errors become stable typed failures instead of Chinese strings.
# Also clean up partial auth state on failed login/register persistence.
# ---------------------------------------------------------------------------
path = 'apps/mobile-flutter/lib/features/auth/data/repositories/firebase_auth_repository.dart'
text = read(path)
text = once(
    text,
    "import '../../domain/models/user_model.dart';\n",
    "import '../../domain/errors/auth_failure.dart';\nimport '../../domain/models/user_model.dart';\n",
    'auth repository failure import',
)
login_method = '''  @override
  Future<UserModel> login(String email, String password) async {
    UserCredential credential;
    try {
      credential = await _authService.loginWithEmailPassword(email, password);
    } on FirebaseAuthException catch (error) {
      throw _loginFailure(error);
    } catch (error) {
      throw AuthFailure(AuthFailureCode.loginFailed, cause: error);
    }

    final uid = credential.user?.uid;
    if (uid == null || uid.isEmpty) {
      await _authService.logout();
      throw const AuthFailure(AuthFailureCode.loginFailed);
    }

    final userMap = await _authService.getUserData(uid);
    if (userMap == null) {
      await _authService.logout();
      throw const AuthFailure(AuthFailureCode.userDataMissing);
    }

    if (userMap['banned'] == true) {
      await _authService.logout();
      throw const AuthFailure(AuthFailureCode.accountBanned);
    }

    try {
      await _authService.recordSuccessfulLogin(uid);
    } catch (error) {
      debugPrint('Legacy lastLogin mirror failed: $error');
    }

    return UserModelMapper.fromMap(userMap);
  }

'''
text = replace_between(
    text,
    '  @override\n  Future<UserModel> login(String email, String password) async {',
    '  @override\n  Future<UserModel> register(',
    login_method,
    'login method',
)
register_method = '''  @override
  Future<UserModel> register(
    String email,
    String password,
    String username,
  ) async {
    UserCredential credential;
    try {
      credential = await _authService.registerWithEmailPassword(
        email,
        password,
      );
    } on FirebaseAuthException catch (error) {
      throw _registerFailure(error);
    } catch (error) {
      throw AuthFailure(AuthFailureCode.registerFailed, cause: error);
    }

    final uid = credential.user?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthFailure(AuthFailureCode.registerFailed);
    }

    final newUserMap = <String, dynamic>{
      'uid': uid,
      'username': username,
      'email': email,
      'displayName': username,
      'photoUrl': null,
      'bio': null,
      'friends': <String>[],
      'friendRequests': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'banned': false,
      'role': 'user',
    };

    try {
      await _authService.saveUserData(uid, newUserMap);
    } catch (error) {
      // Avoid leaving an unusable Firebase Auth account behind when the
      // profile write fails. Otherwise retrying registration reports that the
      // email is already in use even though the account was never completed.
      try {
        await credential.user?.delete();
      } catch (cleanupError) {
        debugPrint('Failed to roll back incomplete auth user: $cleanupError');
      }
      throw AuthFailure(AuthFailureCode.registerFailed, cause: error);
    }

    return UserModelMapper.fromMap(newUserMap);
  }

'''
text = replace_between(
    text,
    '  @override\n  Future<UserModel> register(',
    '  @override\n  Future<UserModel?> getCurrentUser()',
    register_method,
    'register method',
)
change_method = '''  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _authService.reauthenticate(currentPassword);
      await _authService.updatePassword(newPassword);
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          throw const AuthFailure(AuthFailureCode.wrongCurrentPassword);
        case 'weak-password':
          throw const AuthFailure(AuthFailureCode.weakPassword);
        case 'too-many-requests':
          throw const AuthFailure(AuthFailureCode.tooManyRequests);
        case 'user-disabled':
          throw const AuthFailure(AuthFailureCode.accountDisabled);
        default:
          throw AuthFailure(AuthFailureCode.changePasswordFailed, cause: error);
      }
    } catch (error) {
      if (error is AuthFailure) {
        rethrow;
      }
      throw AuthFailure(AuthFailureCode.changePasswordFailed, cause: error);
    }
  }

'''
text = replace_between(
    text,
    '  @override\n  Future<void> changePassword(',
    '  @override\n  Future<void> sendPasswordResetEmail',
    change_method,
    'change password method',
)
reset_method = '''  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email.trim());
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'invalid-email':
          throw const AuthFailure(AuthFailureCode.invalidEmail);
        case 'too-many-requests':
          throw const AuthFailure(AuthFailureCode.tooManyRequests);
        case 'user-disabled':
          throw const AuthFailure(AuthFailureCode.accountDisabled);
        default:
          throw AuthFailure(AuthFailureCode.resetEmailFailed, cause: error);
      }
    } catch (error) {
      if (error is AuthFailure) {
        rethrow;
      }
      throw AuthFailure(AuthFailureCode.resetEmailFailed, cause: error);
    }
  }

'''
text = replace_between(
    text,
    '  @override\n  Future<void> sendPasswordResetEmail(String email) async {',
    '  @override\n  Future<Set<String>> getLegacyInterests',
    reset_method,
    'reset password method',
)
helpers = '''
  AuthFailure _loginFailure(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => const AuthFailure(AuthFailureCode.invalidEmail),
      'wrong-password' || 'invalid-credential' || 'user-not-found' =>
        const AuthFailure(AuthFailureCode.invalidCredentials),
      'user-disabled' => const AuthFailure(AuthFailureCode.accountDisabled),
      'too-many-requests' => const AuthFailure(AuthFailureCode.tooManyRequests),
      _ => AuthFailure(AuthFailureCode.loginFailed, cause: error),
    };
  }

  AuthFailure _registerFailure(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => const AuthFailure(AuthFailureCode.invalidEmail),
      'email-already-in-use' =>
        const AuthFailure(AuthFailureCode.emailAlreadyInUse),
      'weak-password' => const AuthFailure(AuthFailureCode.weakPassword),
      'user-disabled' => const AuthFailure(AuthFailureCode.accountDisabled),
      'too-many-requests' => const AuthFailure(AuthFailureCode.tooManyRequests),
      _ => AuthFailure(AuthFailureCode.registerFailed, cause: error),
    };
  }
'''
text = once(text, '\n}\n', helpers + '\n}\n', 'auth repository helpers')
write(path, text)


# AuthCubit uses the same typed username-taken failure.
path = 'apps/mobile-flutter/lib/features/auth/presentation/cubit/auth_cubit.dart'
text = read(path)
text = once(
    text,
    "import '../../domain/models/user_model.dart';\n",
    "import '../../domain/errors/auth_failure.dart';\nimport '../../domain/models/user_model.dart';\n",
    'auth cubit failure import',
)
text = once(
    text,
    "        throw Exception('该用户名已被使用，请换一个');",
    "        throw const AuthFailure(AuthFailureCode.usernameTaken);",
    'username taken failure',
)
write(path, text)


# ---------------------------------------------------------------------------
# Login screen.
# ---------------------------------------------------------------------------
path = 'apps/mobile-flutter/lib/features/auth/presentation/screens/login_screen.dart'
text = read(path)
text = once(
    text,
    "import '../../../../app/router/app_routes.dart';\n",
    "import '../../../../app/l10n/app_localizations.dart';\nimport '../../../../app/router/app_routes.dart';\n",
    'login l10n import',
)
text = once(
    text,
    "import '../cubit/auth_cubit.dart' as auth_cubit;\n",
    "import '../cubit/auth_cubit.dart' as auth_cubit;\nimport '../utils/auth_failure_message.dart';\n",
    'login auth message import',
)
text = once(
    text,
    "    if (email.isEmpty || password.isEmpty) {\n      ScaffoldMessenger.of(context).clearSnackBars();\n      ScaffoldMessenger.of(\n        context,\n      ).showSnackBar(const SnackBar(content: Text(\"请输入邮箱和密码\")));",
    "    if (email.isEmpty || password.isEmpty) {\n      final l10n = AppLocalizations.of(context)!;\n      ScaffoldMessenger.of(context).clearSnackBars();\n      ScaffoldMessenger.of(\n        context,\n      ).showSnackBar(SnackBar(content: Text(l10n.get('enterEmailAndPassword'))));",
    'login required fields',
)
old_catch = '''    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Exception:')) {
        msg = msg.replaceFirst('Exception:', '').trim();
      } else {
        msg = '登录失败，请稍后重试';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400),
        );
      }
'''
new_catch = '''    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authFailureMessage(error, l10n, fallbackKey: 'authLoginFailed')),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
'''
text = once(text, old_catch, new_catch, 'login error handling')
text = once(
    text,
    "  Widget build(BuildContext context) {\n    if (savedAccounts.isNotEmpty && !showForm) {",
    "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n\n    if (savedAccounts.isNotEmpty && !showForm) {",
    'login build l10n',
)
text = text.replace('title: const Text("登录")', 'title: Text(l10n.login)')
text = text.replace('const Text(\n                  "选择账号登录",', 'Text(\n                  l10n.get(\'chooseAccountToSignIn\'),')
text = text.replace('child: const Text("使用其他账号登录")', "child: Text(l10n.get('useAnotherAccount'))")
text = text.replace('appBar: AppBar(title: const Text("登录"), centerTitle: true)', 'appBar: AppBar(title: Text(l10n.login), centerTitle: true)')
text = text.replace('const Text(\n                "论坛社区",', 'Text(\n                l10n.appTitle,')
text = text.replace('labelText: "邮箱"', 'labelText: l10n.email')
text = text.replace('labelText: "密码"', 'labelText: l10n.password')
text = text.replace("child: const Text(\n                    '忘记密码？',\n                    style: TextStyle(fontSize: 13, color: Colors.grey),\n                  )", "child: Text(\n                    l10n.get('forgotPasswordQuestion'),\n                    style: const TextStyle(fontSize: 13, color: Colors.grey),\n                  )")
text = text.replace(': const Text("登录", style: TextStyle(fontSize: 16))', ': Text(l10n.login, style: const TextStyle(fontSize: 16))')
text = text.replace('child: const Text("没有账号？立即注册")', "child: Text(l10n.get('noAccountRegisterNow'))")
write(path, text)


# Register screen.
path = 'apps/mobile-flutter/lib/features/auth/presentation/screens/register_screen.dart'
text = read(path)
text = once(text, "import '../../../../app/router/app_routes.dart';\n", "import '../../../../app/l10n/app_localizations.dart';\nimport '../../../../app/router/app_routes.dart';\n", 'register l10n import')
text = once(text, "import '../cubit/auth_cubit.dart' as auth_cubit;\n", "import '../cubit/auth_cubit.dart' as auth_cubit;\nimport '../utils/auth_failure_message.dart';\n", 'register failure mapper')
text = text.replace("const SnackBar(content: Text('注册成功！'), backgroundColor: Colors.green)", "SnackBar(content: Text(AppLocalizations.of(context)!.get('registrationSuccess')), backgroundColor: Colors.green)")
old = '''    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Exception:')) {
        msg = msg.replaceFirst('Exception:', '').trim();
      } else {
        msg = '注册失败，请稍后重试';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
'''
new = '''    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authFailureMessage(error, l10n, fallbackKey: 'authRegisterFailed')),
            backgroundColor: Colors.red,
          ),
        );
      }
'''
text = once(text, old, new, 'register errors')
text = once(text, "  Widget build(BuildContext context) {\n    return Scaffold(", "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n\n    return Scaffold(", 'register build l10n')
text = text.replace("appBar: AppBar(title: const Text('注册'), centerTitle: true)", "appBar: AppBar(title: Text(l10n.register), centerTitle: true)")
text = text.replace("const Text(\n                '创建新账号',", "Text(\n                l10n.get('createNewAccount'),")
text = text.replace("decoration: const InputDecoration(\n                  labelText: '用户名（唯一ID）',\n                  prefixIcon: Icon(Icons.person),\n                  border: OutlineInputBorder(),\n                  hintText: '设置你的唯一用户名',\n                )", "decoration: InputDecoration(\n                  labelText: l10n.get('usernameUniqueId'),\n                  prefixIcon: const Icon(Icons.person),\n                  border: const OutlineInputBorder(),\n                  hintText: l10n.get('usernameSetupHint'),\n                )")
text = text.replace("return '请输入用户名';", "return l10n.get('enterUsername');")
text = text.replace("return '用户名至少2个字符';", "return l10n.get('usernameMinLength');")
text = text.replace("return '用户名最多20个字符';", "return l10n.get('usernameMaxLength');")
text = text.replace("return '用户名只能包含中英文、数字和下划线';", "return l10n.get('usernameAllowedCharacters');")
text = text.replace("decoration: const InputDecoration(\n                  labelText: '邮箱',\n                  prefixIcon: Icon(Icons.email),\n                  border: OutlineInputBorder(),\n                )", "decoration: InputDecoration(\n                  labelText: l10n.email,\n                  prefixIcon: const Icon(Icons.email),\n                  border: const OutlineInputBorder(),\n                )")
text = text.replace("return '请输入邮箱';", "return l10n.get('enterEmail');")
text = text.replace("return '邮箱格式不正确';", "return l10n.get('authInvalidEmail');")
text = text.replace("decoration: const InputDecoration(\n                  labelText: '密码',\n                  prefixIcon: Icon(Icons.lock),\n                  border: OutlineInputBorder(),\n                )", "decoration: InputDecoration(\n                  labelText: l10n.password,\n                  prefixIcon: const Icon(Icons.lock),\n                  border: const OutlineInputBorder(),\n                )")
text = text.replace("return '请输入密码';", "return l10n.get('enterPassword');")
text = text.replace("return '密码至少6位';", "return l10n.get('passwordMinLength');")
text = text.replace("decoration: const InputDecoration(\n                  labelText: '确认密码',\n                  prefixIcon: Icon(Icons.lock_outline),\n                  border: OutlineInputBorder(),\n                )", "decoration: InputDecoration(\n                  labelText: l10n.get('confirmPassword'),\n                  prefixIcon: const Icon(Icons.lock_outline),\n                  border: const OutlineInputBorder(),\n                )")
text = text.replace("return '请再次输入密码';", "return l10n.get('enterPasswordAgain');")
text = text.replace("return '两次密码不一致';", "return l10n.get('passwordsDoNotMatch');")
text = text.replace(": const Text('注册', style: TextStyle(fontSize: 18))", ": Text(l10n.register, style: const TextStyle(fontSize: 18))")
text = text.replace("child: const Text('已有账号？立即登录')", "child: Text(l10n.get('alreadyHaveAccountSignIn'))")
write(path, text)


# Forgot password.
path = 'apps/mobile-flutter/lib/features/auth/presentation/screens/forgot_password_screen.dart'
text = read(path)
text = once(text, "import '../../../../app/router/app_routes.dart';\n", "import '../../../../app/l10n/app_localizations.dart';\nimport '../../../../app/router/app_routes.dart';\n", 'forgot l10n import')
text = once(text, "import '../cubit/auth_cubit.dart' as auth_cubit;\n", "import '../cubit/auth_cubit.dart' as auth_cubit;\nimport '../utils/auth_failure_message.dart';\n", 'forgot failure mapper')
text = text.replace("const SnackBar(content: Text('请输入邮箱'), backgroundColor: Colors.red)", "SnackBar(content: Text(AppLocalizations.of(context)!.get('enterEmail')), backgroundColor: Colors.red)")
text = text.replace("SnackBar(content: Text('$error'), backgroundColor: Colors.red)", "SnackBar(\n          content: Text(authFailureMessage(error, AppLocalizations.of(context)!, fallbackKey: 'authResetEmailFailed')),\n          backgroundColor: Colors.red,\n        )")
text = once(text, "  Widget build(BuildContext context) {\n    return Scaffold(", "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n    final colorScheme = Theme.of(context).colorScheme;\n\n    return Scaffold(", 'forgot build')
text = text.replace("appBar: AppBar(title: const Text('找回密码'), centerTitle: true)", "appBar: AppBar(title: Text(l10n.get('recoverPassword')), centerTitle: true)")
text = text.replace("color: Theme.of(context).colorScheme.primary", 'color: colorScheme.primary')
text = text.replace("_emailSent ? '检查你的邮箱' : '通过邮箱重置密码'", "_emailSent ? l10n.get('checkYourEmail') : l10n.get('resetPasswordByEmail')")
text = text.replace("_emailSent\n                  ? '如果这个邮箱已注册，我们会发送密码重置链接。请打开邮件并按照提示设置新密码。'\n                  : '输入注册邮箱，我们会通过 Firebase Authentication 发送安全的密码重置链接。'", "_emailSent\n                  ? l10n.get('resetEmailSentDescription')\n                  : l10n.get('resetEmailDescription')")
text = text.replace("style: TextStyle(color: Colors.grey.shade700, height: 1.5)", "style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.5)")
text = text.replace("decoration: const InputDecoration(\n                labelText: '邮箱',\n                border: OutlineInputBorder(),\n                prefixIcon: Icon(Icons.email_outlined),\n              )", "decoration: InputDecoration(\n                labelText: l10n.email,\n                border: const OutlineInputBorder(),\n                prefixIcon: const Icon(Icons.email_outlined),\n              )")
text = text.replace("label: Text(_emailSent ? '重新发送重置邮件' : '发送重置邮件')", "label: Text(\n                _emailSent ? l10n.get('resendResetEmail') : l10n.get('sendResetEmail'),\n              )")
text = text.replace("child: const Text('返回登录')", "child: Text(l10n.get('backToSignIn'))")
write(path, text)


# Change password.
path = 'apps/mobile-flutter/lib/features/auth/presentation/screens/change_password_screen.dart'
text = read(path)
text = once(text, "import 'package:flutter_bloc/flutter_bloc.dart';\n", "import 'package:flutter_bloc/flutter_bloc.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n", 'change password l10n')
text = once(text, "import '../cubit/auth_cubit.dart' as auth_cubit;\n", "import '../cubit/auth_cubit.dart' as auth_cubit;\nimport '../utils/auth_failure_message.dart';\n", 'change password mapper')
text = text.replace("const SnackBar(\n            content: Text('密码修改成功'),\n            backgroundColor: Colors.green,\n          )", "SnackBar(\n            content: Text(AppLocalizations.of(context)!.get('passwordChangedSuccess')),\n            backgroundColor: Colors.green,\n          )")
old = '''    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Exception:')) {
        msg = msg.replaceFirst('Exception:', '').trim();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
'''
new = '''    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authFailureMessage(error, l10n, fallbackKey: 'authChangePasswordFailed')),
            backgroundColor: Colors.red,
          ),
        );
      }
'''
text = once(text, old, new, 'change password errors')
text = once(text, "  Widget build(BuildContext context) {\n    return Scaffold(", "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n\n    return Scaffold(", 'change password build')
text = text.replace("appBar: AppBar(title: const Text('修改密码'), centerTitle: true)", "appBar: AppBar(title: Text(l10n.changePassword), centerTitle: true)")
for label, key, icon in [
    ('当前密码','currentPassword','Icons.lock'),('新密码','newPassword','Icons.lock_open'),('确认新密码','confirmNewPassword','Icons.lock_open')
]:
    old_dec = f"decoration: const InputDecoration(\n                  labelText: '{label}',\n                  prefixIcon: Icon({icon}),\n                  border: OutlineInputBorder(),\n                )"
    new_dec = f"decoration: InputDecoration(\n                  labelText: l10n.get('{key}'),\n                  prefixIcon: const Icon({icon}),\n                  border: const OutlineInputBorder(),\n                )"
    text = text.replace(old_dec, new_dec)
text = text.replace("v == null || v.isEmpty ? '请输入当前密码' : null", "v == null || v.isEmpty ? l10n.get('enterCurrentPassword') : null")
text = text.replace("if (v == null || v.isEmpty) return '请输入新密码';", "if (v == null || v.isEmpty) return l10n.get('enterNewPassword');")
text = text.replace("if (v.length < 6) return '密码至少6位';", "if (v.length < 6) return l10n.get('passwordMinLength');")
text = text.replace("if (v == null || v.isEmpty) return '请再次输入新密码';", "if (v == null || v.isEmpty) return l10n.get('enterNewPasswordAgain');")
text = text.replace("if (v != _newPasswordController.text) return '两次密码不一致';", "if (v != _newPasswordController.text) return l10n.get('passwordsDoNotMatch');")
text = text.replace(": const Text('确认修改', style: TextStyle(fontSize: 16))", ": Text(l10n.get('confirmChange'), style: const TextStyle(fontSize: 16))")
write(path, text)


# Security settings.
path = 'apps/mobile-flutter/lib/features/profile/presentation/screens/security_settings_screen.dart'
text = read(path)
text = once(text, "import 'package:flutter_bloc/flutter_bloc.dart';\n\n", "import 'package:flutter_bloc/flutter_bloc.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n", 'security l10n import')
text = once(text, "import '../../../auth/presentation/cubit/auth_cubit.dart';\n", "import '../../../auth/presentation/cubit/auth_cubit.dart';\nimport '../../../auth/presentation/utils/auth_failure_message.dart';\n", 'security mapper import')
text = text.replace("const SnackBar(\n          content: Text('当前账号没有可用邮箱'),\n          backgroundColor: Colors.red,\n        )", "SnackBar(\n          content: Text(AppLocalizations.of(context)!.get('noUsableEmail')),\n          backgroundColor: Colors.red,\n        )")
text = text.replace("const SnackBar(\n          content: Text('密码重置邮件已发送，请检查邮箱'),\n          backgroundColor: Colors.green,\n        )", "SnackBar(\n          content: Text(AppLocalizations.of(context)!.get('resetEmailSent')),\n          backgroundColor: Colors.green,\n        )")
text = text.replace("SnackBar(content: Text('$error'), backgroundColor: Colors.red)", "SnackBar(\n          content: Text(authFailureMessage(error, AppLocalizations.of(context)!, fallbackKey: 'authResetEmailFailed')),\n          backgroundColor: Colors.red,\n        )")
text = once(text, "  Widget build(BuildContext context) {\n    final email", "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n    final colorScheme = Theme.of(context).colorScheme;\n    final email", 'security build')
text = text.replace("appBar: AppBar(title: const Text('账户安全'), centerTitle: true)", "appBar: AppBar(title: Text(l10n.get('accountSecurity')), centerTitle: true)")
text = text.replace("color: Theme.of(context).colorScheme.surfaceContainerLow", 'color: colorScheme.surfaceContainerLow')
text = replace_between(
    text,
    "            child: const Row(\n              crossAxisAlignment: CrossAxisAlignment.start,",
    "          ),\n          const SizedBox(height: 24),",
    "            child: Row(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                const Icon(Icons.verified_user_outlined),\n                const SizedBox(width: 12),\n                Expanded(\n                  child: Text(\n                    l10n.get('passwordRecoveryPrivacyDescription'),\n                    style: const TextStyle(height: 1.5),\n                  ),\n                ),\n              ],\n            ),\n          ),\n          const SizedBox(height: 24),",
    'security info card',
)
text = text.replace("const Text(\n            '密码恢复',\n            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),\n          )", "Text(\n            l10n.get('passwordRecovery'),\n            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),\n          )")
text = text.replace("email == null || email.isEmpty ? '当前账号没有可用邮箱' : email", "email == null || email.isEmpty ? l10n.get('noUsableEmail') : email")
text = text.replace("style: TextStyle(color: Colors.grey.shade700)", "style: TextStyle(color: colorScheme.onSurfaceVariant)")
text = text.replace("label: Text(_isSendingResetEmail ? '发送中...' : '发送密码重置邮件')", "label: Text(\n              _isSendingResetEmail ? l10n.get('sending') : l10n.get('sendResetEmail'),\n            )")
text = text.replace("            '重置链接由 Firebase Authentication 生成，密码不会经过 Firestore。',", "            l10n.get('passwordResetTechnicalNote'),")
text = text.replace("color: Colors.grey.shade600", "color: colorScheme.onSurfaceVariant")
write(path, text)


translations = {
'en': {
'enterEmailAndPassword':'Enter your email and password','chooseAccountToSignIn':'Choose an account','useAnotherAccount':'Use another account','forgotPasswordQuestion':'Forgot password?','noAccountRegisterNow':'No account? Register now','createNewAccount':'Create a new account','usernameUniqueId':'Username (unique ID)','usernameSetupHint':'Choose your unique username','enterUsername':'Enter a username','usernameMinLength':'Username must be at least 2 characters','usernameMaxLength':'Username can be at most 20 characters','usernameAllowedCharacters':'Username can contain letters, Chinese characters, numbers, and underscores','enterEmail':'Enter your email','enterPassword':'Enter your password','passwordMinLength':'Password must be at least 6 characters','confirmPassword':'Confirm password','enterPasswordAgain':'Enter your password again','passwordsDoNotMatch':'Passwords do not match','alreadyHaveAccountSignIn':'Already have an account? Sign in','registrationSuccess':'Registration successful','recoverPassword':'Recover password','checkYourEmail':'Check your email','resetPasswordByEmail':'Reset password by email','resetEmailSentDescription':'If this email is registered, a password reset link will be sent. Open the email and follow the instructions to set a new password.','resetEmailDescription':'Enter your registered email address to receive a secure password reset link.','resendResetEmail':'Resend reset email','sendResetEmail':'Send password reset email','backToSignIn':'Back to sign in','currentPassword':'Current password','newPassword':'New password','confirmNewPassword':'Confirm new password','enterCurrentPassword':'Enter your current password','enterNewPassword':'Enter a new password','enterNewPasswordAgain':'Enter the new password again','confirmChange':'Confirm change','passwordChangedSuccess':'Password changed successfully','accountSecurity':'Account security','noUsableEmail':'This account has no usable email address','resetEmailSent':'Password reset email sent. Check your inbox.','passwordRecoveryPrivacyDescription':'Password recovery is handled through the registered email address. The app does not store or verify plaintext security answers.','passwordRecovery':'Password recovery','sending':'Sending...','passwordResetTechnicalNote':'The reset link is generated by Firebase Authentication; your password is not stored in Firestore.','authInvalidCredentials':'Incorrect email or password','authInvalidEmail':'Invalid email address','authEmailAlreadyInUse':'This email is already registered','authWeakPassword':'Password is too weak; use at least 6 characters','authUsernameTaken':'This username is already taken','authUserDataMissing':'Account profile data is missing. Please contact support or register again.','authAccountBanned':'This account has been banned','authAccountDisabled':'This account has been disabled','authTooManyRequests':'Too many requests. Please try again later.','authWrongCurrentPassword':'Current password is incorrect','authLoginFailed':'Sign-in failed. Please try again later.','authRegisterFailed':'Registration failed. Please try again later.','authChangePasswordFailed':'Password change failed. Please try again later.','authResetEmailFailed':'Could not send the password reset email. Please try again later.','authUnexpectedError':'Something went wrong. Please try again.'},
'zh': {
'enterEmailAndPassword':'请输入邮箱和密码','chooseAccountToSignIn':'选择账号登录','useAnotherAccount':'使用其他账号登录','forgotPasswordQuestion':'忘记密码？','noAccountRegisterNow':'没有账号？立即注册','createNewAccount':'创建新账号','usernameUniqueId':'用户名（唯一 ID）','usernameSetupHint':'设置你的唯一用户名','enterUsername':'请输入用户名','usernameMinLength':'用户名至少 2 个字符','usernameMaxLength':'用户名最多 20 个字符','usernameAllowedCharacters':'用户名只能包含中英文、数字和下划线','enterEmail':'请输入邮箱','enterPassword':'请输入密码','passwordMinLength':'密码至少 6 位','confirmPassword':'确认密码','enterPasswordAgain':'请再次输入密码','passwordsDoNotMatch':'两次密码不一致','alreadyHaveAccountSignIn':'已有账号？立即登录','registrationSuccess':'注册成功','recoverPassword':'找回密码','checkYourEmail':'检查你的邮箱','resetPasswordByEmail':'通过邮箱重置密码','resetEmailSentDescription':'如果这个邮箱已注册，我们会发送密码重置链接。请打开邮件并按照提示设置新密码。','resetEmailDescription':'输入注册邮箱，我们会发送安全的密码重置链接。','resendResetEmail':'重新发送重置邮件','sendResetEmail':'发送密码重置邮件','backToSignIn':'返回登录','currentPassword':'当前密码','newPassword':'新密码','confirmNewPassword':'确认新密码','enterCurrentPassword':'请输入当前密码','enterNewPassword':'请输入新密码','enterNewPasswordAgain':'请再次输入新密码','confirmChange':'确认修改','passwordChangedSuccess':'密码修改成功','accountSecurity':'账户安全','noUsableEmail':'当前账号没有可用邮箱','resetEmailSent':'密码重置邮件已发送，请检查邮箱','passwordRecoveryPrivacyDescription':'密码找回统一通过注册邮箱完成。应用不会保存或验证明文密保答案。','passwordRecovery':'密码恢复','sending':'发送中...','passwordResetTechnicalNote':'重置链接由 Firebase Authentication 生成，密码不会存储在 Firestore。','authInvalidCredentials':'邮箱或密码不正确','authInvalidEmail':'邮箱格式不正确','authEmailAlreadyInUse':'该邮箱已经注册','authWeakPassword':'密码强度不足，请至少输入 6 位','authUsernameTaken':'该用户名已被使用，请换一个','authUserDataMissing':'账号资料不存在，请联系支持或重新注册','authAccountBanned':'账号已被封禁','authAccountDisabled':'账号已被停用','authTooManyRequests':'请求过于频繁，请稍后再试','authWrongCurrentPassword':'当前密码错误','authLoginFailed':'登录失败，请稍后重试','authRegisterFailed':'注册失败，请稍后重试','authChangePasswordFailed':'修改密码失败，请稍后重试','authResetEmailFailed':'发送重置邮件失败，请稍后重试','authUnexpectedError':'操作失败，请稍后重试'},
'ja': {
'enterEmailAndPassword':'メールアドレスとパスワードを入力してください','chooseAccountToSignIn':'アカウントを選択','useAnotherAccount':'別のアカウントを使用','forgotPasswordQuestion':'パスワードを忘れましたか？','noAccountRegisterNow':'アカウントがありませんか？登録','createNewAccount':'新しいアカウントを作成','usernameUniqueId':'ユーザー名（固有 ID）','usernameSetupHint':'固有のユーザー名を設定','enterUsername':'ユーザー名を入力してください','usernameMinLength':'ユーザー名は2文字以上必要です','usernameMaxLength':'ユーザー名は20文字以内です','usernameAllowedCharacters':'ユーザー名には英数字、中国語文字、アンダースコアを使用できます','enterEmail':'メールアドレスを入力してください','enterPassword':'パスワードを入力してください','passwordMinLength':'パスワードは6文字以上必要です','confirmPassword':'パスワード確認','enterPasswordAgain':'パスワードをもう一度入力してください','passwordsDoNotMatch':'パスワードが一致しません','alreadyHaveAccountSignIn':'アカウントをお持ちですか？ログイン','registrationSuccess':'登録しました','recoverPassword':'パスワードを復元','checkYourEmail':'メールを確認してください','resetPasswordByEmail':'メールでパスワードをリセット','resetEmailSentDescription':'このメールが登録済みの場合、パスワード再設定リンクが送信されます。メールの案内に従って新しいパスワードを設定してください。','resetEmailDescription':'登録したメールアドレスを入力すると、安全なパスワード再設定リンクが送信されます。','resendResetEmail':'再設定メールを再送','sendResetEmail':'パスワード再設定メールを送信','backToSignIn':'ログインに戻る','currentPassword':'現在のパスワード','newPassword':'新しいパスワード','confirmNewPassword':'新しいパスワードを確認','enterCurrentPassword':'現在のパスワードを入力してください','enterNewPassword':'新しいパスワードを入力してください','enterNewPasswordAgain':'新しいパスワードをもう一度入力してください','confirmChange':'変更を確定','passwordChangedSuccess':'パスワードを変更しました','accountSecurity':'アカウントのセキュリティ','noUsableEmail':'このアカウントには利用可能なメールアドレスがありません','resetEmailSent':'パスワード再設定メールを送信しました。受信箱を確認してください。','passwordRecoveryPrivacyDescription':'パスワードの復元は登録メールアドレスを通じて行います。アプリは秘密の質問への回答を平文で保存・検証しません。','passwordRecovery':'パスワードの復元','sending':'送信中...','passwordResetTechnicalNote':'再設定リンクは Firebase Authentication により生成され、パスワードは Firestore に保存されません。','authInvalidCredentials':'メールアドレスまたはパスワードが正しくありません','authInvalidEmail':'メールアドレスの形式が正しくありません','authEmailAlreadyInUse':'このメールアドレスはすでに登録されています','authWeakPassword':'パスワードが弱すぎます。6文字以上にしてください','authUsernameTaken':'このユーザー名はすでに使用されています','authUserDataMissing':'アカウントのプロフィール情報がありません。サポートに連絡するか、再登録してください。','authAccountBanned':'このアカウントは禁止されています','authAccountDisabled':'このアカウントは無効化されています','authTooManyRequests':'リクエストが多すぎます。しばらくしてから再試行してください。','authWrongCurrentPassword':'現在のパスワードが正しくありません','authLoginFailed':'ログインに失敗しました。後でもう一度お試しください。','authRegisterFailed':'登録に失敗しました。後でもう一度お試しください。','authChangePasswordFailed':'パスワード変更に失敗しました。後でもう一度お試しください。','authResetEmailFailed':'パスワード再設定メールを送信できませんでした。後でもう一度お試しください。','authUnexpectedError':'エラーが発生しました。もう一度お試しください。'},
'ko': {
'enterEmailAndPassword':'이메일과 비밀번호를 입력하세요','chooseAccountToSignIn':'로그인할 계정 선택','useAnotherAccount':'다른 계정 사용','forgotPasswordQuestion':'비밀번호를 잊으셨나요?','noAccountRegisterNow':'계정이 없나요? 지금 가입','createNewAccount':'새 계정 만들기','usernameUniqueId':'사용자 이름 (고유 ID)','usernameSetupHint':'고유한 사용자 이름을 설정하세요','enterUsername':'사용자 이름을 입력하세요','usernameMinLength':'사용자 이름은 2자 이상이어야 합니다','usernameMaxLength':'사용자 이름은 20자 이하여야 합니다','usernameAllowedCharacters':'사용자 이름에는 영문, 한자, 숫자, 밑줄을 사용할 수 있습니다','enterEmail':'이메일을 입력하세요','enterPassword':'비밀번호를 입력하세요','passwordMinLength':'비밀번호는 6자 이상이어야 합니다','confirmPassword':'비밀번호 확인','enterPasswordAgain':'비밀번호를 다시 입력하세요','passwordsDoNotMatch':'비밀번호가 일치하지 않습니다','alreadyHaveAccountSignIn':'이미 계정이 있나요? 로그인','registrationSuccess':'가입이 완료되었습니다','recoverPassword':'비밀번호 찾기','checkYourEmail':'이메일을 확인하세요','resetPasswordByEmail':'이메일로 비밀번호 재설정','resetEmailSentDescription':'등록된 이메일이면 비밀번호 재설정 링크가 전송됩니다. 이메일의 안내에 따라 새 비밀번호를 설정하세요.','resetEmailDescription':'등록한 이메일 주소를 입력하면 안전한 비밀번호 재설정 링크를 보내드립니다.','resendResetEmail':'재설정 이메일 다시 보내기','sendResetEmail':'비밀번호 재설정 이메일 보내기','backToSignIn':'로그인으로 돌아가기','currentPassword':'현재 비밀번호','newPassword':'새 비밀번호','confirmNewPassword':'새 비밀번호 확인','enterCurrentPassword':'현재 비밀번호를 입력하세요','enterNewPassword':'새 비밀번호를 입력하세요','enterNewPasswordAgain':'새 비밀번호를 다시 입력하세요','confirmChange':'변경 확인','passwordChangedSuccess':'비밀번호가 변경되었습니다','accountSecurity':'계정 보안','noUsableEmail':'이 계정에는 사용할 수 있는 이메일이 없습니다','resetEmailSent':'비밀번호 재설정 이메일을 보냈습니다. 받은편지함을 확인하세요.','passwordRecoveryPrivacyDescription':'비밀번호 복구는 등록된 이메일을 통해 진행됩니다. 앱은 보안 질문 답변을 평문으로 저장하거나 검증하지 않습니다.','passwordRecovery':'비밀번호 복구','sending':'보내는 중...','passwordResetTechnicalNote':'재설정 링크는 Firebase Authentication에서 생성되며 비밀번호는 Firestore에 저장되지 않습니다.','authInvalidCredentials':'이메일 또는 비밀번호가 올바르지 않습니다','authInvalidEmail':'이메일 형식이 올바르지 않습니다','authEmailAlreadyInUse':'이미 등록된 이메일입니다','authWeakPassword':'비밀번호가 너무 약합니다. 6자 이상 입력하세요','authUsernameTaken':'이미 사용 중인 사용자 이름입니다','authUserDataMissing':'계정 프로필 정보가 없습니다. 지원팀에 문의하거나 다시 가입하세요.','authAccountBanned':'차단된 계정입니다','authAccountDisabled':'비활성화된 계정입니다','authTooManyRequests':'요청이 너무 많습니다. 잠시 후 다시 시도하세요.','authWrongCurrentPassword':'현재 비밀번호가 올바르지 않습니다','authLoginFailed':'로그인에 실패했습니다. 잠시 후 다시 시도하세요.','authRegisterFailed':'가입에 실패했습니다. 잠시 후 다시 시도하세요.','authChangePasswordFailed':'비밀번호 변경에 실패했습니다. 잠시 후 다시 시도하세요.','authResetEmailFailed':'비밀번호 재설정 이메일을 보내지 못했습니다. 잠시 후 다시 시도하세요.','authUnexpectedError':'문제가 발생했습니다. 다시 시도하세요.'},
'ms': {
'enterEmailAndPassword':'Masukkan e-mel dan kata laluan','chooseAccountToSignIn':'Pilih akaun untuk log masuk','useAnotherAccount':'Gunakan akaun lain','forgotPasswordQuestion':'Lupa kata laluan?','noAccountRegisterNow':'Belum ada akaun? Daftar sekarang','createNewAccount':'Cipta akaun baharu','usernameUniqueId':'Nama pengguna (ID unik)','usernameSetupHint':'Tetapkan nama pengguna unik anda','enterUsername':'Masukkan nama pengguna','usernameMinLength':'Nama pengguna mesti sekurang-kurangnya 2 aksara','usernameMaxLength':'Nama pengguna boleh mempunyai maksimum 20 aksara','usernameAllowedCharacters':'Nama pengguna boleh mengandungi huruf, aksara Cina, nombor dan garis bawah','enterEmail':'Masukkan e-mel','enterPassword':'Masukkan kata laluan','passwordMinLength':'Kata laluan mesti sekurang-kurangnya 6 aksara','confirmPassword':'Sahkan kata laluan','enterPasswordAgain':'Masukkan kata laluan sekali lagi','passwordsDoNotMatch':'Kata laluan tidak sepadan','alreadyHaveAccountSignIn':'Sudah ada akaun? Log masuk','registrationSuccess':'Pendaftaran berjaya','recoverPassword':'Pulihkan kata laluan','checkYourEmail':'Semak e-mel anda','resetPasswordByEmail':'Tetapkan semula kata laluan melalui e-mel','resetEmailSentDescription':'Jika e-mel ini didaftarkan, pautan tetapan semula kata laluan akan dihantar. Buka e-mel dan ikuti arahan untuk menetapkan kata laluan baharu.','resetEmailDescription':'Masukkan alamat e-mel berdaftar untuk menerima pautan tetapan semula kata laluan yang selamat.','resendResetEmail':'Hantar semula e-mel tetapan semula','sendResetEmail':'Hantar e-mel tetapan semula kata laluan','backToSignIn':'Kembali ke log masuk','currentPassword':'Kata laluan semasa','newPassword':'Kata laluan baharu','confirmNewPassword':'Sahkan kata laluan baharu','enterCurrentPassword':'Masukkan kata laluan semasa','enterNewPassword':'Masukkan kata laluan baharu','enterNewPasswordAgain':'Masukkan kata laluan baharu sekali lagi','confirmChange':'Sahkan perubahan','passwordChangedSuccess':'Kata laluan berjaya ditukar','accountSecurity':'Keselamatan akaun','noUsableEmail':'Akaun ini tiada alamat e-mel yang boleh digunakan','resetEmailSent':'E-mel tetapan semula kata laluan telah dihantar. Semak peti masuk anda.','passwordRecoveryPrivacyDescription':'Pemulihan kata laluan dilakukan melalui e-mel berdaftar. Aplikasi tidak menyimpan atau mengesahkan jawapan keselamatan dalam bentuk teks biasa.','passwordRecovery':'Pemulihan kata laluan','sending':'Menghantar...','passwordResetTechnicalNote':'Pautan tetapan semula dijana oleh Firebase Authentication; kata laluan anda tidak disimpan dalam Firestore.','authInvalidCredentials':'E-mel atau kata laluan tidak betul','authInvalidEmail':'Alamat e-mel tidak sah','authEmailAlreadyInUse':'E-mel ini telah didaftarkan','authWeakPassword':'Kata laluan terlalu lemah; gunakan sekurang-kurangnya 6 aksara','authUsernameTaken':'Nama pengguna ini telah digunakan','authUserDataMissing':'Data profil akaun tiada. Hubungi sokongan atau daftar semula.','authAccountBanned':'Akaun ini telah disekat','authAccountDisabled':'Akaun ini telah dinyahaktifkan','authTooManyRequests':'Terlalu banyak permintaan. Cuba lagi kemudian.','authWrongCurrentPassword':'Kata laluan semasa tidak betul','authLoginFailed':'Log masuk gagal. Cuba lagi kemudian.','authRegisterFailed':'Pendaftaran gagal. Cuba lagi kemudian.','authChangePasswordFailed':'Penukaran kata laluan gagal. Cuba lagi kemudian.','authResetEmailFailed':'E-mel tetapan semula kata laluan gagal dihantar. Cuba lagi kemudian.','authUnexpectedError':'Sesuatu berlaku. Cuba lagi.'},
'vi': {
'enterEmailAndPassword':'Nhập email và mật khẩu','chooseAccountToSignIn':'Chọn tài khoản để đăng nhập','useAnotherAccount':'Dùng tài khoản khác','forgotPasswordQuestion':'Quên mật khẩu?','noAccountRegisterNow':'Chưa có tài khoản? Đăng ký ngay','createNewAccount':'Tạo tài khoản mới','usernameUniqueId':'Tên người dùng (ID duy nhất)','usernameSetupHint':'Đặt tên người dùng duy nhất của bạn','enterUsername':'Nhập tên người dùng','usernameMinLength':'Tên người dùng phải có ít nhất 2 ký tự','usernameMaxLength':'Tên người dùng tối đa 20 ký tự','usernameAllowedCharacters':'Tên người dùng có thể chứa chữ cái, chữ Hán, số và dấu gạch dưới','enterEmail':'Nhập email','enterPassword':'Nhập mật khẩu','passwordMinLength':'Mật khẩu phải có ít nhất 6 ký tự','confirmPassword':'Xác nhận mật khẩu','enterPasswordAgain':'Nhập lại mật khẩu','passwordsDoNotMatch':'Mật khẩu không khớp','alreadyHaveAccountSignIn':'Đã có tài khoản? Đăng nhập','registrationSuccess':'Đăng ký thành công','recoverPassword':'Khôi phục mật khẩu','checkYourEmail':'Kiểm tra email của bạn','resetPasswordByEmail':'Đặt lại mật khẩu qua email','resetEmailSentDescription':'Nếu email này đã đăng ký, liên kết đặt lại mật khẩu sẽ được gửi. Hãy mở email và làm theo hướng dẫn để đặt mật khẩu mới.','resetEmailDescription':'Nhập email đã đăng ký để nhận liên kết đặt lại mật khẩu an toàn.','resendResetEmail':'Gửi lại email đặt lại','sendResetEmail':'Gửi email đặt lại mật khẩu','backToSignIn':'Quay lại đăng nhập','currentPassword':'Mật khẩu hiện tại','newPassword':'Mật khẩu mới','confirmNewPassword':'Xác nhận mật khẩu mới','enterCurrentPassword':'Nhập mật khẩu hiện tại','enterNewPassword':'Nhập mật khẩu mới','enterNewPasswordAgain':'Nhập lại mật khẩu mới','confirmChange':'Xác nhận thay đổi','passwordChangedSuccess':'Đã đổi mật khẩu','accountSecurity':'Bảo mật tài khoản','noUsableEmail':'Tài khoản này không có email có thể sử dụng','resetEmailSent':'Đã gửi email đặt lại mật khẩu. Hãy kiểm tra hộp thư.','passwordRecoveryPrivacyDescription':'Khôi phục mật khẩu được thực hiện qua email đã đăng ký. Ứng dụng không lưu hoặc xác minh câu trả lời bảo mật ở dạng văn bản thuần.','passwordRecovery':'Khôi phục mật khẩu','sending':'Đang gửi...','passwordResetTechnicalNote':'Liên kết đặt lại được tạo bởi Firebase Authentication; mật khẩu không được lưu trong Firestore.','authInvalidCredentials':'Email hoặc mật khẩu không đúng','authInvalidEmail':'Địa chỉ email không hợp lệ','authEmailAlreadyInUse':'Email này đã được đăng ký','authWeakPassword':'Mật khẩu quá yếu; hãy dùng ít nhất 6 ký tự','authUsernameTaken':'Tên người dùng này đã được sử dụng','authUserDataMissing':'Thiếu dữ liệu hồ sơ tài khoản. Hãy liên hệ hỗ trợ hoặc đăng ký lại.','authAccountBanned':'Tài khoản này đã bị cấm','authAccountDisabled':'Tài khoản này đã bị vô hiệu hóa','authTooManyRequests':'Có quá nhiều yêu cầu. Hãy thử lại sau.','authWrongCurrentPassword':'Mật khẩu hiện tại không đúng','authLoginFailed':'Đăng nhập thất bại. Hãy thử lại sau.','authRegisterFailed':'Đăng ký thất bại. Hãy thử lại sau.','authChangePasswordFailed':'Đổi mật khẩu thất bại. Hãy thử lại sau.','authResetEmailFailed':'Không thể gửi email đặt lại mật khẩu. Hãy thử lại sau.','authUnexpectedError':'Đã xảy ra lỗi. Hãy thử lại.'},
'th': {
'enterEmailAndPassword':'กรอกอีเมลและรหัสผ่าน','chooseAccountToSignIn':'เลือกบัญชีเพื่อเข้าสู่ระบบ','useAnotherAccount':'ใช้บัญชีอื่น','forgotPasswordQuestion':'ลืมรหัสผ่าน?','noAccountRegisterNow':'ยังไม่มีบัญชี? สมัครตอนนี้','createNewAccount':'สร้างบัญชีใหม่','usernameUniqueId':'ชื่อผู้ใช้ (ID ไม่ซ้ำ)','usernameSetupHint':'ตั้งชื่อผู้ใช้ที่ไม่ซ้ำของคุณ','enterUsername':'กรอกชื่อผู้ใช้','usernameMinLength':'ชื่อผู้ใช้ต้องมีอย่างน้อย 2 ตัวอักษร','usernameMaxLength':'ชื่อผู้ใช้มีได้ไม่เกิน 20 ตัวอักษร','usernameAllowedCharacters':'ชื่อผู้ใช้สามารถมีตัวอักษร อักษรจีน ตัวเลข และขีดล่าง','enterEmail':'กรอกอีเมล','enterPassword':'กรอกรหัสผ่าน','passwordMinLength':'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร','confirmPassword':'ยืนยันรหัสผ่าน','enterPasswordAgain':'กรอกรหัสผ่านอีกครั้ง','passwordsDoNotMatch':'รหัสผ่านไม่ตรงกัน','alreadyHaveAccountSignIn':'มีบัญชีแล้ว? เข้าสู่ระบบ','registrationSuccess':'สมัครสมาชิกสำเร็จ','recoverPassword':'กู้คืนรหัสผ่าน','checkYourEmail':'ตรวจสอบอีเมลของคุณ','resetPasswordByEmail':'รีเซ็ตรหัสผ่านทางอีเมล','resetEmailSentDescription':'หากอีเมลนี้ลงทะเบียนไว้ ระบบจะส่งลิงก์รีเซ็ตรหัสผ่าน โปรดเปิดอีเมลและทำตามคำแนะนำเพื่อตั้งรหัสผ่านใหม่','resetEmailDescription':'กรอกอีเมลที่ลงทะเบียนเพื่อรับลิงก์รีเซ็ตรหัสผ่านที่ปลอดภัย','resendResetEmail':'ส่งอีเมลรีเซ็ตอีกครั้ง','sendResetEmail':'ส่งอีเมลรีเซ็ตรหัสผ่าน','backToSignIn':'กลับไปเข้าสู่ระบบ','currentPassword':'รหัสผ่านปัจจุบัน','newPassword':'รหัสผ่านใหม่','confirmNewPassword':'ยืนยันรหัสผ่านใหม่','enterCurrentPassword':'กรอกรหัสผ่านปัจจุบัน','enterNewPassword':'กรอกรหัสผ่านใหม่','enterNewPasswordAgain':'กรอกรหัสผ่านใหม่อีกครั้ง','confirmChange':'ยืนยันการเปลี่ยนแปลง','passwordChangedSuccess':'เปลี่ยนรหัสผ่านสำเร็จ','accountSecurity':'ความปลอดภัยของบัญชี','noUsableEmail':'บัญชีนี้ไม่มีอีเมลที่ใช้งานได้','resetEmailSent':'ส่งอีเมลรีเซ็ตรหัสผ่านแล้ว โปรดตรวจสอบกล่องจดหมาย','passwordRecoveryPrivacyDescription':'การกู้คืนรหัสผ่านดำเนินการผ่านอีเมลที่ลงทะเบียน แอปจะไม่จัดเก็บหรือตรวจสอบคำตอบคำถามความปลอดภัยเป็นข้อความธรรมดา','passwordRecovery':'การกู้คืนรหัสผ่าน','sending':'กำลังส่ง...','passwordResetTechnicalNote':'ลิงก์รีเซ็ตสร้างโดย Firebase Authentication และรหัสผ่านจะไม่ถูกเก็บใน Firestore','authInvalidCredentials':'อีเมลหรือรหัสผ่านไม่ถูกต้อง','authInvalidEmail':'ที่อยู่อีเมลไม่ถูกต้อง','authEmailAlreadyInUse':'อีเมลนี้ลงทะเบียนแล้ว','authWeakPassword':'รหัสผ่านอ่อนเกินไป กรุณาใช้至少 6 ตัวอักษร','authUsernameTaken':'ชื่อผู้ใช้นี้ถูกใช้แล้ว','authUserDataMissing':'ไม่พบข้อมูลโปรไฟล์บัญชี โปรดติดต่อฝ่ายสนับสนุนหรือสมัครใหม่','authAccountBanned':'บัญชีนี้ถูกแบน','authAccountDisabled':'บัญชีนี้ถูกปิดใช้งาน','authTooManyRequests':'มีคำขอมากเกินไป โปรดลองอีกครั้งภายหลัง','authWrongCurrentPassword':'รหัสผ่านปัจจุบันไม่ถูกต้อง','authLoginFailed':'เข้าสู่ระบบไม่สำเร็จ โปรดลองอีกครั้งภายหลัง','authRegisterFailed':'สมัครสมาชิกไม่สำเร็จ โปรดลองอีกครั้งภายหลัง','authChangePasswordFailed':'เปลี่ยนรหัสผ่านไม่สำเร็จ โปรดลองอีกครั้งภายหลัง','authResetEmailFailed':'ส่งอีเมลรีเซ็ตรหัสผ่านไม่สำเร็จ โปรดลองอีกครั้งภายหลัง','authUnexpectedError':'เกิดข้อผิดพลาด โปรดลองอีกครั้ง'}
}

# Fix one accidental mixed-language Thai translation before writing.
translations['th']['authWeakPassword'] = 'รหัสผ่านอ่อนเกินไป กรุณาใช้อย่างน้อย 6 ตัวอักษร'

for code, values in translations.items():
    locale_path = APP / 'assets' / 'l10n' / f'{code}.json'
    data = json.loads(locale_path.read_text(encoding='utf-8'))
    data.update(values)
    locale_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

print('Applied typed auth failures and localized auth/security UI.')
