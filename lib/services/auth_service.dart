import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin/admin_dashboard.dart';
import '../screens/home_screen.dart';

class AuthService {
  static Future<void> loginAndRoute(
      BuildContext context,
      String email,
      String password) async {

    final cred = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
          email: email,
          password: password,
        );

    final uid = cred.user!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) {
      await FirebaseAuth.instance.signOut();
      return;
    }

    final data = doc.data()!;

    // 🚨 banned 用户直接踢掉
    if (data['banned'] == true) {
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("账号已被封禁")),
      );
      return;
    }

    final role = data['role'] ?? 'user';

    // 🚀 分流
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}