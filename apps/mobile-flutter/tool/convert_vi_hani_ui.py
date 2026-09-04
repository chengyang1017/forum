#!/usr/bin/env python3
import json
import re
import unicodedata
from pathlib import Path

# Exact phrase mappings found in the user's Bảng Chữ Hán Nôm Chuẩn / extracted
# phrase-example database. Phrase matches always win over single-word readings.
PHRASES = {
    'ngôn ngữ': '言語',
    'nội dung': '內容',
    'sở thích': '所適',
    'đề xuất': '提出',
    'hiển thị': '顯示',
    'kết nối': '結綏',
    'mọi người': '𤗆𠊛',
    'ảnh hưởng': '影響',
    'phương pháp': '方法',
    'tiếp tục': '接續',
    'cụ thể': '具體',
    'thời gian': '時間',
    'bình luận': '評論',
    'quảng cáo': '廣告',
    'quấy rối': '撌𦇒',
    'bắt nạt': '扒㖏',
    'thù ghét': '讎恄',
    'tình dục': '情欲',
    'bạo lực': '暴力',
    'bổ sung': '補充',
    'kiểm duyệt': '檢閱',
    'chia sẻ': '𢺹𢩿',
    'hồ sơ': '糊疏',
    'thất bại': '失敗',
    'không thể': '空体',
    'ghi chú': '𥱬註',
    'cài đặt': '掑撻',
    'tài khoản': '財款',
    'liên kết': '連結',
    'hướng dẫn': '向引',
    'an toàn': '安全',
    'thay đổi': '𠊝𢷮',
    'bảo mật': '保密',
    'địa chỉ': '地址',
    'sử dụng': '使用',
    'liên hệ': '聯繫',
    'hỗ trợ': '互助',
    'theo dõi': '蹺𠼲',
    'lịch sử': '歷史',
    'phát triển': '發展',
    'phiên bản': '翻版',
    'bạn bè': '伴佊',
    'ai đó': '埃妬',
    'nhi khoa': '兒科',
    'dữ liệu': '與料',
    'kết quả': '結果',
    'chi tiết': '枝節',
    'sao chép': '抄劄',
    'giới hạn': '界限',
    'phân loại': '分類',
    'vui lòng': '𢝙𢚸',
    'không có': '空固',
    'bây giờ': '𣊾𣇞',
    'cho phép': '朱法',
    'có thể': '固体',
    'không được': '空得',
    'đầu tiên': '頭先',
    'tổng cộng': '總共',
    'tối đa': '最多',
    'bên phải': '邊沛',
    'bên cạnh': '邊𧣲',
    'cập nhật': '及日',
    'khôi phục': '恢復',
    'kiểm tra': '檢查',
    'chữ cái': '𡨸𡣨',
    'yêu cầu': '要求',
    'thao tác': '操作',
    'tin nhắn': '信𠴍',
    'hoàn tất': '完畢',
    'tiêu đề': '標題',
    'tất cả': '悉𪥘󠄁',
    'không chỉ': '空只',
    'phù hợp': '符合',
    'biến mất': '變𠅒',
    'hình ảnh': '形影',
    'vị trí': '位置',
    'con trỏ': '𡥵𢸫',
}

# Single readings below are also source-backed. They are only used after no exact
# phrase match exists, which prevents e.g. a common syllable from overriding a
# documented multi-word expression.
WORDS = {
    'bạn': '伴',
    'cho': '朱',
    'chỉ': '只',
    'đã': '㐌',
    'kênh': '涇',
    'đang': '當',
    'tải': '載',
    'hãy': '唉',
    'để': '抵',
    'phần': '份',
    'học': '學',
    'chung': '終',
    'chưa': '𣗓',
    'có': '固',
    'hoặc': '或',
    'chọn': '譔',
    'một': '𠬠',
    'trước': '𠓀',
    'trong': '𥪝',
    'tìm': '尋',
    'tên': '𠸜',
    'mã': '碼',
    'khác': '恪',
    'gửi': '寄',
    'xem': '䀡',
    'viết': '𢪏',
    'tạo': '造',
    'nút': '𨨷',
    'mới': '㵋',
    'do': '由',
    'yếu': '𪽳',
    'sai': '差',
    'nhóm': '𡖡',
    'gốc': '㭲',
    'được': '得',
    'sau': '𢖖󠄁',
    'với': '貝',
    'nhấn': '扨',
    'nhập': '入',
    'mở': '𢲫',
    'đóng': '㨂',
    'thêm': '添',
    'bỏ': '𠬃',
    'gỡ': '攑',
    'đổi': '𢷮',
    'đặt': '撻',
    'làm': '𫜵',
    'thuần': '純',
    'chứa': '貯',
    'số': '數',
    'khớp': '𨨤',
    'đúng': '倲',
    'ảnh': '影',
    'tổng': '總',
    'dành': '𧶄',
}

