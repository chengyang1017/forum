#!/usr/bin/env python3
import json
import re
import unicodedata
from collections import Counter
from pathlib import Path

# Final pass over the remaining Quốc Ngữ fragments after the broad source-backed
# conversion. Exact phrases win over single readings. Entries marked as modern
# spelling aliases use the PDF's equivalent spelling (kí/lí/hoá -> ký/lý/hóa).
PHRASES = {
    # Directly attested phrases / spelling aliases from the supplied standard table.
    'kết bạn': '結伴',
    'bắt buộc': '扒𫃚',
    'quản lý': '管理',       # source spelling: quản lí
    'đăng ký': '登記',       # source spelling: đăng kí
    'xác nhận': '確認',
    'công nhận': '公認',
    'tìm thấy': '尋𧡊',
    'tìm kiếm': '尋檢',
    'trái tim': '𬃻心',
    'bên trái': '邊債',
    'ở đâu': '於兜',
    'khi nào': '欺𱜢',
    'mỗi khi': '每欺',
    'chữ hán': '𡨸漢',
    'hán nôm': '漢喃',
    'sản xuất': '產出',
    # UI compounds composed from source-backed characters/readings.
    'mật khẩu': '密口',
    'ký tự': '記字',         # source spelling uses kí; 記字 also appears in the standard-table prose
    'lý do': '理由',         # source spelling uses lí
    'thành công': '成功',
    'hợp lệ': '合例',
    'xác minh': '確明',
    'tự động': '自動',
    'thử lại': '㧗徠',
    'quay lại': '𢮿徠',
    'tải lại': '載徠',
    'gửi lại': '寄徠',
    'nhập lại': '入徠',
    'thu gọn': '收袞',
    # Keep the existing Glyphora vi_Hani terminology consistent.
    'bài viết': '排曰',
}

WORDS = {
    'lại': '徠',
    'mật': '密',
    'khẩu': '口',
    'bài': '排',
    'này': '尼',
    'đăng': '登',
    'thử': '㧗',
    'kết': '結',
    'sẽ': '仕',
    'các': '各',
    'bắt': '扒',
    'tự': '自',
    'thấy': '𧡊',
    'ký': '記',              # modern spelling alias of source kí
    'ở': '於',
    'chèn': '㙻',
    'đánh': '打',
    'lý': '理',              # modern spelling alias of source lí
    'là': '𱺵',
    'buộc': '𫃚',
    'khi': '欺',
    'rồi': '耒',
    'ít': '𠃣',
    'nhất': '一',
    'thành': '成',
    'quản': '管',
    'quay': '𢮿',
    'sách': '冊',
    'rõ': '𤑟',
    'nào': '𱜢',
    'ngay': '𬆄',
    'theo': '蹺',
    'mỗi': '每',
    'sang': '𨖅',
    'tiếng': '㗂',
    'duyệt': '閱',
    'bằng': '憑',
    'mà': '𦓡',
    'đa': '多',
    'viện': '院',
    'lấy': '𥙩',
    'biểu': '表',
    'tượng': '象',
    'trái': '債',
    'xuống': '𬺗',
    'tới': '𬧐',
    'hán': '漢',
    'gạch': '劃',
    'công': '功',
    'nhận': '認',
    'xác': '確',
    'minh': '明',
    'bởi': '𤳸',
    'hợp': '合',
    'lệ': '例',
    'thiếu': '少',
    'hóa': '化',             # modern spelling alias of source hoá
    'kia': '其',
    'vẫn': '吻',
    'thần': '神',
    'chuyển': '轉',
    'xuất': '出',
    'đây': '低',
    'đâu': '兜',
    'như': '如',
    'đạt': '達',
    'biết': '別',
    'kiếm': '檢',
    'thu': '收',
    'gọn': '袞',
}

TECH = {
    'ai', 'email', 'id', 'oled', 'glyphora', 'language', 'core', 'firebase',
    'authentication', 'firestore', 'web', 'backend', 'flutter', 'react',
    'native', 'rpg', 'fps', 'spam', 'video', 'chat', 'hindi', 'game',
}

ARB = Path('lib/l10n/app_vi_Hani.arb')
REVIEW = Path('tool/vi_hani_final_review.json')
WORD_RE = re.compile(r'[A-Za-zÀ-ỹĐđ]+', re.UNICODE)
PLACEHOLDER_RE = re.compile(r'\{[^{}]+\}')
CJK = r'\u3400-\u9fff\U00020000-\U000323af'


def norm(value):
    return unicodedata.normalize('NFC', value).lower()


def replace_phrases(text):
    for source in sorted(PHRASES, key=lambda s: (-len(s.split()), -len(s))):
        pattern = (
            r'(?<![A-Za-zÀ-ỹĐđ])'
            + r'\s+'.join(re.escape(part) for part in source.split())
            + r'(?![A-Za-zÀ-ỹĐđ])'
        )
        text = re.sub(pattern, PHRASES[source], text, flags=re.IGNORECASE)
    return text


def convert_value(text):
    placeholders = {}

    def protect(match):
        marker = f'§PH{len(placeholders)}§'
        placeholders[marker] = match.group(0)
        return marker

    work = PLACEHOLDER_RE.sub(protect, text)
    work = replace_phrases(work)

    def replace_word(match):
        raw = match.group(0)
        key = norm(raw)
        if key in TECH:
            return raw
        return WORDS.get(key, raw)

    work = WORD_RE.sub(replace_word, work)
    work = re.sub(rf'(?<=[{CJK}])\s+(?=[{CJK}])', '', work)

    for marker, original in placeholders.items():
        work = work.replace(marker, original)

    unresolved = [
        word
        for word in WORD_RE.findall(PLACEHOLDER_RE.sub('', work))
        if norm(word) not in TECH
    ]
    return work, unresolved


data = json.loads(ARB.read_text(encoding='utf-8'))
remaining = {}
changed = 0

for key, value in list(data.items()):
    if key.startswith('@') or not isinstance(value, str) or not WORD_RE.search(value):
        continue
    converted, unresolved = convert_value(value)
    if converted != value:
        data[key] = converted
        changed += 1
    if unresolved:
        remaining[key] = {'value': converted, 'latin_words': unresolved}

ARB.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
counts = Counter(norm(word) for item in remaining.values() for word in item['latin_words'])
REVIEW.write_text(
    json.dumps(
        {
            'method': 'final phrase-first pass over supplied-source readings; technical Latin tokens are allowed',
            'changed_count_this_run': changed,
            'remaining_count': len(remaining),
            'remaining_word_counts': counts.most_common(),
            'remaining': remaining,
        },
        ensure_ascii=False,
        indent=2,
    ) + '\n',
    encoding='utf-8',
)

print(f'Final pass changed {changed} values; remaining Latin-review keys: {len(remaining)}')
print('Remaining words:', counts.most_common(100))
if remaining:
    raise SystemExit(2)
