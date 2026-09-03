from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / 'apps' / 'mobile-flutter'


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')


def write(rel: str, text: str) -> None:
    (ROOT / rel).write_text(text, encoding='utf-8')


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f'missing marker: {label}')
    return text.replace(old, new, 1)


def replace_all(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count == 0:
        raise RuntimeError(f'missing marker: {label}')
    return text.replace(old, new)


# chat list
path = 'apps/mobile-flutter/lib/features/chat/presentation/screens/chat_list_screen.dart'
text = read(path)
text = replace_once(
    text,
    "  String _displayNameOf(UserModel? user) {\n",
    "  String _displayNameOf(BuildContext context, UserModel? user) {\n",
    'chat display name signature',
)
text = replace_once(
    text,
    "    return email.isNotEmpty ? email : '未知用户';\n",
    "    return email.isNotEmpty\n        ? email\n        : AppLocalizations.of(context)!.get('unknownUser');\n",
    'chat unknown user',
)
text = replace_all(text, '_displayNameOf(user)', '_displayNameOf(context, user)', 'chat display name calls')
text = text.replace("label: '发送消息'", "label: AppLocalizations.of(context)!.get('sendMessage')")
text = text.replace("label: '查看主页'", "label: AppLocalizations.of(context)!.get('viewProfile')")
text = replace_once(
    text,
    "      ).showSnackBar(SnackBar(content: Text('创建聊天失败: $error')));\n",
    "      ).showSnackBar(\n        SnackBar(content: Text('${AppLocalizations.of(context)!.createChatFailed}: $error')),\n      );\n",
    'chat create failure',
)
text = replace_once(
    text,
    "        body: const Center(child: Text('请先登录')),\n",
    "        body: Center(child: Text(l10n.notLoggedIn)),\n",
    'chat login prompt',
)
text = replace_once(
    text,
    "                  tooltip: l10n.reply,\n",
    "                  tooltip: l10n.get('friendRequests'),\n",
    'chat friend request tooltip',
)
text = replace_once(
    text,
    "          tabs: [\n            Tab(text: l10n.comment),\n            Tab(text: l10n.reply),\n          ],\n",
    "          tabs: [\n            Tab(text: l10n.get('chats')),\n            Tab(text: l10n.get('friends')),\n          ],\n",
    'chat tab labels',
)
text = replace_once(
    text,
    "            title: l10n.noPosts,\n            subtitle: '还没有聊天，开始对话吧',\n",
    "            title: l10n.get('noChats'),\n            subtitle: l10n.get('startConversation'),\n",
    'chat empty state',
)
text = replace_once(
    text,
    "                                hasMessage ? chat.lastMessage : l10n.noPosts,\n",
    "                                hasMessage\n                                    ? chat.lastMessage\n                                    : l10n.get('noMessagesYet'),\n",
    'chat empty preview',
)
text = replace_once(
    text,
    "          return const EmptyState(\n            icon: Icons.people_alt_outlined,\n            title: '暂无好友',\n            subtitle: '去发现页面添加好友吧',\n          );\n",
    "          final l10n = AppLocalizations.of(context)!;\n          return EmptyState(\n            icon: Icons.people_alt_outlined,\n            title: l10n.get('noFriends'),\n            subtitle: l10n.get('findFriendsPrompt'),\n          );\n",
    'chat friends empty state',
)
write(path, text)


# friend requests
path = 'apps/mobile-flutter/lib/features/social/presentation/screens/friend_requests_screen.dart'
text = read(path)
text = replace_once(
    text,
    "import 'package:provider/provider.dart';\n\n",
    "import 'package:provider/provider.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n",
    'friend requests l10n import',
)
text = replace_once(
    text,
    "    final friendRepository = context.read<FriendRepository>();\n",
    "    final l10n = AppLocalizations.of(context)!;\n    final friendRepository = context.read<FriendRepository>();\n",
    'friend requests l10n local',
)
text = text.replace("appBar: AppBar(title: const Text('好友申请'), centerTitle: true)", "appBar: AppBar(title: Text(l10n.get('friendRequests')), centerTitle: true)")
text = text.replace("return Center(child: Text('加载失败: ${snapshot.error}'));", "return Center(child: Text('${l10n.loadFailed}: ${snapshot.error}'));" )
text = replace_once(
    text,
    "            return const Center(\n              child: Column(\n                mainAxisAlignment: MainAxisAlignment.center,\n                children: [\n                  Icon(Icons.person_add_disabled, size: 80, color: Colors.grey),\n                  SizedBox(height: 16),\n                  Text(\n                    '暂无好友申请',\n                    style: TextStyle(fontSize: 18, color: Colors.grey),\n                  ),\n                ],\n              ),\n            );\n",
    "            return Center(\n              child: Column(\n                mainAxisAlignment: MainAxisAlignment.center,\n                children: [\n                  const Icon(\n                    Icons.person_add_disabled,\n                    size: 80,\n                    color: Colors.grey,\n                  ),\n                  const SizedBox(height: 16),\n                  Text(\n                    l10n.get('noFriendRequests'),\n                    style: const TextStyle(fontSize: 18, color: Colors.grey),\n                  ),\n                ],\n              ),\n            );\n",
    'friend requests empty state',
)
text = replace_once(
    text,
    "                    return const ListTile(\n                      leading: CircularProgressIndicator(),\n                      title: Text('加载中...'),\n                    );\n",
    "                    return ListTile(\n                      leading: const CircularProgressIndicator(),\n                      title: Text(l10n.get('loading')),\n                    );\n",
    'friend requests loading',
)
text = text.replace(": '未知用户';", ": l10n.get('unknownUser');")
text = replace_once(
    text,
    "                                const Text(\n                                  '请求添加你为好友',\n                                  style: TextStyle(\n                                    color: Colors.grey,\n                                    fontSize: 14,\n                                  ),\n                                ),\n",
    "                                Text(\n                                  l10n.get('friendRequestDescription'),\n                                  style: const TextStyle(\n                                    color: Colors.grey,\n                                    fontSize: 14,\n                                  ),\n                                ),\n",
    'friend request description',
)
text = text.replace("content: Text('已接受 $displayName 的好友申请')", "content: Text(l10n.getWithArgs('friendRequestAccepted', {'name': displayName}))")
text = text.replace("content: Text('操作失败: $error')", "content: Text('${l10n.get('operationFailed')}: $error')")
text = text.replace("child: const Text('接受')", "child: Text(l10n.get('accept'))")
text = replace_once(
    text,
    "                                      const SnackBar(\n                                        content: Text('已拒绝好友申请'),\n                                        backgroundColor: Colors.red,\n                                      ),\n",
    "                                      SnackBar(\n                                        content: Text(\n                                          l10n.get('friendRequestRejected'),\n                                        ),\n                                        backgroundColor: Colors.red,\n                                      ),\n",
    'friend request rejected snackbar',
)
text = text.replace("child: const Text('拒绝')", "child: Text(l10n.get('reject'))")
write(path, text)


# friends list
path = 'apps/mobile-flutter/lib/features/social/presentation/screens/friends_list_screen.dart'
text = read(path)
text = replace_once(
    text,
    "import 'package:go_router/go_router.dart';\n\n",
    "import 'package:go_router/go_router.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n",
    'friends list l10n import',
)
text = replace_once(
    text,
    "    final theme = Theme.of(context);\n",
    "    final theme = Theme.of(context);\n    final l10n = AppLocalizations.of(context)!;\n",
    'friends list l10n local',
)
text = replace_once(
    text,
    "        title: const Text(\n          '我的好友',\n          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),\n        ),\n",
    "        title: Text(\n          l10n.get('myFriends'),\n          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),\n        ),\n",
    'friends list title',
)
text = text.replace("tooltip: '好友申请'", "tooltip: l10n.get('friendRequests')")
text = text.replace("return Center(child: Text('加载失败: ${snapshot.error}'));", "return Center(child: Text('${l10n.loadFailed}: ${snapshot.error}'));" )
text = text.replace("'暂无好友'", "l10n.get('noFriends')")
text = text.replace("'去发现用户页面添加一些新朋友吧'", "l10n.get('findFriendsPrompt')")
text = text.replace(": '未知用户';", ": l10n.get('unknownUser');")
text = text.replace("SnackBar(content: Text('创建聊天失败: $error'))", "SnackBar(content: Text('${l10n.createChatFailed}: $error'))")
write(path, text)


# users screen
path = 'apps/mobile-flutter/lib/features/profile/presentation/screens/users_screen.dart'
text = read(path)
text = replace_once(
    text,
    "import '../../../../app/router/app_routes.dart';\n",
    "import '../../../../app/l10n/app_localizations.dart';\nimport '../../../../app/router/app_routes.dart';\n",
    'users l10n import',
)
text = replace_once(
    text,
    "  Widget build(BuildContext context) {\n    final currentUserId",
    "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n    final currentUserId",
    'users l10n local',
)
text = replace_once(
    text,
    "        appBar: AppBar(title: const Text('用户列表')),\n        body: const Center(child: Text('请先登录')),\n",
    "        appBar: AppBar(title: Text(l10n.get('userList'))),\n        body: Center(child: Text(l10n.notLoggedIn)),\n",
    'users signed out state',
)
text = text.replace("appBar: AppBar(title: const Text('用户列表'))", "appBar: AppBar(title: Text(l10n.get('userList')))")
text = text.replace("user.displayName.isEmpty ? '未知用户' : user.displayName", "user.displayName.isEmpty ? l10n.get('unknownUser') : user.displayName")
text = replace_once(
    text,
    "      ).showSnackBar(SnackBar(content: Text('创建聊天失败：$error')));\n",
    "      ).showSnackBar(\n        SnackBar(\n          content: Text(\n            '${AppLocalizations.of(context)!.createChatFailed}: $error',\n          ),\n        ),\n      );\n",
    'users create chat failure',
)
text = replace_once(
    text,
    "    return const Center(\n      child: Column(\n        mainAxisAlignment: MainAxisAlignment.center,\n        children: [\n          Icon(Icons.people_outline, size: 64, color: Colors.grey),\n          SizedBox(height: 16),\n          Text('暂无其他用户', style: TextStyle(color: Colors.grey)),\n        ],\n      ),\n    );\n",
    "    final l10n = AppLocalizations.of(context)!;\n    return Center(\n      child: Column(\n        mainAxisAlignment: MainAxisAlignment.center,\n        children: [\n          const Icon(Icons.people_outline, size: 64, color: Colors.grey),\n          const SizedBox(height: 16),\n          Text(l10n.noOtherUsers, style: const TextStyle(color: Colors.grey)),\n        ],\n      ),\n    );\n",
    'users empty state',
)
text = replace_once(
    text,
    "    return Center(\n      child: Column(\n",
    "    final l10n = AppLocalizations.of(context)!;\n    return Center(\n      child: Column(\n",
    'users error l10n local',
)
text = text.replace("Text('加载失败：$error')", "Text('${l10n.loadFailed}: $error')")
write(path, text)


translations = {
    'en': {
        'unknownUser': 'Unknown user',
        'sendMessage': 'Send message',
        'viewProfile': 'View profile',
        'friendRequests': 'Friend requests',
        'chats': 'Chats',
        'friends': 'Friends',
        'noChats': 'No chats yet',
        'startConversation': 'Start a conversation with someone.',
        'noMessagesYet': 'No messages yet',
        'noFriends': 'No friends yet',
        'findFriendsPrompt': 'Discover users and add some new friends.',
        'noFriendRequests': 'No friend requests',
        'loading': 'Loading...',
        'friendRequestDescription': 'Wants to add you as a friend',
        'friendRequestAccepted': 'Accepted {name}’s friend request',
        'operationFailed': 'Operation failed',
        'accept': 'Accept',
        'reject': 'Reject',
        'friendRequestRejected': 'Friend request rejected',
        'myFriends': 'My Friends',
        'userList': 'Users',
    },
    'zh': {
        'unknownUser': '未知用户',
        'sendMessage': '发送消息',
        'viewProfile': '查看主页',
        'friendRequests': '好友申请',
        'chats': '聊天',
        'friends': '好友',
        'noChats': '暂无聊天',
        'startConversation': '还没有聊天，开始一段对话吧',
        'noMessagesYet': '暂无消息',
        'noFriends': '暂无好友',
        'findFriendsPrompt': '去发现用户页面添加一些新朋友吧',
        'noFriendRequests': '暂无好友申请',
        'loading': '加载中...',
        'friendRequestDescription': '请求添加你为好友',
        'friendRequestAccepted': '已接受 {name} 的好友申请',
        'operationFailed': '操作失败',
        'accept': '接受',
        'reject': '拒绝',
        'friendRequestRejected': '已拒绝好友申请',
        'myFriends': '我的好友',
        'userList': '用户列表',
    },
    'ja': {
        'unknownUser': '不明なユーザー',
        'sendMessage': 'メッセージを送信',
        'viewProfile': 'プロフィールを見る',
        'friendRequests': '友達申請',
        'chats': 'チャット',
        'friends': '友達',
        'noChats': 'チャットはまだありません',
        'startConversation': '誰かと会話を始めましょう。',
        'noMessagesYet': 'メッセージはまだありません',
        'noFriends': '友達はまだいません',
        'findFriendsPrompt': 'ユーザーを見つけて新しい友達を追加しましょう。',
        'noFriendRequests': '友達申請はありません',
        'loading': '読み込み中...',
        'friendRequestDescription': '友達追加を希望しています',
        'friendRequestAccepted': '{name} さんの友達申請を承認しました',
        'operationFailed': '操作に失敗しました',
        'accept': '承認',
        'reject': '拒否',
        'friendRequestRejected': '友達申請を拒否しました',
        'myFriends': '友達',
        'userList': 'ユーザー一覧',
    },
    'ko': {
        'unknownUser': '알 수 없는 사용자',
        'sendMessage': '메시지 보내기',
        'viewProfile': '프로필 보기',
        'friendRequests': '친구 요청',
        'chats': '채팅',
        'friends': '친구',
        'noChats': '아직 채팅이 없습니다',
        'startConversation': '누군가와 대화를 시작해 보세요.',
        'noMessagesYet': '아직 메시지가 없습니다',
        'noFriends': '아직 친구가 없습니다',
        'findFriendsPrompt': '사용자를 찾아 새 친구를 추가해 보세요.',
        'noFriendRequests': '친구 요청이 없습니다',
        'loading': '불러오는 중...',
        'friendRequestDescription': '친구로 추가하려고 합니다',
        'friendRequestAccepted': '{name}님의 친구 요청을 수락했습니다',
        'operationFailed': '작업에 실패했습니다',
        'accept': '수락',
        'reject': '거절',
        'friendRequestRejected': '친구 요청을 거절했습니다',
        'myFriends': '내 친구',
        'userList': '사용자 목록',
    },
    'ms': {
        'unknownUser': 'Pengguna tidak dikenali',
        'sendMessage': 'Hantar mesej',
        'viewProfile': 'Lihat profil',
        'friendRequests': 'Permintaan rakan',
        'chats': 'Sembang',
        'friends': 'Rakan',
        'noChats': 'Belum ada sembang',
        'startConversation': 'Mulakan perbualan dengan seseorang.',
        'noMessagesYet': 'Belum ada mesej',
        'noFriends': 'Belum ada rakan',
        'findFriendsPrompt': 'Temui pengguna dan tambah rakan baharu.',
        'noFriendRequests': 'Tiada permintaan rakan',
        'loading': 'Memuatkan...',
        'friendRequestDescription': 'Ingin menambah anda sebagai rakan',
        'friendRequestAccepted': 'Permintaan rakan {name} diterima',
        'operationFailed': 'Operasi gagal',
        'accept': 'Terima',
        'reject': 'Tolak',
        'friendRequestRejected': 'Permintaan rakan ditolak',
        'myFriends': 'Rakan Saya',
        'userList': 'Senarai Pengguna',
    },
    'vi': {
        'unknownUser': 'Người dùng không xác định',
        'sendMessage': 'Gửi tin nhắn',
        'viewProfile': 'Xem hồ sơ',
        'friendRequests': 'Lời mời kết bạn',
        'chats': 'Trò chuyện',
        'friends': 'Bạn bè',
        'noChats': 'Chưa có cuộc trò chuyện',
        'startConversation': 'Hãy bắt đầu trò chuyện với ai đó.',
        'noMessagesYet': 'Chưa có tin nhắn',
        'noFriends': 'Chưa có bạn bè',
        'findFriendsPrompt': 'Khám phá người dùng và thêm bạn mới.',
        'noFriendRequests': 'Không có lời mời kết bạn',
        'loading': 'Đang tải...',
        'friendRequestDescription': 'Muốn kết bạn với bạn',
        'friendRequestAccepted': 'Đã chấp nhận lời mời kết bạn của {name}',
        'operationFailed': 'Thao tác thất bại',
        'accept': 'Chấp nhận',
        'reject': 'Từ chối',
        'friendRequestRejected': 'Đã từ chối lời mời kết bạn',
        'myFriends': 'Bạn bè của tôi',
        'userList': 'Danh sách người dùng',
    },
    'th': {
        'unknownUser': 'ผู้ใช้ไม่ทราบชื่อ',
        'sendMessage': 'ส่งข้อความ',
        'viewProfile': 'ดูโปรไฟล์',
        'friendRequests': 'คำขอเป็นเพื่อน',
        'chats': 'แชต',
        'friends': 'เพื่อน',
        'noChats': 'ยังไม่มีแชต',
        'startConversation': 'เริ่มการสนทนากับใครสักคน',
        'noMessagesYet': 'ยังไม่มีข้อความ',
        'noFriends': 'ยังไม่มีเพื่อน',
        'findFriendsPrompt': 'ค้นหาผู้ใช้และเพิ่มเพื่อนใหม่',
        'noFriendRequests': 'ไม่มีคำขอเป็นเพื่อน',
        'loading': 'กำลังโหลด...',
        'friendRequestDescription': 'ต้องการเพิ่มคุณเป็นเพื่อน',
        'friendRequestAccepted': 'ยอมรับคำขอเป็นเพื่อนของ {name} แล้ว',
        'operationFailed': 'ดำเนินการไม่สำเร็จ',
        'accept': 'ยอมรับ',
        'reject': 'ปฏิเสธ',
        'friendRequestRejected': 'ปฏิเสธคำขอเป็นเพื่อนแล้ว',
        'myFriends': 'เพื่อนของฉัน',
        'userList': 'รายชื่อผู้ใช้',
    },
}

for code, values in translations.items():
    locale_path = APP / 'assets' / 'l10n' / f'{code}.json'
    data = json.loads(locale_path.read_text(encoding='utf-8'))
    data.update(values)
    locale_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )

print('Localized remaining chat/social/user-list UI.')
