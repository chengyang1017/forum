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


# Post edit history: localize labels and stop exposing raw language codes.
path = 'apps/mobile-flutter/lib/features/post/presentation/screens/post_edit_history_screen.dart'
text = read(path)
text = once(text, "import 'package:provider/provider.dart';\n\n", "import 'package:provider/provider.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n", 'history import')
text = once(text, "  String _formatTime(DateTime? time) {\n    if (time == null) {\n      return '时间未知';\n    }", "  String _formatTime(DateTime? time, AppLocalizations l10n) {\n    if (time == null) {\n      return l10n.get('unknownTime');\n    }", 'history time')
text = once(text, "  Widget build(BuildContext context) {\n    return Scaffold(\n      appBar: AppBar(title: const Text('编辑历史')),", "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n\n    return Scaffold(\n      appBar: AppBar(title: Text(l10n.get('postEditHistory'))),", 'history build')
text = text.replace("return Center(child: Text('加载失败：${snapshot.error}'));", "return Center(child: Text('${l10n.loadFailed}: ${snapshot.error}'));" )
text = text.replace("return const Center(child: Text('暂无编辑历史'));", "return Center(child: Text(l10n.get('noEditHistory')));")
text = text.replace("title: Text(_formatTime(entry.editedAt)),", "title: Text(_formatTime(entry.editedAt, l10n)),")
text = once(text, "                      Text(\n                        entry.languageCode.isEmpty\n                            ? '语言未知'\n                            : '语言：${entry.languageCode}',\n                      ),", "                      Text(\n                        entry.languageCode.isEmpty\n                            ? l10n.get('unknownLanguage')\n                            : l10n.getWithArgs('languageValue', {\n                                'language': l10n.getLanguageName(\n                                  entry.languageCode,\n                                ),\n                              }),\n                      ),", 'history language')
text = once(text, "  Widget build(BuildContext context) {\n    final entry = widget.entry;\n\n    return Scaffold(\n      appBar: AppBar(title: const Text('历史版本')),", "  Widget build(BuildContext context) {\n    final entry = widget.entry;\n    final l10n = AppLocalizations.of(context)!;\n\n    return Scaffold(\n      appBar: AppBar(title: Text(l10n.get('historyVersion'))),", 'history detail title')
write(path, text)


# Comments: localize copy and remove light-theme-only surfaces.
path = 'apps/mobile-flutter/lib/features/post/presentation/screens/node_comment_screen.dart'
text = read(path)
text = once(text, "import 'package:image_picker/image_picker.dart';\n\n", "import 'package:image_picker/image_picker.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n", 'comments import')
text = text.replace("SnackBar(content: Text('发送失败: $error'), backgroundColor: Colors.red)", "SnackBar(\n        content: Text('${AppLocalizations.of(context)!.get('sendFailed')}: $error'),\n        backgroundColor: Colors.red,\n      )")
text = once(text, "  Widget buildReplies(PostCommentModel comment) {\n    final replies = comment.replies;", "  Widget buildReplies(PostCommentModel comment) {\n    final replies = comment.replies;\n    final l10n = AppLocalizations.of(context)!;\n    final colorScheme = Theme.of(context).colorScheme;", 'comments replies locals')
text = text.replace("color: Colors.grey.shade50,", "color: colorScheme.surfaceContainerLow,")
text = text.replace("text: '回复 ',", "text: '${l10n.reply} ',")
text = once(text, "  Widget _buildCommentList() {\n    if (_isLoading) {", "  Widget _buildCommentList() {\n    final l10n = AppLocalizations.of(context)!;\n\n    if (_isLoading) {", 'comment list local')
text = text.replace("Text('评论加载失败\\n$_errorMessage', textAlign: TextAlign.center)", "Text(\n                '${l10n.get('commentLoadFailed')}\\n$_errorMessage',\n                textAlign: TextAlign.center,\n              )")
text = text.replace("FilledButton(onPressed: _loadComments, child: const Text('重试'))", "FilledButton(\n                onPressed: _loadComments,\n                child: Text(l10n.get('retry')),\n              )")
text = text.replace("'暂无评论，快来抢沙发吧~'", "l10n.get('noCommentsYet')")
text = text.replace("                        '回复',", "                        l10n.reply,")
text = once(text, "  Widget build(BuildContext context) {\n    final busy = _isUploading || _isSending;", "  Widget build(BuildContext context) {\n    final busy = _isUploading || _isSending;\n    final l10n = AppLocalizations.of(context)!;\n    final colorScheme = Theme.of(context).colorScheme;", 'comments build locals')
text = text.replace("color: Colors.white,", "color: colorScheme.surface,")
text = text.replace("fillColor: Colors.grey.shade100,", "fillColor: colorScheme.surfaceContainerHighest,")
text = text.replace("? '回复内容...'\n                                : '说点什么吧...'", "? l10n.get('replyHint')\n                                : l10n.get('commentHint')")
write(path, text)


