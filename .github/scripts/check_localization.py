#!/usr/bin/env python3
"""Validate Reynard localization files.

Checks performed:
1. Every key in en.lproj/Localizable.strings has a matching key in zh-Hans.lproj/Localizable.strings.
2. Every key referenced via L("...") in Swift source files exists in the strings files.
3. .strings syntax is parseable (no duplicates, no unterminated strings).
4. Format specifier compatibility: corresponding translations preserve %@/%d/%s placeholders.

Run from the repo root. Exits non-zero on any failure.
"""

from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path
from typing import Dict, List, Set, Tuple

REPO_ROOT = Path(__file__).resolve().parents[2]
RESOURCES_DIR = REPO_ROOT / "browser" / "Reynard" / "Resources"
CLIENT_DIR = REPO_ROOT / "browser" / "Reynard" / "Client"
LANGUAGES = ["en", "zh-Hans"]
BASE_LANGUAGE = "en"
STRINGS_FILE = "Localizable.strings"

STRINGS_ENTRY_PATTERN = re.compile(
    r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;\s*$',
    re.MULTILINE,
)
SWIFT_KEY_PATTERN = re.compile(r'\bL\(\s*"((?:[^"\\]|\\.)*)"')
FORMAT_SPECIFIER_PATTERN = re.compile(r"%(?:\d+\$)?[@dDuUfFeEgGsoxX%]")


def strip_comments(text: str) -> str:
    """Remove /* ... */ block comments and // line comments from a strings file.

    Carefully ignores `//` that appears inside double-quoted string literals
    (e.g. URLs like `https://example.com`).
    """
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)

    cleaned: List[str] = []
    in_string = False
    escape = False
    i = 0
    while i < len(text):
        ch = text[i]
        if in_string:
            cleaned.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            cleaned.append(ch)
            i += 1
            continue
        if ch == "/" and i + 1 < len(text) and text[i + 1] == "/":
            # Skip to end of line.
            while i < len(text) and text[i] != "\n":
                i += 1
            continue
        cleaned.append(ch)
        i += 1
    return "".join(cleaned)


def parse_strings_file(path: Path) -> Tuple[Dict[str, str], List[str]]:
    """Parse a .strings file. Returns (key->value dict, list of issues)."""
    text = path.read_text(encoding="utf-8")
    stripped = strip_comments(text)

    issues: List[str] = []
    entries: Dict[str, str] = {}
    seen: Counter = Counter()

    for match in STRINGS_ENTRY_PATTERN.finditer(stripped):
        key, value = match.group(1), match.group(2)
        seen[key] += 1
        entries[key] = value

    for key, count in seen.items():
        if count > 1:
            issues.append(f"{path}: duplicate key {key!r} appears {count} times")

    # Sanity check: ensure number of `=` matches the number of entries we parsed.
    expected_count = stripped.count(" = ")
    if expected_count and abs(expected_count - len(entries)) > 1:
        issues.append(
            f"{path}: parser found {len(entries)} entries but file has ~{expected_count} '=' separators; "
            "check for unterminated strings or unusual quoting."
        )

    return entries, issues


def find_swift_keys() -> Set[str]:
    """Scan Swift files for `L("...")` references."""
    keys: Set[str] = set()
    for swift_file in CLIENT_DIR.rglob("*.swift"):
        try:
            text = swift_file.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for match in SWIFT_KEY_PATTERN.finditer(text):
            keys.add(match.group(1))
    return keys


def format_specifiers(value: str) -> List[str]:
    """Return the list of format specifiers in the order they appear."""
    return [
        m.group(0)
        for m in FORMAT_SPECIFIER_PATTERN.finditer(value)
        if m.group(0) != "%%"
    ]


def main() -> int:
    print(f"Repo root: {REPO_ROOT}")
    print(f"Resources: {RESOURCES_DIR}")

    parsed: Dict[str, Dict[str, str]] = {}
    errors: List[str] = []
    warnings: List[str] = []

    for lang in LANGUAGES:
        path = RESOURCES_DIR / f"{lang}.lproj" / STRINGS_FILE
        if not path.exists():
            errors.append(f"missing strings file: {path}")
            continue
        entries, issues = parse_strings_file(path)
        parsed[lang] = entries
        errors.extend(issues)
        print(f"  {lang}: {len(entries)} keys ({path.relative_to(REPO_ROOT)})")

    if errors:
        print()
        for err in errors:
            print(f"  ERROR: {err}")
        return 1

    base_keys = set(parsed[BASE_LANGUAGE].keys())

    # Cross-language key alignment.
    for lang, entries in parsed.items():
        if lang == BASE_LANGUAGE:
            continue
        lang_keys = set(entries.keys())
        missing = base_keys - lang_keys
        extra = lang_keys - base_keys
        for key in sorted(missing):
            errors.append(f"{lang} is missing key present in {BASE_LANGUAGE}: {key!r}")
        for key in sorted(extra):
            errors.append(f"{lang} has key not present in {BASE_LANGUAGE}: {key!r}")

    # Format specifier compatibility.
    for lang, entries in parsed.items():
        if lang == BASE_LANGUAGE:
            continue
        for key, value in entries.items():
            base_value = parsed[BASE_LANGUAGE].get(key)
            if base_value is None:
                continue
            base_spec = format_specifiers(base_value)
            lang_spec = format_specifiers(value)
            if Counter(base_spec) != Counter(lang_spec):
                warnings.append(
                    f"{lang}[{key!r}] has different format specifiers from {BASE_LANGUAGE}: "
                    f"{base_spec} vs {lang_spec}"
                )

    # Swift references.
    swift_keys = find_swift_keys()
    print(f"  Swift L(\"...\") references: {len(swift_keys)} unique keys")
    missing_in_base = swift_keys - base_keys
    for key in sorted(missing_in_base):
        errors.append(
            f"Swift code references L({key!r}) but no entry in {BASE_LANGUAGE}.lproj/Localizable.strings"
        )

    # Print warnings (non-fatal).
    if warnings:
        print()
        for w in warnings:
            print(f"  WARN:  {w}")

    if errors:
        print()
        for err in errors:
            print(f"  ERROR: {err}")
        print()
        print(f"Localization validation FAILED with {len(errors)} error(s).")
        return 1

    print()
    print("Localization OK")
    if warnings:
        print(f"({len(warnings)} non-fatal warning(s).)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
