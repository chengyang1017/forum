from __future__ import annotations

import copy
import json
import re
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
REPO = PROJECT.parents[1]
SOURCE_DIR = PROJECT / "assets" / "l10n"
ARB_DIR = PROJECT / "lib" / "l10n"
WRAPPER = PROJECT / "lib" / "app" / "l10n" / "app_localizations.dart"
DELEGATE = PROJECT / "lib" / "app" / "l10n" / "localizations_delegate.dart"
WORKFLOW = REPO / ".github" / "workflows" / "one-time-flutter-arb-migration.yml"
SCRIPT = Path(__file__)

STRUCTURED_KEYS = {
    "categoryNames",
    "categoryTranslations",
    "languageTranslations",
}
LOCALE_FILE_NAMES = {
    "chunom": "vi_Hani",
}
PLACEHOLDER_RE = re.compile(r"\{([A-Za-z][A-Za-z0-9_]*)\}")
VALID_MESSAGE_KEY = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def overlay(base: dict, extra: dict) -> dict:
    result = copy.deepcopy(base)
    for key, value in extra.items():
        if key == "categoryNames" and isinstance(value, list):
            current = list(result.get(key, []))
            for index, item in enumerate(value):
                if index < len(current):
                    current[index] = item
                else:
                    current.append(item)
            result[key] = current
        elif isinstance(value, dict) and isinstance(result.get(key), dict):
            merged = dict(result[key])
            merged.update(value)
            result[key] = merged
        else:
            result[key] = copy.deepcopy(value)
    return result


def ordered_placeholders(text: str) -> list[str]:
    found: list[str] = []
    for match in PLACEHOLDER_RE.finditer(text):
        name = match.group(1)
        if name not in found:
            found.append(name)
    return found


def suffix(value: str) -> str:
    parts = [part for part in re.split(r"[^A-Za-z0-9]+", value) if part]
    if not parts:
        raise ValueError(f"Cannot build Dart identifier suffix from {value!r}")
    return "".join(part[0].upper() + part[1:] for part in parts)


def as_message(value: object) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def dart_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def build_effective(raw: dict[str, dict], locale: str) -> dict:
    english = raw["en"]
    if locale == "en":
        return copy.deepcopy(english)
    if locale == "chunom":
        vietnamese = overlay(english, raw.get("vi", {}))
        return overlay(vietnamese, raw[locale])
    return overlay(english, raw[locale])


def collect_top_level_keys(raw: dict[str, dict]) -> list[str]:
    keys: list[str] = []
    for locale_data in raw.values():
        for key, value in locale_data.items():
            if key in STRUCTURED_KEYS or not isinstance(value, (str, int, float, bool)):
                continue
            if not VALID_MESSAGE_KEY.fullmatch(key):
                raise ValueError(f"Invalid ARB message key: {key}")
            if key not in keys:
                keys.append(key)
    return keys


def collect_map_keys(raw: dict[str, dict], field: str) -> list[str]:
    keys: list[str] = []
    for locale_data in raw.values():
        value = locale_data.get(field, {})
        if not isinstance(value, dict):
            continue
        for key in value:
            key = str(key)
            if key not in keys:
                keys.append(key)
    return keys


def max_category_names(raw: dict[str, dict]) -> int:
    return max(
        (len(value.get("categoryNames", [])) for value in raw.values()),
        default=0,
    )


def build_messages(
    effective: dict,
    template: dict,
    top_level_keys: list[str],
    category_ids: list[str],
    language_codes: list[str],
    category_name_count: int,
) -> dict[str, str]:
    result: dict[str, str] = {}

    for key in top_level_keys:
        value = effective.get(key, template.get(key, key))
        if not isinstance(value, (str, int, float, bool)):
            value = template.get(key, key)
        result[key] = as_message(value)

    names = effective.get("categoryNames", [])
    template_names = template.get("categoryNames", [])
    for index in range(category_name_count):
        if index < len(names):
            value = names[index]
        elif index < len(template_names):
            value = template_names[index]
        else:
            value = f"Category {index + 1}"
        result[f"categoryName{index}"] = as_message(value)

    categories = effective.get("categoryTranslations", {})
    template_categories = template.get("categoryTranslations", {})
    for category_id in category_ids:
        value = categories.get(
            category_id,
            template_categories.get(category_id, category_id.replace("_", " ")),
        )
        result[f"category{suffix(category_id)}"] = as_message(value)

    languages = effective.get("languageTranslations", {})
    template_languages = template.get("languageTranslations", {})
    for language_code in language_codes:
        value = languages.get(
            language_code,
            template_languages.get(language_code, language_code),
        )
        result[f"languageName{suffix(language_code)}"] = as_message(value)

    return result


