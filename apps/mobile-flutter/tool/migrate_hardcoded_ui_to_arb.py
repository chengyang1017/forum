from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
L10N_DIR = ROOT / "lib" / "l10n"
WRAPPER = ROOT / "lib" / "app" / "l10n" / "app_localizations.dart"

LOCALES = ("en", "zh", "ja", "ko", "ms", "vi", "th", "vi_Hani")

# New UI messages that were still hard-coded after the JSON -> ARB migration.
# vi_Hani intentionally inherits the Vietnamese wording for newly-added messages;
# the existing Nôm-specific translations remain untouched.
M = {
    "allLanguages": {
        "en": "All languages", "zh": "全部语言", "ja": "すべての言語", "ko": "모든 언어", "ms": "Semua bahasa", "vi": "Tất cả ngôn ngữ", "th": "ทุกภาษา",
    },
    "unspecifiedLanguage": {
        "en": "Unspecified language", "zh": "未指定语言", "ja": "言語未指定", "ko": "언어 미지정", "ms": "Bahasa tidak dinyatakan", "vi": "Chưa chỉ định ngôn ngữ", "th": "ไม่ได้ระบุภาษา",
    },
    "notSelected": {
        "en": "Not selected", "zh": "未选择", "ja": "未選択", "ko": "선택 안 함", "ms": "Belum dipilih", "vi": "Chưa chọn", "th": "ยังไม่ได้เลือก",
    },
    "category": {
        "en": "Category", "zh": "分类", "ja": "カテゴリ", "ko": "카테고리", "ms": "Kategori", "vi": "Danh mục", "th": "หมวดหมู่",
    },
    "allCategories": {
        "en": "All categories", "zh": "全部分类", "ja": "すべてのカテゴリ", "ko": "모든 카테고리", "ms": "Semua kategori", "vi": "Tất cả danh mục", "th": "ทุกหมวดหมู่",
    },
    "uncategorized": {
        "en": "Uncategorized", "zh": "未分类", "ja": "未分類", "ko": "분류 없음", "ms": "Tanpa kategori", "vi": "Chưa phân loại", "th": "ไม่มีหมวดหมู่",
    },
    "selectCategory": {
        "en": "Select category", "zh": "选择分类", "ja": "カテゴリを選択", "ko": "카테고리 선택", "ms": "Pilih kategori", "vi": "Chọn danh mục", "th": "เลือกหมวดหมู่",
    },
    "noteLanguage": {
        "en": "Note language", "zh": "笔记语言", "ja": "ノートの言語", "ko": "노트 언어", "ms": "Bahasa nota", "vi": "Ngôn ngữ ghi chú", "th": "ภาษาของโน้ต",
    },
    "noteCategory": {
        "en": "Note category", "zh": "笔记分类", "ja": "ノートのカテゴリ", "ko": "노트 카테고리", "ms": "Kategori nota", "vi": "Danh mục ghi chú", "th": "หมวดหมู่โน้ต",
    },
    "sharing": {
        "en": "Sharing", "zh": "共享", "ja": "共有", "ko": "공유", "ms": "Perkongsian", "vi": "Chia sẻ", "th": "การแชร์",
    },
    "onlyMe": {
        "en": "Only me", "zh": "仅自己", "ja": "自分のみ", "ko": "나만", "ms": "Saya sahaja", "vi": "Chỉ mình tôi", "th": "เฉพาะฉัน",
    },
    "selectedPeople": {
        "en": "{count} selected", "zh": "已选择 {count} 人", "ja": "{count}人を選択", "ko": "{count}명 선택됨", "ms": "{count} dipilih", "vi": "Đã chọn {count} người", "th": "เลือกแล้ว {count} คน",
    },
    "newNoteConfigDescription": {
        "en": "You can set note details now or change them later.", "zh": "可以先设置笔记信息，也可以以后再修改。", "ja": "ノート情報は今設定しても、後で変更してもかまいません。", "ko": "노트 정보를 지금 설정하거나 나중에 변경할 수 있습니다.", "ms": "Anda boleh menetapkan maklumat nota sekarang atau mengubahnya kemudian.", "vi": "Bạn có thể đặt thông tin ghi chú ngay bây giờ hoặc thay đổi sau.", "th": "คุณสามารถตั้งค่ารายละเอียดโน้ตตอนนี้หรือเปลี่ยนภายหลังก็ได้",
    },
    "createNote": {
        "en": "Create note", "zh": "创建笔记", "ja": "ノートを作成", "ko": "노트 만들기", "ms": "Cipta nota", "vi": "Tạo ghi chú", "th": "สร้างโน้ต",
    },
    "myNotes": {
        "en": "My notes", "zh": "我的笔记", "ja": "自分のノート", "ko": "내 노트", "ms": "Nota saya", "vi": "Ghi chú của tôi", "th": "โน้ตของฉัน",
    },
    "clear": {
        "en": "Clear", "zh": "清除", "ja": "クリア", "ko": "지우기", "ms": "Kosongkan", "vi": "Xóa", "th": "ล้าง",
    },
    "noMatchingNotes": {
        "en": "No notes match the current filters", "zh": "没有符合条件的笔记", "ja": "条件に一致するノートはありません", "ko": "조건에 맞는 노트가 없습니다", "ms": "Tiada nota yang sepadan dengan penapis", "vi": "Không có ghi chú phù hợp với bộ lọc", "th": "ไม่มีโน้ตที่ตรงกับตัวกรอง",
    },
    "noNotesYet": {
        "en": "No notes yet", "zh": "还没有笔记", "ja": "まだノートはありません", "ko": "아직 노트가 없습니다", "ms": "Belum ada nota", "vi": "Chưa có ghi chú", "th": "ยังไม่มีโน้ต",
    },
    "clearFilters": {
        "en": "Clear filters", "zh": "清除筛选", "ja": "フィルターを解除", "ko": "필터 지우기", "ms": "Kosongkan penapis", "vi": "Xóa bộ lọc", "th": "ล้างตัวกรอง",
    },
    "tapFabToCreateNote": {
        "en": "Tap the bottom-right button to create a note", "zh": "点击右下角新建", "ja": "右下のボタンから新しいノートを作成できます", "ko": "오른쪽 아래 버튼을 눌러 새 노트를 만드세요", "ms": "Ketik butang kanan bawah untuk mencipta nota", "vi": "Nhấn nút góc dưới bên phải để tạo ghi chú", "th": "แตะปุ่มมุมขวาล่างเพื่อสร้างโน้ต",
    },
    "privateNote": {
        "en": "Only you can see this", "zh": "仅自己可见", "ja": "自分だけに表示", "ko": "나만 볼 수 있음", "ms": "Hanya anda boleh melihatnya", "vi": "Chỉ bạn có thể xem", "th": "มีเพียงคุณที่มองเห็น",
    },
    "user": {
        "en": "User", "zh": "用户", "ja": "ユーザー", "ko": "사용자", "ms": "Pengguna", "vi": "Người dùng", "th": "ผู้ใช้",
    },
    "sharedWithUser": {
        "en": "Shared with {name}", "zh": "与 {name} 共享", "ja": "{name} と共有", "ko": "{name}님과 공유", "ms": "Dikongsi dengan {name}", "vi": "Chia sẻ với {name}", "th": "แชร์กับ {name}",
    },
    "sharedWithUsers": {
        "en": "Shared with {names}", "zh": "与 {names} 共享", "ja": "{names} と共有", "ko": "{names}와 공유", "ms": "Dikongsi dengan {names}", "vi": "Chia sẻ với {names}", "th": "แชร์กับ {names}",
    },
    "sharedWithMany": {
        "en": "Shared with {names} and {count} people total", "zh": "与 {names} 等 {count} 人共享", "ja": "{names} など計{count}人と共有", "ko": "{names} 등 총 {count}명과 공유", "ms": "Dikongsi dengan {names} dan {count} orang keseluruhan", "vi": "Chia sẻ với {names} và tổng cộng {count} người", "th": "แชร์กับ {names} และรวมทั้งหมด {count} คน",
    },
    "sharedMembers": {
        "en": "Shared members", "zh": "共享成员", "ja": "共有メンバー", "ko": "공유 멤버", "ms": "Ahli perkongsian", "vi": "Thành viên được chia sẻ", "th": "สมาชิกที่แชร์",
    },
    "searchNicknameOrUsername": {
        "en": "Search nickname or username", "zh": "搜索昵称或用户名", "ja": "ニックネームまたはユーザー名を検索", "ko": "닉네임 또는 사용자 이름 검색", "ms": "Cari nama panggilan atau nama pengguna", "vi": "Tìm biệt danh hoặc tên người dùng", "th": "ค้นหาชื่อเล่นหรือชื่อผู้ใช้",
    },
    "noUsersFound": {
        "en": "No users found", "zh": "没有找到用户", "ja": "ユーザーが見つかりません", "ko": "사용자를 찾을 수 없습니다", "ms": "Tiada pengguna ditemui", "vi": "Không tìm thấy người dùng", "th": "ไม่พบผู้ใช้",
    },
    "currentUserNotChatMember": {
        "en": "The current user is not a member of this chat", "zh": "当前用户不是聊天室成员", "ja": "現在のユーザーはこのチャットのメンバーではありません", "ko": "현재 사용자는 이 채팅방의 멤버가 아닙니다", "ms": "Pengguna semasa bukan ahli sembang ini", "vi": "Người dùng hiện tại không phải thành viên của cuộc trò chuyện này", "th": "ผู้ใช้ปัจจุบันไม่ได้เป็นสมาชิกของแชทนี้",
    },
    "chatPeerNotFound": {
        "en": "Chat participant not found", "zh": "找不到聊天对象", "ja": "チャット相手が見つかりません", "ko": "대화 상대를 찾을 수 없습니다", "ms": "Rakan sembang tidak ditemui", "vi": "Không tìm thấy người trò chuyện", "th": "ไม่พบคู่สนทนา",
    },
    "editingNotAllowed": {
        "en": "The creator has not enabled editing", "zh": "创建者没有开放编辑权限", "ja": "作成者が編集を許可していません", "ko": "작성자가 편집 권한을 허용하지 않았습니다", "ms": "Pencipta belum membenarkan penyuntingan", "vi": "Người tạo chưa cho phép chỉnh sửa", "th": "ผู้สร้างยังไม่ได้อนุญาตให้แก้ไข",
    },
    "noteImageLimit": {
        "en": "Each note can contain up to 9 images", "zh": "每条笔记最多插入 9 张图片", "ja": "1つのノートには最大9枚の画像を挿入できます", "ko": "노트 하나에 최대 9개의 이미지를 넣을 수 있습니다", "ms": "Setiap nota boleh mengandungi sehingga 9 imej", "vi": "Mỗi ghi chú có thể chứa tối đa 9 ảnh", "th": "แต่ละโน้ตใส่รูปได้สูงสุด 9 รูป",
    },
    "selectPostCategory": {
        "en": "Select post category", "zh": "选择帖子分类", "ja": "投稿カテゴリを選択", "ko": "게시물 카테고리 선택", "ms": "Pilih kategori siaran", "vi": "Chọn danh mục bài viết", "th": "เลือกหมวดหมู่โพสต์",
    },
    "choosePrimaryLanguage": {
        "en": "Choose primary language", "zh": "选择主语言", "ja": "主言語を選択", "ko": "주 언어 선택", "ms": "Pilih bahasa utama", "vi": "Chọn ngôn ngữ chính", "th": "เลือกภาษาหลัก",
    },
    "notePublishedAsPost": {
        "en": "Note published as a post", "zh": "笔记已发布为帖子", "ja": "ノートを投稿として公開しました", "ko": "노트를 게시물로 발행했습니다", "ms": "Nota diterbitkan sebagai siaran", "vi": "Đã đăng ghi chú thành bài viết", "th": "เผยแพร่โน้ตเป็นโพสต์แล้ว",
    },
    "deleteSharedNote": {
        "en": "Delete shared note?", "zh": "删除共享笔记？", "ja": "共有ノートを削除しますか？", "ko": "공유 노트를 삭제할까요?", "ms": "Padam nota yang dikongsi?", "vi": "Xóa ghi chú được chia sẻ?", "th": "ลบโน้ตที่แชร์หรือไม่",
    },
    "deleteSharedNoteDescription": {
        "en": "After deletion, this note will disappear from both users’ note lists.", "zh": "删除后，这条笔记会从双方的笔记列表中消失。", "ja": "削除すると、このノートは双方のノート一覧から消えます。", "ko": "삭제하면 이 노트가 양쪽 사용자의 노트 목록에서 사라집니다.", "ms": "Selepas dipadam, nota ini akan hilang daripada senarai nota kedua-dua pengguna.", "vi": "Sau khi xóa, ghi chú này sẽ biến mất khỏi danh sách ghi chú của cả hai bên.", "th": "หลังจากลบ โน้ตนี้จะหายไปจากรายการโน้ตของทั้งสองฝ่าย",
    },
    "publishAsPost": {
        "en": "Publish as post", "zh": "发布为帖子", "ja": "投稿として公開", "ko": "게시물로 발행", "ms": "Terbitkan sebagai siaran", "vi": "Đăng thành bài viết", "th": "เผยแพร่เป็นโพสต์",
    },
    "publishAsPostDescription": {
        "en": "Use the note category, choose a primary language, then continue to the post screen", "zh": "使用笔记分类，选择主语言后进入发帖页", "ja": "ノートのカテゴリを使い、主言語を選んで投稿画面へ進みます", "ko": "노트 카테고리를 사용하고 주 언어를 선택한 뒤 게시 화면으로 이동합니다", "ms": "Gunakan kategori nota, pilih bahasa utama, kemudian teruskan ke skrin siaran", "vi": "Dùng danh mục của ghi chú, chọn ngôn ngữ chính rồi chuyển sang màn hình đăng bài", "th": "ใช้หมวดหมู่ของโน้ต เลือกภาษาหลัก แล้วไปยังหน้าสร้างโพสต์",
    },
    "postCategory": {
        "en": "Post category", "zh": "帖子分类", "ja": "投稿カテゴリ", "ko": "게시물 카테고리", "ms": "Kategori siaran", "vi": "Danh mục bài viết", "th": "หมวดหมู่โพสต์",
    },
    "sharedWithCount": {
        "en": "Shared with {count} people", "zh": "已共享给 {count} 人", "ja": "{count}人と共有中", "ko": "{count}명과 공유됨", "ms": "Dikongsi dengan {count} orang", "vi": "Đã chia sẻ với {count} người", "th": "แชร์กับ {count} คน",
    },
    "membersCount": {
        "en": "{count} people total", "zh": "共 {count} 人", "ja": "合計{count}人", "ko": "총 {count}명", "ms": "{count} orang keseluruhan", "vi": "Tổng {count} người", "th": "รวม {count} คน",
    },
    "allowSharedMembersEdit": {
        "en": "Allow shared members to edit", "zh": "允许共享成员编辑", "ja": "共有メンバーの編集を許可", "ko": "공유 멤버 편집 허용", "ms": "Benarkan ahli perkongsian mengedit", "vi": "Cho phép thành viên được chia sẻ chỉnh sửa", "th": "อนุญาตให้สมาชิกที่แชร์แก้ไข",
    },
    "sharedMembersCanEdit": {
        "en": "Shared members can edit text and images", "zh": "共享成员可以修改文字和图片", "ja": "共有メンバーは文字と画像を編集できます", "ko": "공유 멤버가 텍스트와 이미지를 수정할 수 있습니다", "ms": "Ahli perkongsian boleh mengedit teks dan imej", "vi": "Thành viên được chia sẻ có thể sửa văn bản và hình ảnh", "th": "สมาชิกที่แชร์สามารถแก้ไขข้อความและรูปภาพได้",
    },
    "sharedMembersViewOnly": {
        "en": "Shared members can only view this note", "zh": "共享成员只能查看这条笔记", "ja": "共有メンバーはこのノートを閲覧のみできます", "ko": "공유 멤버는 이 노트를 보기만 할 수 있습니다", "ms": "Ahli perkongsian hanya boleh melihat nota ini", "vi": "Thành viên được chia sẻ chỉ có thể xem ghi chú này", "th": "สมาชิกที่แชร์ดูโน้ตนี้ได้อย่างเดียว",
    },
    "canEditThisNote": {
        "en": "You can edit this note", "zh": "你可以编辑这条笔记", "ja": "このノートを編集できます", "ko": "이 노트를 편집할 수 있습니다", "ms": "Anda boleh mengedit nota ini", "vi": "Bạn có thể chỉnh sửa ghi chú này", "th": "คุณสามารถแก้ไขโน้ตนี้ได้",
    },
    "readOnlyNote": {
        "en": "This note is view-only", "zh": "这条笔记只能查看", "ja": "このノートは閲覧専用です", "ko": "이 노트는 읽기 전용입니다", "ms": "Nota ini hanya untuk dilihat", "vi": "Ghi chú này chỉ có thể xem", "th": "โน้ตนี้ดูได้อย่างเดียว",
    },
    "deleteNote": {
        "en": "Delete note", "zh": "删除笔记", "ja": "ノートを削除", "ko": "노트 삭제", "ms": "Padam nota", "vi": "Xóa ghi chú", "th": "ลบโน้ต",
    },
    "sharedNote": {
        "en": "Shared note", "zh": "共享笔记", "ja": "共有ノート", "ko": "공유 노트", "ms": "Nota dikongsi", "vi": "Ghi chú được chia sẻ", "th": "โน้ตที่แชร์",
    },
    "noteDeleted": {
        "en": "This note has been deleted", "zh": "这条笔记已被删除", "ja": "このノートは削除されました", "ko": "이 노트는 삭제되었습니다", "ms": "Nota ini telah dipadam", "vi": "Ghi chú này đã bị xóa", "th": "โน้ตนี้ถูกลบแล้ว",
    },
    "insertImage": {
        "en": "Insert image", "zh": "插入图片", "ja": "画像を挿入", "ko": "이미지 삽입", "ms": "Sisip imej", "vi": "Chèn ảnh", "th": "แทรกรูปภาพ",
    },
    "noteSettings": {
        "en": "Note settings", "zh": "笔记设置", "ja": "ノート設定", "ko": "노트 설정", "ms": "Tetapan nota", "vi": "Cài đặt ghi chú", "th": "การตั้งค่าโน้ต",
    },
    "noteTitle": {
        "en": "Note title", "zh": "笔记标题", "ja": "ノートのタイトル", "ko": "노트 제목", "ms": "Tajuk nota", "vi": "Tiêu đề ghi chú", "th": "ชื่อโน้ต",
    },
    "noteContentHint": {
        "en": "Enter note content…", "zh": "输入笔记内容……", "ja": "ノートの内容を入力…", "ko": "노트 내용을 입력하세요…", "ms": "Masukkan kandungan nota…", "vi": "Nhập nội dung ghi chú…", "th": "ป้อนเนื้อหาโน้ต…",
    },
    "bookmarksTitle": {
        "en": "My bookmarks", "zh": "我的收藏", "ja": "ブックマーク", "ko": "내 북마크", "ms": "Penanda buku saya", "vi": "Dấu trang của tôi", "th": "บุ๊กมาร์กของฉัน",
    },
    "bookmarksLoadFailed": {
        "en": "Could not load bookmarks", "zh": "收藏加载失败", "ja": "ブックマークを読み込めませんでした", "ko": "북마크를 불러오지 못했습니다", "ms": "Gagal memuatkan penanda buku", "vi": "Không thể tải dấu trang", "th": "โหลดบุ๊กมาร์กไม่สำเร็จ",
    },
    "reload": {
        "en": "Reload", "zh": "重新加载", "ja": "再読み込み", "ko": "다시 불러오기", "ms": "Muat semula", "vi": "Tải lại", "th": "โหลดใหม่",
    },
    "noBookmarks": {
        "en": "No bookmarks yet", "zh": "还没有收藏", "ja": "まだブックマークはありません", "ko": "아직 북마크가 없습니다", "ms": "Belum ada penanda buku", "vi": "Chưa có dấu trang", "th": "ยังไม่มีบุ๊กมาร์ก",
    },
    "noBookmarksDescription": {
        "en": "Posts you bookmark from the post details screen will appear here.", "zh": "在帖子详情页点击收藏后，会出现在这里。", "ja": "投稿詳細でブックマークした投稿がここに表示されます。", "ko": "게시물 상세 화면에서 북마크한 게시물이 여기에 표시됩니다.", "ms": "Siaran yang anda tandai dari skrin butiran akan muncul di sini.", "vi": "Các bài viết bạn đánh dấu từ trang chi tiết sẽ xuất hiện ở đây.", "th": "โพสต์ที่คุณบุ๊กมาร์กจากหน้ารายละเอียดจะแสดงที่นี่",
    },
    "postImageLimit": {
        "en": "Each post can contain up to 9 images", "zh": "每篇帖子最多添加 9 张图片", "ja": "1件の投稿には最大9枚の画像を追加できます", "ko": "게시물 하나에 최대 9개의 이미지를 추가할 수 있습니다", "ms": "Setiap siaran boleh mengandungi sehingga 9 imej", "vi": "Mỗi bài viết có thể chứa tối đa 9 ảnh", "th": "แต่ละโพสต์เพิ่มรูปได้สูงสุด 9 รูป",
    },
    "imagePlacement": {
        "en": "Where should the image go?", "zh": "图片放在哪里？", "ja": "画像をどこに配置しますか？", "ko": "이미지를 어디에 배치할까요?", "ms": "Di manakah imej perlu diletakkan?", "vi": "Đặt ảnh ở đâu?", "th": "ต้องการวางรูปไว้ที่ไหน",
    },
    "imagesAtTop": {
        "en": "At the top of the post", "zh": "放在文章顶部", "ja": "投稿の上部", "ko": "게시물 상단", "ms": "Di bahagian atas siaran", "vi": "Ở đầu bài viết", "th": "ไว้ด้านบนของโพสต์",
    },
    "imagesAtTopDescription": {
        "en": "Keep the existing top-image layout", "zh": "保持原来的图片展示方式", "ja": "従来の上部画像レイアウトを維持します", "ko": "기존 상단 이미지 표시 방식을 유지합니다", "ms": "Kekalkan susun atur imej di bahagian atas", "vi": "Giữ cách hiển thị ảnh ở đầu bài như hiện tại", "th": "คงรูปแบบการแสดงรูปด้านบนเดิม",
    },
    "insertIntoBody": {
        "en": "Insert into body", "zh": "插入正文", "ja": "本文に挿入", "ko": "본문에 삽입", "ms": "Sisip ke dalam kandungan", "vi": "Chèn vào nội dung", "th": "แทรกในเนื้อหา",
    },
    "insertIntoBodyDescription": {
        "en": "Insert at the current text cursor position", "zh": "插入到当前文字光标的位置", "ja": "現在のテキストカーソル位置に挿入します", "ko": "현재 텍스트 커서 위치에 삽입합니다", "ms": "Sisip pada kedudukan kursor teks semasa", "vi": "Chèn tại vị trí con trỏ văn bản hiện tại", "th": "แทรกที่ตำแหน่งเคอร์เซอร์ข้อความปัจจุบัน",
    },
    "fillTitleAndContent": {
        "en": "Enter a title and content", "zh": "请填写标题和内容", "ja": "タイトルと内容を入力してください", "ko": "제목과 내용을 입력하세요", "ms": "Masukkan tajuk dan kandungan", "vi": "Hãy nhập tiêu đề và nội dung", "th": "กรุณากรอกชื่อเรื่องและเนื้อหา",
    },
    "postBodyLimit": {
        "en": "Body text can be at most 5000 characters", "zh": "正文最多 5000 字", "ja": "本文は最大5000文字です", "ko": "본문은 최대 5000자까지 입력할 수 있습니다", "ms": "Kandungan maksimum ialah 5000 aksara", "vi": "Nội dung tối đa 5000 ký tự", "th": "เนื้อหาได้สูงสุด 5000 ตัวอักษร",
    },
    "publishedInChannel": {
        "en": "Published in the {language} channel", "zh": "已在{language}频道发布成功", "ja": "{language}チャンネルに投稿しました", "ko": "{language} 채널에 게시했습니다", "ms": "Diterbitkan dalam saluran {language}", "vi": "Đã đăng trong kênh {language}", "th": "เผยแพร่ในช่อง {language} แล้ว",
    },
    "deleteImage": {
        "en": "Delete image", "zh": "删除图片", "ja": "画像を削除", "ko": "이미지 삭제", "ms": "Padam imej", "vi": "Xóa ảnh", "th": "ลบรูปภาพ",
    },
    "deleteImageConfirm": {
        "en": "Delete this image?", "zh": "确定要删除这张图片吗？", "ja": "この画像を削除しますか？", "ko": "이 이미지를 삭제할까요?", "ms": "Padam imej ini?", "vi": "Xóa ảnh này?", "th": "ลบรูปภาพนี้หรือไม่",
    },
    "postTitleHint": {
        "en": "Enter post title…", "zh": "输入帖子标题...", "ja": "投稿タイトルを入力…", "ko": "게시물 제목을 입력하세요…", "ms": "Masukkan tajuk siaran…", "vi": "Nhập tiêu đề bài viết…", "th": "ป้อนชื่อโพสต์…",
    },
    "postContentHint": {
        "en": "Enter post content…", "zh": "输入帖子内容……", "ja": "投稿内容を入力…", "ko": "게시물 내용을 입력하세요…", "ms": "Masukkan kandungan siaran…", "vi": "Nhập nội dung bài viết…", "th": "ป้อนเนื้อหาโพสต์…",
    },
    "optionalImages": {
        "en": "Images (optional)", "zh": "图片（可选）", "ja": "画像（任意）", "ko": "이미지(선택 사항)", "ms": "Imej (pilihan)", "vi": "Ảnh (không bắt buộc)", "th": "รูปภาพ (ไม่บังคับ)",
    },
    "insertingImage": {
        "en": "Inserting image…", "zh": "正在插入图片...", "ja": "画像を挿入中…", "ko": "이미지 삽입 중…", "ms": "Menyisip imej…", "vi": "Đang chèn ảnh…", "th": "กำลังแทรกรูป…",
    },
    "limitReached": {
        "en": "Limit reached", "zh": "已达上限", "ja": "上限に達しました", "ko": "한도에 도달했습니다", "ms": "Had telah dicapai", "vi": "Đã đạt giới hạn", "th": "ถึงขีดจำกัดแล้ว",
    },
    "uploadingInlineImage": {
        "en": "Uploading and inserting image into the body…", "zh": "正在上传并插入正文图片...", "ja": "画像をアップロードして本文に挿入中…", "ko": "이미지를 업로드해 본문에 삽입하는 중…", "ms": "Memuat naik dan menyisip imej ke dalam kandungan…", "vi": "Đang tải lên và chèn ảnh vào nội dung…", "th": "กำลังอัปโหลดและแทรกรูปลงในเนื้อหา…",
    },
    "uploadProgress": {
        "en": "Uploading {percent}%", "zh": "上传中 {percent}%", "ja": "アップロード中 {percent}%", "ko": "업로드 중 {percent}%", "ms": "Memuat naik {percent}%", "vi": "Đang tải lên {percent}%", "th": "กำลังอัปโหลด {percent}%",
    },
    "postDetail": {
        "en": "Post details", "zh": "帖子详情", "ja": "投稿詳細", "ko": "게시물 상세", "ms": "Butiran siaran", "vi": "Chi tiết bài viết", "th": "รายละเอียดโพสต์",
    },
    "postNotFound": {
        "en": "Post not found", "zh": "帖子不存在", "ja": "投稿が見つかりません", "ko": "게시물을 찾을 수 없습니다", "ms": "Siaran tidak ditemui", "vi": "Không tìm thấy bài viết", "th": "ไม่พบโพสต์",
    },
    "currentLanguageUnavailable": {
        "en": "Could not determine the current language", "zh": "无法确定当前语言", "ja": "現在の言語を判定できません", "ko": "현재 언어를 확인할 수 없습니다", "ms": "Tidak dapat menentukan bahasa semasa", "vi": "Không thể xác định ngôn ngữ hiện tại", "th": "ไม่สามารถระบุภาษาปัจจุบันได้",
    },
    "postUpdated": {
        "en": "Post updated ✨", "zh": "帖子已更新 ✨", "ja": "投稿を更新しました ✨", "ko": "게시물이 업데이트되었습니다 ✨", "ms": "Siaran dikemas kini ✨", "vi": "Đã cập nhật bài viết ✨", "th": "อัปเดตโพสต์แล้ว ✨",
    },
    "bookmarkActionFailed": {
        "en": "Bookmark action failed", "zh": "收藏操作失败", "ja": "ブックマーク操作に失敗しました", "ko": "북마크 작업에 실패했습니다", "ms": "Tindakan penanda buku gagal", "vi": "Thao tác dấu trang thất bại", "th": "การบุ๊กมาร์กล้มเหลว",
    },
    "sharePost": {
        "en": "Share post", "zh": "分享帖子", "ja": "投稿を共有", "ko": "게시물 공유", "ms": "Kongsi siaran", "vi": "Chia sẻ bài viết", "th": "แชร์โพสต์",
    },
    "postLinkCopied": {
        "en": "Post link copied", "zh": "帖子链接已复制", "ja": "投稿リンクをコピーしました", "ko": "게시물 링크가 복사되었습니다", "ms": "Pautan siaran disalin", "vi": "Đã sao chép liên kết bài viết", "th": "คัดลอกลิงก์โพสต์แล้ว",
    },
    "languageVersionAvailable": {
        "en": "Language version available · Tap to view", "zh": "已有语言版本 · 点击查看", "ja": "言語版があります · タップして表示", "ko": "언어 버전 있음 · 눌러서 보기", "ms": "Versi bahasa tersedia · Ketik untuk lihat", "vi": "Đã có phiên bản ngôn ngữ · Nhấn để xem", "th": "มีเวอร์ชันภาษาแล้ว · แตะเพื่อดู",
    },
    "noLanguageVersion": {
        "en": "No language version yet · Tap to translate", "zh": "尚无语言版本 · 点击翻译", "ja": "言語版はまだありません · タップして翻訳", "ko": "언어 버전 없음 · 눌러서 번역", "ms": "Belum ada versi bahasa · Ketik untuk terjemah", "vi": "Chưa có phiên bản ngôn ngữ · Nhấn để dịch", "th": "ยังไม่มีเวอร์ชันภาษา · แตะเพื่อแปล",
    },
    "chooseTranslationMethod": {
        "en": "Choose translation method", "zh": "选择翻译方式", "ja": "翻訳方法を選択", "ko": "번역 방식 선택", "ms": "Pilih kaedah terjemahan", "vi": "Chọn cách dịch", "th": "เลือกวิธีแปล",
    },
    "aiTranslationDescription": {
        "en": "You can edit the AI-generated translation before publishing", "zh": "AI 生成译文后可以继续修改", "ja": "AI生成の翻訳は公開前に編集できます", "ko": "AI가 생성한 번역을 게시 전에 수정할 수 있습니다", "ms": "Anda boleh mengedit terjemahan AI sebelum menerbitkan", "vi": "Bạn có thể chỉnh sửa bản dịch do AI tạo trước khi đăng", "th": "คุณสามารถแก้ไขคำแปลที่ AI สร้างก่อนเผยแพร่ได้",
    },
    "manualTranslationDescription": {
        "en": "Start from a blank translation and write it yourself", "zh": "从空白开始自己填写译文", "ja": "空の翻訳から自分で入力します", "ko": "빈 번역에서 직접 작성합니다", "ms": "Mulakan dengan terjemahan kosong dan tulis sendiri", "vi": "Bắt đầu từ bản dịch trống và tự nhập", "th": "เริ่มจากคำแปลว่างและเขียนเอง",
    },
    "deletePost": {
        "en": "Delete post", "zh": "删除帖子", "ja": "投稿を削除", "ko": "게시물 삭제", "ms": "Padam siaran", "vi": "Xóa bài viết", "th": "ลบโพสต์",
    },
    "deletePostConfirm": {
        "en": "Delete this post? This action cannot be undone.", "zh": "确定要删除这个帖子吗？此操作不可撤销。", "ja": "この投稿を削除しますか？この操作は元に戻せません。", "ko": "이 게시물을 삭제할까요? 이 작업은 되돌릴 수 없습니다.", "ms": "Padam siaran ini? Tindakan ini tidak boleh dibuat asal.", "vi": "Xóa bài viết này? Thao tác này không thể hoàn tác.", "th": "ลบโพสต์นี้หรือไม่ การดำเนินการนี้ย้อนกลับไม่ได้",
    },
    "confirmDelete": {
        "en": "Confirm delete", "zh": "确认删除", "ja": "削除を確認", "ko": "삭제 확인", "ms": "Sahkan padam", "vi": "Xác nhận xóa", "th": "ยืนยันการลบ",
    },
    "postDeleted": {
        "en": "Post deleted safely", "zh": "帖子已安全删除", "ja": "投稿を削除しました", "ko": "게시물이 삭제되었습니다", "ms": "Siaran telah dipadam", "vi": "Đã xóa bài viết", "th": "ลบโพสต์แล้ว",
    },
    "deleteThisImage": {
        "en": "Delete this image", "zh": "删除这张图片", "ja": "この画像を削除", "ko": "이 이미지 삭제", "ms": "Padam imej ini", "vi": "Xóa ảnh này", "th": "ลบรูปนี้",
    },
    "appendMoreImages": {
        "en": "Add more images", "zh": "追加更多图片", "ja": "画像をさらに追加", "ko": "이미지 더 추가", "ms": "Tambah lagi imej", "vi": "Thêm ảnh", "th": "เพิ่มรูปภาพอีก",
    },
    "reportSubmitted": {
        "en": "Report submitted. Thank you for your feedback.", "zh": "举报已提交，感谢你的反馈", "ja": "通報を送信しました。ご協力ありがとうございます。", "ko": "신고가 제출되었습니다. 피드백 감사합니다.", "ms": "Laporan dihantar. Terima kasih atas maklum balas anda.", "vi": "Đã gửi báo cáo. Cảm ơn phản hồi của bạn.", "th": "ส่งรายงานแล้ว ขอบคุณสำหรับความคิดเห็น",
    },
    "details": {
        "en": "Details", "zh": "详情", "ja": "詳細", "ko": "세부 정보", "ms": "Butiran", "vi": "Chi tiết", "th": "รายละเอียด",
    },
    "finishSorting": {
        "en": "Finish sorting", "zh": "完成排序", "ja": "並べ替えを完了", "ko": "정렬 완료", "ms": "Selesai menyusun", "vi": "Hoàn tất sắp xếp", "th": "จัดเรียงเสร็จ",
    },
    "reorderImages": {
        "en": "Reorder images", "zh": "重排图片", "ja": "画像を並べ替え", "ko": "이미지 순서 변경", "ms": "Susun semula imej", "vi": "Sắp xếp lại ảnh", "th": "จัดลำดับรูปภาพใหม่",
    },
    "editPost": {
        "en": "Edit post", "zh": "编辑帖子", "ja": "投稿を編集", "ko": "게시물 편집", "ms": "Edit siaran", "vi": "Chỉnh sửa bài viết", "th": "แก้ไขโพสต์",
    },
    "holdDragToReorder": {
        "en": "Press and hold the handle on the right to drag and reorder", "zh": "长按右侧控制手柄拖动排序", "ja": "右側のハンドルを長押ししてドラッグすると並べ替えられます", "ko": "오른쪽 핸들을 길게 눌러 드래그해 순서를 바꾸세요", "ms": "Tekan lama pemegang di kanan dan seret untuk menyusun semula", "vi": "Nhấn giữ tay cầm bên phải rồi kéo để sắp xếp", "th": "กดค้างที่ตัวจับด้านขวาแล้วลากเพื่อจัดลำดับ",
    },
    "imageNumber": {
        "en": "Image {index}", "zh": "第 {index} 张", "ja": "画像 {index}", "ko": "이미지 {index}", "ms": "Imej {index}", "vi": "Ảnh {index}", "th": "รูปที่ {index}",
    },
    "translationVersion": {
        "en": "Translation version", "zh": "翻译版本", "ja": "翻訳版", "ko": "번역 버전", "ms": "Versi terjemahan", "vi": "Phiên bản dịch", "th": "เวอร์ชันคำแปล",
    },
    "translationPublishedAt": {
        "en": "Translation published {time}", "zh": "译文发布于 {time}", "ja": "翻訳の公開: {time}", "ko": "번역 게시: {time}", "ms": "Terjemahan diterbitkan {time}", "vi": "Bản dịch được đăng lúc {time}", "th": "เผยแพร่คำแปลเมื่อ {time}",
    },
    "modifiedAt": {
        "en": "Modified {time}", "zh": "修改于 {time}", "ja": "更新: {time}", "ko": "수정: {time}", "ms": "Diubah {time}", "vi": "Đã sửa lúc {time}", "th": "แก้ไขเมื่อ {time}",
    },
    "bookmark": {
        "en": "Bookmark", "zh": "收藏", "ja": "ブックマーク", "ko": "북마크", "ms": "Tanda buku", "vi": "Dấu trang", "th": "บุ๊กมาร์ก",
    },
    "translate": {
        "en": "Translate", "zh": "翻译", "ja": "翻訳", "ko": "번역", "ms": "Terjemah", "vi": "Dịch", "th": "แปล",
    },
    "mainLanguage": {
        "en": "Primary language", "zh": "主语言", "ja": "主言語", "ko": "주 언어", "ms": "Bahasa utama", "vi": "Ngôn ngữ chính", "th": "ภาษาหลัก",
    },
    "titleRequired": {
        "en": "Title cannot be empty", "zh": "标题不能为空", "ja": "タイトルを空にできません", "ko": "제목은 비워 둘 수 없습니다", "ms": "Tajuk tidak boleh kosong", "vi": "Tiêu đề không được để trống", "th": "ชื่อเรื่องต้องไม่ว่าง",
    },
    "contentRequired": {
        "en": "Content cannot be empty", "zh": "内容不能为空", "ja": "内容を空にできません", "ko": "내용은 비워 둘 수 없습니다", "ms": "Kandungan tidak boleh kosong", "vi": "Nội dung không được để trống", "th": "เนื้อหาต้องไม่ว่าง",
    },
    "topImages": {
        "en": "Top images", "zh": "顶部图片", "ja": "上部画像", "ko": "상단 이미지", "ms": "Imej bahagian atas", "vi": "Ảnh đầu bài", "th": "รูปด้านบน",
    },
    "noTopImages": {
        "en": "No top images", "zh": "暂无顶部图片", "ja": "上部画像はありません", "ko": "상단 이미지가 없습니다", "ms": "Tiada imej bahagian atas", "vi": "Chưa có ảnh đầu bài", "th": "ยังไม่มีรูปด้านบน",
    },
    "close": {
        "en": "Close", "zh": "关闭", "ja": "閉じる", "ko": "닫기", "ms": "Tutup", "vi": "Đóng", "th": "ปิด",
    },
    "myNotesDescription": {
        "en": "View and manage all shared notes", "zh": "查看和管理所有共享笔记", "ja": "共有ノートをすべて表示・管理", "ko": "모든 공유 노트 보기 및 관리", "ms": "Lihat dan urus semua nota yang dikongsi", "vi": "Xem và quản lý tất cả ghi chú được chia sẻ", "th": "ดูและจัดการโน้ตที่แชร์ทั้งหมด",
    },
    "bookmarksDescription": {
        "en": "View bookmarked posts", "zh": "查看收藏的帖子", "ja": "ブックマークした投稿を表示", "ko": "북마크한 게시물 보기", "ms": "Lihat siaran yang ditanda", "vi": "Xem các bài viết đã đánh dấu", "th": "ดูโพสต์ที่บุ๊กมาร์ก",
    },
    "selectedCount": {
        "en": "Selected ({count})", "zh": "已选择 ({count})", "ja": "選択済み ({count})", "ko": "선택됨 ({count})", "ms": "Dipilih ({count})", "vi": "Đã chọn ({count})", "th": "เลือกแล้ว ({count})",
    },
    "chooseKnownLanguages": {
        "en": "Choose the languages you know", "zh": "选择你掌握的语言", "ja": "使用できる言語を選択", "ko": "사용 가능한 언어를 선택하세요", "ms": "Pilih bahasa yang anda kuasai", "vi": "Chọn các ngôn ngữ bạn biết", "th": "เลือกภาษาที่คุณรู้",
    },
    "languageCount": {
        "en": "{count} languages selected", "zh": "已选择 {count} 门语言", "ja": "{count}言語を選択", "ko": "{count}개 언어 선택됨", "ms": "{count} bahasa dipilih", "vi": "Đã chọn {count} ngôn ngữ", "th": "เลือกแล้ว {count} ภาษา",
    },
    "searchResults": {
        "en": "Search results", "zh": "搜索结果", "ja": "検索結果", "ko": "검색 결과", "ms": "Hasil carian", "vi": "Kết quả tìm kiếm", "th": "ผลการค้นหา",
    },
    "remove": {
        "en": "Remove", "zh": "移除", "ja": "削除", "ko": "제거", "ms": "Alih keluar", "vi": "Gỡ", "th": "นำออก",
    },
    "currentNativeLanguage": {
        "en": "Currently set as native", "zh": "当前设置为母语", "ja": "現在は母語に設定されています", "ko": "현재 모국어로 설정됨", "ms": "Kini ditetapkan sebagai bahasa ibunda", "vi": "Hiện được đặt là tiếng mẹ đẻ", "th": "ตั้งเป็นภาษาแม่อยู่ในขณะนี้",
    },
    "changeToProficiency": {
        "en": "Change to proficiency level", "zh": "改为熟练度", "ja": "習熟度に変更", "ko": "숙련도로 변경", "ms": "Tukar kepada tahap kemahiran", "vi": "Đổi sang mức độ thành thạo", "th": "เปลี่ยนเป็นระดับความชำนาญ",
    },
    "proficiency": {
        "en": "Proficiency", "zh": "熟练度", "ja": "習熟度", "ko": "숙련도", "ms": "Kemahiran", "vi": "Mức độ thành thạo", "th": "ความชำนาญ",
    },
    "setAsNativeLanguage": {
        "en": "Set as native language", "zh": "设为母语", "ja": "母語に設定", "ko": "모국어로 설정", "ms": "Tetapkan sebagai bahasa ibunda", "vi": "Đặt làm tiếng mẹ đẻ", "th": "ตั้งเป็นภาษาแม่",
    },
    "noLanguagesSelected": {
        "en": "No languages selected yet", "zh": "还没有选择语言", "ja": "まだ言語が選択されていません", "ko": "아직 선택한 언어가 없습니다", "ms": "Belum ada bahasa dipilih", "vi": "Chưa chọn ngôn ngữ nào", "th": "ยังไม่ได้เลือกภาษา",
    },
    "addLanguagePrompt": {
        "en": "Go to “Add language” to search and select", "zh": "前往“添加语言”搜索并选择", "ja": "「言語を追加」から検索して選択してください", "ko": "‘언어 추가’에서 검색하고 선택하세요", "ms": "Pergi ke “Tambah bahasa” untuk mencari dan memilih", "vi": "Vào “Thêm ngôn ngữ” để tìm và chọn", "th": "ไปที่ “เพิ่มภาษา” เพื่อค้นหาและเลือก",
    },
    "searchOtherLanguagePrompt": {
        "en": "Try another name, language code, or writing system", "zh": "尝试搜索其他名称、语言代码或文字系统", "ja": "別の名称、言語コード、または文字体系で検索してください", "ko": "다른 이름, 언어 코드 또는 문자 체계로 검색해 보세요", "ms": "Cuba nama lain, kod bahasa atau sistem tulisan", "vi": "Thử tên khác, mã ngôn ngữ hoặc hệ chữ", "th": "ลองค้นหาชื่ออื่น รหัสภาษา หรือระบบอักษร",
    },
    "collapse": {
        "en": "Show less", "zh": "收起", "ja": "折りたたむ", "ko": "접기", "ms": "Tunjuk kurang", "vi": "Thu gọn", "th": "ย่อ",
    },
    "showMore": {
        "en": "Show more", "zh": "查看更多", "ja": "もっと見る", "ko": "더 보기", "ms": "Tunjuk lagi", "vi": "Xem thêm", "th": "ดูเพิ่มเติม",
    },
    "selectedTagsCount": {
        "en": "Selected tags ({count}/10)", "zh": "已选标签 ({count}/10)", "ja": "選択済みタグ ({count}/10)", "ko": "선택된 태그 ({count}/10)", "ms": "Tag dipilih ({count}/10)", "vi": "Thẻ đã chọn ({count}/10)", "th": "แท็กที่เลือก ({count}/10)",
    },
}

