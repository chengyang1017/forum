// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  Future<String> getOrCreateChat(String otherUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('未登录');

    final existing = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUser.uid)
        .get();

    for (var doc in existing.docs) {
      final users = List<String>.from(doc.data()['users'] ?? []);
      if (users.contains(otherUid)) return doc.id;
    }

    final newChat = await FirebaseFirestore.instance.collection('chats').add({
      'users': [currentUser.uid, otherUid],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
    });

    return newChat.id;
  }

  Future<void> sendMessage(String chatId, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    final users = List<String>.from(chatDoc.data()?['users'] ?? []);
    final otherUid = users.firstWhere((id) => id != user.uid, orElse: () => '');

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': user.uid,
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final updates = <String, dynamic>{
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (otherUid.isNotEmpty) {
      updates['unreadCount.$otherUid'] = FieldValue.increment(1);
    }

    await FirebaseFirestore.instance.collection('chats').doc(chatId).update(updates);
  }
}