# Post report dialog: reason values stay stable, only labels become localized.
path = 'apps/mobile-flutter/lib/features/post/presentation/widgets/post_report_dialog.dart'
text = read(path)
text = once(text, "import 'package:flutter/material.dart';\n", "import 'package:flutter/material.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n", 'report import')
text = text.replace('final String label;', 'final String localizationKey;')
text = text.replace('required this.label,', 'required this.localizationKey,')
reason_keys = {
    "label: '垃圾信息或广告'": "localizationKey: 'reportReasonSpam'",
    "label: '骚扰或欺凌'": "localizationKey: 'reportReasonHarassment'",
    "label: '仇恨言论'": "localizationKey: 'reportReasonHate'",
    "label: '色情或性内容'": "localizationKey: 'reportReasonSexual'",
    "label: '暴力或危险内容'": "localizationKey: 'reportReasonViolence'",
    "label: '虚假或误导信息'": "localizationKey: 'reportReasonMisinformation'",
    "label: '侵犯版权'": "localizationKey: 'reportReasonCopyright'",
    "label: '其他'": "localizationKey: 'reportReasonOther'",
}
for old, new in reason_keys.items():
    text = once(text, old, new, f'report reason {old}')
text = once(text, "    final colors = Theme.of(context).colorScheme;\n\n    return AlertDialog(\n      title: const Row(", "    final colors = Theme.of(context).colorScheme;\n    final l10n = AppLocalizations.of(context)!;\n\n    return AlertDialog(\n      title: Row(", 'report build')
text = text.replace("          Icon(Icons.flag_outlined, size: 22),\n          SizedBox(width: 10),\n          Text('举报帖子'),", "          const Icon(Icons.flag_outlined, size: 22),\n          const SizedBox(width: 10),\n          Text(l10n.get('reportPost')),")
text = text.replace("                '请选择举报原因',", "                l10n.get('chooseReportReason'),")
text = text.replace('                              option.label,', "                              l10n.get(option.localizationKey),")
text = once(text, "                decoration: const InputDecoration(\n                  labelText: '补充说明（可选）',\n                  hintText: '可以补充说明具体情况',\n                  alignLabelWithHint: true,\n                  border: OutlineInputBorder(),\n                ),", "                decoration: InputDecoration(\n                  labelText: l10n.get('reportDetailsLabel'),\n                  hintText: l10n.get('reportDetailsHint'),\n                  alignLabelWithHint: true,\n                  border: const OutlineInputBorder(),\n                ),", 'report details')
text = text.replace("                '举报提交后会进入管理员审核队列。',", "                l10n.get('reportReviewNotice'),")
text = text.replace("child: const Text('取消'),", "child: Text(l10n.cancel),")
text = text.replace("child: const Text('提交举报'),", "child: Text(l10n.get('submitReport')),")
write(path, text)


# User-to-user shared notes.
path = 'apps/mobile-flutter/lib/features/notes/presentation/screens/user_notes_screen.dart'
text = read(path)
text = once(text, "import 'package:provider/provider.dart';\n\n", "import 'package:provider/provider.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n", 'user notes import')
text = once(text, "  Future<String> _resolveOtherUserName() async {\n    final user = await", "  Future<String> _resolveOtherUserName() async {\n    final unknownUser = AppLocalizations.of(context)!.get('unknownUser');\n    final user = await", 'user notes fallback')
text = text.replace("return '未知用户';", 'return unknownUser;')
text = once(text, "  Widget build(BuildContext context) {\n    final initialName = widget.initialOtherUserName?.trim();", "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n    final initialName = widget.initialOtherUserName?.trim();", 'route build l10n')
text = text.replace("appBar: AppBar(title: const Text('共享笔记'))", "appBar: AppBar(title: Text(l10n.get('sharedNotes')))")
text = text.replace("const Text('无法加载用户资料')", "Text(l10n.get('profileLoadFailed'))")
text = text.replace("FilledButton(onPressed: _retry, child: const Text('重试'))", "FilledButton(onPressed: _retry, child: Text(l10n.get('retry')))")
text = text.replace("otherUserName: snapshot.data ?? '未知用户'", "otherUserName: snapshot.data ?? l10n.get('unknownUser')")
text = text.replace("SnackBar(content: Text('创建笔记失败：$error'), backgroundColor: Colors.red)", "SnackBar(\n          content: Text('${AppLocalizations.of(context)!.get('createNoteFailed')}: $error'),\n          backgroundColor: Colors.red,\n        )")
text = once(text, "  Widget build(BuildContext context) {\n    final currentUserId = _currentUserId;", "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n    final currentUserId = _currentUserId;", 'user notes screen build')
text = text.replace("body: const Center(child: Text('请先登录'))", "body: Center(child: Text(l10n.notLoggedIn))")
text = text.replace("backgroundColor: const Color(0xFFF4F4F4),", "backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,")
text = text.replace("          '${widget.otherUserName} · 笔记',", "          l10n.getWithArgs('notesWithUserTitle', {'name': widget.otherUserName}),")
text = text.replace("                  '加载笔记失败：${snapshot.error}',", "                  '${l10n.get('notesLoadFailed')}: ${snapshot.error}',")
text = text.replace("                    '还没有与 ${widget.otherUserName} 共享的笔记',", "                    l10n.getWithArgs('noSharedNotesWithUser', {\n                      'name': widget.otherUserName,\n                    }),")
text = text.replace("                  const Text(\n                    '点击右下角新建',\n                    style: TextStyle(fontSize: 13, color: Colors.grey),\n                  ),", "                  Text(\n                    l10n.get('tapFabToCreate'),\n                    style: const TextStyle(fontSize: 13, color: Colors.grey),\n                  ),")
text = text.replace("label: Text(_isCreating ? '正在创建' : '新建笔记')", "label: Text(\n          _isCreating ? l10n.get('creating') : l10n.get('newNote'),\n        )")
text = once(text, "  Widget _buildNoteCard({\n    required NoteModel note,\n    required String currentUserId,\n  }) {\n    final title", "  Widget _buildNoteCard({\n    required NoteModel note,\n    required String currentUserId,\n  }) {\n    final l10n = AppLocalizations.of(context)!;\n    final colorScheme = Theme.of(context).colorScheme;\n    final title", 'note card locals')
text = text.replace("title.isEmpty ? '无标题笔记' : title", "title.isEmpty ? l10n.get('untitledNote') : title")
text = text.replace("content.isEmpty ? '暂无内容' : content", "content.isEmpty ? l10n.get('noContent') : content")
text = text.replace(": const Color(0xFF666666),", ': colorScheme.onSurfaceVariant,')
text = text.replace("                          ? '由你创建'\n                          : '由 ${widget.otherUserName} 创建',", "                          ? l10n.get('createdByYou')\n                          : l10n.getWithArgs('createdByUser', {\n                              'name': widget.otherUserName,\n                            }),")
write(path, text)