PARAM_RE = re.compile(r"\{([A-Za-z][A-Za-z0-9_]*)\}")


def add_messages() -> None:
    for locale in LOCALES:
        path = L10N_DIR / f"app_{locale}.arb"
        data = json.loads(path.read_text(encoding="utf-8"))
        for key, values in M.items():
            value = values["vi"] if locale == "vi_Hani" else values[locale]
            data[key] = value
            if locale == "en":
                params = list(dict.fromkeys(PARAM_RE.findall(values["en"])))
                if params:
                    data[f"@{key}"] = {
                        "placeholders": {name: {"type": "String"} for name in params}
                    }
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def ensure_context_extension() -> None:
    text = WRAPPER.read_text(encoding="utf-8")
    if "package:flutter/widgets.dart" not in text:
        text = "import 'package:flutter/widgets.dart';\n\n" + text
    marker = "extension AppLocalizationsBuildContext on BuildContext"
    if marker not in text:
        text += (
            "\n"
            "extension AppLocalizationsBuildContext on BuildContext {\n"
            "  AppLocalizations get l10n => AppLocalizations.of(this)!;\n"
            "}\n"
        )
    WRAPPER.write_text(text, encoding="utf-8")


def ensure_import(path: Path, text: str) -> str:
    if "app/l10n/app_localizations.dart" in text:
        return text
    needle = "import 'package:flutter/material.dart';\n"
    package_import = "import 'package:glyphora_mobile/app/l10n/app_localizations.dart';\n"
    if needle in text:
        return text.replace(needle, needle + package_import, 1)
    return package_import + text