ARB = Path('lib/l10n/app_vi_Hani.arb')
REVIEW = Path('tool/vi_hani_conversion_review.json')
TECH = {
    'ai', 'email', 'id', 'oled', 'glyphora', 'language', 'core', 'firebase',
    'authentication', 'firestore', 'web', 'backend', 'flutter', 'react',
    'native', 'rpg', 'fps', 'spam', 'video', 'chat', 'hindi',
}
WORD_RE = re.compile(r'[A-Za-zÀ-ỹĐđ]+', re.UNICODE)
PLACEHOLDER_RE = re.compile(r'\{[^{}]+\}')
CJK = r'\u3400-\u9fff\U00020000-\U000323af'


def norm(value):
    return unicodedata.normalize('NFC', value).lower()


def convert_value(text):
    placeholders = {}

    def protect(match):
        marker = f'§PH{len(placeholders)}§'
        placeholders[marker] = match.group(0)
        return marker

    work = PLACEHOLDER_RE.sub(protect, text)
    provenance = []

    # Longest phrase first. Flexible whitespace allows matches across normal UI spacing.
    for source in sorted(PHRASES, key=lambda s: (-len(s.split()), -len(s))):
        pattern = r'(?<![A-Za-zÀ-ỹĐđ])' + r'\s+'.join(
            re.escape(part) for part in source.split()
        ) + r'(?![A-Za-zÀ-ỹĐđ])'
        replacement = PHRASES[source]
        work, count = re.subn(pattern, replacement, work, flags=re.IGNORECASE)
        if count:
            provenance.append(['source-phrase', source, replacement, count])

    def replace_word(match):
        raw = match.group(0)
        word = norm(raw)
        if word in TECH:
            return raw
        if word in WORDS:
            replacement = WORDS[word]
            provenance.append(['source-word', word, replacement, 1])
            return replacement
        return raw

    work = WORD_RE.sub(replace_word, work)

    # Traditional Nôm prose does not need spaces between adjacent Han/Nôm characters.
    work = re.sub(rf'(?<=[{CJK}])\s+(?=[{CJK}])', '', work)

    for marker, value in placeholders.items():
        work = work.replace(marker, value)

    unresolved = [
        word for word in WORD_RE.findall(PLACEHOLDER_RE.sub('', work))
        if norm(word) not in TECH
    ]
    return work, provenance, unresolved


data = json.loads(ARB.read_text(encoding='utf-8'))
changed = {}
remaining = {}

for key, value in list(data.items()):
    if key.startswith('@') or not isinstance(value, str):
        continue
    if not WORD_RE.search(value):
        continue

    converted, provenance, unresolved = convert_value(value)
    if converted != value:
        data[key] = converted
        changed[key] = {
            'before': value,
            'after': converted,
            'provenance': provenance,
        }

    if unresolved:
        remaining[key] = {
            'value': converted,
            'latin_words': unresolved,
        }

ARB.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
REVIEW.parent.mkdir(parents=True, exist_ok=True)
REVIEW.write_text(
    json.dumps({
        'method': 'phrase-first; mappings are source-backed; unresolved text is retained for review',
        'changed_count': len(changed),
        'remaining_count': len(remaining),
        'changed': changed,
        'remaining': remaining,
    }, ensure_ascii=False, indent=2) + '\n',
    encoding='utf-8',
)

print(f'Changed {len(changed)} values; remaining Latin-review keys: {len(remaining)}')
for key, value in list(remaining.items())[:160]:
    print(f"REMAIN {key}: {value['value']} :: {value['latin_words']}")
