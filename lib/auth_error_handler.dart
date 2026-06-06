import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  static String handle(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return '该账号已存在';
        case 'invalid-email':
          return '邮箱格式不正确';
        case 'weak-password':
          return '密码至少6位';
        case 'user-not-found':
          return '该账号不存在';
        case 'wrong-password':
          return '密码错误';
        case 'too-many-requests':
          return '尝试次数过多，请稍后再试';
        default:
          return '操作失败，请重试';
      }
    }
    return '未知错误';
  }
}