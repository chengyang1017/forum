from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / 'apps' / 'mobile-flutter'


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')


def write(rel: str, text: str) -> None:
    (ROOT / rel).write_text(text, encoding='utf-8')


def rep(text: str, old: str, new: str, label: str | None = None) -> str:
    if old not in text:
        raise RuntimeError(f'missing marker: {label or old[:80]}')
    return text.replace(old, new)


# ---------------------------------------------------------------------------
# All notes screen
# ---------------------------------------------------------------------------
path = 'apps/mobile-flutter/lib/features/notes/presentation/screens/all_notes_screen.dart'
text = read(path)

replacements = [
    ("return '全部语言';", "return AppLocalizations.of(context)!.get('allLanguages');"),
    ("return '未指定语言';", "return AppLocalizations.of(context)!.get('unspecifiedLanguage');"),
    ("return '未选择';", "return AppLocalizations.of(context)!.get('notSelected');"),
    ("return '全部分类';", "return AppLocalizations.of(context)!.get('allCategories');"),
    ("return '未分类';", "return AppLocalizations.of(context)!.get('uncategorized');"),
    ("SnackBar(content: Text('加载用户失败：$error'), backgroundColor: Colors.red)", "SnackBar(content: Text(AppLocalizations.of(context)!.get('usersLoadFailed')), backgroundColor: Colors.red)"),
    ("SnackBar(content: Text('创建笔记失败：$error'), backgroundColor: Colors.red)", "SnackBar(content: Text(AppLocalizations.of(context)!.get('createNoteFailed')), backgroundColor: Colors.red)"),
    ("appBar: AppBar(title: const Text('我的笔记'))", "appBar: AppBar(title: Text(AppLocalizations.of(context)!.get('myNotes')))"),
    ("body: const Center(child: Text('请先登录'))", "body: Center(child: Text(AppLocalizations.of(context)!.get('pleaseSignIn')))"),
    ("title: const Text('我的笔记'),", "title: Text(AppLocalizations.of(context)!.get('myNotes')),"),
    ("TextButton(onPressed: _clearFilters, child: const Text('清除'))", "TextButton(onPressed: _clearFilters, child: Text(AppLocalizations.of(context)!.get('clear')))"),
    ("const Text(\n                      '笔记加载失败',", "Text(\n                      AppLocalizations.of(context)!.get('notesLoadFailed'),"),
    ("Text(\n                      '${snapshot.error}',\n                      textAlign: TextAlign.center,\n                      style: const TextStyle(color: Colors.grey),\n                    ),", "Text(\n                      AppLocalizations.of(context)!.get('notesLoadFailedDescription'),\n                      textAlign: TextAlign.center,\n                      style: const TextStyle(color: Colors.grey),\n                    ),"),
    ("label: Text(_isCreating ? '正在创建' : '新建笔记'),", "label: Text(_isCreating ? AppLocalizations.of(context)!.get('creating') : AppLocalizations.of(context)!.get('newNote')),"),
    ("_hasActiveFilter ? '没有符合条件的笔记' : '还没有笔记',", "_hasActiveFilter ? AppLocalizations.of(context)!.get('noMatchingNotes') : AppLocalizations.of(context)!.get('noNotesYet'),"),
    ("TextButton(onPressed: _clearFilters, child: const Text('清除筛选'))", "TextButton(onPressed: _clearFilters, child: Text(AppLocalizations.of(context)!.get('clearFilters')))"),
    ("const Text(\n                '点击右下角新建',", "Text(\n                AppLocalizations.of(context)!.get('tapFabToCreateNote'),"),
    ("title.isEmpty ? '无标题笔记' : title,", "title.isEmpty ? AppLocalizations.of(context)!.get('untitledNote') : title,"),
    ("content.isEmpty ? '暂无内容' : content,", "content.isEmpty ? AppLocalizations.of(context)!.get('noContent') : content,"),
    ("return '仅自己可见';", "return AppLocalizations.of(context)!.get('onlyMeVisible');"),
    ("_usersById[userId]?.name ?? '用户'", "_usersById[userId]?.name ?? AppLocalizations.of(context)!.get('unknownUser')"),
    ("return '与 ${names.first} 共享';", "return AppLocalizations.of(context)!.getWithArgs('sharedWithOne', {'name': names.first});"),
    ("return '与 ${names.join('、')} 共享';", "return AppLocalizations.of(context)!.getWithArgs('sharedWithTwo', {'names': names.join(' · ')});"),
    ("return '与 ${names.take(2).join('、')} 等 '\n        '${names.length} 人共享';", "return AppLocalizations.of(context)!.getWithArgs(\n      'sharedWithMany',\n      {'names': names.take(2).join(' · '), 'count': '${names.length}'},\n    );"),
]
for old, new in replacements:
    text = rep(text, old, new)

