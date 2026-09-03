import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
// ✅ 别名导入
import '../cubit/auth_cubit.dart' as auth_cubit;
import '../utils/auth_failure_message.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Username uniqueness is checked by AuthCubit against PostgreSQL.
      final authCubit = context.read<auth_cubit.AuthCubit>();
      await authCubit.register(email, password, username);

      // 注册完成后建立/同步 Node 用户，并初始化 interests。
      await authCubit.loadUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.get('registrationSuccess'),
          ),
          backgroundColor: Colors.green,
        ),
      );

      context.go(AppRoutes.home);
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authFailureMessage(
                error,
                l10n,
                fallbackKey: 'authRegisterFailed',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.register), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.person_add, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                l10n.get('createNewAccount'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: l10n.get('usernameUniqueId'),
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                  hintText: l10n.get('usernameSetupHint'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.get('enterUsername');
                  }
                  if (value.trim().length < 2) {
                    return l10n.get('usernameMinLength');
                  }
                  if (value.trim().length > 20) {
                    return l10n.get('usernameMaxLength');
                  }
                  if (!RegExp(
                    r'^[a-zA-Z0-9_\u4e00-\u9fa5]+$',
                  ).hasMatch(value.trim())) {
                    return l10n.get('usernameAllowedCharacters');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.get('enterEmail');
                  }
                  if (!value.contains('@')) {
                    return l10n.get('authInvalidEmail');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.get('enterPassword');
                  }
                  if (value.length < 6) {
                    return l10n.get('passwordMinLength');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.get('confirmPassword'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.get('enterPasswordAgain');
                  }
                  if (value != _passwordController.text) {
                    return l10n.get('passwordsDoNotMatch');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.register, style: const TextStyle(fontSize: 18)),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(l10n.get('alreadyHaveAccountSignIn')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
