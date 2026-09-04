from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRESENTATION = ROOT / "lib" / "features"

# Quoted strings containing CJK/Thai characters. These are the languages that
# have historically been hard-coded in the Flutter presentation layer.
LITERAL_RE = re.compile(r"(?P<quote>['\"])(?P<text>(?:(?!\1).)*[\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af\u0e00-\u0e7f](?:(?!\1).)*)\1")

# Presentation-layer strings on these lines are developer-facing rather than UI.
IGNORE_LINE_MARKERS = (
    "debugPrint(",
    "assert(",
    "RegExp(",
    "//",
    "import '",
    'import "',
)

# Known data/format literals that are intentionally not translated.
IGNORE_EXACT = {
    "年-月-日",
}

findings: list[tuple[Path, int, str]] = []

for path in sorted(PRESENTATION.rglob("*.dart")):
    # Only presentation code. Domain/data error messages are handled separately
    # and should not be treated as UI copy by this audit.
    if "presentation" not in path.parts:
        continue
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.strip()
        if any(marker in stripped for marker in IGNORE_LINE_MARKERS):
            continue
        for match in LITERAL_RE.finditer(line):
            text = match.group("text")
            if text in IGNORE_EXACT:
                continue
            findings.append((path.relative_to(ROOT), line_no, text))

if findings:
    print("Hard-coded localized UI strings found:")
    for path, line_no, text in findings:
        print(f"{path}:{line_no}: {text}")
    raise SystemExit(1)

print("No hard-coded CJK/Thai UI literals found in Flutter presentation code.")
