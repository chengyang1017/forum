#!/usr/bin/env python3
import json
import re
import unicodedata
from collections import Counter
from pathlib import Path

# Exact phrase mappings found in the user's Bảng Chữ Hán Nôm Chuẩn / extracted
# phrase-example database. Phrase matches always win over single-word readings.
PHRASES = {
    'ngôn ngữ': '言語', 'nội dung': '內容', 'sở thích': '所適', 'đề xuất': '提出',
    'hiển thị': '顯示', 'kết nối': '結綏', 'mọi người': '𤗆𠊛', 'ảnh hưởng': '影響',
    'phương pháp': '方法', 'tiếp tục': '接續', 'cụ thể': '具體', 'thời gian': '時間',
    'bình luận': '評論', 'quảng cáo': '廣告', 'quấy rối': '撌𦇒', 'bắt nạt': '扒㖏',
    'thù ghét': '讎恄', 'tình dục': '情欲', 'bạo lực': '暴力', 'bổ sung': '補充',
    'kiểm duyệt': '檢閱', 'chia sẻ': '𢺹𢩿', 'hồ sơ': '糊疏', 'thất bại': '失敗',
    'không thể': '空体', 'ghi chú': '𥱬註', 'cài đặt': '掑撻', 'tài khoản': '財款',
    'liên kết': '連結', 'hướng dẫn': '向引', 'an toàn': '安全', 'thay đổi': '𠊝𢷮',
    'bảo mật': '保密', 'địa chỉ': '地址', 'sử dụng': '使用', 'liên hệ': '聯繫',
    'hỗ trợ': '互助', 'theo dõi': '蹺𠼲', 'lịch sử': '歷史', 'phát triển': '發展',
    'phiên bản': '翻版', 'bạn bè': '伴佊', 'ai đó': '埃妬', 'nhi khoa': '兒科',
    'dữ liệu': '與料', 'kết quả': '結果', 'chi tiết': '枝節', 'sao chép': '抄劄',
    'giới hạn': '界限', 'phân loại': '分類', 'vui lòng': '𢝙𢚸', 'không có': '空固',
    'bây giờ': '𣊾𣇞', 'cho phép': '朱法', 'có thể': '固体', 'không được': '空得',
    'đầu tiên': '頭先', 'tổng cộng': '總共', 'tối đa': '最多', 'bên phải': '邊沛',
    'bên cạnh': '邊𧣲', 'cập nhật': '及日', 'khôi phục': '恢復', 'kiểm tra': '檢查',
    'chữ cái': '𡨸𡣨', 'yêu cầu': '要求', 'thao tác': '操作', 'tin nhắn': '信𠴍',
    'hoàn tất': '完畢', 'tiêu đề': '標題', 'tất cả': '悉𪥘󠄁', 'không chỉ': '空只',
    'phù hợp': '符合', 'biến mất': '變𠅒', 'hình ảnh': '形影', 'vị trí': '位置',
    'con trỏ': '𡥵𢸫', 'hệ thống': '系統', 'kết bạn': '結伴', 'chấp nhận': '執認',
    'từ chối': '辭挃', 'trả lời': '㨋𠳒', 'nguy hiểm': '危險', 'vi phạm': '違犯',
    'tham gia': '參加', 'duy nhất': '唯一', 'xác nhận': '確認', 'xảy ra': '侈𫥨',
    'chiến thuật': '戰術', 'mô phỏng': '模倣', 'tài liệu': '材料', 'xác định': '確定',
    'phản hồi': '返回', 'sắp xếp': '𢯛攝', 'mức độ': '𣞪度', 'thành thạo': '成繰',
    'cảm ơn': '感恩',
}

