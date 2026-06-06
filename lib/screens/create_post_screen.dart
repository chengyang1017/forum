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

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      urls.add(url);
    }

    return urls;
  }

  Future uploadPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (title.text.isEmpty || content.text.isEmpty) return;

    setState(() => isUploading = true);

    try {
      final doc = FirebaseFirestore.instance.collection('posts').doc();

      final imageUrls = await uploadImages(doc.id);

      await doc.set({
        'title': title.text,
        'content': content.text,
        'category': widget.category,
        'uid': user.uid,
        'user': user.email,
        'images': imageUrls,
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      print("UPLOAD ERROR: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("发帖")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: "标题")),
            TextField(controller: content, decoration: const InputDecoration(labelText: "内容")),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: pickImages,
              child: const Text("选择图片"),
            ),

            Text("已选 ${images.length} 张"),

            Expanded(
              child: GridView.builder(
                itemCount: images.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemBuilder: (_, i) => Image.file(images[i]),
              ),
            ),

            ElevatedButton(
              onPressed: isUploading ? null : uploadPost,
              child: Text(isUploading ? "上传中..." : "发布"),
            )
          ],
        ),
      ),
    );
  }
}