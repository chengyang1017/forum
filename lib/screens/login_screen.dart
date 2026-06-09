// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'register_screen.dart';
import 'main_navigation_screen.dart';
import 'forgot_password_screen.dart';

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
  List<Map<String, String>> savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getString('saved_accounts');
    if (accountsJson != null) {
      final list = jsonDecode(accountsJson) as List;
      savedAccounts = list.map((e) => Map<String, String>.from(e)).toList();
      setState(() {});
    }
  }

  Future<void> _saveAccount(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    final newAccount = <String, String>{
  'email': user.email ?? '',
  'username': (data?['username'] ?? user.email?.split('@')[0] ?? '用户').toString(),
  'avatar': (data?['avatar'] ?? '').toString(),
  'uid': user.uid,
};

    // 去重：如果已存在则移除旧的
    savedAccounts.removeWhere((a) => a['uid'] == user.uid);
    // 加到最前面
    savedAccounts.insert(0, newAccount);
    // 最多保存5个
    if (savedAccounts.length > 5) savedAccounts = savedAccounts.sublist(0, 5);

    await prefs.setString('saved_accounts', jsonEncode(savedAccounts));
    setState(() {});
  }

  Future<void> _removeAccount(int index) async {
    final prefs = await SharedPreferences.getInstance();
    savedAccounts.removeAt(index);
    await prefs.setString('saved_accounts', jsonEncode(savedAccounts));
    setState(() {});
  }

  Future<void> login() async {
    if (isLoading) return;
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("请输入邮箱和密码")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        await _saveAccount(user);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'email': email,
          'uid': user.uid,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "登录失败";
      switch (e.code) {
        case "user-not-found": msg = "账号不存在"; break;
        case "wrong-password": msg = "密码错误"; break;
        case "invalid-email": msg = "邮箱格式错误"; break;
        case "invalid-credential": msg = "账号或密码错误"; break;
        case "too-many-requests": msg = "登录尝试次数过多，请稍后再试"; break;
        default: msg = "登录失败：${e.message}";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400),
        );
      }
    } catch (e) {
      debugPrint('登录错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发生错误：$e'), backgroundColor: Colors.red.shade400),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _selectAccount(Map<String, String> account) {
    emailController.text = account['email'] ?? '';
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
                const Text("选择账号登录", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                          backgroundImage: account['avatar'] != null && account['avatar']!.isNotEmpty
                              ? NetworkImage(account['avatar']!)
                              : null,
                          child: account['avatar'] == null || account['avatar']!.isEmpty
                              ? Text(
                                  (account['username'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                )
                              : null,
                        ),
                        title: Text(account['username'] ?? '用户',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(account['email'] ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
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
      appBar: AppBar(
        title: const Text("登录"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.forum, size: 90, color: Colors.blue),
              const SizedBox(height: 20),
              const Text("论坛社区", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "邮箱",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "密码",
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (_) => login(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                  },
                  child: const Text('忘记密码？', style: TextStyle(fontSize: 13, color: Colors.grey)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("登录", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
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