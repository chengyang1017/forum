#!/usr/bin/env python3
import base64
import json
import re
import unicodedata
import zlib
from pathlib import Path

PHRASES = json.loads(
    zlib.decompress(
        base64.b64decode(
            ''.join(
                p.read_text()
                for p in sorted(Path('tool/vi_hani_lexicon').glob('ph_*.txt'))
            )
        )
    )
)

# Contextual single-word choices used only when an exact source phrase is unavailable.
# These are kept deliberately small so ambiguous words remain visible in the review.
WORDS = {
    'bạn': '伴',
    'lý': '理',
    'xóa': '𠚢',
    'lưu': '留',
    'dịch': '譯',
    'mới': '𡤓',
    'danh': '名',
    'mục': '目',
    'đề': '題',
    'thành': '成',
    'viên': '員',
    'mật': '密',
    'khẩu': '口',
    'ngữ': '語',
    'tài': '財',
    'bản': '版',
    'hồ': '糊',
    'sơ': '疏',
    'thông': '通',
    'tin': '信',
    'xác': '確',
    'nhận': '認',
}

ARB = Path('lib/l10n/app_vi_Hani.arb')
REVIEW = Path('tool/vi_hani_conversion_review.json')
TECH = {
    'ai', 'email', 'id', 'oled', 'glyphora', 'language', 'core', 'firebase',
    'authentication', 'firestore', 'web', 'backend', 'flutter', 'react',
    'native', 'rpg', 'fps', 'spam', 'video', 'chat',
}
WORD_RE = re.compile(r'[A-Za-zÀ-ỹĐđ]+', re.UNICODE)
PLACEHOLDER_RE = re.compile(r'\{[^{}]+\}')


def norm(value):
    return unicodedata.normalize('NFC', value).lower()


def convert_value(text):
    placeholders = {}

    def protect(match):
        key = f'§PH{len(placeholders)}§'
        placeholders[key] = match.group(0)
        return key

    work = PLACEHOLDER_RE.sub(protect, text)
    tokens = re.findall(r'§PH\d+§|[A-Za-zÀ-ỹĐđ]+|[^A-Za-zÀ-ỹĐđ§]+|§', work)
    out = []
    provenance = []
    unresolved = []
    i = 0

    while i < len(tokens):
        token = tokens[i]
        if token in placeholders:
            out.append(token)
            i += 1
            continue
        if not WORD_RE.fullmatch(token):
            out.append(token)
            i += 1
            continue

        run_words = []
        j = i
        while j < len(tokens):
            if WORD_RE.fullmatch(tokens[j]):
                run_words.append(tokens[j])
                j += 1
                if j < len(tokens) and tokens[j].isspace():
                    j += 1
                    continue
                break
            break

        k = 0
        run_out = []
        while k < len(run_words):
            matched = False
            for size in range(min(8, len(run_words) - k), 1, -1):
                key = ' '.join(norm(word) for word in run_words[k:k + size])
                if key in PHRASES:
                    run_out.append(PHRASES[key])
                    provenance.append(['source-phrase', key, PHRASES[key]])
                    k += size
                    matched = True
                    break
            if matched:
                continue

            word = norm(run_words[k])
            if word in TECH:
                run_out.append(run_words[k])
            elif word in WORDS:
                run_out.append(WORDS[word])
                provenance.append(['manual-word', word, WORDS[word]])
            else:
                run_out.append(run_words[k])
                unresolved.append(run_words[k])
            k += 1

        out.append(''.join(run_out))
        i = j

    result = ''.join(out)
    for key, value in placeholders.items():
        result = result.replace(key, value)
    return result, provenance, unresolved


data = json.loads(ARB.read_text(encoding='utf-8'))
changed = {}
remaining = {}

for key, value in list(data.items()):
    if key.startswith('@') or not isinstance(value, str):
        continue
    if not WORD_RE.search(value):
        continue

    words = [norm(word) for word in WORD_RE.findall(PLACEHOLDER_RE.sub('', value))]
    if words and all(word in TECH or (word.isascii() and word.upper() == word) for word in words):
        continue

    converted, provenance, unresolved = convert_value(value)
    if converted != value:
        data[key] = converted
        changed[key] = {
            'before': value,
            'after': converted,
            'provenance': provenance,
        }

    latin_words = [
        word
        for word in WORD_RE.findall(PLACEHOLDER_RE.sub('', converted))
        if norm(word) not in TECH
    ]
    if latin_words:
        remaining[key] = {
            'value': converted,
            'latin_words': latin_words,
            'unresolved': unresolved,
        }

ARB.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
REVIEW.parent.mkdir(parents=True, exist_ok=True)
REVIEW.write_text(
    json.dumps(
        {
            'method': 'phrase-first; source phrase matches before contextual manual words',
            'changed_count': len(changed),
            'remaining_count': len(remaining),
            'changed': changed,
            'remaining': remaining,
        },
        ensure_ascii=False,
        indent=2,
    ) + '\n',
    encoding='utf-8',
)

print(f'Changed {len(changed)} values; remaining Latin-review keys: {len(remaining)}')
for key, value in list(remaining.items())[:120]:
    print(f"REMAIN {key}: {value['value']} :: {value['latin_words']}")
