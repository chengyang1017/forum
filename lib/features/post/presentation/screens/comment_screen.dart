import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({super.key, required this.postId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final user = FirebaseAuth.instance.currentUser;
  final _picker = ImagePicker();
  bool _isUploading = false;

  String? replyingToCommentId;
  String? replyingToUser;

  final List<String> _emojis = [
    '😀', '😂', '🤣', '😍', '🥰', '😘', '😜', '😎',
    '🤩', '🥳', '😢', '😡', '👍', '👎', '🙏', '💪',
    '🔥', '❤️', '💔', '🎉', '🌟', '💯', '✅', '❌',
  ];

  Future<void> sendComment() async {
    final text = controller.text.trim();
    if (text.isEmpty && !_isUploading) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': text,
      'uid': user?.uid ?? '',
      'user': user?.email?.split('@').first ?? 'Guest',
      'timestamp': FieldValue.serverTimestamp(),
    });

    controller.clear();
    focusNode.unfocus();
    setState(() {
      replyingToCommentId = null;
      replyingToUser = null;
    });
  }

  Future<void> sendImageComment() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('comment_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'text': '',
        'uid': user?.uid ?? '',
        'user': user?.email?.split('@').first ?? 'Guest',
        'imageUrl': url,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> sendReply(String commentId) async {
    final text = controller.text.trim();
    if (text.isEmpty && !_isUploading) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .add({
      'text': text,
      'uid': user?.uid ?? '',
      'user': user?.email?.split('@').first ?? 'Guest',
      'replyTo': replyingToUser ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });

    controller.clear();
    focusNode.unfocus();
    setState(() {
      replyingToCommentId = null;
      replyingToUser = null;
    });
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((emoji) => GestureDetector(
                onTap: () {
                  controller.text += emoji;
                  Navigator.pop(context);
                },
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
        if (docs.isEmpty) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.only(left: 46, top: 4, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final imageUrl = data['imageUrl'] as String?;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.blueGrey.shade100,
                      child: Text(
                        (data['user'] ?? 'G').toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : RichText(
                              text: TextSpan(
                                style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: "${data['user']} ",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (data['replyTo'] != null && data['replyTo'].toString().isNotEmpty) ...[
                                    TextSpan(text: '回复 ', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    TextSpan(
                                      text: "@${data['replyTo']} ",
                                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  TextSpan(text: data['text'] ?? ''),
                                ],
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.unfocus(),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text("暂无评论，快来抢沙发吧~", style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final commentId = doc.id;
                    final userName = data['user'] ?? 'Guest';
                    final imageUrl = data['imageUrl'] as String?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  userName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                                    ),
                                    const SizedBox(height: 2),
                                    if (imageUrl != null && imageUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Text(
                                        data['text'] ?? '',
                                        style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.3),
                                      ),
                                  ],
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text("回复", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                onPressed: () {
                                  setState(() {
                                    replyingToCommentId = commentId;
                                    replyingToUser = userName;
                                  });
                                  focusNode.requestFocus();
                                },
                              ),
                            ],
                          ),
                          buildReplies(commentId),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (replyingToUser != null)
                    Container(
                      padding: const EdgeInsets.only(left: 4, bottom: 6, right: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13),
                              children: [
                                TextSpan(text: "回复 ", style: TextStyle(color: Colors.grey.shade600)),
                                TextSpan(text: "@$replyingToUser", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                replyingToCommentId = null;
                                replyingToUser = null;
                              });
                            },
                            child: Icon(Icons.cancel, size: 18, color: Colors.grey.shade400),
                          )
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined, size: 26),
                        color: Colors.grey[600],
                        onPressed: _showEmojiPicker,
                      ),
                      IconButton(
                        icon: const Icon(Icons.image_outlined, size: 26),
                        color: Colors.grey[600],
                        onPressed: _isUploading ? null : sendImageComment,
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          maxLines: 4,
                          minLines: 1,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: replyingToUser != null ? "回复内容..." : "说点什么吧...",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isUploading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.send_rounded, size: 26),
                              color: Colors.blue,
                              onPressed: () {
                                if (replyingToCommentId == null) {
                                  sendComment();
                                } else {
                                  sendReply(replyingToCommentId!);
                                }
                              },
                            ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}