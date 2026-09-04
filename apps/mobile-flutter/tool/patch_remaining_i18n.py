from __future__ import annotations

import json
from pathlib import Path

from migrate_hardcoded_ui_to_arb import L10N_DIR, remove_invalid_const

ROOT = Path(__file__).resolve().parents[1]
POST_DETAIL = ROOT / "lib" / "features" / "post" / "presentation" / "screens" / "post_detail_screen.dart"

COPY_LINK = {
    "en": "Copy link",
    "zh": "复制链接",
    "ja": "リンクをコピー",
    "ko": "링크 복사",
    "ms": "Salin pautan",
    "vi": "Sao chép liên kết",
    "th": "คัดลอกลิงก์",
}

for locale in ("en", "zh", "ja", "ko", "ms", "vi", "th", "vi_Hani"):
    path = L10N_DIR / f"app_{locale}.arb"
    data = json.loads(path.read_text(encoding="utf-8"))
    data["copyLink"] = COPY_LINK["vi"] if locale == "vi_Hani" else COPY_LINK[locale]
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

text = POST_DETAIL.read_text(encoding="utf-8")
replacements = {
    "'复制链接'": "context.l10n.copyLink",
    "'最多只能添加 9 张图片 📸'": "context.l10n.postImageLimit",
    "'确定要移除这张图片吗？'": "context.l10n.deleteImageConfirm",
    "'输入帖子标题'": "context.l10n.postTitleHint",
    "'正在上传并插入图片...'": "context.l10n.uploadingInlineImage",
}
for source, replacement in replacements.items():
    text = text.replace(source, replacement)
text = remove_invalid_const(text)
POST_DETAIL.write_text(text, encoding="utf-8")

print("Patched the five remaining hard-coded post-detail UI strings.")