# Source-backed single readings. These are applied only after exact phrase matching.
WORDS = {
    'bạn': '伴', 'cho': '朱', 'chỉ': '只', 'đã': '㐌', 'kênh': '涇', 'đang': '當',
    'tải': '載', 'hãy': '唉', 'để': '抵', 'phần': '份', 'học': '學', 'chung': '終',
    'chưa': '𣗓', 'có': '固', 'hoặc': '或', 'chọn': '譔', 'một': '𠬠', 'trước': '𠓀',
    'trong': '𥪝', 'tìm': '尋', 'tên': '𠸜', 'mã': '碼', 'khác': '恪', 'gửi': '寄',
    'xem': '䀡', 'viết': '𢪏', 'tạo': '造', 'nút': '𨨷', 'mới': '㵋', 'do': '由',
    'yếu': '𪽳', 'sai': '差', 'nhóm': '𡖡', 'gốc': '㭲', 'được': '得', 'sau': '𢖖󠄁',
    'với': '貝', 'nhấn': '扨', 'nhập': '入', 'mở': '𢲫', 'đóng': '㨂', 'thêm': '添',
    'bỏ': '𠬃', 'gỡ': '攑', 'đổi': '𢷮', 'đặt': '撻', 'làm': '𫜵', 'thuần': '純',
    'chứa': '貯', 'số': '數', 'khớp': '𨨤', 'đúng': '倲', 'ảnh': '影', 'tổng': '總',
    'dành': '𧶄', 'chữ': '𡨸', 'chủ': '主', 'đề': '提', 'tâm': '心', 'bảng': '榜',
    'tin': '信', 'định': '定', 'hình': '形', 'khám': '勘', 'phá': '破', 'cả': '𪥘󠄁',
    'hiểu': '曉', 'lầm': '𡍚', 'phản': '返', 'hồi': '回', 'người': '𠊛', 'trò': '𠻀',
    'chuyện': '𡀯', 'lời': '𠳒', 'mời': '𫬱', 'báo': '報', 'cáo': '告', 'ngôn': '言',
    'từ': '詞', 'thông': '通', 'gây': '𨠳', 'bản': '版', 'quyền': '權', 'hàng': '行',
    'đợi': '待', 'đưa': '迻', 'ứng': '應', 'dụng': '用', 'câu': '句', 'hộp': '𪡄',
    'thư': '書', 'bị': '被', 'cấm': '禁', 'vô': '無', 'hiệu': '效', 'quá': '過',
    'nhiều': '𡗉', 'trạng': '狀', 'thái': '態', 'tính': '性', 'năng': '能', 'gọi': '噲',
    'thoại': '話', 'văn': '文', 'hoạt': '活', 'động': '動', 'nhắn': '𠴍', 'y': '醫',
    'khoa': '科', 'nội': '內', 'ngoại': '外', 'da': '䏧', 'liễu': '柳', 'tim': '心',
    'mạch': '脈', 'di': '移', 'cơ': '基', 'sở': '所', 'điện': '電', 'phim': '𣆅',
    'truyền': '傳', 'danh': '名', 'mục': '目', 'bộ': '部', 'lọc': '漉', 'góc': '𧣳',
    'dưới': '𨑜', 'biệt': '別', 'hiện': '現', 'không': '空', 'chính': '正', 'hai': '𠄩',
    'bên': '邊', 'màn': '幔', 'dấu': '𨁪', 'trang': '張', 'đầu': '頭', 'giữ': '𡨺',
    'tại': '在', 'lên': '𬨠', 'phương': '方', 'thức': '式', 'hoàn': '完', 'tác': '作',
    'tay': '𢬣', 'cầm': '擒', 'mẹ': '媄', 'đẻ': '𤯰', 'thẻ': '𥮋', 'và': '吧',
    'vào': '𠓨', 'khỏi': '𠺌', 'đến': '𦤾', 'muốn': '㦖', 'của': '𧵑', 'nếu': '裊',
    'cần': '懃', 'dùng': '用', 'lọc': '漉', 'quên': '悁', 'phải': '沛', 'qua': '過',
    'lưu': '留', 'dạng': '樣', 'lỗi': '纇', 'mình': '𨉟', 'tôi': '碎', 'thực': '寔',
    'sửa': '𢯢', 'trống': '𤿰', 'lúc': '𣅶', 'tuổi': '歲', 'cách': '格', 'kéo': '捁',
}

