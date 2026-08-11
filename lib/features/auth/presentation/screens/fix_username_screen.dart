// lib/screens/fix_username_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FixUsernameScreen extends StatelessWidget {
  const FixUsernameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修复用户数据')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final hasUsername = data['username'] != null && 
                                  data['username'].toString().isNotEmpty;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(data['email'] ?? '未知'),
                  subtitle: Text(hasUsername 
                    ? '用户名: ${data['username']}' 
                    : '❌ 缺少用户名'),
                  trailing: hasUsername
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(
                        child: const Text('修复'),
                        onPressed: () async {
                          // 用邮箱前缀作为默认用户名
                          final email = data['email'] ?? '';
                          final username = email.split('@')[0];
                          
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(doc.id)
                              .set({
                            'username': username,
                          }, SetOptions(merge: true));
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('已将用户名设置为: $username')),
                            );
                          }
                        },
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}