# Picker/config labels: replace only literal UI occurrences; comments/debug remain untouched.
text = text.replace("Text(\n                        '选择语言',", "Text(\n                        AppLocalizations.of(context)!.get('selectLanguage'),")
text = text.replace("title: const Text('全部语言'),", "title: Text(AppLocalizations.of(context)!.get('allLanguages')),")
text = text.replace("title: const Text('未指定语言'),", "title: Text(AppLocalizations.of(context)!.get('unspecifiedLanguage')),")
text = text.replace("Text(\n                        '选择分类',", "Text(\n                        AppLocalizations.of(context)!.get('selectCategory'),")
text = text.replace("title: const Text('全部分类'),", "title: Text(AppLocalizations.of(context)!.get('allCategories')),")
text = text.replace("title: const Text('未分类'),", "title: Text(AppLocalizations.of(context)!.get('uncategorized')),")
text = text.replace("Text(\n                        '笔记语言',", "Text(\n                        AppLocalizations.of(context)!.get('noteLanguage'),")
text = text.replace("title: const Text('未选择'),", "title: Text(AppLocalizations.of(context)!.get('notSelected')),")
text = text.replace("Text(\n                        '笔记分类',", "Text(\n                        AppLocalizations.of(context)!.get('noteCategory'),")
text = text.replace("child: Text(\n                        '新建笔记',", "child: Text(\n                        AppLocalizations.of(context)!.get('newNote'),")
text = text.replace("child: Text(\n                        '可以先设置笔记信息，也可以以后再修改。',", "child: Text(\n                        AppLocalizations.of(context)!.get('newNoteSetupDescription'),")
text = text.replace("title: '语言',", "title: AppLocalizations.of(context)!.get('languageLabel'),")
text = text.replace("title: '分类',", "title: AppLocalizations.of(context)!.get('categoryLabel'),")
text = text.replace("title: '共享',", "title: AppLocalizations.of(context)!.get('shareLabel'),")
text = text.replace("? '仅自己'", "? AppLocalizations.of(context)!.get('onlyMe')")
text = text.replace(" : '已选择 '\n                                      '${sharedUserIds.length} 人',", " : AppLocalizations.of(context)!.getWithArgs(\n                                      'selectedPeople',\n                                      {'count': '${sharedUserIds.length}'},\n                                    ),")
text = text.replace("label: const Text('创建笔记'),", "label: Text(AppLocalizations.of(context)!.get('createNote')),")
text = text.replace("const Text(\n                    '语言',", "Text(\n                    AppLocalizations.of(context)!.get('languageLabel'),")
text = text.replace("const Text(\n                    '分类',", "Text(\n                    AppLocalizations.of(context)!.get('categoryLabel'),")

# Shared-user picker is a separate State and still has a BuildContext.
text = text.replace("const Expanded(\n                    child: Text(\n                      '共享成员',", "Expanded(\n                    child: Text(\n                      AppLocalizations.of(context)!.get('sharedMembers'),")
text = text.replace("child: const Text('完成'),", "child: Text(AppLocalizations.of(context)!.get('done')),")
text = text.replace("hintText: '搜索昵称或用户名',", "hintText: AppLocalizations.of(context)!.get('searchNicknameOrUsername'),")
text = text.replace("? const Center(child: Text('没有找到用户'))", "? Center(child: Text(AppLocalizations.of(context)!.get('noUsersFound')))")

# Model factory fallbacks cannot access BuildContext. Prefer real username, then a language-neutral marker.
text = text.replace("name: name.isEmpty ? '用户' : name,\n      username: user.username.trim(),", "name: name.isEmpty\n          ? (user.username.trim().isEmpty ? '?' : user.username.trim())\n          : name,\n      username: user.username.trim(),")

write(path, text)


# ---------------------------------------------------------------------------
# Note editor screen
# ---------------------------------------------------------------------------
path = 'apps/mobile-flutter/lib/features/notes/presentation/screens/note_editor_screen.dart'
text = read(path)

