from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / 'apps' / 'mobile-flutter'


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')


def write(rel: str, text: str) -> None:
    (ROOT / rel).write_text(text, encoding='utf-8')


def once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f'missing marker: {label}')
    return text.replace(old, new, 1)


path = 'apps/mobile-flutter/lib/features/chat/presentation/widgets/chat_input_bar.dart'
text = read(path)
text = once(
    text,
    "import 'package:flutter/material.dart';\n",
    "import 'package:flutter/material.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n",
    'chat input l10n import',
)
text = once(
    text,
    "hintText: '输入消息...'",
    "hintText: AppLocalizations.of(context)!.get('messageInputHint')",
    'chat input hint',
)
write(path, text)

path = 'apps/mobile-flutter/lib/features/social/presentation/widgets/follow_button.dart'
text = read(path)
text = once(
    text,
    "import 'package:provider/provider.dart';\n\n",
    "import 'package:provider/provider.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n",
    'follow button l10n import',
)
text = once(
    text,
    "label: Text(isFollowing ? '已关注' : '关注'),",
    "label: Text(\n            isFollowing\n                ? AppLocalizations.of(context)!.get('following')\n                : AppLocalizations.of(context)!.get('followAction'),\n          ),",
    'follow label',
)
text = once(
    text,
    ").showSnackBar(SnackBar(content: Text('关注操作失败：$error')));",
    ").showSnackBar(\n        SnackBar(\n          content: Text(AppLocalizations.of(context)!.get('followActionFailed')),\n        ),\n      );",
    'follow error',
)
write(path, text)

path = 'apps/mobile-flutter/lib/features/social/presentation/widgets/follow_stats.dart'
text = read(path)
text = once(
    text,
    "import 'package:provider/provider.dart';\n\n",
    "import 'package:provider/provider.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n",
    'follow stats l10n import',
)
text = once(
    text,
    "    this.postsLabel = '动态',\n    this.followingLabel = '关注',\n    this.followersLabel = '粉丝',\n    this.likesLabel = '获赞',",
    "    this.postsLabel,\n    this.followingLabel,\n    this.followersLabel,\n    this.likesLabel,",
    'follow stats constructor',
)
text = once(
    text,
    "  final String postsLabel;\n  final String followingLabel;\n  final String followersLabel;\n  final String likesLabel;",
    "  final String? postsLabel;\n  final String? followingLabel;\n  final String? followersLabel;\n  final String? likesLabel;",
    'follow stats fields',
)
text = once(
    text,
    "  Widget build(BuildContext context) {\n    final repository = context.read<FollowRepository>();",
    "  Widget build(BuildContext context) {\n    final repository = context.read<FollowRepository>();\n    final l10n = AppLocalizations.of(context)!;\n    final resolvedPostsLabel = postsLabel ?? l10n.posts;\n    final resolvedFollowingLabel = followingLabel ?? l10n.get('following');\n    final resolvedFollowersLabel = followersLabel ?? l10n.get('followers');\n    final resolvedLikesLabel = likesLabel ?? l10n.likesCount;",
    'follow stats build',
)
text = text.replace(
    "_StatItem(label: postsLabel, value: postCount.toString())",
    "_StatItem(label: resolvedPostsLabel, value: postCount.toString())",
)
text = text.replace('label: followingLabel,', 'label: resolvedFollowingLabel,')
text = text.replace('label: followersLabel,', 'label: resolvedFollowersLabel,')
text = text.replace(
    "_StatItem(label: likesLabel, value: totalLikes.toString())",
    "_StatItem(label: resolvedLikesLabel, value: totalLikes.toString())",
)
write(path, text)

translations = {
    'en': {'messageInputHint': 'Type a message...', 'followAction': 'Follow', 'followActionFailed': 'Could not update follow status', 'followers': 'Followers'},
    'zh': {'messageInputHint': '输入消息...', 'followAction': '关注', 'followActionFailed': '关注操作失败', 'followers': '粉丝'},
    'ja': {'messageInputHint': 'メッセージを入力...', 'followAction': 'フォロー', 'followActionFailed': 'フォロー状態を更新できませんでした', 'followers': 'フォロワー'},
    'ko': {'messageInputHint': '메시지 입력...', 'followAction': '팔로우', 'followActionFailed': '팔로우 상태를 업데이트하지 못했습니다', 'followers': '팔로워'},
    'ms': {'messageInputHint': 'Taip mesej...', 'followAction': 'Ikuti', 'followActionFailed': 'Status mengikuti gagal dikemas kini', 'followers': 'Pengikut'},
    'vi': {'messageInputHint': 'Nhập tin nhắn...', 'followAction': 'Theo dõi', 'followActionFailed': 'Không thể cập nhật trạng thái theo dõi', 'followers': 'Người theo dõi'},
    'th': {'messageInputHint': 'พิมพ์ข้อความ...', 'followAction': 'ติดตาม', 'followActionFailed': 'อัปเดตสถานะการติดตามไม่สำเร็จ', 'followers': 'ผู้ติดตาม'},
}

for code, values in translations.items():
    locale_path = APP / 'assets' / 'l10n' / f'{code}.json'
    data = json.loads(locale_path.read_text(encoding='utf-8'))
    data.update(values)
    locale_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

print('Applied social and chat input localization.')
