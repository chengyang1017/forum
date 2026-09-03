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


# ---------------------------------------------------------------------------
# Post translation screen
# ---------------------------------------------------------------------------
path = 'apps/mobile-flutter/lib/features/translation/presentation/screens/post_translation_screen.dart'
text = read(path)
text = replace_once(
    text,
    "import 'package:provider/provider.dart';\n\n",
    "import 'package:provider/provider.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n",
    'translation l10n import',
)
text = text.replace(
    ").showSnackBar(SnackBar(content: Text('AI 翻译调用失败: $e')));",
    ").showSnackBar(\n        SnackBar(content: Text(AppLocalizations.of(context)!.get('aiTranslationFailed'))),\n      );",
)
text = text.replace(
    "const SnackBar(content: Text('请先登录'))",
    "SnackBar(content: Text(AppLocalizations.of(context)!.get('pleaseSignIn')))",
)
text = text.replace(
    "const SnackBar(content: Text('请完成翻译'))",
    "SnackBar(content: Text(AppLocalizations.of(context)!.get('completeTranslationFirst')))",
)
text = text.replace(
    "const SnackBar(content: Text('翻译已保存到笔记'))",
    "SnackBar(content: Text(AppLocalizations.of(context)!.get('translationSavedToNotes')))",
)
text = text.replace(
    "SnackBar(content: Text('保存到笔记失败：$e'))",
    "SnackBar(content: Text(AppLocalizations.of(context)!.get('saveToNotesFailed')))",
)
text = text.replace(
    "SnackBar(content: Text('${widget.targetLanguageName}版本发布成功'))",
    "SnackBar(\n          content: Text(\n            AppLocalizations.of(context)!.getWithArgs(\n              'languageVersionPublished',\n              {'language': widget.targetLanguageName},\n            ),\n          ),\n        )",
)
text = text.replace(
    "SnackBar(content: Text('发布失败：$e'))",
    "SnackBar(content: Text(AppLocalizations.of(context)!.get('publishTranslationFailed')))",
)
text = replace_once(
    text,
    "  Widget _buildAiActions() {\n    return Row(",
    "  Widget _buildAiActions() {\n    final l10n = AppLocalizations.of(context)!;\n\n    return Row(",
    'ai action l10n',
)
text = text.replace(
    "label: Text(_savingToNote ? '保存中...' : '保存到笔记'),",
    "label: Text(\n              _savingToNote ? l10n.get('saving') : l10n.get('saveToNotes'),\n            ),",
)
text = text.replace(
    "label: Text(_saving ? '发布中...' : '发布翻译'),",
    "label: Text(\n              _saving ? l10n.get('publishing') : l10n.get('publishTranslation'),\n            ),",
)
text = replace_once(
    text,
    "  Widget build(BuildContext context) {\n    final isAi = widget.mode == TranslationMode.ai;",
    "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n    final isAi = widget.mode == TranslationMode.ai;",
    'translation build l10n',
)
text = text.replace(
    "appBar: AppBar(title: Text(isAi ? 'AI 翻译' : '自己翻译'))",
    "appBar: AppBar(\n        title: Text(isAi ? l10n.get('aiTranslation') : l10n.get('manualTranslation')),\n      )",
)
text = text.replace(
    "'翻译成 ${widget.targetLanguageName}',",
    "l10n.getWithArgs(\n              'translateToLanguage',\n              {'language': widget.targetLanguageName},\n            ),",
)
text = text.replace("          if (_isTranslating) ...[\n            const Center(", "          if (_isTranslating) ...[\n            Center(")
text = text.replace(
    "                    Text('AI 正在生成译文...'),",
    "                    Text(l10n.get('aiGeneratingTranslation')),
",
)
text = text.replace(
    "            const Text(\n              'AI 翻译预览',",
    "            Text(\n              l10n.get('aiTranslationPreview'),",
)
text = text.replace(
    "              const Text(\n                '标题',",
    "              Text(\n                l10n.title,",
)
text = text.replace(
    "            const Text(\n              '正文',",
    "            Text(\n              l10n.get('bodyLabel'),",
)
text = text.replace("label: const Text('编辑译文'),", "label: Text(l10n.get('editTranslation')),")
text = text.replace(
    "            const Text('原文标题', style: TextStyle(fontWeight: FontWeight.bold)),",
    "            Text(\n              l10n.get('originalTitle'),\n              style: const TextStyle(fontWeight: FontWeight.bold),\n            ),",
)
text = text.replace(
    "labelText: isAi ? '编辑翻译标题' : '翻译标题',",
    "labelText: isAi\n                    ? l10n.get('editTranslationTitle')\n                    : l10n.get('translationTitle'),",
)
text = text.replace(
    "            const Text('原文', style: TextStyle(fontWeight: FontWeight.bold)),",
    "            Text(\n              l10n.get('originalText'),\n              style: const TextStyle(fontWeight: FontWeight.bold),\n            ),",
)
text = text.replace(
    "labelText: isAi ? '编辑翻译内容' : '翻译内容',",
    "labelText: isAi\n                    ? l10n.get('editTranslationContent')\n                    : l10n.get('translationContent'),",
)
text = text.replace("child: const Text('取消修改'),", "child: Text(l10n.get('discardChanges')),")
text = text.replace(
    "label: Text(_saving ? '发布中...' : '发布语言版本'),",
    "label: Text(\n                  _saving ? l10n.get('publishing') : l10n.get('publishLanguageVersion'),\n                ),",
)
write(path, text)