STATIC = {
    "未登录": "context.l10n.notLoggedIn",
    "当前用户不是聊天室成员": "context.l10n.currentUserNotChatMember",
    "找不到聊天对象": "context.l10n.chatPeerNotFound",
    "未知用户": "context.l10n.unknownUser",
    "全部语言": "context.l10n.allLanguages",
    "未指定语言": "context.l10n.unspecifiedLanguage",
    "未选择": "context.l10n.notSelected",
    "全部分类": "context.l10n.allCategories",
    "未分类": "context.l10n.uncategorized",
    "选择语言": "context.l10n.selectLanguage",
    "选择分类": "context.l10n.selectCategory",
    "笔记语言": "context.l10n.noteLanguage",
    "笔记分类": "context.l10n.noteCategory",
    "新建笔记": "context.l10n.newNote",
    "可以先设置笔记信息，也可以以后再修改。": "context.l10n.newNoteConfigDescription",
    "语言": "context.l10n.currentLanguage",
    "分类": "context.l10n.category",
    "共享": "context.l10n.sharing",
    "仅自己": "context.l10n.onlyMe",
    "创建笔记": "context.l10n.createNote",
    "我的笔记": "context.l10n.myNotes",
    "请先登录": "context.l10n.pleaseSignIn",
    "清除": "context.l10n.clear",
    "笔记加载失败": "context.l10n.notesLoadFailed",
    "正在创建": "context.l10n.creating",
    "没有符合条件的笔记": "context.l10n.noMatchingNotes",
    "还没有笔记": "context.l10n.noNotesYet",
    "清除筛选": "context.l10n.clearFilters",
    "点击右下角新建": "context.l10n.tapFabToCreateNote",
    "无标题笔记": "context.l10n.untitledNote",
    "暂无内容": "context.l10n.noContent",
    "仅自己可见": "context.l10n.privateNote",
    "用户": "context.l10n.user",
    "共享成员": "context.l10n.sharedMembers",
    "完成": "context.l10n.done",
    "搜索昵称或用户名": "context.l10n.searchNicknameOrUsername",
    "没有找到用户": "context.l10n.noUsersFound",
    "创建者没有开放编辑权限": "context.l10n.editingNotAllowed",
    "每条笔记最多插入 9 张图片": "context.l10n.noteImageLimit",
    "选择帖子分类": "context.l10n.selectPostCategory",
    "选择主语言": "context.l10n.choosePrimaryLanguage",
    "笔记已发布为帖子": "context.l10n.notePublishedAsPost",
    "删除共享笔记？": "context.l10n.deleteSharedNote",
    "删除后，这条笔记会从双方的笔记列表中消失。": "context.l10n.deleteSharedNoteDescription",
    "取消": "context.l10n.cancel",
    "删除": "context.l10n.delete",
    "发布为帖子": "context.l10n.publishAsPost",
    "使用笔记分类，选择主语言后进入发帖页": "context.l10n.publishAsPostDescription",
    "帖子分类": "context.l10n.postCategory",
    "当前仅自己可见": "context.l10n.privateNote",
    "允许共享成员编辑": "context.l10n.allowSharedMembersEdit",
    "共享成员可以修改文字和图片": "context.l10n.sharedMembersCanEdit",
    "共享成员只能查看这条笔记": "context.l10n.sharedMembersViewOnly",
    "你可以编辑这条笔记": "context.l10n.canEditThisNote",
    "这条笔记只能查看": "context.l10n.readOnlyNote",
    "删除笔记": "context.l10n.deleteNote",
    "共享笔记": "context.l10n.sharedNote",
    "这条笔记已被删除": "context.l10n.noteDeleted",
    "插入图片": "context.l10n.insertImage",
    "笔记设置": "context.l10n.noteSettings",
    "笔记标题": "context.l10n.noteTitle",
    "输入笔记内容……": "context.l10n.noteContentHint",
    "我的收藏": "context.l10n.bookmarksTitle",
    "刷新": "context.l10n.refresh",
    "收藏加载失败": "context.l10n.bookmarksLoadFailed",
    "重新加载": "context.l10n.reload",
    "还没有收藏": "context.l10n.noBookmarks",
    "在帖子详情页点击收藏后，会出现在这里。": "context.l10n.noBookmarksDescription",
    "每篇帖子最多添加 9 张图片": "context.l10n.postImageLimit",
    "图片放在哪里？": "context.l10n.imagePlacement",
    "放在文章顶部": "context.l10n.imagesAtTop",
    "保持原来的图片展示方式": "context.l10n.imagesAtTopDescription",
    "插入正文": "context.l10n.insertIntoBody",
    "插入到当前文字光标的位置": "context.l10n.insertIntoBodyDescription",
    "请填写标题和内容": "context.l10n.fillTitleAndContent",
    "正文最多 5000 字": "context.l10n.postBodyLimit",
    "删除图片": "context.l10n.deleteImage",
    "确定要删除这张图片吗？": "context.l10n.deleteImageConfirm",
    "发帖": "context.l10n.publishPost",
    "标题": "context.l10n.title",
    "输入帖子标题...": "context.l10n.postTitleHint",
    "输入帖子内容……": "context.l10n.postContentHint",
    "图片（可选）": "context.l10n.optionalImages",
    "正在插入图片...": "context.l10n.insertingImage",
    "已达上限": "context.l10n.limitReached",
    "添加图片": "context.l10n.addMoreImages",
    "正在上传并插入正文图片...": "context.l10n.uploadingInlineImage",
    "发布中...": "context.l10n.publishing",
    "发布帖子": "context.l10n.publishPost",
    "帖子详情": "context.l10n.postDetail",
    "帖子加载失败": "context.l10n.postsLoadFailed",
    "重试": "context.l10n.retry",
    "帖子不存在": "context.l10n.postNotFound",
    "刚刚": "context.l10n.justNow",
    "无法确定当前语言": "context.l10n.currentLanguageUnavailable",
    "帖子已更新 ✨": "context.l10n.postUpdated",
    "收藏操作失败": "context.l10n.bookmarkActionFailed",
    "分享帖子": "context.l10n.sharePost",
    "帖子链接已复制": "context.l10n.postLinkCopied",
    "已有语言版本 · 点击查看": "context.l10n.languageVersionAvailable",
    "尚无语言版本 · 点击翻译": "context.l10n.noLanguageVersion",
    "选择翻译方式": "context.l10n.chooseTranslationMethod",
    "AI 翻译": "context.l10n.aiTranslation",
    "AI 生成译文后可以继续修改": "context.l10n.aiTranslationDescription",
    "自己翻译": "context.l10n.manualTranslation",
    "从空白开始自己填写译文": "context.l10n.manualTranslationDescription",
    "删除帖子": "context.l10n.deletePost",
    "确定要删除这个帖子吗？此操作不可撤销。": "context.l10n.deletePostConfirm",
    "确认删除": "context.l10n.confirmDelete",
    "帖子已安全删除": "context.l10n.postDeleted",
    "删除这张图片": "context.l10n.deleteThisImage",
    "追加更多图片": "context.l10n.appendMoreImages",
    "举报已提交，感谢你的反馈": "context.l10n.reportSubmitted",
    "详情": "context.l10n.details",
    "完成排序": "context.l10n.finishSorting",
    "重排图片": "context.l10n.reorderImages",
    "编辑帖子": "context.l10n.editPost",
    "编辑历史": "context.l10n.postEditHistory",
    "举报帖子": "context.l10n.reportPost",
    "长按右侧控制手柄拖动排序": "context.l10n.holdDragToReorder",
    "翻译版本": "context.l10n.translationVersion",
    "无内容": "context.l10n.noContent",
    "赞同": "context.l10n.like",
    "评论": "context.l10n.comment",
    "收藏": "context.l10n.bookmark",
    "翻译": "context.l10n.translate",
    "分享": "context.l10n.share",
    "主语言": "context.l10n.mainLanguage",
    "每篇帖子最多 9 张图片": "context.l10n.postImageLimit",
    "标题不能为空": "context.l10n.titleRequired",
    "内容不能为空": "context.l10n.contentRequired",
    "保存中…": "context.l10n.saving",
    "保存": "context.l10n.save",
    "顶部图片": "context.l10n.topImages",
    "添加": "context.l10n.add",
    "暂无顶部图片": "context.l10n.noTopImages",
    "关闭": "context.l10n.close",
    "标签更新成功": "context.l10n.tagsUpdated",
    "语言已更新": "context.l10n.languagesUpdated",
    "生日已更新": "context.l10n.birthdayUpdated",
    "头像更新成功": "context.l10n.avatarUpdated",
    "修改昵称": "context.l10n.editNicknameTitle",
    "新的昵称": "context.l10n.newNicknameLabel",
    "给自己起个好听的名字吧": "context.l10n.nicknameHint",
    "昵称修改成功": "context.l10n.nicknameUpdated",
    "修改用户名": "context.l10n.editUsernameTitle",
    "新的用户名": "context.l10n.newUsernameLabel",
    "用户名将作为你的唯一标识": "context.l10n.usernameHint",
    "用户名修改成功": "context.l10n.usernameUpdated",
    "编辑个人简介": "context.l10n.editBioTitle",
    "介绍一下你自己...": "context.l10n.bioHint",
    "个人简介更新成功": "context.l10n.bioUpdated",
    "查看和管理所有共享笔记": "context.l10n.myNotesDescription",
    "查看收藏的帖子": "context.l10n.bookmarksDescription",
    "暂无帖子": "context.l10n.noPosts",
    "选择文字系统": "context.l10n.selectWritingSystem",
    "添加语言": "context.l10n.addLanguage",
    "语言能力": "context.l10n.languageAbility",
    "选择你掌握的语言": "context.l10n.chooseKnownLanguages",
    "搜索语言名称或代码": "context.l10n.searchLanguageNameOrCode",
    "搜索结果": "context.l10n.searchResults",
    "移除": "context.l10n.remove",
    "母语": "context.l10n.nativeLanguage",
    "当前设置为母语": "context.l10n.currentNativeLanguage",
    "改为熟练度": "context.l10n.changeToProficiency",
    "熟练度": "context.l10n.proficiency",
    "设为母语": "context.l10n.setAsNativeLanguage",
    "还没有选择语言": "context.l10n.noLanguagesSelected",
    "前往“添加语言”搜索并选择": "context.l10n.addLanguagePrompt",
    "没有找到相关语言": "context.l10n.noLanguagesFound",
    "尝试搜索其他名称、语言代码或文字系统": "context.l10n.searchOtherLanguagePrompt",
    "收起": "context.l10n.collapse",
    "查看更多": "context.l10n.showMore",
    "编辑个性标签": "context.l10n.editTagsTitle",
    "输入自定义标签": "context.l10n.customTagHint",
    "推荐标签": "context.l10n.recommendTags",
    "该标签已经添加过了": "context.l10n.tagExists",
    "最多只能添加10个标签": "context.l10n.tagMax",
}