# Birthday editor: localize and fix 2000-01-01 sentinel + invalid day rollover bugs.
path = 'apps/mobile-flutter/lib/features/profile/presentation/widgets/birthday_editor_dialog.dart'
text = read(path)
text = once(text, "import 'package:flutter/material.dart';\n", "import 'package:flutter/material.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n", 'birthday import')
text = once(text, "  bool tempShowAge = showAge;\n  int tempYear = birthday?.year ?? 2000;\n  int tempMonth = birthday?.month ?? 1;\n  int tempDay = birthday?.day ?? 1;\n", "  final l10n = AppLocalizations.of(context)!;\n  bool tempShowAge = showAge;\n  bool hasDate = birthday != null;\n  int tempYear = birthday?.year ?? 2000;\n  int tempMonth = birthday?.month ?? 1;\n  int tempDay = birthday?.day ?? 1;\n\n  void normalizeDay() {\n    final maxDay = DateUtils.getDaysInMonth(tempYear, tempMonth);\n    if (tempDay > maxDay) {\n      tempDay = maxDay;\n    }\n  }\n", 'birthday state')
text = text.replace("title: const Text(\n          '设置生日',\n          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),\n        )", "title: Text(\n          l10n.setBirthday,\n          style: const TextStyle(fontWeight: FontWeight.bold),\n        )")
text = text.replace("            const Text(\n              '选择你的出生日期',\n              style: TextStyle(color: Colors.grey, fontSize: 13),\n            )", "            Text(\n              l10n.selectBirthDate,\n              style: const TextStyle(color: Colors.grey, fontSize: 13),\n            )")
text = text.replace("                  tempYear == 2000 ? 'Y' : '$tempYear',", "                  hasDate ? '$tempYear' : 'Y',")
text = text.replace("                  (v) => setDialogState(() => tempYear = v),", "                  (v) => setDialogState(() {\n                    tempYear = v;\n                    hasDate = true;\n                    normalizeDay();\n                  }),")
text = text.replace("                const Text(\n                  '年',\n                  style: TextStyle(fontSize: 14, color: Colors.black87),\n                )", "                Text(l10n.year, style: const TextStyle(fontSize: 14))")
text = text.replace("                  tempMonth == 1 ? 'M' : '$tempMonth',", "                  hasDate ? '$tempMonth' : 'M',")
text = text.replace("                  (v) => setDialogState(() => tempMonth = v),", "                  (v) => setDialogState(() {\n                    tempMonth = v;\n                    hasDate = true;\n                    normalizeDay();\n                  }),")
text = text.replace("                const Text(\n                  '月',\n                  style: TextStyle(fontSize: 14, color: Colors.black87),\n                )", "                Text(l10n.month, style: const TextStyle(fontSize: 14))")
text = text.replace("                  tempDay == 1 ? 'D' : '$tempDay',\n                  31,", "                  hasDate ? '$tempDay' : 'D',\n                  DateUtils.getDaysInMonth(tempYear, tempMonth),")
text = text.replace("                  (v) => setDialogState(() => tempDay = v),", "                  (v) => setDialogState(() {\n                    tempDay = v;\n                    hasDate = true;\n                  }),")
text = text.replace("                const Text(\n                  '日',\n                  style: TextStyle(fontSize: 14, color: Colors.black87),\n                )", "                Text(l10n.day, style: const TextStyle(fontSize: 14))")
text = text.replace("                    tempYear = 2000;\n                    tempMonth = 1;\n                    tempDay = 1;", "                    hasDate = false;")
text = text.replace("                  child: const Text(\n                    '清除生日',\n                    style: TextStyle(color: Colors.red),\n                  )", "                  child: Text(\n                    l10n.clearBirthday,\n                    style: const TextStyle(color: Colors.red),\n                  )")
text = text.replace("              title: const Text('公开年龄', style: TextStyle(fontSize: 14)),\n              subtitle: const Text('关闭后仅自己可见', style: TextStyle(fontSize: 12)),", "              title: Text(l10n.showAge, style: const TextStyle(fontSize: 14)),\n              subtitle: Text(\n                l10n.showAgeDesc,\n                style: const TextStyle(fontSize: 12),\n              ),")
text = text.replace("child: const Text('取消', style: TextStyle(color: Colors.black87))", "child: Text(l10n.cancel)")
text = once(text, "              final date = DateTime(tempYear, tempMonth, tempDay);\n              Navigator.pop(\n                context,\n                BirthdayEditorResult(\n                  birthday: _isDefaultBirthday(date) ? null : date,", "              normalizeDay();\n              final date = DateTime(tempYear, tempMonth, tempDay);\n              Navigator.pop(\n                context,\n                BirthdayEditorResult(\n                  birthday: hasDate ? date : null,", 'birthday save')
text = text.replace("            child: const Text(\n              '保存',\n              style: TextStyle(fontWeight: FontWeight.bold),\n            )", "            child: Text(\n              l10n.save,\n              style: const TextStyle(fontWeight: FontWeight.bold),\n            )")
text = text.replace("            style: const TextStyle(fontSize: 14, color: Colors.black87),", "            style: const TextStyle(fontSize: 14),")
start = text.find('\nbool _isDefaultBirthday(')
if start != -1:
    text = text[:start] + '\n'
