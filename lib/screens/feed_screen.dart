import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'post_detail_screen.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatelessWidget {
  final String category;

  const FeedScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreatePostScreen(
                    category: category,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('category', isEqualTo: category)
            .orderBy('timestamp', descending: true)
            .limit(20)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("暂无帖子"),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            cacheExtent: 1000,
            itemCount: docs.length,

            itemBuilder: (context, index) {
              final doc = docs[index];

              final data =
                  doc.data() as Map<String, dynamic>;

              final images =
                  List<String>.from(data['images'] ?? []);

              final likes =
                  List<String>.from(data['likes'] ?? []);

              final likeCount = likes.length;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(
                          id: doc.id,
                          data: data,
                        ),
                      ),
                    );
                  },

                  child: Padding(
                    padding: const EdgeInsets.all(12),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        if (images.isNotEmpty)
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),

                            child: CachedNetworkImage(
                              imageUrl: images.first,

                              width: 90,
                              height: 90,

                              fit: BoxFit.cover,

                              placeholder:
                                  (context, url) =>
                                      Container(
                                width: 90,
                                height: 90,
                                alignment:
                                    Alignment.center,
                                child:
                                    const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),

                              errorWidget:
                                  (context, url, error) =>
                                      Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                ),
                              ),
                            ),
                          ),

                        if (images.isNotEmpty)
                          const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              Text(
                                data['title'] ?? '',
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                data['user'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                data['content'] ?? '',
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 18,
                                  ),

                                  const SizedBox(
                                      width: 4),

                                  Text(
                                    likeCount.toString(),
                                  ),

                                  const Spacer(),

                                  if (images.isNotEmpty)
                                    Text(
                                      "${images.length} 图",
                                      style: TextStyle(
                                        color:
                                            Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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