# Dynamic literals that should retain values while localizing their surrounding copy.
DYNAMIC = {
    "加载用户失败：$error": "'${context.l10n.loadFailed}: $error'",
    "创建笔记失败：$error": "'${context.l10n.createNoteFailed}: $error'",
    "加载笔记失败：$error": "'${context.l10n.notesLoadFailed}: $error'",
    "保存失败：$error": "'${context.l10n.updateFailed}: $error'",
    "权限设置失败：$error": "'${context.l10n.updateFailed}: $error'",
    "更新共享成员失败：$error": "'${context.l10n.updateFailed}: $error'",
    "插入图片失败：$error": "'${context.l10n.updateFailed}: $error'",
    "修改分类失败：$error": "'${context.l10n.updateFailed}: $error'",
    "删除失败：$error": "'${context.l10n.updateFailed}: $error'",
    "插入图片失败: $error": "'${context.l10n.updateFailed}: $error'",
    "复制笔记正文图片失败：$error": "'${context.l10n.updateFailed}: $error'",
    "上传失败: $error": "'${context.l10n.updateFailed}: $error'",
    "在${widget.languageName}频道发布成功": "context.l10n.publishedInChannel(widget.languageName)",
    "上传中 ${(progress * 100).toStringAsFixed(0)}%": "context.l10n.uploadProgress((progress * 100).toStringAsFixed(0))",
    "${difference.inMinutes} 分钟前": "'${difference.inMinutes}${context.l10n.minutesAgo}'",
    "${difference.inHours} 小时前": "'${difference.inHours}${context.l10n.hoursAgo}'",
    "${difference.inDays} 天前": "'${difference.inDays}${context.l10n.daysAgo}'",
    "操作失败: $e": "'${context.l10n.operationFailed}: $e'",
    "收藏操作失败: $e": "'${context.l10n.bookmarkActionFailed}: $e'",
    "切换语言失败: $e": "'${context.l10n.updateFailed}: $e'",
    "删除失败: $e": "'${context.l10n.updateFailed}: $e'",
    "图片上传失败: $e": "'${context.l10n.updateFailed}: $e'",
    "同步失败: $e": "'${context.l10n.updateFailed}: $e'",
    "排序失败: $e": "'${context.l10n.updateFailed}: $e'",
    "第 ${index + 1} 张": "context.l10n.imageNumber('${index + 1}')",
    "译文发布于 ${_formatVersionTimestamp(_currentVersionCreatedAt!)}": "context.l10n.translationPublishedAt(_formatVersionTimestamp(_currentVersionCreatedAt!))",
    "修改于 ${_formatTimestamp(_post.updatedAt)}": "context.l10n.modifiedAt(_formatTimestamp(_post.updatedAt))",
    "$_likeCount 赞同": "'$_likeCount ${context.l10n.like}'",
    "${language.nameOf(uiLanguageCode)} · 主语言": "'${language.nameOf(uiLanguageCode)} · ${context.l10n.mainLanguage}'",
    "顶部图片上传失败: $e": "'${context.l10n.updateFailed}: $e'",
    "更新失败: $e": "'${context.l10n.updateFailed}: $e'",
    "需要相册权限: ${e.message}": "'${context.l10n.galleryPermission}: ${e.message}'",
    "头像更新失败: $e": "'${context.l10n.avatarFailed}: $e'",
    "修改失败: $e": "'${context.l10n.updateFailed}: $e'",
    "已选择 (${_selectedLanguages.length})": "context.l10n.selectedCount('${_selectedLanguages.length}')",
    "已选择 ${_selectedLanguages.length} 门语言": "context.l10n.languageCount('${_selectedLanguages.length}')",
    "${_visibleLanguages.length} 门": "context.l10n.languageCount('${_visibleLanguages.length}')",
    "${_calculateAge(birthday!)} 岁": "context.l10n.ageYears('${_calculateAge(birthday!)}')",
    "已选标签 (${selected.length}/10)": "context.l10n.selectedTagsCount('${selected.length}')",
}

