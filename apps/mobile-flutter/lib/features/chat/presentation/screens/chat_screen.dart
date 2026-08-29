import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart' as auth_prov;
import '../providers/chat_provider.dart' as chat_prov;
import '../widgets/message_bubble.dart';
import '../widgets/emoji_picker.dart';
import '../widgets/chat_input_bar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/services/live_draft_service.dart';
import '../../domain/models/live_draft.dart';
import '../../../auth/domain/models/user_model.dart';

class ChatRouteScreen extends StatefulWidget {
  final String chatId;
  final String? initialOtherUserName;

  const ChatRouteScreen({
    super.key,
    required this.chatId,
    this.initialOtherUserName,
  });

  @override
  State<ChatRouteScreen> createState() => _ChatRouteScreenState();
}

class _ChatRouteScreenState extends State<ChatRouteScreen> {
  Future<String>? _otherUserNameFuture;

  @override
  void initState() {
    super.initState();
    _prepareRoute();
  }

  @override
  void didUpdateWidget(covariant ChatRouteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.chatId != widget.chatId ||
        oldWidget.initialOtherUserName != widget.initialOtherUserName) {
      _prepareRoute();
    }
  }

  void _prepareRoute() {
    if (widget.initialOtherUserName != null) {
      _otherUserNameFuture = null;
      return;
    }

    _otherUserNameFuture = _resolveOtherUserName();
  }

  Future<String> _resolveOtherUserName() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      throw StateError('未登录');
    }

    final chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();

    final chatData = chatSnapshot.data();

    if (chatData == null) {
      throw StateError('聊天室不存在');
    }

    final participants = List<String>.from(
      chatData['users'] ?? const <String>[],
    );

    if (!participants.contains(currentUserId)) {
      throw StateError('当前用户不是聊天室成员');
    }

    final otherUserId = participants.firstWhere(
      (userId) => userId != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) {
      throw StateError('找不到聊天对象');
    }

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId)
        .get();

    final userData = userSnapshot.data();

    if (userData == null) {
      return '未知用户';
    }

    final nickname = (userData['nickname'] as String? ?? '').trim();
    final username = (userData['username'] as String? ?? '').trim();
    final email = (userData['email'] as String? ?? '').trim();

    if (nickname.isNotEmpty) {
      return nickname;
    }

    if (username.isNotEmpty) {
      return username;
    }

    if (email.isNotEmpty) {
      return email;
    }

    return '未知用户';
  }

  void _retry() {
    setState(() {
      _otherUserNameFuture = _resolveOtherUserName();
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialOtherUserName = widget.initialOtherUserName;

    if (initialOtherUserName != null) {
      return ChatScreen(
        chatId: widget.chatId,
        otherUserName: initialOtherUserName,
      );
    }

    final future = _otherUserNameFuture ??= _resolveOtherUserName();

    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: LoadingIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('聊天')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 52),
                    const SizedBox(height: 16),
                    const Text(
                      '聊天加载失败',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ChatScreen(
          chatId: widget.chatId,
          otherUserName: snapshot.data ?? '未知用户',
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  // 先作为可选字段，不影响现有私聊代码。
  final bool isGroupChat;
  final String? groupName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.isGroupChat = false,
    this.groupName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //late final TabController _tabController;

  final _messageController = TextEditingController();
  final _picker = ImagePicker();
  bool _isUploading = false;
  bool _isActionLocked = false;
  final Map<String, UserModel> _participantData = {};
  String? _currentUserId;
  String? _otherUid;

  late final LiveDraftService _liveDraftService;
  Stream<List<LiveDraft>>? _draftsStream;

  bool _shareMyLiveDraft = false;

  String get _chatTitle {
    if (widget.isGroupChat) {
      final name = widget.groupName?.trim() ?? '';

      return name.isNotEmpty ? name : '群聊';
    }

    return widget.otherUserName;
  }

  String _formatMessageTime(dynamic value) {
    if (value is! Timestamp) {
      return '';
    }

    final time = value.toDate().toLocal();
    final now = DateTime.now();

    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    final month = time.month.toString().padLeft(2, '0');

    final day = time.day.toString().padLeft(2, '0');

    final isToday =
        time.year == now.year && time.month == now.month && time.day == now.day;

    if (isToday) {
      return '$hour:$minute';
    }

    if (time.year == now.year) {
      return '$month-$day $hour:$minute';
    }

    return '${time.year}-$month-$day $hour:$minute';
  }

  Future<void> _showMessageActions({
    required String messageId,
    required Map<String, dynamic> message,
  }) async {
    final status = message['status'] as String? ?? 'active';

    if (status == 'deleted') {
      return;
    }
    final currentUserId = _currentUserId;

    if (currentUserId == null) {
      return;
    }

    final senderId = message['senderId'] as String? ?? '';

    final content = message['content'] as String? ?? '';

    final imageUrl = message['imageUrl'] as String?;

    final isMe = senderId == currentUserId;

    final canEdit =
        isMe &&
        content.trim().isNotEmpty &&
        (imageUrl == null || imageUrl.isEmpty);

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('编辑消息'),
                  onTap: () {
                    Navigator.pop(sheetContext, 'edit');
                  },
                ),

              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除消息', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext, 'delete');
                },
              ),
            ],
          ),
        );
      },
    );

    switch (action) {
      case 'edit':
        await _editMessage(messageId: messageId, oldContent: content);
        break;

      case 'delete':
        await _showDeleteMessageOptions(messageId: messageId, isMe: isMe);
        break;
    }
  }

  Future<void> _editMessage({
    required String messageId,
    required String oldContent,
  }) async {
    var editedContent = oldContent;

    final newContent = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('编辑消息'),

          content: TextFormField(
            initialValue: oldContent,
            autofocus: true,
            minLines: 1,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: '输入消息内容',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              editedContent = value;
            },
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('取消'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, editedContent.trim());
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    final currentUserId = _currentUserId;
    final content = newContent?.trim();

    if (currentUserId == null ||
        content == null ||
        content.isEmpty ||
        content == oldContent.trim()) {
      return;
    }

    try {
      await context.read<chat_prov.ChatProvider>().editMessage(
        chatId: widget.chatId,
        messageId: messageId,
        currentUserId: currentUserId,
        newContent: content,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('消息已编辑')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('编辑失败：$error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showDeleteMessageOptions({
    required String messageId,
    required bool isMe,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_remove_outlined),
                title: const Text('仅删除自己'),
                subtitle: const Text('消息只会从你的聊天记录中消失'),
                onTap: () {
                  Navigator.pop(sheetContext, 'deleteForMe');
                },
              ),

              if (isMe)
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.red,
                  ),
                  title: Text(
                    widget.isGroupChat ? '删除所有人' : '双方删除',
                    style: const TextStyle(color: Colors.red),
                  ),
                  subtitle: Text(
                    widget.isGroupChat ? '消息会从所有群成员的聊天中删除' : '消息会从双方聊天中删除',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, 'deleteForEveryone');
                  },
                ),
            ],
          ),
        );
      },
    );

    switch (action) {
      case 'deleteForMe':
        await _deleteMessageForMe(messageId);
        break;

      case 'deleteForEveryone':
        await _confirmDeleteForEveryone(messageId);
        break;
    }
  }

  Future<void> _deleteMessageForMe(String messageId) async {
    final currentUserId = _currentUserId;

    if (currentUserId == null) {
      return;
    }

    try {
      await context.read<chat_prov.ChatProvider>().deleteMessageForMe(
        chatId: widget.chatId,
        messageId: messageId,
        currentUserId: currentUserId,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmDeleteForEveryone(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(widget.isGroupChat ? '删除所有人的消息？' : '双方删除消息？'),
          content: Text(
            widget.isGroupChat ? '这条消息会从所有群成员的聊天中删除。' : '这条消息会从双方的聊天记录中删除。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final currentUserId = _currentUserId;

    if (currentUserId == null) {
      return;
    }

    try {
      await context.read<chat_prov.ChatProvider>().deleteMessageForEveryone(
        chatId: widget.chatId,
        messageId: messageId,
        currentUserId: currentUserId,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$error'), backgroundColor: Colors.red),
      );
    }
  }

  void _showChatSettings() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SwitchListTile(
                title: const Text('分享实时输入内容'),
                subtitle: const Text('开启后，聊天室里的其他成员可以实时看到你正在输入的文字'),
                value: _shareMyLiveDraft,
                onChanged: (value) async {
                  final userId = _currentUserId;
                  if (userId == null) return;

                  setModalState(() {
                    _shareMyLiveDraft = value;
                  });

                  if (mounted) {
                    setState(() {
                      _shareMyLiveDraft = value;
                    });
                  }

                  // 关闭时先删除实时内容。
                  // 不要等待 Firestore 设置保存完成。
                  if (!value) {
                    await _liveDraftService.clearDraft(
                      chatId: widget.chatId,
                      userId: userId,
                    );
                  }

                  try {
                    final chatProvider = context.read<chat_prov.ChatProvider>();

                    await chatProvider.updateLiveDraftEnabled(
                      chatId: widget.chatId,
                      userId: userId,
                      enabled: value,
                    );

                    if (value) {
                      // 开启时，如果输入框已有内容，立即上传。
                      _onMessageChanged();
                    }
                  } catch (error) {
                    debugPrint('保存实时输入设置失败：$error');

                    if (!mounted) return;

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('设置保存失败，请稍后重试')),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // _tabController = TabController(
    //   length: 3,
    //   vsync: this,
    // );

    _liveDraftService = LiveDraftService();

    _messageController.addListener(_onMessageChanged);

    _initializeChat();
  }

  Future<void> _loadLiveDraftSetting() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final chatProvider = context.read<chat_prov.ChatProvider>();

      final enabled = await chatProvider.getLiveDraftEnabled(
        chatId: widget.chatId,
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        _shareMyLiveDraft = enabled;
      });

      if (!enabled) {
        await _liveDraftService.clearDraft(
          chatId: widget.chatId,
          userId: userId,
        );
      }

      // 设置已开启，并且输入框原本就有文字时，立即上传。
      if (enabled && _messageController.text.trim().isNotEmpty) {
        _onMessageChanged();
      }

      debugPrint('实时输入分享设置：$enabled');
    } catch (error) {
      debugPrint('读取实时输入设置失败：$error');

      if (!mounted) return;

      setState(() {
        _shareMyLiveDraft = false;
      });
    }
  }

  Future<void> _initializeChat() async {
    final authProvider = context.read<auth_prov.AuthProvider>();

    final currentUser = authProvider.user;

    if (currentUser == null) {
      debugPrint('聊天初始化失败：当前用户为空');
      return;
    }

    final currentUserId = currentUser.id;

    _currentUserId = currentUserId;

    // 先建立监听。即使断线清理注册失败，
    // 也不能影响实时预览。
    final draftsStream = _liveDraftService.watchChatDrafts(
      chatId: widget.chatId,
      currentUserId: currentUserId,
    );

    if (!mounted) return;

    setState(() {
      _draftsStream = draftsStream;
    });

    // 单独处理断线清理错误。
    try {
      await _liveDraftService.prepare(
        chatId: widget.chatId,
        userId: currentUserId,
      );
    } catch (error) {
      debugPrint('注册断线草稿清理失败：$error');
    }

    await _loadLiveDraftSetting();

    if (!widget.isGroupChat) {
      await _loadOtherUserData();
    }

    await _loadParticipantData();
    await _clearUnread();

    debugPrint('聊天和实时草稿初始化完成');
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);

    final userId = _currentUserId;

    if (userId != null) {
      unawaited(
        _liveDraftService.clearDraft(chatId: widget.chatId, userId: userId),
      );
    }

    _liveDraftService.dispose();
    _messageController.dispose();
    //_tabController.dispose();

    super.dispose();
  }

  void _onMessageChanged() {
    final userId = _currentUserId;

    if (userId == null) {
      debugPrint('草稿未上传：当前用户 ID 为空');
      return;
    }

    if (!_shareMyLiveDraft) {
      return;
    }

    final text = _messageController.text;

    _liveDraftService.updateDraft(
      chatId: widget.chatId,
      userId: userId,
      text: text,
    );
  }

  Future<void> _loadOtherUserData() async {
    final chatProvider = context.read<chat_prov.ChatProvider>();

    final userIds = await chatProvider.getChatParticipants(widget.chatId);

    final currentUserId = _currentUserId;

    if (userIds.isEmpty || currentUserId == null) {
      return;
    }

    final otherUserId = userIds.firstWhere(
      (userId) => userId != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _otherUid = otherUserId;
    });
  }

  Future<void> _loadParticipantData() async {
    final chatProvider = context.read<chat_prov.ChatProvider>();

    final userIds = await chatProvider.getChatParticipants(widget.chatId);

    final currentUserId = _currentUserId;

    // 使用 Set，避免重复，同时保证当前用户也在里面。
    final allUserIds = <String>{
      ...userIds,
      if (currentUserId != null) currentUserId,
    };

    if (allUserIds.isEmpty) {
      return;
    }

    final loadedData = <String, UserModel>{};

    for (final userId in allUserIds) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final data = doc.data();

        if (data == null) {
          debugPrint('用户资料不存在：$userId');
          continue;
        }

        loadedData[userId] = UserModel.fromJson({...data, 'uid': doc.id});

        debugPrint(
          '用户资料加载成功：'
          '$userId，头像：${loadedData[userId]?.avatarUrl}',
        );
      } catch (error) {
        debugPrint('用户资料加载失败：$userId，$error');
      }
    }

    if (!mounted) return;

    setState(() {
      _participantData
        ..clear()
        ..addAll(loadedData);
    });
  }

  // ============================================================
  // 数据加载
  // ============================================================

  Future<void> _clearUnread() async {
    if (_currentUserId == null) return;
    final chatProvider = context.read<chat_prov.ChatProvider>();
    await chatProvider.markAsRead(widget.chatId, _currentUserId!);
  }

  // ============================================================
  // 发送消息
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final authProvider = context.read<auth_prov.AuthProvider>();

    final senderId = authProvider.user?.id;

    if (senderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await context.read<chat_prov.ChatProvider>().sendMessageWithSender(
        widget.chatId,
        senderId,
        text,
      );

      if (!mounted) return;

      _messageController.clear();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败：$error'), backgroundColor: Colors.red),
      );
    }
  }

  void _sendEmoji(String emoji) {
    final authProvider = context.read<auth_prov.AuthProvider>();
    final senderId = authProvider.user?.id;
    if (senderId == null) return;

    final chatProvider = context.read<chat_prov.ChatProvider>();
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
      final authProvider = context.read<auth_prov.AuthProvider>();
      final chatProvider = context.read<chat_prov.ChatProvider>();
      await chatProvider.sendImageMessage(
        widget.chatId,
        File(image.path),
        authProvider,
      );
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
      context.push(AppRoutes.userProfileLocation(uid: _otherUid!));
    }
  }

  void _openChatNotes() {
    final otherUserId = _otherUid;

    if (otherUserId == null || otherUserId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('对方用户资料尚未加载')));

      return;
    }

    context.push(
      AppRoutes.userNotesLocation(uid: otherUserId),
      extra: _chatTitle,
    );
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
      body: _buildChatTab(),
    );
  }

  Widget _buildOtherUserDraft() {
    final stream = _draftsStream;

    if (stream == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<LiveDraft>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('实时草稿监听失败：${snapshot.error}');
          return const SizedBox.shrink();
        }

        final drafts = snapshot.data ?? [];

        debugPrint('收到其他成员草稿数量：${drafts.length}');

        if (drafts.isEmpty) {
          return const SizedBox.shrink();
        }

        // 最多显示最近输入的两个人。
        final visibleDrafts = drafts.take(2).toList();
        final remainingCount = drafts.length - visibleDrafts.length;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Container(
            key: ValueKey(drafts.map((draft) => draft.text).join()),
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8E8E8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int index = 0; index < visibleDrafts.length; index++) ...[
                  Builder(
                    builder: (context) {
                      final draft = visibleDrafts[index];

                      final user = _participantData[draft.userId];

                      final displayName = user?.profileDisplayName ?? '用户';

                      final avatar = user?.avatarUrl;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRealAvatar(
                            imageUrl: avatar,
                            radius: 18,
                            onTap: () {
                              context.push(
                                AppRoutes.userProfileLocation(
                                  uid: draft.userId,
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                    ),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF8F1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        '正在输入',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF24945D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 7),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF6F7F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    draft.text,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Color(0xFF555555),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  if (index < visibleDrafts.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                ],

                if (remainingCount > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    '另外 $remainingCount 人正在输入',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,

      title: GestureDetector(
        onTap: widget.isGroupChat ? null : _navigateToProfile,
        child: Text(
          _chatTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black87),
        ),
      ),

      actions: [
        IconButton(
          tooltip: '共享笔记',
          icon: const Icon(Icons.note_alt_outlined, color: Colors.black87),
          onPressed: _openChatNotes,
        ),

        IconButton(
          icon: const Icon(Icons.call_outlined, color: Colors.black87),
          onPressed: _isActionLocked
              ? null
              : () {
                  _showLockedAction('语音通话功能开发中');
                },
        ),

        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Colors.black87),
          onPressed: _isActionLocked
              ? null
              : () {
                  _showLockedAction('视频通话功能开发中');
                },
        ),

        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onPressed: _showChatSettings,
        ),
      ],
    );
  }

  // ============================================================
  // 消息列表
  // ============================================================

  Widget _buildMessageList() {
    final chatProvider = context.watch<chat_prov.ChatProvider>();

    return StreamBuilder<QuerySnapshot>(
      stream: chatProvider.watchMessages(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('加载失败: ${snapshot.error}'));
        }

        final currentUserId = _currentUserId;

        final visibleDocs = (snapshot.data?.docs ?? []).where((document) {
          final data = document.data() as Map<String, dynamic>;

          final hiddenFor = List<String>.from(data['hiddenFor'] ?? const []);

          return currentUserId == null || !hiddenFor.contains(currentUserId);
        }).toList();

        if (visibleDocs.isEmpty) {
          return const Center(child: Text('没有消息，开始聊天吧！'));
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: visibleDocs.length,
          itemBuilder: (context, index) {
            final document = visibleDocs[index];

            final messageId = document.id;

            final message = document.data() as Map<String, dynamic>;

            final senderId = message['senderId'] as String? ?? '';

            final isMe = senderId == currentUserId;

            final isDeleted = message['status'] == 'deleted';

            final originalImageUrl = message['imageUrl'] as String?;

            final imageUrl = isDeleted ? null : originalImageUrl;

            final originalContent = message['content'] as String? ?? '';

            final content = isDeleted ? '此消息已删除' : originalContent;

            final isEdited = !isDeleted && message['editedAt'] != null;

            final messageTime = _formatMessageTime(message['timestamp']);

            final sender = _participantData[senderId];

            final senderAvatar = sender?.avatarUrl;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,

                // 头像与消息气泡顶部对齐，
                // 不再与下面的时间对齐。
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 2),
                      child: _buildRealAvatar(
                        imageUrl: senderAvatar,
                        radius: 20,
                        onTap: senderId.isEmpty
                            ? null
                            : () {
                                context.push(
                                  AppRoutes.userProfileLocation(uid: senderId),
                                );
                              },
                      ),
                    ),

                  Flexible(
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,

                          onLongPress: isDeleted
                              ? null
                              : () {
                                  _showMessageActions(
                                    messageId: messageId,
                                    message: message,
                                  );
                                },

                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                            ),

                            child: isDeleted
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE4E4E4),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.block,
                                          size: 15,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          '此消息已删除',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : MessageBubble(
                                    isMe: isMe,
                                    content: content,
                                    imageUrl: imageUrl,
                                    onImageTap: () {
                                      if (imageUrl == null) {
                                        return;
                                      }

                                      showDialog(
                                        context: context,
                                        builder: (_) {
                                          return Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: CachedNetworkImage(
                                              imageUrl: imageUrl,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),

                        if (messageTime.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              top: 3,
                              left: isMe ? 0 : 5,
                              right: isMe ? 5 : 0,
                            ),
                            child: Text(
                              isEdited ? '已编辑 · $messageTime' : messageTime,
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1.2,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRealAvatar({
    required String? imageUrl,
    required double radius,
    VoidCallback? onTap,
  }) {
    final url = imageUrl?.trim();

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE8E8E8),
        backgroundImage: url != null && url.isNotEmpty
            ? NetworkImage(url)
            : null,
        child: url == null || url.isEmpty
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(child: _buildMessageList()),

        _buildOtherUserDraft(),

        ChatInputBar(
          controller: _messageController,
          onSend: _sendMessage,
          onEmoji: _showEmojiPicker,
          onImage: _pickAndSendImage,
          isLoading: _isUploading,
        ),
      ],
    );
  }
}
