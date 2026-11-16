#!/usr/bin/env python3
"""Name the app Arma in the strings a build ships, leaving Crest's source as
Crest wrote it.

Crest's interface strings are keys in CrestShared/Resources/Localizable.xcstrings,
and many name the app: "Quit Crest", "Crest couldn’t save this change." Xcode
compiles the catalog into <language>.lproj/Localizable.strings (and .stringsdict
for plurals), but the source language's table holds only the keys that carry an
explicit English value; every other key shows as itself. This build phase runs
after the resources are copied and, for every catalog key that names the app,
writes the key into each language's compiled table with Arma in place of Crest:
the English value is the key itself unless the catalog gives one, and a
translation keeps its own words. Keys stay Crest's, so translations stay
attached and Crest's new strings are covered the next time they reach the
catalog.

"Crest" is also heraldry here: a Space wears a crest, drawn in Crest Studio.
The phrases in HERALDRY keep the word, wherever they appear.

Run by the app and Chromium host targets with the build's environment; with
--check <bundle resources> it only reports the strings that still say Crest.
"""
import json
import os
import plistlib
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
CATALOG = ROOT / "CrestShared/Resources/Localizable.xcstrings"
NAME = "Arma"

# Where "Crest" names the Space's emblem, not the app.
HERALDRY = re.compile(
    r"^Crest$|Crest Studio|Layered Crest|Edit Crest|Crest colors|Crest preview|Crest branding"
    r"|Make Crest your own|Choose Crest under Emblem"
)
WORD = re.compile(r"\bCrest\b")


def branded(text):
    """`text` with the app's name as Arma, its heraldic phrases kept."""
    if not WORD.search(text):
        return text
    kept = []

    def keep(match):
        kept.append(match.group(0))
        return f"\0{len(kept) - 1}\0"

    masked = HERALDRY.sub(keep, text)
    masked = WORD.sub(NAME, masked)
    return re.sub(r"\0(\d+)\0", lambda match: kept[int(match.group(1))], masked)


def unit_value(localization):
    """The plain string a catalog localization gives, or None for variations."""
    unit = localization.get("stringUnit") if localization else None
    return unit.get("value") if unit else None


def read_table(path):
    if not path.is_file():
        return {}
    data = subprocess.run(["plutil", "-convert", "json", "-o", "-", str(path)],
                          check=True, capture_output=True).stdout
    return json.loads(data)


def rebrand_plist(path):
    """Rewrites every string value in a compiled .stringsdict."""
    table = read_table(path)

    def walk(value):
        if isinstance(value, dict):
            return {key: walk(item) for key, item in value.items()}
        return branded(value) if isinstance(value, str) else value

    rewritten = {key: walk(item) for key, item in table.items()}
    if rewritten != table:
        with path.open("wb") as stream:
            plistlib.dump(rewritten, stream, fmt=plistlib.FMT_BINARY)


def extracted_keys():
    """The Localizable keys the compiler extracted from this target's Swift,
    when the target extracts them: strings that reach the catalog only the
    next time Xcode syncs it."""
    objects = os.environ.get("OBJECT_FILE_DIR_normal")
    if not objects:
        return set()
    keys = set()
    for path in Path(objects).glob("*/*.stringsdata"):
        tables = json.loads(path.read_text()).get("tables", {})
        keys.update(entry["key"] for entry in tables.get("Localizable", []) if "key" in entry)
    return keys


def rebrand(resources):
    strings = json.loads(CATALOG.read_text())["strings"]
    strings.update({key: {} for key in extracted_keys() if key not in strings})
    named = {key: entry for key, entry in strings.items() if branded(key) != key}
    languages = sorted({path.stem for path in resources.glob("*.lproj")} & (
        {"en"} | {language for entry in strings.values() for language in entry.get("localizations", {})}))
    for language in languages:
        table_path = resources / f"{language}.lproj/Localizable.strings"
        table = read_table(table_path)
        for key, entry in named.items():
            localizations = entry.get("localizations", {})
            # Plural and device variations compile into the .stringsdict.
            if any("variations" in localizations.get(code, {}) for code in (language, "en")):
                continue
            value = table.get(key) or unit_value(localizations.get(language)) or unit_value(
                localizations.get("en")) or key
            table[key] = branded(value)
        for key, value in list(table.items()):
            table[key] = branded(value)
        table_path.parent.mkdir(parents=True, exist_ok=True)
        with table_path.open("wb") as stream:
            plistlib.dump(table, stream, fmt=plistlib.FMT_BINARY)
        plurals = resources / f"{language}.lproj/Localizable.stringsdict"
        if plurals.is_file():
            rebrand_plist(plurals)
    return len(named), languages


def leftovers(resources):
    """The compiled strings that still say Crest outside its heraldry."""
    found = []
    for path in sorted(resources.glob("*.lproj/Localizable.strings*")):
        table = read_table(path)
        for key, value in table.items():
            texts = [value] if isinstance(value, str) else re.findall(r'"((?:[^"\\]|\\.)*)"', json.dumps(value))
            if any(branded(text) != text for text in texts):
                found.append(f"{path.parent.name}: {key!r} -> {value!r}"[:200])
    return found


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--check":
        found = leftovers(Path(sys.argv[2]))
        print("\n".join(found) or "Every compiled string says Arma where it names the app.")
        sys.exit(1 if found else 0)
    resources = Path(os.environ["TARGET_BUILD_DIR"]) / os.environ["UNLOCALIZED_RESOURCES_FOLDER_PATH"]
    count, languages = rebrand(resources)
    print(f"brand-strings: {count} catalog strings name {NAME} in {', '.join(languages) or 'no languages'}")


if __name__ == "__main__":
    main()