TARGETS = [
    "lib/features/chat/presentation/screens/chat_screen.dart",
    "lib/features/notes/presentation/screens/all_notes_screen.dart",
    "lib/features/notes/presentation/screens/note_editor_screen.dart",
    "lib/features/post/presentation/screens/bookmarked_posts_screen.dart",
    "lib/features/post/presentation/screens/create_post_screen.dart",
    "lib/features/post/presentation/screens/post_detail_screen.dart",
    "lib/features/profile/presentation/screens/my_profile_screen.dart",
    "lib/features/profile/presentation/widgets/language_editor_sheet.dart",
    "lib/features/profile/presentation/widgets/profile_header.dart",
    "lib/features/profile/presentation/widgets/profile_language_section.dart",
    "lib/features/profile/presentation/widgets/tag_editor_sheet.dart",
]


def replace_quoted(text: str, source: str, replacement: str) -> str:
    # All source UI literals in this migration use single quotes. Double-quoted
    # support is included for future-proofing.
    text = text.replace("'" + source + "'", replacement)
    text = text.replace('"' + source + '"', replacement)
    return text


def special_replacements(text: str) -> str:
    text = text.replace(
        "value: sharedUserIds.isEmpty\n                                ? '仅自己'\n                                : '已选择 '\n                                      '${sharedUserIds.length} 人',",
        "value: sharedUserIds.isEmpty\n                                ? context.l10n.onlyMe\n                                : context.l10n.selectedPeople('${sharedUserIds.length}'),",
    )
    text = text.replace(
        "  String _buildSharedLabel(List<String> userIds) {\n    if (userIds.isEmpty) {\n      return '仅自己可见';\n    }\n\n    final names = userIds\n        .map((userId) => _usersById[userId]?.name ?? '用户')\n        .toList();\n\n    if (names.length == 1) {\n      return '与 ${names.first} 共享';\n    }\n\n    if (names.length == 2) {\n      return '与 ${names.join('、')} 共享';\n    }\n\n    return '与 ${names.take(2).join('、')} 等 '\n        '${names.length} 人共享';\n  }",
        "  String _buildSharedLabel(List<String> userIds) {\n    if (userIds.isEmpty) {\n      return context.l10n.privateNote;\n    }\n\n    final names = userIds\n        .map((userId) => _usersById[userId]?.name ?? context.l10n.user)\n        .toList();\n\n    if (names.length == 1) {\n      return context.l10n.sharedWithUser(names.first);\n    }\n\n    if (names.length == 2) {\n      return context.l10n.sharedWithUsers(names.join('、'));\n    }\n\n    return context.l10n.sharedWithMany(\n      names.take(2).join('、'),\n      '${names.length}',\n    );\n  }",
    )
    text = text.replace(
        "_sharedUserIds.isEmpty\n                            ? '当前仅自己可见'\n                            : '已共享给 ${_sharedUserIds.length} 人'",
        "_sharedUserIds.isEmpty\n                            ? context.l10n.privateNote\n                            : context.l10n.sharedWithCount('${_sharedUserIds.length}')",
    )
    text = text.replace(
        "'共 ${_sharedUserIds.length + 1} 人'",
        "context.l10n.membersCount('${_sharedUserIds.length + 1}')",
    )
    return text