# ---------------------------------------------------------------------------
# Public user profile screen + birthday sentinel bug
# ---------------------------------------------------------------------------
path = 'apps/mobile-flutter/lib/features/profile/presentation/screens/user_profile_screen.dart'
text = read(path)
text = text.replace(
    "const SnackBar(content: Text('已发送好友申请'), backgroundColor: Colors.green)",
    "SnackBar(\n          content: Text(AppLocalizations.of(context)!.get('friendRequestSent')),\n          backgroundColor: Colors.green,\n        )",
)
text = text.replace(
    "SnackBar(content: Text('发送失败: $error'), backgroundColor: Colors.red)",
    "SnackBar(\n          content: Text(AppLocalizations.of(context)!.get('friendRequestSendFailed')),\n          backgroundColor: Colors.red,\n        )",
)
text = text.replace(
    "content: Text('已接受 $displayName 的好友申请'),",
    "content: Text(\n            AppLocalizations.of(context)!.getWithArgs(\n              'friendRequestAccepted',\n              {'name': displayName},\n            ),\n          ),",
)
text = text.replace(
    "SnackBar(content: Text('操作失败: $error'), backgroundColor: Colors.red)",
    "SnackBar(\n          content: Text(AppLocalizations.of(context)!.get('operationFailed')),\n          backgroundColor: Colors.red,\n        )",
)
text = text.replace(
    ").showSnackBar(SnackBar(content: Text('创建聊天失败: $error')));",
    ").showSnackBar(\n        SnackBar(content: Text(AppLocalizations.of(context)!.get('createChatFailed'))),\n      );",
)
text = replace_once(
    text,
    "  bool _isDefaultBirthday(DateTime? date) {\n    return date == null ||\n        (date.year == 2000 && date.month == 1 && date.day == 1);\n  }",
    "  bool _isDefaultBirthday(DateTime? date) {\n    return date == null;\n  }",
    'birthday sentinel fix',
)
text = text.replace(
    "appBar: AppBar(title: const Text('用户不存在'), centerTitle: true),\n        body: const Center(\n          child: Text('该用户不存在', style: TextStyle(color: Colors.grey)),\n        ),",
    "appBar: AppBar(title: Text(l10n.get('userNotFound')), centerTitle: true),\n        body: Center(\n          child: Text(\n            l10n.get('userNotFound'),\n            style: const TextStyle(color: Colors.grey),\n          ),\n        ),",
)
text = text.replace(
    "final username = user.username.isNotEmpty ? user.username : '未知用户';",
    "final username = user.username.isNotEmpty ? user.username : l10n.get('unknownUser');",
)
text = text.replace(
    "isMe ? '我的动态' : 'TA 的动态',",
    "isMe ? l10n.get('myActivity') : l10n.get('theirActivity'),",
)
text = text.replace(
    "'${_calculateAge(birthday)} 岁',",
    "AppLocalizations.of(context)!.getWithArgs(\n                    'ageYears',\n                    {'age': '${_calculateAge(birthday)}'},\n                  ),",
)
text = text.replace("title: const Text('共同笔记'),", "title: Text(AppLocalizations.of(context)!.get('sharedNotes')),")
text = text.replace(
    "subtitle: Text('查看与 $displayName 共享的笔记'),",
    "subtitle: Text(\n          AppLocalizations.of(context)!.getWithArgs(\n            'viewSharedNotesWithUser',\n            {'name': displayName},\n          ),\n        ),",
)
text = text.replace("label: const Text('好友 · 发消息'),", "label: Text(AppLocalizations.of(context)!.get('friendMessageAction')),")
text = text.replace("label: const Text('好友申请已发送'),", "label: Text(AppLocalizations.of(context)!.get('friendRequestPending')),")
text = text.replace("label: const Text('接受好友申请'),", "label: Text(AppLocalizations.of(context)!.get('acceptFriendRequest')),")
text = text.replace("label: const Text('添加好友'),", "label: Text(AppLocalizations.of(context)!.addFriend),")
write(path, text)


