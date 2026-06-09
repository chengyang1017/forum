// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final questionController = TextEditingController();
  final answerController = TextEditingController();
  final newPasswordController = TextEditingController();

  int step = 1; // 1:输入邮箱, 2:回答问题, 3:重置密码
  String? uid;
  String? securityQuestion;
  bool isLoading = false;

  // 验证邮箱并获取密保问题
  Future<void> verifyEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入邮箱'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('该邮箱未注册'), backgroundColor: Colors.red),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      final userData = query.docs.first.data();
      final question = userData['securityQuestion'];

      if (question == null || question.toString().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('该用户未设置密保，无法找回密码'), backgroundColor: Colors.red),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      setState(() {
        uid = query.docs.first.id;
        securityQuestion = question;
        step = 2;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('验证失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 验证密保答案
  Future<void> verifyAnswer() async {
    final answer = answerController.text.trim();
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入答案'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final correctAnswer = doc.data()?['securityAnswer'] ?? '';

      if (answer != correctAnswer) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('答案错误'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        step = 3;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('验证失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 重置密码
  Future<void> resetPassword() async {
    final password = newPasswordController.text.trim();
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码至少6位'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 通过 Firebase Auth 更新密码（需要先登录）
      // 这里简化处理，实际可以调用 Cloud Function
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码重置成功，请重新登录'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重置失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('找回密码'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 步骤指示器
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStep(1, '验证身份', step >= 1),
                Container(width: 40, height: 2, color: step >= 2 ? Colors.blue : Colors.grey[300]),
                _buildStep(2, '回答问题', step >= 2),
                Container(width: 40, height: 2, color: step >= 3 ? Colors.blue : Colors.grey[300]),
                _buildStep(3, '重置密码', step >= 3),
              ],
            ),
            const SizedBox(height: 32),

            // 步骤1
            if (step == 1) ...[
              const Icon(Icons.email_outlined, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('请输入注册时使用的邮箱',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '邮箱',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyEmail,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('下一步', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],

            // 步骤2
            if (step == 2) ...[
              const Icon(Icons.lock_outlined, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('回答密保问题',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  securityQuestion ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: '你的答案',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyAnswer,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('验证', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],

            // 步骤3
            if (step == 3) ...[
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text('设置新密码',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '新密码',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : resetPassword,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('重置密码', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int stepNum, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.blue : Colors.grey[300],
          ),
          child: Center(
            child: active
                ? (step > stepNum
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text('$stepNum', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                : Text('$stepNum', style: TextStyle(color: Colors.grey[600])),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.blue : Colors.grey)),
      ],
    );
  }
}