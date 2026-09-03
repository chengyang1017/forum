from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / 'apps' / 'mobile-flutter' / 'lib'
CJK = re.compile(r'[\u3400-\u4dbf\u4e00-\u9fff]')
STRING = re.compile(r"(?P<q>['\"])(?P<body>(?:\\.|(?!\1).)*)(?P=q)")

ignored_fragments = (
    'debugPrint(',
    '//',
    'TODO',
    'FIXME',
)

rows: list[tuple[str, int, str]] = []
for path in sorted(LIB.rglob('*.dart')):
    rel = path.relative_to(ROOT).as_posix()
    for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
        stripped = line.strip()
        if not stripped or stripped.startswith('//'):
            continue
        if 'debugPrint(' in line:
            continue
        if not CJK.search(line):
            continue
        if not any(CJK.search(match.group('body')) for match in STRING.finditer(line)):
            continue
        rows.append((rel, number, stripped))

print(f'CJK_USER_VISIBLE_CANDIDATES={len(rows)}')
for rel, number, text in rows:
    print(f'{rel}:{number}: {text}')
