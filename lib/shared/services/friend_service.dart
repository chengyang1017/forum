import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  String get _uid => auth.currentUser!.uid;

  // =========================
  // 1️⃣ 发送好友申请
  // =========================
  Future<void> sendRequest(String toUid) async {
    final id = "${_uid}_$toUid";

    await db.collection('friend_requests').doc(id).set({
      "from": _uid,
      "to": toUid,
      "status": "pending",
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  // =========================
  // 2️⃣ 接受好友申请
  // =========================
  Future<void> acceptRequest(String fromUid) async {
    final id = "${fromUid}_$_uid";

    // 更新申请状态
    await db.collection('friend_requests').doc(id).update({
      "status": "accepted",
    });

    // 写入好友关系（双向）
    await db.collection('friends').doc(_uid).set({
      fromUid: true,
    }, SetOptions(merge: true));

    await db.collection('friends').doc(fromUid).set({
      _uid: true,
    }, SetOptions(merge: true));
  }

  // =========================
  // 3️⃣ 拒绝申请
  // =========================
  Future<void> rejectRequest(String fromUid) async {
    final id = "${fromUid}_$_uid";

    await db.collection('friend_requests').doc(id).update({
      "status": "rejected",
    });
  }

  // =========================
  // 4️⃣ 获取好友列表
  // =========================
  Stream<List<String>> myFriends() {
    return db.collection('friends').doc(_uid).snapshots().map((doc) {
      if (!doc.exists) return [];

      final data = doc.data()!;
      return data.keys.toList(); // 所有好友UID
    });
  }

  // =========================
  // 5️⃣ 查看是否好友
  // =========================
  Future<bool> isFriend(String otherUid) async {
    final doc = await db.collection('friends').doc(_uid).get();

    return doc.data()?[otherUid] == true;
  }
}