pairs = [
    ("SnackBar(content: Text('加载笔记失败：$error'), backgroundColor: Colors.red)", "SnackBar(content: Text(AppLocalizations.of(context)!.get('notesLoadFailed')), backgroundColor: Colors.red)"),
    ("SnackBar(content: Text('保存失败：$error'), backgroundColor: Colors.red)", "SnackBar(content: Text(AppLocalizations.of(context)!.get('saveFailed')), backgroundColor: Colors.red)"),
    ("SnackBar(content: Text('权限设置失败：$error'), backgroundColor: Colors.red)", "SnackBar(content: Text(AppLocalizations.of(context)!.get('permissionUpdateFailed')), backgroundColor: Colors.red)"),
    ("SnackBar(content: Text('更新共享成员失败：$error'), backgroundColor: Colors.red)", "SnackBar(content: Text(AppLocalizations.of(context)!.get('sharedMembersUpdateFailed')), backgroundColor: Colors.red)"),
    ("const SnackBar(content: Text('创建者没有开放编辑权限'))", "SnackBar(content: Text(AppLocalizations.of(context)!.get('editingNotAllowed')))"),
    ("const SnackBar(content: Text('每条笔记最多插入 9 张图片'))", "SnackBar(content: Text(AppLocalizations.of(context)!.getWithArgs('noteImageLimit', {'count': '9'})))"),
    ("SnackBar(content: Text('插入图片失败：$error'), backgroundColor: Colors.red)", "SnackBar(content: Text(AppLocalizations.of(context)!.get('insertImageFailed')), backgroundColor: Colors.red)"),
    ("return '未选择';", "return AppLocalizations.of(context)!.get('notSelected');"),
    ("SnackBar(content: Text('修改分类失败：$error'), backgroundColor: Colors.red)", "SnackBar(content: Text(AppLocalizations.of(context)!.get('categoryUpdateFailed')), backgroundColor: Colors.red)"),
    ("content: Text('笔记已发布为帖子'),", "content: Text(AppLocalizations.of(context)!.get('notePublishedAsPost')),"),
    ("SnackBar(content: Text('删除失败：$error'), backgroundColor: Colors.red)", "SnackBar(content: Text(AppLocalizations.of(context)!.get('deleteNoteFailed')), backgroundColor: Colors.red)"),
    ("appBar: AppBar(title: const Text('共享笔记'))", "appBar: AppBar(title: Text(AppLocalizations.of(context)!.get('sharedNotes')))"),
    ("body: const Center(child: Text('请先登录'))", "body: Center(child: Text(AppLocalizations.of(context)!.get('pleaseSignIn')))"),
    ("body: const Center(child: Text('这条笔记已被删除'))", "body: Center(child: Text(AppLocalizations.of(context)!.get('noteDeleted')))"),
    ("title: const Text('共享笔记'),", "title: Text(AppLocalizations.of(context)!.get('sharedNotes')),"),
    ("tooltip: '插入图片',", "tooltip: AppLocalizations.of(context)!.get('insertImage'),"),
    ("tooltip: '笔记设置',", "tooltip: AppLocalizations.of(context)!.get('noteSettings'),"),
    ("hintText: '笔记标题',", "hintText: AppLocalizations.of(context)!.get('noteTitleHint'),"),
    ("placeholder: '输入笔记内容……',", "placeholder: AppLocalizations.of(context)!.get('noteContentHint'),"),
]
for old, new in pairs:
    text = rep(text, old, new)

text = text.replace("child: Text(\n                      '选择帖子分类',", "child: Text(\n                      AppLocalizations.of(context)!.get('selectPostCategory'),")
text = text.replace("child: Text(\n                      '选择主语言',", "child: Text(\n                      AppLocalizations.of(context)!.get('selectPrimaryLanguage'),")

text = text.replace("title: const Text('删除共享笔记？'),", "title: Text(AppLocalizations.of(context)!.get('deleteSharedNoteTitle')),")
text = text.replace("content: const Text('删除后，这条笔记会从双方的笔记列表中消失。'),", "content: Text(AppLocalizations.of(context)!.get('deleteSharedNoteDescription')),")
text = text.replace("child: const Text('取消'),", "child: Text(AppLocalizations.of(context)!.get('cancel')),")
text = text.replace("child: const Text('删除'),", "child: Text(AppLocalizations.of(context)!.get('delete')),")

settings_replacements = [
    ("title: const Text('发布为帖子'),", "title: Text(AppLocalizations.of(context)!.get('publishAsPost')),"),
    ("subtitle: const Text('使用笔记分类，选择主语言后进入发帖页'),", "subtitle: Text(AppLocalizations.of(context)!.get('publishAsPostDescription')),"),
    ("title: const Text('帖子分类'),", "title: Text(AppLocalizations.of(context)!.get('postCategory')),"),
    ("title: const Text('共享成员'),", "title: Text(AppLocalizations.of(context)!.get('sharedMembers')),"),
    ("? '当前仅自己可见'", "? AppLocalizations.of(context)!.get('onlyMeVisible')"),
    (": '已共享给 ${_sharedUserIds.length} 人',", ": AppLocalizations.of(context)!.getWithArgs('sharedToPeople', {'count': '${_sharedUserIds.length}'}),"),
    ("subtitle: Text('共 ${_sharedUserIds.length + 1} 人'),", "subtitle: Text(AppLocalizations.of(context)!.getWithArgs('peopleTotal', {'count': '${_sharedUserIds.length + 1}'})),"),
    ("title: const Text('允许共享成员编辑'),", "title: Text(AppLocalizations.of(context)!.get('allowSharedEditing')),"),
    ("_allowOthersEdit ? '共享成员可以修改文字和图片' : '共享成员只能查看这条笔记',", "_allowOthersEdit ? AppLocalizations.of(context)!.get('sharedMembersCanEdit') : AppLocalizations.of(context)!.get('sharedMembersViewOnly'),"),
    ("title: Text(_canEdit ? '你可以编辑这条笔记' : '这条笔记只能查看'),", "title: Text(_canEdit ? AppLocalizations.of(context)!.get('youCanEditNote') : AppLocalizations.of(context)!.get('noteViewOnly')),"),
    ("'删除笔记',", "AppLocalizations.of(context)!.get('deleteNote'),"),
]
for old, new in settings_replacements:
    text = rep(text, old, new)