def matching_end(text: str, open_index: int) -> int | None:
    pairs = {"(": ")", "[": "]", "{": "}"}
    opener = text[open_index]
    closer = pairs.get(opener)
    if closer is None:
        return None
    stack = [closer]
    quote = None
    escape = False
    i = open_index + 1
    while i < len(text):
        ch = text[i]
        if quote is not None:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                quote = None
            i += 1
            continue
        if ch in ("'", '"'):
            quote = ch
            i += 1
            continue
        if ch in pairs:
            stack.append(pairs[ch])
        elif stack and ch == stack[-1]:
            stack.pop()
            if not stack:
                return i
        i += 1
    return None


def remove_invalid_const(text: str) -> str:
    # Remove only const expressions that now contain a runtime l10n lookup.
    # This preserves unrelated const constructors/default values.
    while True:
        changed = False
        for match in list(re.finditer(r"\bconst\b", text)):
            start = match.start()
            i = match.end()
            while i < len(text) and text[i].isspace():
                i += 1
            # Generic collection: const <T>[...]
            if i < len(text) and text[i] == "<":
                depth = 1
                i += 1
                while i < len(text) and depth:
                    if text[i] == "<": depth += 1
                    elif text[i] == ">": depth -= 1
                    i += 1
                while i < len(text) and text[i].isspace(): i += 1
            # Constructor name: advance to its opening paren; collection starts directly.
            if i >= len(text):
                continue
            if text[i] not in "([{":
                candidates = [p for p in (text.find("(", i), text.find("[", i), text.find("{", i)) if p != -1]
                if not candidates:
                    continue
                open_index = min(candidates)
                # Do not jump across a statement boundary.
                boundary = min([p for p in (text.find(";", i), text.find("\n", i)) if p != -1] or [len(text)])
                if open_index > boundary and text[open_index] != "(":
                    continue
            else:
                open_index = i
            end = matching_end(text, open_index)
            if end is None:
                continue
            segment = text[start:end + 1]
            if "context.l10n" in segment:
                text = text[:start] + text[match.end():]
                changed = True
                break
        if not changed:
            return text