write(path, text)


# Recommended feed empty states.
path = 'apps/mobile-flutter/lib/features/home/presentation/widgets/recommended_posts_view.dart'
text = read(path)
text = once(text, "import 'package:provider/provider.dart';\n\n", "import 'package:provider/provider.dart';\n\nimport '../../../../app/l10n/app_localizations.dart';\n", 'recommended import')
text = once(text, "    final authProvider = context.watch<auth_cubit.AuthCubit>();\n\n    if", "    final authProvider = context.watch<auth_cubit.AuthCubit>();\n    final l10n = AppLocalizations.of(context)!;\n\n    if", 'recommended l10n')
text = text.replace("return const _InterestEmptyState(\n        icon: Icons.login_rounded,\n        title: '登录后使用推荐主页',\n        description: '登录后可以选择感兴趣的语言频道和分类。',\n      );", "return _InterestEmptyState(\n        icon: Icons.login_rounded,\n        title: l10n.get('recommendedLoginTitle'),\n        description: l10n.get('recommendedLoginDescription'),\n      );")
text = text.replace("title: '兴趣加载失败',\n          description: '无法加载你的兴趣设置，请检查网络或后端连接后重试。',\n          actionLabel: '重试',", "title: l10n.get('interestsLoadFailed'),\n          description: l10n.get('interestsLoadFailedDescription'),\n          actionLabel: l10n.get('retry'),")
text = text.replace("return const _InterestEmptyState(\n        icon: Icons.favorite_border_rounded,\n        title: '还没有感兴趣的分类',\n        description: '进入分类频道，选择一个语言，再点击分类右侧的心形。',\n      );", "return _InterestEmptyState(\n        icon: Icons.favorite_border_rounded,\n        title: l10n.get('noInterestsTitle'),\n        description: l10n.get('noInterestsDescription'),\n      );")
text = once(text, "  Widget build(BuildContext context) {\n    if (_isLoading", "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context)!;\n\n    if (_isLoading", 'recommended list l10n')
text = text.replace("title: '帖子加载失败',", "title: l10n.get('postsLoadFailed'),")
text = text.replace("child: const _InterestEmptyState(\n          icon: Icons.inbox_outlined,\n          title: '这些兴趣暂时没有帖子',\n          description:\n              '已选择的语言频道和分类中，目前还没有可显示的内容。\\n'\n              '你也可以下拉重新加载。',\n        )", "child: _InterestEmptyState(\n          icon: Icons.inbox_outlined,\n          title: l10n.get('noRecommendedPostsTitle'),\n          description: l10n.get('noRecommendedPostsDescription'),\n        )")
write(path, text)


# Discover screen + main FAB tooltip.
path = 'apps/mobile-flutter/lib/features/discover/presentation/screens/discover_screen.dart'
text = read(path)
text = text.replace("content: Text('${l10n.startChat}失败：$error')", "content: Text('${l10n.createChatFailed}: $error')")
text = once(text, "      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text('已向 ${user.displayName} 发送好友请求'),", "      final l10n = AppLocalizations.of(context)!;\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text(\n            l10n.getWithArgs('friendRequestSentTo', {'name': user.displayName}),\n          ),", 'discover friend sent')
text = once(text, "      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(content: Text('发送好友请求失败：$error'), backgroundColor: Colors.red),\n      );", "      final l10n = AppLocalizations.of(context)!;\n      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(\n          content: Text('${l10n.get('friendRequestSendFailed')}: $error'),\n          backgroundColor: Colors.red,\n        ),\n      );", 'discover friend failure')
text = text.replace("body: const Center(child: Text('请先登录'))", "body: Center(child: Text(l10n.notLoggedIn))")
text = text.replace("subtitle: '还没有其他用户，邀请朋友加入吧',", "subtitle: l10n.get('inviteFriendsPrompt'),")
write(path, text)

path = 'apps/mobile-flutter/lib/features/home/presentation/screens/main_navigation_screen.dart'
text = read(path).replace("tooltip: '发现用户',", 'tooltip: l10n.discover,')
write(path, text)