translations = {
    'en': {
        'aiTranslation': 'AI translation', 'manualTranslation': 'Translate manually',
        'translateToLanguage': 'Translate to {language}', 'aiTranslationFailed': 'AI translation failed. Please try again.',
        'completeTranslationFirst': 'Complete the translation first', 'translationSavedToNotes': 'Translation saved to notes',
        'saveToNotesFailed': 'Could not save the translation to notes', 'languageVersionPublished': '{language} version published',
        'publishTranslationFailed': 'Could not publish the translation', 'saving': 'Saving...', 'saveToNotes': 'Save to notes',
        'publishing': 'Publishing...', 'publishTranslation': 'Publish translation', 'aiGeneratingTranslation': 'AI is generating the translation...',
        'aiTranslationPreview': 'AI translation preview', 'bodyLabel': 'Body', 'editTranslation': 'Edit translation',
        'originalTitle': 'Original title', 'editTranslationTitle': 'Edit translated title', 'translationTitle': 'Translated title',
        'originalText': 'Original text', 'editTranslationContent': 'Edit translated content', 'translationContent': 'Translated content',
        'discardChanges': 'Discard changes', 'publishLanguageVersion': 'Publish language version',
        'userNotFound': 'User not found', 'ageYears': '{age} years old', 'myActivity': 'My activity', 'theirActivity': 'Their activity',
        'viewSharedNotesWithUser': 'View notes shared with {name}', 'friendMessageAction': 'Friend · Message',
        'friendRequestPending': 'Friend request sent', 'acceptFriendRequest': 'Accept friend request'
    },
    'zh': {
        'aiTranslation': 'AI 翻译', 'manualTranslation': '自己翻译', 'translateToLanguage': '翻译成 {language}',
        'aiTranslationFailed': 'AI 翻译调用失败，请稍后重试', 'completeTranslationFirst': '请完成翻译',
        'translationSavedToNotes': '翻译已保存到笔记', 'saveToNotesFailed': '保存到笔记失败',
        'languageVersionPublished': '{language}版本发布成功', 'publishTranslationFailed': '发布翻译失败',
        'saving': '保存中...', 'saveToNotes': '保存到笔记', 'publishing': '发布中...', 'publishTranslation': '发布翻译',
        'aiGeneratingTranslation': 'AI 正在生成译文...', 'aiTranslationPreview': 'AI 翻译预览', 'bodyLabel': '正文',
        'editTranslation': '编辑译文', 'originalTitle': '原文标题', 'editTranslationTitle': '编辑翻译标题',
        'translationTitle': '翻译标题', 'originalText': '原文', 'editTranslationContent': '编辑翻译内容',
        'translationContent': '翻译内容', 'discardChanges': '取消修改', 'publishLanguageVersion': '发布语言版本',
        'userNotFound': '用户不存在', 'ageYears': '{age} 岁', 'myActivity': '我的动态', 'theirActivity': 'TA 的动态',
        'viewSharedNotesWithUser': '查看与 {name} 共享的笔记', 'friendMessageAction': '好友 · 发消息',
        'friendRequestPending': '好友申请已发送', 'acceptFriendRequest': '接受好友申请'
    },
    'ja': {
        'aiTranslation': 'AI翻訳', 'manualTranslation': '自分で翻訳', 'translateToLanguage': '{language}に翻訳',
        'aiTranslationFailed': 'AI翻訳に失敗しました。もう一度お試しください。', 'completeTranslationFirst': '翻訳を完成させてください',
        'translationSavedToNotes': '翻訳をノートに保存しました', 'saveToNotesFailed': '翻訳をノートに保存できませんでした',
        'languageVersionPublished': '{language}版を公開しました', 'publishTranslationFailed': '翻訳を公開できませんでした',
        'saving': '保存中...', 'saveToNotes': 'ノートに保存', 'publishing': '公開中...', 'publishTranslation': '翻訳を公開',
        'aiGeneratingTranslation': 'AIが翻訳を生成しています...', 'aiTranslationPreview': 'AI翻訳プレビュー', 'bodyLabel': '本文',
        'editTranslation': '翻訳を編集', 'originalTitle': '原文タイトル', 'editTranslationTitle': '翻訳タイトルを編集',
        'translationTitle': '翻訳タイトル', 'originalText': '原文', 'editTranslationContent': '翻訳内容を編集',
        'translationContent': '翻訳内容', 'discardChanges': '変更を破棄', 'publishLanguageVersion': '言語版を公開',
        'userNotFound': 'ユーザーが見つかりません', 'ageYears': '{age}歳', 'myActivity': '自分の投稿', 'theirActivity': 'このユーザーの投稿',
        'viewSharedNotesWithUser': '{name}との共有ノートを見る', 'friendMessageAction': '友達 · メッセージ',
        'friendRequestPending': '友達申請を送信済み', 'acceptFriendRequest': '友達申請を承認'
    },
    'ko': {
        'aiTranslation': 'AI 번역', 'manualTranslation': '직접 번역', 'translateToLanguage': '{language}(으)로 번역',
        'aiTranslationFailed': 'AI 번역에 실패했습니다. 다시 시도해 주세요.', 'completeTranslationFirst': '번역을 완료해 주세요',
        'translationSavedToNotes': '번역을 노트에 저장했습니다', 'saveToNotesFailed': '번역을 노트에 저장하지 못했습니다',
        'languageVersionPublished': '{language} 버전을 게시했습니다', 'publishTranslationFailed': '번역을 게시하지 못했습니다',
        'saving': '저장 중...', 'saveToNotes': '노트에 저장', 'publishing': '게시 중...', 'publishTranslation': '번역 게시',
        'aiGeneratingTranslation': 'AI가 번역을 생성하고 있습니다...', 'aiTranslationPreview': 'AI 번역 미리보기', 'bodyLabel': '본문',
        'editTranslation': '번역 편집', 'originalTitle': '원문 제목', 'editTranslationTitle': '번역 제목 편집',
        'translationTitle': '번역 제목', 'originalText': '원문', 'editTranslationContent': '번역 내용 편집',
        'translationContent': '번역 내용', 'discardChanges': '변경 취소', 'publishLanguageVersion': '언어 버전 게시',
        'userNotFound': '사용자를 찾을 수 없습니다', 'ageYears': '{age}세', 'myActivity': '내 활동', 'theirActivity': '이 사용자의 활동',
        'viewSharedNotesWithUser': '{name}님과 공유한 노트 보기', 'friendMessageAction': '친구 · 메시지',
        'friendRequestPending': '친구 요청 보냄', 'acceptFriendRequest': '친구 요청 수락'
    },
    'ms': {
        'aiTranslation': 'Terjemahan AI', 'manualTranslation': 'Terjemah sendiri', 'translateToLanguage': 'Terjemah ke {language}',
        'aiTranslationFailed': 'Terjemahan AI gagal. Sila cuba lagi.', 'completeTranslationFirst': 'Sila lengkapkan terjemahan dahulu',
        'translationSavedToNotes': 'Terjemahan disimpan ke nota', 'saveToNotesFailed': 'Terjemahan gagal disimpan ke nota',
        'languageVersionPublished': 'Versi {language} telah diterbitkan', 'publishTranslationFailed': 'Terjemahan gagal diterbitkan',
        'saving': 'Menyimpan...', 'saveToNotes': 'Simpan ke nota', 'publishing': 'Menerbitkan...', 'publishTranslation': 'Terbitkan terjemahan',
        'aiGeneratingTranslation': 'AI sedang menjana terjemahan...', 'aiTranslationPreview': 'Pratonton terjemahan AI', 'bodyLabel': 'Isi',
        'editTranslation': 'Edit terjemahan', 'originalTitle': 'Tajuk asal', 'editTranslationTitle': 'Edit tajuk terjemahan',
        'translationTitle': 'Tajuk terjemahan', 'originalText': 'Teks asal', 'editTranslationContent': 'Edit kandungan terjemahan',
        'translationContent': 'Kandungan terjemahan', 'discardChanges': 'Buang perubahan', 'publishLanguageVersion': 'Terbitkan versi bahasa',
        'userNotFound': 'Pengguna tidak ditemui', 'ageYears': '{age} tahun', 'myActivity': 'Aktiviti saya', 'theirActivity': 'Aktiviti pengguna',
        'viewSharedNotesWithUser': 'Lihat nota yang dikongsi dengan {name}', 'friendMessageAction': 'Rakan · Mesej',
        'friendRequestPending': 'Permintaan rakan dihantar', 'acceptFriendRequest': 'Terima permintaan rakan'
    },
    'vi': {
        'aiTranslation': 'Dịch bằng AI', 'manualTranslation': 'Tự dịch', 'translateToLanguage': 'Dịch sang {language}',
        'aiTranslationFailed': 'Dịch bằng AI thất bại. Vui lòng thử lại.', 'completeTranslationFirst': 'Vui lòng hoàn tất bản dịch trước',
        'translationSavedToNotes': 'Đã lưu bản dịch vào ghi chú', 'saveToNotesFailed': 'Không thể lưu bản dịch vào ghi chú',
        'languageVersionPublished': 'Đã đăng phiên bản {language}', 'publishTranslationFailed': 'Không thể đăng bản dịch',
        'saving': 'Đang lưu...', 'saveToNotes': 'Lưu vào ghi chú', 'publishing': 'Đang đăng...', 'publishTranslation': 'Đăng bản dịch',
        'aiGeneratingTranslation': 'AI đang tạo bản dịch...', 'aiTranslationPreview': 'Xem trước bản dịch AI', 'bodyLabel': 'Nội dung',
        'editTranslation': 'Chỉnh sửa bản dịch', 'originalTitle': 'Tiêu đề gốc', 'editTranslationTitle': 'Sửa tiêu đề bản dịch',
        'translationTitle': 'Tiêu đề bản dịch', 'originalText': 'Văn bản gốc', 'editTranslationContent': 'Sửa nội dung bản dịch',
        'translationContent': 'Nội dung bản dịch', 'discardChanges': 'Bỏ thay đổi', 'publishLanguageVersion': 'Đăng phiên bản ngôn ngữ',
        'userNotFound': 'Không tìm thấy người dùng', 'ageYears': '{age} tuổi', 'myActivity': 'Hoạt động của tôi', 'theirActivity': 'Hoạt động của người dùng',
        'viewSharedNotesWithUser': 'Xem ghi chú được chia sẻ với {name}', 'friendMessageAction': 'Bạn bè · Nhắn tin',
        'friendRequestPending': 'Đã gửi lời mời kết bạn', 'acceptFriendRequest': 'Chấp nhận lời mời kết bạn'
    },
    'th': {
        'aiTranslation': 'แปลด้วย AI', 'manualTranslation': 'แปลด้วยตนเอง', 'translateToLanguage': 'แปลเป็น {language}',
        'aiTranslationFailed': 'การแปลด้วย AI ล้มเหลว โปรดลองอีกครั้ง', 'completeTranslationFirst': 'โปรดแปลให้เสร็จก่อน',
        'translationSavedToNotes': 'บันทึกคำแปลลงในโน้ตแล้ว', 'saveToNotesFailed': 'ไม่สามารถบันทึกคำแปลลงในโน้ตได้',
        'languageVersionPublished': 'เผยแพร่เวอร์ชัน {language} แล้ว', 'publishTranslationFailed': 'ไม่สามารถเผยแพร่คำแปลได้',
        'saving': 'กำลังบันทึก...', 'saveToNotes': 'บันทึกลงโน้ต', 'publishing': 'กำลังเผยแพร่...', 'publishTranslation': 'เผยแพร่คำแปล',
        'aiGeneratingTranslation': 'AI กำลังสร้างคำแปล...', 'aiTranslationPreview': 'ตัวอย่างคำแปล AI', 'bodyLabel': 'เนื้อหา',
        'editTranslation': 'แก้ไขคำแปล', 'originalTitle': 'ชื่อเรื่องต้นฉบับ', 'editTranslationTitle': 'แก้ไขชื่อเรื่องคำแปล',
        'translationTitle': 'ชื่อเรื่องคำแปล', 'originalText': 'ข้อความต้นฉบับ', 'editTranslationContent': 'แก้ไขเนื้อหาคำแปล',
        'translationContent': 'เนื้อหาคำแปล', 'discardChanges': 'ยกเลิกการแก้ไข', 'publishLanguageVersion': 'เผยแพร่เวอร์ชันภาษา',
        'userNotFound': 'ไม่พบผู้ใช้', 'ageYears': 'อายุ {age} ปี', 'myActivity': 'กิจกรรมของฉัน', 'theirActivity': 'กิจกรรมของผู้ใช้นี้',
        'viewSharedNotesWithUser': 'ดูโน้ตที่แชร์กับ {name}', 'friendMessageAction': 'เพื่อน · ส่งข้อความ',
        'friendRequestPending': 'ส่งคำขอเป็นเพื่อนแล้ว', 'acceptFriendRequest': 'ยอมรับคำขอเป็นเพื่อน'
    },
}

