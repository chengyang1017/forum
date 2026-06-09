// lib/screens/security_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final questionController = TextEditingController();
  final answerController = TextEditingController();
  
  String? savedQuestion;
  bool isLoading = true;

  final List<String> presetQuestions = [
    '你的小学名字是什么？',
    '你第一只宠物叫什么名字？',
    '你母亲的名字是什么？',
    '你父亲的名字是什么？',
    '你出生的城市是哪里？',
    '你最喜欢的老师叫什么？',
    '你最喜欢的书是什么？',
  ];

  @override
  void initState() {
    super.initState();
    loadSecurityData();
  }

  Future<void> loadSecurityData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    if (doc.exists) {
      setState(() {
        savedQuestion = doc.data()?['securityQuestion'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveSecurityQuestion() async {
    final question = questionController.text.trim();
    final answer = answerController.text.trim();

    if (question.isEmpty || answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('问题和答案不能为空'), backgroundColor: Colors.red),
      );
      return;
    }

    if (answer.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('答案至少2个字符'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'securityQuestion': question,
        'securityAnswer': answer,
      }, SetOptions(merge: true));
      
      setState(() => savedQuestion = question);
      questionController.clear();
      answerController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密保已设置'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('密保设置'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前密保状态
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: savedQuestion != null ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    savedQuestion != null ? Icons.shield : Icons.warning_amber,
                    color: savedQuestion != null ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      savedQuestion != null ? '密保已设置' : '未设置密保',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: savedQuestion != null ? Colors.green.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (savedQuestion != null) ...[
              const SizedBox(height: 16),
              Text('当前问题：$savedQuestion',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],

            const SizedBox(height: 24),
            const Text('设置密保问题', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('用于找回密码，请牢记答案', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),

            // 预设问题
            Text('常用问题', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presetQuestions.map((q) => GestureDetector(
                onTap: () => questionController.text = q,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: questionController.text == q ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: questionController.text == q ? Colors.blue : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(q, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // 自定义问题
            TextField(
              controller: questionController,
              decoration: const InputDecoration(
                labelText: '密保问题',
                hintText: '输入或选择你的密保问题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // 答案
            TextField(
              controller: answerController,
              decoration: const InputDecoration(
                labelText: '答案',
                hintText: '输入你的答案',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveSecurityQuestion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('保存', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}