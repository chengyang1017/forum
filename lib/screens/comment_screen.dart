import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({super.key, required this.postId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  String? replyingToCommentId;
  String? replyingToUser;

  /// ===== 发主评论 =====
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

  /// ===== 发回复 =====
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
      'replyTo': replyingToUser ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      replyingToCommentId = null;
      replyingToUser = null;
    });

    controller.clear();
  }

  Widget buildReplies(String commentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${data['user']}：${data['text']}",
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("评论")),

      body: Column(
        children: [
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

                if (docs.isEmpty) {
                  return const Center(child: Text("暂无评论"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final commentId = doc.id;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// ===== 主评论 =====
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(data['user'] ?? ''),
                          subtitle: Text(data['text'] ?? ''),
                          trailing: TextButton(
                            child: const Text("回复"),
                            onPressed: () {
                              setState(() {
                                replyingToCommentId = commentId;
                                replyingToUser = data['user'];
                              });
                            },
                          ),
                        ),

                        /// ===== 回复列表 =====
                        buildReplies(commentId),
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
            child: Column(
              children: [
                if (replyingToUser != null)
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      "回复 @$replyingToUser",
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: "写评论...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (replyingToCommentId == null) {
                          sendComment();
                        } else {
                          sendReply(replyingToCommentId!);
                        }
                      },
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}