def harmonize_placeholders(
    template_messages: dict[str, str],
    localized_messages: dict[str, str],
    locale_name: str,
) -> dict[str, str]:
    result = dict(localized_messages)
    for key, template_text in template_messages.items():
        expected = set(ordered_placeholders(template_text))
        actual = set(ordered_placeholders(result.get(key, template_text)))
        if actual != expected:
            print(
                f"[{locale_name}] placeholder mismatch for {key}: "
                f"expected {sorted(expected)}, got {sorted(actual)}; using template value"
            )
            result[key] = template_text
    return result


def write_arb(
    locale_name: str,
    messages: dict[str, str],
    template_messages: dict[str, str],
) -> None:
    payload: dict[str, object] = {"@@locale": locale_name}
    for key, value in messages.items():
        payload[key] = value
        if locale_name == "en":
            placeholders = ordered_placeholders(template_messages[key])
            if placeholders:
                payload[f"@{key}"] = {
                    "placeholders": {
                        placeholder: {"type": "String"}
                        for placeholder in placeholders
                    }
                }

    path = ARB_DIR / f"app_{locale_name}.arb"
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def build_wrapper(
    template_messages: dict[str, str],
    top_level_keys: list[str],
    category_ids: list[str],
    language_codes: list[str],
    category_name_count: int,
) -> str:
    plain_keys = [
        key
        for key in top_level_keys
        if not ordered_placeholders(template_messages.get(key, ""))
    ]
    parameterized_keys = [
        key
        for key in top_level_keys
        if ordered_placeholders(template_messages.get(key, ""))
    ]

    lines: list[str] = [
        "// Compatibility facade around Flutter gen_l10n output.",
        "// New code can use generated typed getters directly; legacy get()/getWithArgs()",
        "// calls remain supported while the UI code is migrated incrementally.",
        "import 'generated/app_localizations.dart';",
        "",
        "export 'generated/app_localizations.dart';",
        "",
        "extension AppLocalizationsCompatibility on AppLocalizations {",
        "  bool get isChunom => localeName == 'vi_Hani';",
        "",
        "  List<String> get categoryNames => <String>[",
    ]

    for index in range(category_name_count):
        lines.append(f"    categoryName{index},")
    lines.extend(["  ];", ""])

    lines.extend(
        [
            "  String categoryName(String categoryId, {String? fallback}) {",
            "    switch (categoryId) {",
        ]
    )
    for category_id in category_ids:
        lines.append(
            f"      case {dart_string(category_id)}: return category{suffix(category_id)};"
        )
    lines.extend(
        [
            "      default:",
            "        return fallback ?? categoryId.replaceAll('_', ' ');",
            "    }",
            "  }",
            "",
            "  String translateLanguage(String code) {",
            "    switch (code) {",
        ]
    )
    for language_code in language_codes:
        lines.append(
            f"      case {dart_string(language_code)}: return languageName{suffix(language_code)};"
        )
    lines.extend(
        [
            "      default: return code;",
            "    }",
            "  }",
            "",
            "  String getLanguageName(String code) {",
            "    if (code == 'chunom') return nomWritingSystem;",
            "    return translateLanguage(code);",
            "  }",
            "",
            "  String get(String key) {",
            "    switch (key) {",
        ]
    )
    for key in plain_keys:
        lines.append(f"      case {dart_string(key)}: return {key};")
    lines.extend(
        [
            "      default: return key;",
            "    }",
            "  }",
            "",
            "  String getWithArgs(String key, Map<String, String> args) {",
            "    switch (key) {",
        ]
    )
    for key in parameterized_keys:
        params = ordered_placeholders(template_messages[key])
        args = ", ".join(
            f"args[{dart_string(param)}] ?? ''" for param in params
        )
        lines.append(f"      case {dart_string(key)}: return {key}({args});")
    lines.extend(
        [
            "      default: return get(key);",
            "    }",
            "  }",
            "}",
            "",
        ]
    )
    return "\n".join(lines)