translations = {
'en': {
'unknownTime':'Unknown time','postEditHistory':'Edit history','noEditHistory':'No edit history','unknownLanguage':'Unknown language','languageValue':'Language: {language}','historyVersion':'Historical version','retry':'Retry','sendFailed':'Send failed','commentLoadFailed':'Comments failed to load','noCommentsYet':'No comments yet. Start the conversation.','replyHint':'Write a reply...','commentHint':'Write a comment...','reportPost':'Report post','chooseReportReason':'Choose a reason for reporting','reportReasonSpam':'Spam or advertising','reportReasonHarassment':'Harassment or bullying','reportReasonHate':'Hate speech','reportReasonSexual':'Sexual content','reportReasonViolence':'Violence or dangerous content','reportReasonMisinformation':'False or misleading information','reportReasonCopyright':'Copyright infringement','reportReasonOther':'Other','reportDetailsLabel':'Additional details (optional)','reportDetailsHint':'Add any details that may help','reportReviewNotice':'Submitted reports are sent to the moderation queue.','submitReport':'Submit report','sharedNotes':'Shared notes','profileLoadFailed':'Could not load user profile','notesWithUserTitle':'{name} · Notes','createNoteFailed':'Could not create note','notesLoadFailed':'Could not load notes','noSharedNotesWithUser':'No notes shared with {name} yet','tapFabToCreate':'Use the create button to start a new note.','creating':'Creating...','newNote':'New note','untitledNote':'Untitled note','noContent':'No content','createdByYou':'Created by you','createdByUser':'Created by {name}','recommendedLoginTitle':'Sign in to use recommendations','recommendedLoginDescription':'After signing in, choose the language channels and topics you care about.','interestsLoadFailed':'Could not load interests','interestsLoadFailedDescription':'Your interest settings could not be loaded. Check your connection and try again.','noInterestsTitle':'No interests selected yet','noInterestsDescription':'Open Categories, choose a language, then tap the heart beside a topic.','postsLoadFailed':'Could not load posts','noRecommendedPostsTitle':'No posts for these interests yet','noRecommendedPostsDescription':'There is no content in your selected language channels and topics yet. Pull down to refresh.','friendRequestSentTo':'Friend request sent to {name}','friendRequestSendFailed':'Could not send friend request','inviteFriendsPrompt':'No other users yet. Invite friends to join.'},
'zh': {
'unknownTime':'时间未知','postEditHistory':'编辑历史','noEditHistory':'暂无编辑历史','unknownLanguage':'语言未知','languageValue':'语言：{language}','historyVersion':'历史版本','retry':'重试','sendFailed':'发送失败','commentLoadFailed':'评论加载失败','noCommentsYet':'暂无评论，来发表第一条评论吧','replyHint':'回复内容...','commentHint':'说点什么吧...','reportPost':'举报帖子','chooseReportReason':'请选择举报原因','reportReasonSpam':'垃圾信息或广告','reportReasonHarassment':'骚扰或欺凌','reportReasonHate':'仇恨言论','reportReasonSexual':'色情或性内容','reportReasonViolence':'暴力或危险内容','reportReasonMisinformation':'虚假或误导信息','reportReasonCopyright':'侵犯版权','reportReasonOther':'其他','reportDetailsLabel':'补充说明（可选）','reportDetailsHint':'可以补充说明具体情况','reportReviewNotice':'举报提交后会进入管理员审核队列。','submitReport':'提交举报','sharedNotes':'共享笔记','profileLoadFailed':'无法加载用户资料','notesWithUserTitle':'{name} · 笔记','createNoteFailed':'创建笔记失败','notesLoadFailed':'加载笔记失败','noSharedNotesWithUser':'还没有与 {name} 共享的笔记','tapFabToCreate':'点击创建按钮新建笔记','creating':'正在创建','newNote':'新建笔记','untitledNote':'无标题笔记','noContent':'暂无内容','createdByYou':'由你创建','createdByUser':'由 {name} 创建','recommendedLoginTitle':'登录后使用推荐主页','recommendedLoginDescription':'登录后可以选择感兴趣的语言频道和分类。','interestsLoadFailed':'兴趣加载失败','interestsLoadFailedDescription':'无法加载你的兴趣设置，请检查网络或后端连接后重试。','noInterestsTitle':'还没有感兴趣的分类','noInterestsDescription':'进入分类频道，选择一个语言，再点击分类右侧的心形。','postsLoadFailed':'帖子加载失败','noRecommendedPostsTitle':'这些兴趣暂时没有帖子','noRecommendedPostsDescription':'已选择的语言频道和分类中，目前还没有可显示的内容。下拉即可重新加载。','friendRequestSentTo':'已向 {name} 发送好友请求','friendRequestSendFailed':'发送好友请求失败','inviteFriendsPrompt':'还没有其他用户，邀请朋友加入吧'},
'ja': {
'unknownTime':'時刻不明','postEditHistory':'編集履歴','noEditHistory':'編集履歴はありません','unknownLanguage':'言語不明','languageValue':'言語：{language}','historyVersion':'過去のバージョン','retry':'再試行','sendFailed':'送信に失敗しました','commentLoadFailed':'コメントを読み込めませんでした','noCommentsYet':'コメントはまだありません。最初のコメントを投稿しましょう。','replyHint':'返信を入力...','commentHint':'コメントを書く...','reportPost':'投稿を報告','chooseReportReason':'報告理由を選択してください','reportReasonSpam':'スパムまたは広告','reportReasonHarassment':'嫌がらせ・いじめ','reportReasonHate':'ヘイトスピーチ','reportReasonSexual':'性的なコンテンツ','reportReasonViolence':'暴力・危険なコンテンツ','reportReasonMisinformation':'虚偽・誤解を招く情報','reportReasonCopyright':'著作権侵害','reportReasonOther':'その他','reportDetailsLabel':'補足説明（任意）','reportDetailsHint':'必要に応じて詳しい状況を入力してください','reportReviewNotice':'送信された報告はモデレーションキューで確認されます。','submitReport':'報告を送信','sharedNotes':'共有ノート','profileLoadFailed':'ユーザープロフィールを読み込めませんでした','notesWithUserTitle':'{name} · ノート','createNoteFailed':'ノートを作成できませんでした','notesLoadFailed':'ノートを読み込めませんでした','noSharedNotesWithUser':'{name} さんと共有しているノートはまだありません','tapFabToCreate':'作成ボタンから新しいノートを作成できます。','creating':'作成中...','newNote':'新しいノート','untitledNote':'無題のノート','noContent':'内容なし','createdByYou':'あなたが作成','createdByUser':'{name} さんが作成','recommendedLoginTitle':'ログインしておすすめを利用','recommendedLoginDescription':'ログイン後、興味のある言語チャンネルとトピックを選べます。','interestsLoadFailed':'興味を読み込めませんでした','interestsLoadFailedDescription':'興味設定を読み込めませんでした。接続を確認して再試行してください。','noInterestsTitle':'興味がまだ選択されていません','noInterestsDescription':'カテゴリを開き、言語を選んでトピック横のハートをタップしてください。','postsLoadFailed':'投稿を読み込めませんでした','noRecommendedPostsTitle':'この興味に合う投稿はまだありません','noRecommendedPostsDescription':'選択した言語チャンネルとトピックには、まだ表示できる内容がありません。下に引いて更新できます。','friendRequestSentTo':'{name} さんに友達申請を送信しました','friendRequestSendFailed':'友達申請を送信できませんでした','inviteFriendsPrompt':'他のユーザーはまだいません。友達を招待しましょう。'},
'ko': {
'unknownTime':'시간 알 수 없음','postEditHistory':'수정 기록','noEditHistory':'수정 기록이 없습니다','unknownLanguage':'언어 알 수 없음','languageValue':'언어: {language}','historyVersion':'이전 버전','retry':'다시 시도','sendFailed':'전송 실패','commentLoadFailed':'댓글을 불러오지 못했습니다','noCommentsYet':'아직 댓글이 없습니다. 첫 댓글을 남겨 보세요.','replyHint':'답글 입력...','commentHint':'댓글을 작성하세요...','reportPost':'게시물 신고','chooseReportReason':'신고 사유를 선택하세요','reportReasonSpam':'스팸 또는 광고','reportReasonHarassment':'괴롭힘 또는 따돌림','reportReasonHate':'혐오 발언','reportReasonSexual':'성적인 콘텐츠','reportReasonViolence':'폭력 또는 위험한 콘텐츠','reportReasonMisinformation':'거짓 또는 오해를 부르는 정보','reportReasonCopyright':'저작권 침해','reportReasonOther':'기타','reportDetailsLabel':'추가 설명 (선택)','reportDetailsHint':'도움이 될 세부 정보를 입력하세요','reportReviewNotice':'제출된 신고는 관리자 검토 대기열로 전송됩니다.','submitReport':'신고 제출','sharedNotes':'공유 노트','profileLoadFailed':'사용자 프로필을 불러오지 못했습니다','notesWithUserTitle':'{name} · 노트','createNoteFailed':'노트를 만들지 못했습니다','notesLoadFailed':'노트를 불러오지 못했습니다','noSharedNotesWithUser':'{name}님과 공유한 노트가 아직 없습니다','tapFabToCreate':'만들기 버튼으로 새 노트를 시작하세요.','creating':'만드는 중...','newNote':'새 노트','untitledNote':'제목 없는 노트','noContent':'내용 없음','createdByYou':'내가 만듦','createdByUser':'{name}님이 만듦','recommendedLoginTitle':'로그인하고 추천 사용하기','recommendedLoginDescription':'로그인 후 관심 있는 언어 채널과 주제를 선택할 수 있습니다.','interestsLoadFailed':'관심사를 불러오지 못했습니다','interestsLoadFailedDescription':'관심사 설정을 불러오지 못했습니다. 연결을 확인하고 다시 시도하세요.','noInterestsTitle':'아직 선택한 관심사가 없습니다','noInterestsDescription':'카테고리에서 언어를 고른 뒤 주제 옆 하트를 눌러 주세요.','postsLoadFailed':'게시물을 불러오지 못했습니다','noRecommendedPostsTitle':'이 관심사에는 아직 게시물이 없습니다','noRecommendedPostsDescription':'선택한 언어 채널과 주제에 아직 표시할 콘텐츠가 없습니다. 아래로 당겨 새로고침할 수 있습니다.','friendRequestSentTo':'{name}님에게 친구 요청을 보냈습니다','friendRequestSendFailed':'친구 요청을 보내지 못했습니다','inviteFriendsPrompt':'아직 다른 사용자가 없습니다. 친구를 초대해 보세요.'},
'ms': {
'unknownTime':'Masa tidak diketahui','postEditHistory':'Sejarah suntingan','noEditHistory':'Tiada sejarah suntingan','unknownLanguage':'Bahasa tidak diketahui','languageValue':'Bahasa: {language}','historyVersion':'Versi terdahulu','retry':'Cuba lagi','sendFailed':'Gagal menghantar','commentLoadFailed':'Komen gagal dimuatkan','noCommentsYet':'Belum ada komen. Jadilah yang pertama memberi komen.','replyHint':'Tulis balasan...','commentHint':'Tulis komen...','reportPost':'Laporkan siaran','chooseReportReason':'Pilih sebab laporan','reportReasonSpam':'Spam atau iklan','reportReasonHarassment':'Gangguan atau buli','reportReasonHate':'Ucapan kebencian','reportReasonSexual':'Kandungan seksual','reportReasonViolence':'Keganasan atau kandungan berbahaya','reportReasonMisinformation':'Maklumat palsu atau mengelirukan','reportReasonCopyright':'Pelanggaran hak cipta','reportReasonOther':'Lain-lain','reportDetailsLabel':'Butiran tambahan (pilihan)','reportDetailsHint':'Tambah butiran yang boleh membantu','reportReviewNotice':'Laporan yang dihantar akan masuk ke giliran semakan moderator.','submitReport':'Hantar laporan','sharedNotes':'Nota dikongsi','profileLoadFailed':'Profil pengguna gagal dimuatkan','notesWithUserTitle':'{name} · Nota','createNoteFailed':'Nota gagal dicipta','notesLoadFailed':'Nota gagal dimuatkan','noSharedNotesWithUser':'Belum ada nota yang dikongsi dengan {name}','tapFabToCreate':'Gunakan butang cipta untuk memulakan nota baharu.','creating':'Mencipta...','newNote':'Nota baharu','untitledNote':'Nota tanpa tajuk','noContent':'Tiada kandungan','createdByYou':'Dicipta oleh anda','createdByUser':'Dicipta oleh {name}','recommendedLoginTitle':'Log masuk untuk menggunakan cadangan','recommendedLoginDescription':'Selepas log masuk, pilih saluran bahasa dan topik yang anda minati.','interestsLoadFailed':'Minat gagal dimuatkan','interestsLoadFailedDescription':'Tetapan minat anda gagal dimuatkan. Semak sambungan dan cuba lagi.','noInterestsTitle':'Belum memilih minat','noInterestsDescription':'Buka Kategori, pilih bahasa, kemudian tekan ikon hati di sebelah topik.','postsLoadFailed':'Siaran gagal dimuatkan','noRecommendedPostsTitle':'Belum ada siaran untuk minat ini','noRecommendedPostsDescription':'Belum ada kandungan dalam saluran bahasa dan topik yang dipilih. Tarik ke bawah untuk memuat semula.','friendRequestSentTo':'Permintaan rakan dihantar kepada {name}','friendRequestSendFailed':'Permintaan rakan gagal dihantar','inviteFriendsPrompt':'Belum ada pengguna lain. Jemput rakan untuk menyertai.'},
'vi': {
'unknownTime':'Không rõ thời gian','postEditHistory':'Lịch sử chỉnh sửa','noEditHistory':'Chưa có lịch sử chỉnh sửa','unknownLanguage':'Không rõ ngôn ngữ','languageValue':'Ngôn ngữ: {language}','historyVersion':'Phiên bản trước','retry':'Thử lại','sendFailed':'Gửi thất bại','commentLoadFailed':'Tải bình luận thất bại','noCommentsYet':'Chưa có bình luận. Hãy để lại bình luận đầu tiên.','replyHint':'Viết trả lời...','commentHint':'Viết bình luận...','reportPost':'Báo cáo bài viết','chooseReportReason':'Chọn lý do báo cáo','reportReasonSpam':'Spam hoặc quảng cáo','reportReasonHarassment':'Quấy rối hoặc bắt nạt','reportReasonHate':'Ngôn từ thù ghét','reportReasonSexual':'Nội dung tình dục','reportReasonViolence':'Bạo lực hoặc nội dung nguy hiểm','reportReasonMisinformation':'Thông tin sai hoặc gây hiểu lầm','reportReasonCopyright':'Vi phạm bản quyền','reportReasonOther':'Khác','reportDetailsLabel':'Thông tin bổ sung (không bắt buộc)','reportDetailsHint':'Thêm chi tiết nếu cần','reportReviewNotice':'Báo cáo đã gửi sẽ được đưa vào hàng đợi kiểm duyệt.','submitReport':'Gửi báo cáo','sharedNotes':'Ghi chú chia sẻ','profileLoadFailed':'Không thể tải hồ sơ người dùng','notesWithUserTitle':'{name} · Ghi chú','createNoteFailed':'Tạo ghi chú thất bại','notesLoadFailed':'Tải ghi chú thất bại','noSharedNotesWithUser':'Chưa có ghi chú nào được chia sẻ với {name}','tapFabToCreate':'Dùng nút tạo để bắt đầu ghi chú mới.','creating':'Đang tạo...','newNote':'Ghi chú mới','untitledNote':'Ghi chú không tiêu đề','noContent':'Chưa có nội dung','createdByYou':'Do bạn tạo','createdByUser':'Do {name} tạo','recommendedLoginTitle':'Đăng nhập để dùng mục đề xuất','recommendedLoginDescription':'Sau khi đăng nhập, bạn có thể chọn kênh ngôn ngữ và chủ đề mình quan tâm.','interestsLoadFailed':'Tải sở thích thất bại','interestsLoadFailedDescription':'Không thể tải cài đặt sở thích. Hãy kiểm tra kết nối và thử lại.','noInterestsTitle':'Chưa chọn sở thích','noInterestsDescription':'Mở Danh mục, chọn một ngôn ngữ rồi nhấn biểu tượng trái tim bên cạnh chủ đề.','postsLoadFailed':'Tải bài viết thất bại','noRecommendedPostsTitle':'Chưa có bài viết cho các sở thích này','noRecommendedPostsDescription':'Hiện chưa có nội dung trong các kênh ngôn ngữ và chủ đề đã chọn. Kéo xuống để tải lại.','friendRequestSentTo':'Đã gửi lời mời kết bạn tới {name}','friendRequestSendFailed':'Gửi lời mời kết bạn thất bại','inviteFriendsPrompt':'Chưa có người dùng khác. Hãy mời bạn bè tham gia.'},
'th': {
'unknownTime':'ไม่ทราบเวลา','postEditHistory':'ประวัติการแก้ไข','noEditHistory':'ยังไม่มีประวัติการแก้ไข','unknownLanguage':'ไม่ทราบภาษา','languageValue':'ภาษา: {language}','historyVersion':'เวอร์ชันก่อนหน้า','retry':'ลองอีกครั้ง','sendFailed':'ส่งไม่สำเร็จ','commentLoadFailed':'โหลดความคิดเห็นไม่สำเร็จ','noCommentsYet':'ยังไม่มีความคิดเห็น มาเป็นคนแรกที่แสดงความคิดเห็นกัน','replyHint':'เขียนคำตอบ...','commentHint':'เขียนความคิดเห็น...','reportPost':'รายงานโพสต์','chooseReportReason':'เลือกเหตุผลในการรายงาน','reportReasonSpam':'สแปมหรือโฆษณา','reportReasonHarassment':'การคุกคามหรือกลั่นแกล้ง','reportReasonHate':'ถ้อยคำแสดงความเกลียดชัง','reportReasonSexual':'เนื้อหาทางเพศ','reportReasonViolence':'ความรุนแรงหรือเนื้อหาอันตราย','reportReasonMisinformation':'ข้อมูลเท็จหรือทำให้เข้าใจผิด','reportReasonCopyright':'ละเมิดลิขสิทธิ์','reportReasonOther':'อื่น ๆ','reportDetailsLabel':'รายละเอียดเพิ่มเติม (ไม่บังคับ)','reportDetailsHint':'เพิ่มรายละเอียดที่อาจช่วยในการตรวจสอบ','reportReviewNotice':'รายงานที่ส่งจะเข้าสู่คิวตรวจสอบของผู้ดูแล','submitReport':'ส่งรายงาน','sharedNotes':'โน้ตที่แชร์','profileLoadFailed':'โหลดโปรไฟล์ผู้ใช้ไม่สำเร็จ','notesWithUserTitle':'{name} · โน้ต','createNoteFailed':'สร้างโน้ตไม่สำเร็จ','notesLoadFailed':'โหลดโน้ตไม่สำเร็จ','noSharedNotesWithUser':'ยังไม่มีโน้ตที่แชร์กับ {name}','tapFabToCreate':'ใช้ปุ่มสร้างเพื่อเริ่มโน้ตใหม่','creating':'กำลังสร้าง...','newNote':'โน้ตใหม่','untitledNote':'โน้ตไม่มีชื่อ','noContent':'ไม่มีเนื้อหา','createdByYou':'สร้างโดยคุณ','createdByUser':'สร้างโดย {name}','recommendedLoginTitle':'เข้าสู่ระบบเพื่อใช้คำแนะนำ','recommendedLoginDescription':'หลังเข้าสู่ระบบ คุณสามารถเลือกช่องภาษาและหัวข้อที่สนใจได้','interestsLoadFailed':'โหลดความสนใจไม่สำเร็จ','interestsLoadFailedDescription':'ไม่สามารถโหลดการตั้งค่าความสนใจได้ โปรดตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง','noInterestsTitle':'ยังไม่ได้เลือกความสนใจ','noInterestsDescription':'เปิดหมวดหมู่ เลือกภาษา แล้วแตะหัวใจข้างหัวข้อ','postsLoadFailed':'โหลดโพสต์ไม่สำเร็จ','noRecommendedPostsTitle':'ยังไม่มีโพสต์สำหรับความสนใจเหล่านี้','noRecommendedPostsDescription':'ยังไม่มีเนื้อหาในช่องภาษาและหัวข้อที่เลือก ดึงลงเพื่อรีเฟรชได้','friendRequestSentTo':'ส่งคำขอเป็นเพื่อนถึง {name} แล้ว','friendRequestSendFailed':'ส่งคำขอเป็นเพื่อนไม่สำเร็จ','inviteFriendsPrompt':'ยังไม่มีผู้ใช้อื่น ลองชวนเพื่อนเข้าร่วม'}
}

for code, values in translations.items():
    locale_path = APP / 'assets' / 'l10n' / f'{code}.json'
    data = json.loads(locale_path.read_text(encoding='utf-8'))
    data.update(values)
    locale_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

print('Applied post, note, birthday, recommendation, and discover localization sweep.')
