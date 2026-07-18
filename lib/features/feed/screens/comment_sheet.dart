import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentSheet extends StatefulWidget {
  final String postId;
  final ScrollController scrollController;

  const CommentSheet({
    super.key,
    required this.postId,
    required this.scrollController,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  String? replyTo;
  String? replyUser;

  Future<void> sendComment() async {
    if (controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': controller.text.trim(),
      'uid': user?.uid ?? '',
      'user': user?.email ?? 'Guest',
      'timestamp': FieldValue.serverTimestamp(),
    });

    controller.clear();
  }

  Future<void> sendReply(String commentId) async {
    if (controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .add({
      'text': controller.text.trim(),
      'uid': user?.uid ?? '',
      'user': user?.email ?? 'Guest',
      'replyTo': replyUser ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    controller.clear();

    setState(() {
      replyTo = null;
      replyUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),

      child: Column(
        children: [
          /// 顶部拖动条
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const Text(
            "评论",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const Divider(),

          /// ===== 评论列表 =====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(data['user'] ?? ''),
                          subtitle: Text(data['text'] ?? ''),
                          trailing: TextButton(
                            child: const Text("回复"),
                            onPressed: () {
                              setState(() {
                                replyTo = doc.id;
                                replyUser = data['user'];
                              });
                            },
                          ),
                        ),

                        /// replies
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('posts')
                              .doc(widget.postId)
                              .collection('comments')
                              .doc(doc.id)
                              .collection('replies')
                              .orderBy('timestamp')
                              .snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData) return const SizedBox();

                            return Padding(
                              padding: const EdgeInsets.only(left: 40),
                              child: Column(
                                children: snap.data!.docs.map((r) {
                                  final d = r.data() as Map<String, dynamic>;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      "${d['user']}：${d['text']}",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          /// ===== 输入框 =====
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: replyUser != null
                          ? "回复 @$replyUser"
                          : "写评论...",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (replyTo == null) {
                      sendComment();
                    } else {
                      sendReply(replyTo!);
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}