def migrate_files() -> None:
    for rel in TARGETS:
        path = ROOT / rel
        text = path.read_text(encoding="utf-8")
        text = ensure_import(path, text)
        text = special_replacements(text)
        for source, replacement in DYNAMIC.items():
            text = replace_quoted(text, source, replacement)
        for source, replacement in STATIC.items():
            text = replace_quoted(text, source, replacement)
        text = remove_invalid_const(text)
        path.write_text(text, encoding="utf-8")


def update_audit_exclusions() -> None:
    path = ROOT / "tool" / "audit_hardcoded_ui.py"
    text = path.read_text(encoding="utf-8")
    old = 'IGNORE_EXACT = {\n    "年-月-日",\n}'
    new = '''IGNORE_EXACT = {
    "年-月-日",
    # Language/script self-names should remain in their native form.
    "简", "繁", "中文", "日本語", "한국어", "ภาษาไทย",
    # Preset profile tags are stored as content values, not UI chrome. Translating
    # them in-place would mutate persisted tag identity across locales.
    "前端", "后端", "全栈", "机器学习", "深度学习", "小程序", "游戏开发",
    "摄影", "旅行", "美食", "音乐", "电影", "读书", "健身", "篮球",
    "足球", "跑步", "游泳", "学生", "上班族", "创业者", "自由职业",
}'''
    if old in text:
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")


def main() -> None:
    add_messages()
    ensure_context_extension()
    migrate_files()
    update_audit_exclusions()
    print(f"Added {len(M)} ARB messages and migrated hard-coded Flutter UI strings.")


if __name__ == "__main__":
    main()