for code, values in translations.items():
    locale_path = APP / 'assets' / 'l10n' / f'{code}.json'
    data = json.loads(locale_path.read_text(encoding='utf-8'))
    data.update(values)
    locale_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

# Permanent guard: once a presentation screen is cleaned, keep it free of
# hard-coded Chinese string literals. Debug logs are deliberately ignored.
guard_path = APP / 'test' / 'app' / 'l10n' / 'localized_screen_guard_test.dart'
guard_path.parent.mkdir(parents=True, exist_ok=True)
guard_path.write_text("""import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cleaned presentation screens do not hardcode Chinese UI strings', () {
    const paths = <String>[
      'lib/features/translation/presentation/screens/post_translation_screen.dart',
      'lib/features/profile/presentation/screens/user_profile_screen.dart',
    ];
    final chineseLiteral = RegExp(r'''['\"][^'\"\\n]*[\\u3400-\\u9fff][^'\"\\n]*['\"]''');
    final violations = <String>[];

    for (final path in paths) {
      final lines = File(path).readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.contains('debugPrint')) {
          continue;
        }
        if (chineseLiteral.hasMatch(line)) {
          violations.add('$path:${index + 1}: ${line.trim()}');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\\n'));
  });
}
""", encoding='utf-8')

print('Applied translation/profile localization and guard test.')