# Shared member picker.
text = text.replace("const Expanded(\n                    child: Text(\n                      '共享成员',", "Expanded(\n                    child: Text(\n                      AppLocalizations.of(context)!.get('sharedMembers'),")
text = text.replace("child: const Text('完成'),", "child: Text(AppLocalizations.of(context)!.get('done')),")
text = text.replace("hintText: '搜索昵称或用户名',", "hintText: AppLocalizations.of(context)!.get('searchNicknameOrUsername'),")
text = text.replace("? const Center(child: Text('没有找到用户'))", "? Center(child: Text(AppLocalizations.of(context)!.get('noUsersFound')))")
text = text.replace("name: name.isEmpty ? '用户' : name,", "name: name.isEmpty\n          ? (user.username.trim().isEmpty ? '?' : user.username.trim())\n          : name,")

write(path, text)


# ---------------------------------------------------------------------------
# Locale resources
# ---------------------------------------------------------------------------
translations = {
'en': {
'allLanguages':'All languages','unspecifiedLanguage':'Unspecified language','notSelected':'Not selected','allCategories':'All categories','uncategorized':'Uncategorized','selectCategory':'Select category','noteLanguage':'Note language','noteCategory':'Note category','usersLoadFailed':'Could not load users','newNoteSetupDescription':'Set note details now or change them later.','languageLabel':'Language','categoryLabel':'Category','shareLabel':'Share','onlyMe':'Only me','selectedPeople':'{count} selected','createNote':'Create note','myNotes':'My notes','clear':'Clear','notesLoadFailedDescription':'Your notes could not be loaded. Please try again.','noMatchingNotes':'No notes match these filters','noNotesYet':'No notes yet','clearFilters':'Clear filters','tapFabToCreateNote':'Use the button at the bottom right to create one','onlyMeVisible':'Visible only to you','sharedWithOne':'Shared with {name}','sharedWithTwo':'Shared with {names}','sharedWithMany':'Shared with {names} and {count} people total','sharedMembers':'Shared members','searchNicknameOrUsername':'Search nickname or username','noUsersFound':'No users found','saveFailed':'Could not save the note','permissionUpdateFailed':'Could not update editing permission','sharedMembersUpdateFailed':'Could not update shared members','editingNotAllowed':'The creator has not enabled editing','noteImageLimit':'A note can contain at most {count} images','insertImageFailed':'Could not insert the image','selectPostCategory':'Select post category','categoryUpdateFailed':'Could not update category','selectPrimaryLanguage':'Select primary language','notePublishedAsPost':'Note published as a post','deleteSharedNoteTitle':'Delete shared note?','deleteSharedNoteDescription':'After deletion, this note will disappear from every participant’s note list.','deleteNoteFailed':'Could not delete the note','publishAsPost':'Publish as post','publishAsPostDescription':'Use the note category, choose a primary language, then continue to the post editor.','postCategory':'Post category','sharedToPeople':'Shared with {count} people','peopleTotal':'{count} people total','allowSharedEditing':'Allow shared members to edit','sharedMembersCanEdit':'Shared members can edit text and images','sharedMembersViewOnly':'Shared members can only view this note','youCanEditNote':'You can edit this note','noteViewOnly':'This note is view-only','deleteNote':'Delete note','noteDeleted':'This note has been deleted','insertImage':'Insert image','noteSettings':'Note settings','noteTitleHint':'Note title','noteContentHint':'Write your note…'},
'zh': {
'allLanguages':'全部语言','unspecifiedLanguage':'未指定语言','notSelected':'未选择','allCategories':'全部分类','uncategorized':'未分类','selectCategory':'选择分类','noteLanguage':'笔记语言','noteCategory':'笔记分类','usersLoadFailed':'加载用户失败','newNoteSetupDescription':'可以先设置笔记信息，也可以以后再修改。','languageLabel':'语言','categoryLabel':'分类','shareLabel':'共享','onlyMe':'仅自己','selectedPeople':'已选择 {count} 人','createNote':'创建笔记','myNotes':'我的笔记','clear':'清除','notesLoadFailedDescription':'无法加载笔记，请稍后重试。','noMatchingNotes':'没有符合条件的笔记','noNotesYet':'还没有笔记','clearFilters':'清除筛选','tapFabToCreateNote':'点击右下角新建','onlyMeVisible':'仅自己可见','sharedWithOne':'与 {name} 共享','sharedWithTwo':'与 {names} 共享','sharedWithMany':'与 {names} 等共 {count} 人共享','sharedMembers':'共享成员','searchNicknameOrUsername':'搜索昵称或用户名','noUsersFound':'没有找到用户','saveFailed':'保存失败','permissionUpdateFailed':'权限设置失败','sharedMembersUpdateFailed':'更新共享成员失败','editingNotAllowed':'创建者没有开放编辑权限','noteImageLimit':'每条笔记最多插入 {count} 张图片','insertImageFailed':'插入图片失败','selectPostCategory':'选择帖子分类','categoryUpdateFailed':'修改分类失败','selectPrimaryLanguage':'选择主语言','notePublishedAsPost':'笔记已发布为帖子','deleteSharedNoteTitle':'删除共享笔记？','deleteSharedNoteDescription':'删除后，这条笔记会从所有参与者的笔记列表中消失。','deleteNoteFailed':'删除笔记失败','publishAsPost':'发布为帖子','publishAsPostDescription':'使用笔记分类，选择主语言后进入发帖页','postCategory':'帖子分类','sharedToPeople':'已共享给 {count} 人','peopleTotal':'共 {count} 人','allowSharedEditing':'允许共享成员编辑','sharedMembersCanEdit':'共享成员可以修改文字和图片','sharedMembersViewOnly':'共享成员只能查看这条笔记','youCanEditNote':'你可以编辑这条笔记','noteViewOnly':'这条笔记只能查看','deleteNote':'删除笔记','noteDeleted':'这条笔记已被删除','insertImage':'插入图片','noteSettings':'笔记设置','noteTitleHint':'笔记标题','noteContentHint':'输入笔记内容……'},
'ja': {
'allLanguages':'すべての言語','unspecifiedLanguage':'言語未指定','notSelected':'未選択','allCategories':'すべてのカテゴリ','uncategorized':'未分類','selectCategory':'カテゴリを選択','noteLanguage':'ノートの言語','noteCategory':'ノートのカテゴリ','usersLoadFailed':'ユーザーを読み込めませんでした','newNoteSetupDescription':'ノートの情報は今設定しても、後から変更しても構いません。','languageLabel':'言語','categoryLabel':'カテゴリ','shareLabel':'共有','onlyMe':'自分のみ','selectedPeople':'{count}人選択済み','createNote':'ノートを作成','myNotes':'マイノート','clear':'クリア','notesLoadFailedDescription':'ノートを読み込めませんでした。もう一度お試しください。','noMatchingNotes':'条件に一致するノートはありません','noNotesYet':'まだノートはありません','clearFilters':'フィルターを解除','tapFabToCreateNote':'右下のボタンから作成できます','onlyMeVisible':'自分だけに表示','sharedWithOne':'{name}と共有','sharedWithTwo':'{names}と共有','sharedWithMany':'{names}など計{count}人と共有','sharedMembers':'共有メンバー','searchNicknameOrUsername':'ニックネームまたはユーザー名を検索','noUsersFound':'ユーザーが見つかりません','saveFailed':'ノートを保存できませんでした','permissionUpdateFailed':'編集権限を更新できませんでした','sharedMembersUpdateFailed':'共有メンバーを更新できませんでした','editingNotAllowed':'作成者が編集を許可していません','noteImageLimit':'1つのノートに挿入できる画像は最大{count}枚です','insertImageFailed':'画像を挿入できませんでした','selectPostCategory':'投稿カテゴリを選択','categoryUpdateFailed':'カテゴリを変更できませんでした','selectPrimaryLanguage':'主な言語を選択','notePublishedAsPost':'ノートを投稿として公開しました','deleteSharedNoteTitle':'共有ノートを削除しますか？','deleteSharedNoteDescription':'削除すると、このノートはすべての参加者の一覧から消えます。','deleteNoteFailed':'ノートを削除できませんでした','publishAsPost':'投稿として公開','publishAsPostDescription':'ノートのカテゴリを使い、主な言語を選んで投稿画面へ進みます。','postCategory':'投稿カテゴリ','sharedToPeople':'{count}人と共有中','peopleTotal':'合計{count}人','allowSharedEditing':'共有メンバーの編集を許可','sharedMembersCanEdit':'共有メンバーは文章と画像を編集できます','sharedMembersViewOnly':'共有メンバーはこのノートを閲覧のみできます','youCanEditNote':'このノートを編集できます','noteViewOnly':'このノートは閲覧のみです','deleteNote':'ノートを削除','noteDeleted':'このノートは削除されました','insertImage':'画像を挿入','noteSettings':'ノート設定','noteTitleHint':'ノートのタイトル','noteContentHint':'ノートを入力…'},
'ko': {
'allLanguages':'모든 언어','unspecifiedLanguage':'언어 미지정','notSelected':'선택 안 함','allCategories':'모든 카테고리','uncategorized':'미분류','selectCategory':'카테고리 선택','noteLanguage':'노트 언어','noteCategory':'노트 카테고리','usersLoadFailed':'사용자를 불러오지 못했습니다','newNoteSetupDescription':'노트 정보를 지금 설정하거나 나중에 변경할 수 있습니다.','languageLabel':'언어','categoryLabel':'카테고리','shareLabel':'공유','onlyMe':'나만','selectedPeople':'{count}명 선택','createNote':'노트 만들기','myNotes':'내 노트','clear':'지우기','notesLoadFailedDescription':'노트를 불러오지 못했습니다. 다시 시도해 주세요.','noMatchingNotes':'조건에 맞는 노트가 없습니다','noNotesYet':'아직 노트가 없습니다','clearFilters':'필터 지우기','tapFabToCreateNote':'오른쪽 아래 버튼으로 새 노트를 만드세요','onlyMeVisible':'나만 볼 수 있음','sharedWithOne':'{name}님과 공유','sharedWithTwo':'{names}님과 공유','sharedWithMany':'{names} 외 총 {count}명과 공유','sharedMembers':'공유 멤버','searchNicknameOrUsername':'닉네임 또는 사용자 이름 검색','noUsersFound':'사용자를 찾을 수 없습니다','saveFailed':'노트를 저장하지 못했습니다','permissionUpdateFailed':'편집 권한을 업데이트하지 못했습니다','sharedMembersUpdateFailed':'공유 멤버를 업데이트하지 못했습니다','editingNotAllowed':'작성자가 편집을 허용하지 않았습니다','noteImageLimit':'노트에는 최대 {count}장의 이미지를 넣을 수 있습니다','insertImageFailed':'이미지를 삽입하지 못했습니다','selectPostCategory':'게시물 카테고리 선택','categoryUpdateFailed':'카테고리를 변경하지 못했습니다','selectPrimaryLanguage':'주 언어 선택','notePublishedAsPost':'노트를 게시물로 올렸습니다','deleteSharedNoteTitle':'공유 노트를 삭제할까요?','deleteSharedNoteDescription':'삭제하면 모든 참여자의 노트 목록에서 사라집니다.','deleteNoteFailed':'노트를 삭제하지 못했습니다','publishAsPost':'게시물로 올리기','publishAsPostDescription':'노트 카테고리를 사용하고 주 언어를 선택한 뒤 게시물 편집기로 이동합니다.','postCategory':'게시물 카테고리','sharedToPeople':'{count}명과 공유 중','peopleTotal':'총 {count}명','allowSharedEditing':'공유 멤버 편집 허용','sharedMembersCanEdit':'공유 멤버가 텍스트와 이미지를 수정할 수 있습니다','sharedMembersViewOnly':'공유 멤버는 이 노트를 보기만 할 수 있습니다','youCanEditNote':'이 노트를 편집할 수 있습니다','noteViewOnly':'이 노트는 보기 전용입니다','deleteNote':'노트 삭제','noteDeleted':'이 노트는 삭제되었습니다','insertImage':'이미지 삽입','noteSettings':'노트 설정','noteTitleHint':'노트 제목','noteContentHint':'노트 내용을 입력하세요…'},
'ms': {
'allLanguages':'Semua bahasa','unspecifiedLanguage':'Bahasa tidak dinyatakan','notSelected':'Tidak dipilih','allCategories':'Semua kategori','uncategorized':'Tanpa kategori','selectCategory':'Pilih kategori','noteLanguage':'Bahasa nota','noteCategory':'Kategori nota','usersLoadFailed':'Pengguna gagal dimuatkan','newNoteSetupDescription':'Tetapkan maklumat nota sekarang atau ubah kemudian.','languageLabel':'Bahasa','categoryLabel':'Kategori','shareLabel':'Kongsi','onlyMe':'Saya sahaja','selectedPeople':'{count} dipilih','createNote':'Cipta nota','myNotes':'Nota saya','clear':'Kosongkan','notesLoadFailedDescription':'Nota tidak dapat dimuatkan. Sila cuba lagi.','noMatchingNotes':'Tiada nota yang sepadan dengan penapis','noNotesYet':'Belum ada nota','clearFilters':'Kosongkan penapis','tapFabToCreateNote':'Gunakan butang di kanan bawah untuk mencipta nota','onlyMeVisible':'Hanya anda boleh melihatnya','sharedWithOne':'Dikongsi dengan {name}','sharedWithTwo':'Dikongsi dengan {names}','sharedWithMany':'Dikongsi dengan {names} dan {count} orang keseluruhan','sharedMembers':'Ahli dikongsi','searchNicknameOrUsername':'Cari nama panggilan atau nama pengguna','noUsersFound':'Tiada pengguna ditemui','saveFailed':'Nota gagal disimpan','permissionUpdateFailed':'Kebenaran edit gagal dikemas kini','sharedMembersUpdateFailed':'Ahli dikongsi gagal dikemas kini','editingNotAllowed':'Pencipta belum membenarkan penyuntingan','noteImageLimit':'Satu nota boleh mengandungi maksimum {count} imej','insertImageFailed':'Imej gagal dimasukkan','selectPostCategory':'Pilih kategori siaran','categoryUpdateFailed':'Kategori gagal dikemas kini','selectPrimaryLanguage':'Pilih bahasa utama','notePublishedAsPost':'Nota diterbitkan sebagai siaran','deleteSharedNoteTitle':'Padam nota dikongsi?','deleteSharedNoteDescription':'Selepas dipadam, nota ini akan hilang daripada senarai semua peserta.','deleteNoteFailed':'Nota gagal dipadam','publishAsPost':'Terbit sebagai siaran','publishAsPostDescription':'Gunakan kategori nota, pilih bahasa utama, kemudian teruskan ke editor siaran.','postCategory':'Kategori siaran','sharedToPeople':'Dikongsi dengan {count} orang','peopleTotal':'{count} orang keseluruhan','allowSharedEditing':'Benarkan ahli dikongsi mengedit','sharedMembersCanEdit':'Ahli dikongsi boleh mengedit teks dan imej','sharedMembersViewOnly':'Ahli dikongsi hanya boleh melihat nota ini','youCanEditNote':'Anda boleh mengedit nota ini','noteViewOnly':'Nota ini hanya untuk dilihat','deleteNote':'Padam nota','noteDeleted':'Nota ini telah dipadam','insertImage':'Masukkan imej','noteSettings':'Tetapan nota','noteTitleHint':'Tajuk nota','noteContentHint':'Tulis nota anda…'},
'vi': {
'allLanguages':'Tất cả ngôn ngữ','unspecifiedLanguage':'Chưa chỉ định ngôn ngữ','notSelected':'Chưa chọn','allCategories':'Tất cả danh mục','uncategorized':'Chưa phân loại','selectCategory':'Chọn danh mục','noteLanguage':'Ngôn ngữ ghi chú','noteCategory':'Danh mục ghi chú','usersLoadFailed':'Không thể tải người dùng','newNoteSetupDescription':'Bạn có thể đặt thông tin ghi chú bây giờ hoặc thay đổi sau.','languageLabel':'Ngôn ngữ','categoryLabel':'Danh mục','shareLabel':'Chia sẻ','onlyMe':'Chỉ mình tôi','selectedPeople':'Đã chọn {count} người','createNote':'Tạo ghi chú','myNotes':'Ghi chú của tôi','clear':'Xóa','notesLoadFailedDescription':'Không thể tải ghi chú. Vui lòng thử lại.','noMatchingNotes':'Không có ghi chú phù hợp bộ lọc','noNotesYet':'Chưa có ghi chú','clearFilters':'Xóa bộ lọc','tapFabToCreateNote':'Dùng nút ở góc dưới bên phải để tạo ghi chú','onlyMeVisible':'Chỉ bạn có thể xem','sharedWithOne':'Chia sẻ với {name}','sharedWithTwo':'Chia sẻ với {names}','sharedWithMany':'Chia sẻ với {names} và tổng cộng {count} người','sharedMembers':'Thành viên được chia sẻ','searchNicknameOrUsername':'Tìm biệt danh hoặc tên người dùng','noUsersFound':'Không tìm thấy người dùng','saveFailed':'Không thể lưu ghi chú','permissionUpdateFailed':'Không thể cập nhật quyền chỉnh sửa','sharedMembersUpdateFailed':'Không thể cập nhật thành viên chia sẻ','editingNotAllowed':'Người tạo chưa cho phép chỉnh sửa','noteImageLimit':'Mỗi ghi chú có tối đa {count} hình ảnh','insertImageFailed':'Không thể chèn hình ảnh','selectPostCategory':'Chọn danh mục bài viết','categoryUpdateFailed':'Không thể đổi danh mục','selectPrimaryLanguage':'Chọn ngôn ngữ chính','notePublishedAsPost':'Đã đăng ghi chú thành bài viết','deleteSharedNoteTitle':'Xóa ghi chú chia sẻ?','deleteSharedNoteDescription':'Sau khi xóa, ghi chú này sẽ biến mất khỏi danh sách của mọi người tham gia.','deleteNoteFailed':'Không thể xóa ghi chú','publishAsPost':'Đăng thành bài viết','publishAsPostDescription':'Dùng danh mục của ghi chú, chọn ngôn ngữ chính rồi tiếp tục đến trình soạn bài.','postCategory':'Danh mục bài viết','sharedToPeople':'Đã chia sẻ với {count} người','peopleTotal':'Tổng cộng {count} người','allowSharedEditing':'Cho phép thành viên chia sẻ chỉnh sửa','sharedMembersCanEdit':'Thành viên chia sẻ có thể sửa văn bản và hình ảnh','sharedMembersViewOnly':'Thành viên chia sẻ chỉ có thể xem ghi chú này','youCanEditNote':'Bạn có thể chỉnh sửa ghi chú này','noteViewOnly':'Ghi chú này chỉ có thể xem','deleteNote':'Xóa ghi chú','noteDeleted':'Ghi chú này đã bị xóa','insertImage':'Chèn hình ảnh','noteSettings':'Cài đặt ghi chú','noteTitleHint':'Tiêu đề ghi chú','noteContentHint':'Nhập nội dung ghi chú…'},
'th': {
'allLanguages':'ทุกภาษา','unspecifiedLanguage':'ไม่ได้ระบุภาษา','notSelected':'ยังไม่ได้เลือก','allCategories':'ทุกหมวดหมู่','uncategorized':'ไม่มีหมวดหมู่','selectCategory':'เลือกหมวดหมู่','noteLanguage':'ภาษาของโน้ต','noteCategory':'หมวดหมู่โน้ต','usersLoadFailed':'โหลดผู้ใช้ไม่สำเร็จ','newNoteSetupDescription':'ตั้งค่าข้อมูลโน้ตตอนนี้หรือเปลี่ยนภายหลังก็ได้','languageLabel':'ภาษา','categoryLabel':'หมวดหมู่','shareLabel':'แชร์','onlyMe':'เฉพาะฉัน','selectedPeople':'เลือกแล้ว {count} คน','createNote':'สร้างโน้ต','myNotes':'โน้ตของฉัน','clear':'ล้าง','notesLoadFailedDescription':'ไม่สามารถโหลดโน้ตได้ โปรดลองอีกครั้ง','noMatchingNotes':'ไม่มีโน้ตที่ตรงกับตัวกรอง','noNotesYet':'ยังไม่มีโน้ต','clearFilters':'ล้างตัวกรอง','tapFabToCreateNote':'ใช้ปุ่มมุมขวาล่างเพื่อสร้างโน้ต','onlyMeVisible':'มีเพียงคุณที่มองเห็น','sharedWithOne':'แชร์กับ {name}','sharedWithTwo':'แชร์กับ {names}','sharedWithMany':'แชร์กับ {names} และรวมทั้งหมด {count} คน','sharedMembers':'สมาชิกที่แชร์','searchNicknameOrUsername':'ค้นหาชื่อเล่นหรือชื่อผู้ใช้','noUsersFound':'ไม่พบผู้ใช้','saveFailed':'บันทึกโน้ตไม่สำเร็จ','permissionUpdateFailed':'อัปเดตสิทธิ์แก้ไขไม่สำเร็จ','sharedMembersUpdateFailed':'อัปเดตสมาชิกที่แชร์ไม่สำเร็จ','editingNotAllowed':'ผู้สร้างยังไม่อนุญาตให้แก้ไข','noteImageLimit':'โน้ตหนึ่งรายการใส่รูปได้สูงสุด {count} รูป','insertImageFailed':'แทรกรูปภาพไม่สำเร็จ','selectPostCategory':'เลือกหมวดหมู่โพสต์','categoryUpdateFailed':'เปลี่ยนหมวดหมู่ไม่สำเร็จ','selectPrimaryLanguage':'เลือกภาษาหลัก','notePublishedAsPost':'เผยแพร่โน้ตเป็นโพสต์แล้ว','deleteSharedNoteTitle':'ลบโน้ตที่แชร์หรือไม่?','deleteSharedNoteDescription':'หลังจากลบ โน้ตนี้จะหายจากรายการของผู้เข้าร่วมทุกคน','deleteNoteFailed':'ลบโน้ตไม่สำเร็จ','publishAsPost':'เผยแพร่เป็นโพสต์','publishAsPostDescription':'ใช้หมวดหมู่ของโน้ต เลือกภาษาหลัก แล้วไปยังหน้าสร้างโพสต์','postCategory':'หมวดหมู่โพสต์','sharedToPeople':'แชร์กับ {count} คน','peopleTotal':'รวม {count} คน','allowSharedEditing':'อนุญาตให้สมาชิกที่แชร์แก้ไข','sharedMembersCanEdit':'สมาชิกที่แชร์แก้ไขข้อความและรูปภาพได้','sharedMembersViewOnly':'สมาชิกที่แชร์ดูโน้ตนี้ได้อย่างเดียว','youCanEditNote':'คุณแก้ไขโน้ตนี้ได้','noteViewOnly':'โน้ตนี้ดูได้อย่างเดียว','deleteNote':'ลบโน้ต','noteDeleted':'โน้ตนี้ถูกลบแล้ว','insertImage':'แทรกรูปภาพ','noteSettings':'การตั้งค่าโน้ต','noteTitleHint':'ชื่อโน้ต','noteContentHint':'เขียนโน้ตของคุณ…'},
}

for code, values in translations.items():
    locale_path = APP / 'assets' / 'l10n' / f'{code}.json'
    data = json.loads(locale_path.read_text(encoding='utf-8'))
    data.update(values)
    locale_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

# Expand the permanent hard-coded UI regression guard.
guard = APP / 'test/app/l10n/localized_screen_guard_test.dart'
guard_text = guard.read_text(encoding='utf-8')
needle = "      'lib/features/profile/presentation/screens/user_profile_screen.dart',\n"
addition = needle + "      'lib/features/notes/presentation/screens/all_notes_screen.dart',\n      'lib/features/notes/presentation/screens/note_editor_screen.dart',\n"
if needle not in guard_text:
    raise RuntimeError('guard insertion marker missing')
guard.write_text(guard_text.replace(needle, addition, 1), encoding='utf-8')

print('Applied notes localization migration.')
