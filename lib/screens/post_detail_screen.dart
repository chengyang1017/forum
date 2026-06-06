import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import 'comment_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;

  const PostDetailScreen({
    super.key,
    required this.id,
    required this.data,
  });

  @override
  State<PostDetailScreen> createState() =>
      _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late bool isLiked;
  late List<String> likes;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    likes = List<String>.from(widget.data['likes'] ?? []);

    isLiked = uid != null && likes.contains(uid);
  }

  Future<void> toggleLike() async {
    final uid =
        FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likes.add(uid);
      } else {
        likes.remove(uid);
      }
    });

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.id)
        .update({
      'likes': isLiked
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  void sharePost() {
    Share.share(
      "${widget.data['title']}\n\n${widget.data['content']}",
    );
  }

  Future<void> deletePost() async {
    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid != widget.data['uid']) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.id)
        .delete();

    if (mounted) Navigator.pop(context);
  }

  void openComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentScreen(
          postId: widget.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final images =
        List<String>.from(data['images'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("帖子详情"),
        actions: [
          if (FirebaseAuth.instance.currentUser?.uid ==
              data['uid'])
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: deletePost,
            ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ================= 图片区域 =================
                  if (images.isNotEmpty)
                    SizedBox(
                      height: 320,
                      child: Stack(
                        children: [
                          PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (i) {
                              setState(() {
                                currentIndex = i;
                              });
                            },
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: InteractiveViewer(
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              images[index],
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: CachedNetworkImage(
                                  imageUrl: images[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,

                                  placeholder:
                                      (_, __) => const Center(
                                    child:
                                        CircularProgressIndicator(),
                                  ),

                                  errorWidget:
                                      (_, __, ___) =>
                                          const Icon(
                                    Icons.broken_image,
                                  ),
                                ),
                              );
                            },
                          ),

                          // 图片指示器
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${currentIndex + 1}/${images.length}",
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ================= 内容 =================
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          data['user'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          data['content'] ?? '',
                          style:
                              const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),

                            const SizedBox(width: 5),

                            Text("${likes.length}"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================= 底部操作栏 =================
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey),
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: sharePost,
                  ),

                  IconButton(
                    icon: Icon(
                      isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: toggleLike,
                  ),

                  IconButton(
                    icon: const Icon(Icons.comment),
                    onPressed: openComments,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}