# Editorial composites for modern app vocabulary. Every component is source-backed,
# but these exact compounds are app-domain composition rather than quoted source phrases.
COMPOSITES = {
    'hệ chữ': '系𡨸', 'chữ nôm': '𡨸喃', 'chủ đề': '主題', 'quan tâm': '關心',
    'bảng tin': '榜信', 'định hình': '定形', 'cộng đồng': '共同', 'khám phá': '勘破',
    'danh mục': '名目', 'đăng nhập': '登入', 'đăng ký': '登記', 'đăng bài': '登排',
    'bài viết': '排𢪏', 'người dùng': '𠊛用', 'lời mời': '𠳒𫬱', 'trò chuyện': '𠻀𡀯',
    'cuộc trò chuyện': '局𠻀𡀯', 'báo cáo': '報告', 'thông tin': '通信', 'ngôn từ': '言詞',
    'gây hiểu lầm': '𨠳曉𡍚', 'bản quyền': '版權', 'hàng đợi': '行待', 'ứng dụng': '應用',
    'câu trả lời': '句㨋𠳒', 'trạng thái': '狀態', 'tính năng': '性能', 'chỉnh sửa': '整𢯢',
    'xóa': '𠚢', 'thành viên': '成員', 'thời gian thực': '時間寔', 'gọi thoại': '噲話',
    'gọi video': '噲 video', 'dịch': '譯', 'bản dịch': '版譯', 'tự dịch': '自譯',
    'dịch bằng': '譯憑', 'dịch sang': '譯𨖲', 'hoạt động': '活動', 'nhắn tin': '𠴍信',
    'y học': '醫學', 'nội khoa': '內科', 'ngoại khoa': '外科', 'da liễu': '䏧柳',
    'tâm thần học': '心神學', 'tim mạch': '心脈', 'di động': '移動', 'cơ sở dữ liệu': '基所與料',
    'điện ảnh': '電影', 'truyền hình': '傳形', 'hoạt hình': '活形', 'dấu trang': '𨁪張',
    'bộ lọc': '部漉', 'mẹ đẻ': '媄𤯰',
}

ARB = Path('lib/l10n/app_vi_Hani.arb')
REVIEW = Path('tool/vi_hani_conversion_review.json')
TECH = {
    'ai', 'email', 'id', 'oled', 'glyphora', 'language', 'core', 'firebase',
    'authentication', 'firestore', 'web', 'backend', 'flutter', 'react',
    'native', 'rpg', 'fps', 'spam', 'video', 'chat', 'hindi', 'game',
}
WORD_RE = re.compile(r'[A-Za-zÀ-ỹĐđ]+', re.UNICODE)
PLACEHOLDER_RE = re.compile(r'\{[^{}]+\}')
CJK = r'\u3400-\u9fff\U00020000-\U000323af'


def norm(value):
    return unicodedata.normalize('NFC', value).lower()


def replace_phrases(work, mapping):
    for source in sorted(mapping, key=lambda s: (-len(s.split()), -len(s))):
        pattern = r'(?<![A-Za-zÀ-ỹĐđ])' + r'\s+'.join(re.escape(p) for p in source.split()) + r'(?![A-Za-zÀ-ỹĐđ])'
        work = re.sub(pattern, mapping[source], work, flags=re.IGNORECASE)
    return work


def convert_value(text):
    placeholders = {}
    def protect(match):
        marker = f'§PH{len(placeholders)}§'; placeholders[marker] = match.group(0); return marker
    work = PLACEHOLDER_RE.sub(protect, text)
    work = replace_phrases(work, PHRASES)
    work = replace_phrases(work, COMPOSITES)
    def replace_word(match):
        raw = match.group(0); word = norm(raw)
        if word in TECH: return raw
        return WORDS.get(word, raw)
    work = WORD_RE.sub(replace_word, work)
    work = re.sub(rf'(?<=[{CJK}])\s+(?=[{CJK}])', '', work)
    for marker, value in placeholders.items(): work = work.replace(marker, value)
    unresolved = [w for w in WORD_RE.findall(PLACEHOLDER_RE.sub('', work)) if norm(w) not in TECH]
    return work, unresolved


data = json.loads(ARB.read_text(encoding='utf-8'))
remaining = {}
changed_count = 0
for key, value in list(data.items()):
    if key.startswith('@') or not isinstance(value, str) or not WORD_RE.search(value): continue
    converted, unresolved = convert_value(value)
    if converted != value:
        data[key] = converted; changed_count += 1
    if unresolved:
        remaining[key] = {'value': converted, 'latin_words': unresolved}

ARB.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
counts = Counter(norm(w) for item in remaining.values() for w in item['latin_words'])
REVIEW.parent.mkdir(parents=True, exist_ok=True)
REVIEW.write_text(json.dumps({
    'method': 'source phrase/readings first; app-domain composites are explicitly editorial',
    'changed_count_this_run': changed_count,
    'remaining_count': len(remaining),
    'remaining_word_counts': counts.most_common(),
    'remaining': remaining,
}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'Changed {changed_count} values; remaining Latin-review keys: {len(remaining)}')
print('Top unresolved:', counts.most_common(100))
