import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreatePostScreen extends StatefulWidget {
  final String category;

  const CreatePostScreen({super.key, required this.category});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final title = TextEditingController();
  final content = TextEditingController();

  List<File> images = [];

  bool isUploading = false;

  double progress = 0;

  Future pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isEmpty) return;

    setState(() {
      images.addAll(picked.map((e) => File(e.path)));
      if (images.length > 9) {
        images = images.sublist(0, 9);
      }
    });
  }

  Future<List<String>> uploadImages(String postId) async {
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      final file = images[i];

      final ref = FirebaseStorage.instance
          .ref()
          .child('posts/$postId/$i.jpg');

      final uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((event) {
        final fileProgress =
            event.bytesTransferred / event.totalBytes;

        setState(() {
          progress = (i + fileProgress) / images.length;
        });
      });

      await uploadTask;

      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future uploadPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (title.text.isEmpty || content.text.isEmpty) return;

    setState(() {
      isUploading = true;
      progress = 0;
    });

    try {
      // 获取用户信息
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final username = userData?['username'] ?? '匿名用户';
      final nickname = userData?['nickname'] ?? '';

      final doc = FirebaseFirestore.instance.collection('posts').doc();

      final imageUrls = await uploadImages(doc.id);

      await doc.set({
        'title': title.text,
        'content': content.text,
        'category': widget.category,
        'uid': user.uid,
        'username': username,
        'nickname': nickname,
        'images': imageUrls,
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint("UPLOAD ERROR: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("上传失败: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
          progress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("发帖"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: "标题",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: content,
                maxLines: null,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: "内容",
                  hintText: "输入帖子内容...",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: isUploading ? null : pickImages,
                icon: const Icon(Icons.image),
                label: Text(images.isEmpty ? "选择图片" : "添加更多图片"),
              ),
              if (images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "已选 ${images.length}/9 张",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              const SizedBox(height: 10),
              if (isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 6),
                    Text(
                      "上传中 ${(progress * 100).toStringAsFixed(0)}%",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              if (images.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: images.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.file(images[i], fit: BoxFit.cover, width: double.infinity),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => images.removeAt(i));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isUploading ? null : uploadPost,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isUploading ? "上传中..." : "发布",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}