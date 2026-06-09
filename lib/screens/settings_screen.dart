// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'security_settings_screen.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    // 显示确认对话框
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认登出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('登出'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          // 清除所有路由并跳转到登录页
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('登出失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildItem(
            context,
            icon: Icons.shield,
            title: '密保设置',
            subtitle: '设置密保问题用于找回密码',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
              );
            },
          ),
          _buildItem(
            context,
            icon: Icons.lock,
            title: '修改密码',
            subtitle: '修改你的登录密码',
            onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
  );
},
          ),
          _buildItem(
            context,
            icon: Icons.block,
            title: '拉黑名单',
            subtitle: '管理已拉黑的用户',
            onTap: () {
              // 后续添加
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('功能开发中...')),
              );
            },
          ),
          const Divider(height: 32, thickness: 1),
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text(
        '登出账号',
        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
      ),
      subtitle: Text(
        '退出当前登录账号',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: () => _logout(context),
    );
  }
}