import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../domain/models/saved_account.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/account_history_repository.dart';
import '../cubit/auth_cubit.dart' as auth_cubit;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool showForm = false;
  List<SavedAccount> savedAccounts = const <SavedAccount>[];

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    final repository = context.read<AccountHistoryRepository>();
    final accounts = await repository.loadAccounts();
    if (!mounted) return;
    setState(() => savedAccounts = accounts);
  }

  Future<void> _saveAccount(UserModel user) async {
    final repository = context.read<AccountHistoryRepository>();
    final accounts = await repository.saveAccount(user);
    if (!mounted) return;
    setState(() => savedAccounts = accounts);
  }

  Future<void> _removeAccount(int index) async {
    final repository = context.read<AccountHistoryRepository>();
    final userId = savedAccounts[index].userId;
    final accounts = await repository.removeAccount(userId);
    if (!mounted) return;
    setState(() => savedAccounts = accounts);
  }

  Future<void> login() async {
    if (isLoading) return;
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("请输入邮箱和密码")));
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ 使用别名调用
      final authProvider = context.read<auth_cubit.AuthCubit>();
      await authProvider.login(email, password);

      // 登录完成后同步 Node 用户，并加载当前账号 interests。
      await authProvider.loadUser();

      final user = authProvider.user;
      if (user != null) {
        await _saveAccount(user);
      }

      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
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
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _selectAccount(SavedAccount account) {
    emailController.text = account.email;
    setState(() => showForm = true);
  }

  void _switchToOtherAccount() {
    emailController.clear();
    passwordController.clear();
    setState(() => showForm = true);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (savedAccounts.isNotEmpty && !showForm) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("登录"),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forum, size: 60, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  "选择账号登录",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: savedAccounts.length,
                    itemBuilder: (context, index) {
                      final account = savedAccounts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: account.avatarUrl.isNotEmpty
                              ? NetworkImage(account.avatarUrl)
                              : null,
                          child: account.avatarUrl.isEmpty
                              ? Text(
                                  account.username.isEmpty
                                      ? 'U'
                                      : account.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          account.username,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          account.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () => _removeAccount(index),
                        ),
                        onTap: () => _selectAccount(account),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _switchToOtherAccount,
                  child: const Text("使用其他账号登录"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("登录"), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.forum, size: 90, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "论坛社区",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "邮箱",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "密码",
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => login(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    context.push(AppRoutes.forgotPassword);
                  },
                  child: const Text(
                    '忘记密码？',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("登录", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.push(AppRoutes.register);
                },
                child: const Text("没有账号？立即注册"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
