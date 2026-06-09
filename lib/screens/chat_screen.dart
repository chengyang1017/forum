// lib/screens/chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/chat_service.dart';
import 'user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  final _picker = ImagePicker();
  bool _isUploading = false;
  bool _isActionLocked = false;
  Map<String, dynamic>? _otherUserData;

  final List<String> _emojis = [
    '😀', '😂', '🤣', '😍', '🥰', '😘', '😜', '😎',
    '🤩', '🥳', '😢', '😡', '👍', '👎', '🙏', '💪',
    '🔥', '❤️', '💔', '🎉', '🌟', '💯', '✅', '❌',
  ];

  @override
  void initState() {
    super.initState();
    _loadOtherUserData();
    _clearUnread();
  }

  Future<void> _loadOtherUserData() async {
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    final users = List<String>.from(chatDoc.data()?['users'] ?? []);
    final otherUid = users.firstWhere((id) => id != _currentUser?.uid, orElse: () => '');
    if (otherUid.isNotEmpty) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
      if (doc.exists) setState(() => _otherUserData = doc.data());
    }
  }

  Future<void> _clearUnread() async {
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'unreadCount.${_currentUser?.uid}': 0,
    });
  }

  String? get _otherUid {
    if (_otherUserData == null) return null;
    return _otherUserData!['uid'];
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _chatService.sendMessage(widget.chatId, text);
    _messageController.clear();
  }

  void _sendEmoji(String emoji) {
    _chatService.sendMessage(widget.chatId, emoji);
  }

  Future<void> _pickAndSendImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': _currentUser?.uid,
        'content': '',
        'imageUrl': url,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': '[图片]',
        'updatedAt': FieldValue.serverTimestamp(),
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
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((emoji) => GestureDetector(
                onTap: () {
                  _sendEmoji(emoji);
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

  void _navigateToProfile() {
    if (_otherUid != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(uid: _otherUid!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: GestureDetector(
          onTap: _navigateToProfile,
          child: Text(widget.otherUserName, style: const TextStyle(color: Colors.black87)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.black87),
            onPressed: _isActionLocked ? null : () {
              setState(() => _isActionLocked = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('语音通话功能开发中'), duration: Duration(seconds: 1)),
              );
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) setState(() => _isActionLocked = false);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black87),
            onPressed: _isActionLocked ? null : () {
              setState(() => _isActionLocked = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('视频通话功能开发中'), duration: Duration(seconds: 1)),
              );
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) setState(() => _isActionLocked = false);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: _isActionLocked ? null : () {
              setState(() => _isActionLocked = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('更多功能开发中'), duration: Duration(seconds: 1)),
              );
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) setState(() => _isActionLocked = false);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final msg = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _currentUser?.uid;
                    final imageUrl = msg['imageUrl'] as String?;
                    final content = msg['content'] as String? ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe)
                            GestureDetector(
                              onTap: _navigateToProfile,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.blue.shade50,
                                  backgroundImage: _otherUserData != null &&
                                          _otherUserData!['avatar'] != null &&
                                          _otherUserData!['avatar'].toString().isNotEmpty
                                      ? CachedNetworkImageProvider(_otherUserData!['avatar'])
                                      : null,
                                  child: _otherUserData == null ||
                                          _otherUserData!['avatar'] == null ||
                                          _otherUserData!['avatar'].toString().isEmpty
                                      ? Text(
                                          widget.otherUserName[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: CachedNetworkImage(imageUrl: imageUrl),
                                  ),
                                );
                              },
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                                ),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const SizedBox(
                                      width: 150,
                                      height: 150,
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue.shade100 : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                content,
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined, size: 26),
                      color: Colors.grey[600],
                      onPressed: _showEmojiPicker,
                    ),
                    IconButton(
                      icon: const Icon(Icons.image_outlined, size: 26),
                      color: Colors.grey[600],
                      onPressed: _isUploading ? null : _pickAndSendImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: '输入消息...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isUploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send_rounded, size: 26),
                            color: Colors.blue,
                            onPressed: _sendMessage,
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}