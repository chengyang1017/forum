from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def patch_all_notes() -> None:
    path = ROOT / "lib/features/notes/presentation/screens/all_notes_screen.dart"
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        "_SharedUser.fromUserModel(user)",
        "_SharedUser.fromUserModel(user, fallbackName: context.l10n.user)",
    )
    text = text.replace(
        ".map(_SharedUser.fromDiscoverUser)",
        ".map(\n            (user) => _SharedUser.fromDiscoverUser(\n              user,\n              fallbackName: context.l10n.user,\n            ),\n          )",
    )
    text = text.replace(
        "factory _SharedUser.fromUserModel(UserModel user) {",
        "factory _SharedUser.fromUserModel(\n    UserModel user, {\n    required String fallbackName,\n  }) {",
    )
    text = text.replace(
        "factory _SharedUser.fromDiscoverUser(DiscoverUser user) {",
        "factory _SharedUser.fromDiscoverUser(\n    DiscoverUser user, {\n    required String fallbackName,\n  }) {",
    )
    text = text.replace(
        "name: name.isEmpty ? context.l10n.user : name,",
        "name: name.isEmpty ? fallbackName : name,",
    )
    path.write_text(text, encoding="utf-8")


def patch_note_editor() -> None:
    path = ROOT / "lib/features/notes/presentation/screens/note_editor_screen.dart"
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        ".map(_NoteSharedUser.fromDiscoverUser)",
        ".map(\n            (user) => _NoteSharedUser.fromDiscoverUser(\n              user,\n              fallbackName: context.l10n.user,\n            ),\n          )",
    )
    text = text.replace(
        "factory _NoteSharedUser.fromDiscoverUser(DiscoverUser user) {",
        "factory _NoteSharedUser.fromDiscoverUser(\n    DiscoverUser user, {\n    required String fallbackName,\n  }) {",
    )
    text = text.replace(
        "name: name.isEmpty ? context.l10n.user : name,",
        "name: name.isEmpty ? fallbackName : name,",
    )
    path.write_text(text, encoding="utf-8")


def patch_tag_editor() -> None:
    path = ROOT / "lib/features/profile/presentation/widgets/tag_editor_sheet.dart"
    text = path.read_text(encoding="utf-8")
    # _addTag receives BuildContext as `ctx`, not `context`.
    marker = "void _addTag("
    index = text.find(marker)
    if index != -1:
        prefix = text[:index]
        helper = text[index:].replace("context.l10n.tagExists", "ctx.l10n.tagExists")
        helper = helper.replace("context.l10n.tagMax", "ctx.l10n.tagMax")
        text = prefix + helper
    path.write_text(text, encoding="utf-8")


patch_all_notes()
patch_note_editor()
patch_tag_editor()
print("Fixed contextless localization helper calls.")
