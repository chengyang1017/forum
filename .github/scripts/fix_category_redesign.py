from pathlib import Path

path = Path('apps/mobile-flutter/lib/features/home/presentation/screens/home_tab.dart')
text = path.read_text(encoding='utf-8')

replacements = {
    'crossAxisAlignment: CrossAxisAlignment.stretch,': 'crossAxisAlignment: CrossAxisAlignment.start,',
    'fontWeight: FontWeight.w750,': 'fontWeight: FontWeight.w700,',
}

for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f'Expected redesign snippet missing: {old}')
    text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
