import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart' as authProv;
import '../providers/chat_provider.dart' as chatProv;
import '../../profile/screens/user_profile_screen.dart';
import '../widgets/message_bubble.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/chat_input_bar.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  final _picker = ImagePicker();
  bool _isUploading = false;
  bool _isActionLocked = false;
  Map<String, dynamic>? _otherUserData;
  String? _currentUserId;
  String? _otherUid;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadOtherUserData();
    _clearUnread();
  }

  // ============================================================
  // 数据加载
  // ============================================================

  void _loadCurrentUser() {
    final authProvider = context.read<authProv.AuthProvider>();
    final user = authProvider.user;
    if (user != null) {
      _currentUserId = user.id;
    }
  }

  Future<void> _loadOtherUserData() async {
    final chatProvider = context.read<chatProv.ChatProvider>();
    final users = await chatProvider.getChatParticipants(widget.chatId);
    if (users.isEmpty) return;

    final otherUid = users.firstWhere(
      (id) => id != _currentUserId,
      orElse: () => '',
    );
    if (otherUid.isEmpty) return;

    _otherUid = otherUid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUid)
        .get();
    if (doc.exists) {
      setState(() => _otherUserData = doc.data());
    }
  }

  Future<void> _clearUnread() async {
    if (_currentUserId == null) return;
    final chatProvider = context.read<chatProv.ChatProvider>();
    await chatProvider.markAsRead(widget.chatId, _currentUserId!);
  }

  // ============================================================
  // 发送消息
  // ============================================================

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<authProv.AuthProvider>();
    final senderId = authProvider.user?.id;
    if (senderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录'), backgroundColor: Colors.red),
      );
      return;
    }

    final chatProvider = context.read<chatProv.ChatProvider>();
    chatProvider.sendMessageWithSender(widget.chatId, senderId, text);
    _messageController.clear();
  }

  void _sendEmoji(String emoji) {
    final authProvider = context.read<authProv.AuthProvider>();
    final senderId = authProvider.user?.id;
    if (senderId == null) return;

    final chatProvider = context.read<chatProv.ChatProvider>();
    chatProvider.sendMessageWithSender(widget.chatId, senderId, emoji);
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
      final authProvider = context.read<authProv.AuthProvider>();
      final chatProvider = context.read<chatProv.ChatProvider>();
      await chatProvider.sendImageMessage(widget.chatId, File(image.path), authProvider);
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

  // ============================================================
  // UI 方法
  // ============================================================

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => EmojiPicker(onEmojiSelected: _sendEmoji),
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

  void _showLockedAction(String message) {
    setState(() => _isActionLocked = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isActionLocked = false);
    });
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          ChatInputBar(
            controller: _messageController,
            onSend: _sendMessage,
            onEmoji: _showEmojiPicker,
            onImage: _pickAndSendImage,
            isLoading: _isUploading,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: GestureDetector(
        onTap: _navigateToProfile,
        child: Text(
          widget.otherUserName,
          style: const TextStyle(color: Colors.black87),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Colors.black87),
          onPressed: _isActionLocked
              ? null
              : () => _showLockedAction('语音通话功能开发中'),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Colors.black87),
          onPressed: _isActionLocked
              ? null
              : () => _showLockedAction('视频通话功能开发中'),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onPressed: _isActionLocked
              ? null
              : () => _showLockedAction('更多功能开发中'),
        ),
      ],
    );
  }

  // ============================================================
  // 消息列表
  // ============================================================

  Widget _buildMessageList() {
    final chatProvider = context.watch<chatProv.ChatProvider>();

    return StreamBuilder<QuerySnapshot>(
      stream: chatProvider.watchMessages(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('加载失败: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('没有消息，开始聊天吧！'),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final msg = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final isMe = msg['senderId'] == _currentUserId;
            final imageUrl = msg['imageUrl'] as String?;
            final content = msg['content'] as String? ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: UserAvatar(
                        imageUrl: _otherUserData?['avatar'],
                        displayName: widget.otherUserName,
                        radius: 20,
                        onTap: _navigateToProfile,
                      ),
                    ),
                  MessageBubble(
                    isMe: isMe,
                    content: content,
                    imageUrl: imageUrl,
                    onImageTap: () {
                      if (imageUrl != null) {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: CachedNetworkImage(imageUrl: imageUrl),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}