def patch_pubspec() -> None:
    path = PROJECT / "pubspec.yaml"
    text = path.read_text(encoding="utf-8")
    if not re.search(r"(?m)^  generate: true$", text):
        text, count = re.subn(
            r"(?m)^flutter:\s*$",
            "flutter:\n  generate: true",
            text,
            count=1,
        )
        if count != 1:
            raise RuntimeError("Could not locate the root-level flutter: section")

    lines = text.splitlines()
    lines = [line for line in lines if line.strip() != "- assets/l10n/"]

    cleaned: list[str] = []
    index = 0
    while index < len(lines):
        if lines[index] == "  assets:":
            next_index = index + 1
            asset_entries: list[str] = []
            while next_index < len(lines) and lines[next_index].startswith("    "):
                asset_entries.append(lines[next_index])
                next_index += 1
            if not any(entry.strip().startswith("-") for entry in asset_entries):
                index = next_index
                continue
        cleaned.append(lines[index])
        index += 1

    path.write_text("\n".join(cleaned).rstrip() + "\n", encoding="utf-8")


def patch_dart_references() -> None:
    for base in (PROJECT / "lib", PROJECT / "test"):
        if not base.exists():
            continue
        for path in base.rglob("*.dart"):
            if path == WRAPPER or "generated" in path.parts:
                continue
            text = path.read_text(encoding="utf-8")
            updated = text.replace(
                "import 'app/l10n/localizations_delegate.dart';\n",
                "",
            )
            updated = updated.replace(
                "import 'package:glyphora_mobile/app/l10n/localizations_delegate.dart';",
                "import 'package:glyphora_mobile/app/l10n/app_localizations.dart';",
            )
            updated = updated.replace(
                "AppLocalizationsDelegate()",
                "AppLocalizations.delegate",
            )
            if updated != text:
                path.write_text(updated, encoding="utf-8")


def patch_gitignore() -> None:
    path = PROJECT / ".gitignore"
    line = "lib/app/l10n/generated/"
    if path.exists():
        text = path.read_text(encoding="utf-8")
        if line not in text.splitlines():
            path.write_text(text.rstrip() + f"\n{line}\n", encoding="utf-8")
    else:
        path.write_text(line + "\n", encoding="utf-8")


def write_l10n_yaml() -> None:
    (PROJECT / "l10n.yaml").write_text(
        """arb-dir: lib/l10n
template-arb-file: app_en.arb
output-dir: lib/app/l10n/generated
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
preferred-supported-locales: [zh]
relax-syntax: true
format: true
""",
        encoding="utf-8",
    )


def remove_old_runtime_localizations() -> None:
    for path in SOURCE_DIR.glob("*.json"):
        path.unlink()
    try:
        SOURCE_DIR.rmdir()
    except OSError:
        pass
    if DELEGATE.exists():
        DELEGATE.unlink()


def remove_one_time_files() -> None:
    if SCRIPT.exists():
        SCRIPT.unlink()
    if WORKFLOW.exists():
        WORKFLOW.unlink()


def main() -> None:
    raw: dict[str, dict] = {}
    for path in sorted(SOURCE_DIR.glob("*.json")):
        raw[path.stem] = load_json(path)

    required = {"en", "zh", "ja", "ko", "ms", "vi", "th", "chunom"}
    missing = required.difference(raw)
    if missing:
        raise RuntimeError(f"Missing localization JSON files: {sorted(missing)}")

    top_level_keys = collect_top_level_keys(raw)
    category_ids = collect_map_keys(raw, "categoryTranslations")
    language_codes = collect_map_keys(raw, "languageTranslations")
    category_name_count = max_category_names(raw)

    template_effective = build_effective(raw, "en")
    template_messages = build_messages(
        template_effective,
        template_effective,
        top_level_keys,
        category_ids,
        language_codes,
        category_name_count,
    )

    ARB_DIR.mkdir(parents=True, exist_ok=True)
    for locale in ("en", "zh", "ja", "ko", "ms", "vi", "th", "chunom"):
        effective = build_effective(raw, locale)
        messages = build_messages(
            effective,
            template_effective,
            top_level_keys,
            category_ids,
            language_codes,
            category_name_count,
        )
        locale_name = LOCALE_FILE_NAMES.get(locale, locale)
        messages = harmonize_placeholders(template_messages, messages, locale_name)
        write_arb(locale_name, messages, template_messages)

    WRAPPER.parent.mkdir(parents=True, exist_ok=True)
    WRAPPER.write_text(
        build_wrapper(
            template_messages,
            top_level_keys,
            category_ids,
            language_codes,
            category_name_count,
        ),
        encoding="utf-8",
    )

    patch_pubspec()
    patch_dart_references()
    patch_gitignore()
    write_l10n_yaml()
    remove_old_runtime_localizations()
    remove_one_time_files()

    print(
        f"Migrated {len(top_level_keys)} UI keys, "
        f"{len(category_ids)} category labels, "
        f"{len(language_codes)} language labels, "
        f"and {category_name_count} category-name slots to ARB."
    )


if __name__ == "__main__":
    main()
