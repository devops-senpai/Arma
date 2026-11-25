#!/usr/bin/env python3
"""Contract coverage for Crest's per-version release notes and Arma's entry files."""

from __future__ import annotations

import importlib.util
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest


REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parents[2]
CATALOG_SCRIPT = REPOSITORY_ROOT / "Scripts" / "release_note_catalog.py"


class ReleaseNoteCatalogTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.repository = pathlib.Path(self.temporary_directory.name)
        for arguments in (
            ["init", "--initial-branch=main"],
            ["config", "user.name", "Crest Tests"],
            ["config", "user.email", "tests@crestbrowser.com"],
        ):
            self.git(*arguments)
        self.write_marketing_version("0.1.1")
        self.write_version_notes("0.1.1", [self.entry("existing-change", "fixed", "Keep existing behavior reliable")])
        self.git("add", ".")
        self.git("commit", "-m", "baseline")

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def git(self, *arguments: str) -> None:
        subprocess.run(["git", *arguments], cwd=self.repository, check=True, capture_output=True)

    def entry(self, identifier: str, category: str, message: str, **fields: object) -> dict[str, object]:
        return {"id": identifier, "category": category, "message": message, **fields}

    def write_marketing_version(self, version: str) -> None:
        path = self.repository / "Config" / "Version.xcconfig"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"MARKETING_VERSION = {version}\n")

    def write_version_notes(
        self,
        version: str,
        entries: list[dict[str, object]],
        release: dict[str, object] | None = None,
        line: str | None = None,
    ) -> pathlib.Path:
        line = line or version.rsplit(".", 1)[0]
        path = self.repository / "Documentation" / "ReleaseNotes" / line / f"{version}.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        document: dict[str, object] = {"entries": entries}
        if release is not None:
            document = {"release": release, **document}
        path.write_text(json.dumps(document, indent=2) + "\n")
        return path

    def run_catalog_check(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", str(CATALOG_SCRIPT), "--repository-root", str(self.repository), *arguments],
            cwd=self.repository,
            check=False,
            capture_output=True,
            text=True,
        )

    def test_version_files_must_be_well_formed_and_named_for_their_version(self) -> None:
        valid = self.run_catalog_check()
        self.assertEqual(valid.returncode, 0, valid.stderr)

        invalid_cases = {
            "wrong line folder": lambda: self.write_version_notes(
                "0.1.1", [self.entry("moved", "fixed", "Describe a fix")], line="0.2"
            ),
            "invalid id": lambda: self.write_version_notes(
                "0.1.1", [self.entry("Bad ID", "new", "Describe a feature")]
            ),
            "unknown category": lambda: self.write_version_notes(
                "0.1.1", [self.entry("valid-id", "changed", "Describe a change")]
            ),
            "unknown field": lambda: self.write_version_notes(
                "0.1.1", [self.entry("valid-id", "fixed", "Describe a fix", commit="abc")]
            ),
            "every platform listed": lambda: self.write_version_notes(
                "0.1.1", [self.entry("valid-id", "fixed", "Describe a fix", platforms=["mac", "ios"])]
            ),
            "duplicate id across versions": lambda: self.write_version_notes(
                "0.1.0", [self.entry("existing-change", "fixed", "Describe it again")]
            ),
            "newer than the marketing version": lambda: self.write_version_notes(
                "0.1.2", [self.entry("future-change", "fixed", "Describe a future fix")]
            ),
            "empty release write-up": lambda: self.write_version_notes(
                "0.1.1", [self.entry("existing-change", "fixed", "Keep existing behavior reliable")], release={}
            ),
        }
        notes = self.repository / "Documentation" / "ReleaseNotes"
        for name, write in invalid_cases.items():
            with self.subTest(name):
                shutil.rmtree(notes)
                self.write_version_notes(
                    "0.1.1", [self.entry("existing-change", "fixed", "Keep existing behavior reliable")]
                )
                write()
                result = self.run_catalog_check()
                self.assertNotEqual(result.returncode, 0, name)

    def write_entry(self, identifier: str, category: str, message: str, **fields: object) -> str:
        path = self.repository / "Documentation" / "ReleaseNotes" / f"{identifier}.json"
        path.write_text(json.dumps({"category": category, "message": message, **fields}) + "\n")
        return str(path.relative_to(self.repository))

    def commit(self, *paths: str, message: str = "change") -> None:
        self.git("add", *paths)
        self.git("commit", "-m", message)

    def read_catalog(self):
        specification = importlib.util.spec_from_file_location("release_note_catalog", CATALOG_SCRIPT)
        module = importlib.util.module_from_spec(specification)
        sys.modules[specification.name] = module
        specification.loader.exec_module(module)
        return module.validate_working_catalog(self.repository)

    def test_a_change_adds_an_entry_file_and_leaves_the_version_files_alone(self) -> None:
        missing = self.run_catalog_check("--require-staged-entry")
        self.assertNotEqual(missing.returncode, 0)
        self.assertIn("stage at least one new release-note entry as Documentation/ReleaseNotes/<id>.json", missing.stderr)

        self.write_version_notes(
            "0.1.1",
            [
                self.entry("existing-change", "fixed", "Keep existing behavior reliable"),
                self.entry("new-change", "new", "Add a new workflow"),
            ],
        )
        self.git("add", "Documentation")
        in_version_file = self.run_catalog_check("--require-staged-entry")
        self.assertNotEqual(in_version_file.returncode, 0)
        self.assertIn("changes only as upstream wrote it", in_version_file.stderr)
        self.git("reset", "-q", "--hard")

        added_path = self.write_entry("new-change", "new", "Add a new workflow", platforms=["mac"])
        self.git("add", added_path)
        added = self.run_catalog_check("--require-staged-entry")
        self.assertEqual(added.returncode, 0, added.stderr)
        self.assertIn("new-change", added.stdout)
        self.git("commit", "-m", "entry")

        reused = self.write_entry("existing-change", "new", "Reuse an id the catalog holds")
        self.git("add", reused)
        duplicate = self.run_catalog_check("--require-staged-entry")
        self.assertNotEqual(duplicate.returncode, 0)
        self.assertIn("is in both", duplicate.stderr)
        self.git("reset", "-q", "--hard")

        self.write_entry("new-change", "improved", "Rewrite release copy")
        self.write_entry("another-change", "fixed", "Fix another workflow")
        self.git("add", "Documentation")
        rewritten = self.run_catalog_check("--require-staged-entry")
        self.assertNotEqual(rewritten.returncode, 0)
        self.assertIn("must not change or delete release-note entries", rewritten.stderr)
        self.git("reset", "-q", "--hard")

        (self.repository / "Documentation" / "ReleaseNotes" / "new-change.json").unlink()
        self.write_entry("another-change", "fixed", "Fix another workflow")
        self.git("add", "-A", "Documentation")
        deleted = self.run_catalog_check("--require-staged-entry")
        self.assertNotEqual(deleted.returncode, 0)
        self.assertIn("must not change or delete release-note entries", deleted.stderr)

    def test_entry_files_belong_to_the_versions_their_commits_build_as(self) -> None:
        # Added later but named first: the commit, not the name, places it.
        self.commit(self.write_entry("zeta-change", "new", "Add the first workflow"))
        self.git("switch", "-q", "-c", "topic")
        self.commit(self.write_entry("from-topic", "improved", "Arrive through a merge"))
        self.git("switch", "-q", "main")
        self.git("merge", "-q", "--no-ff", "-m", "merge topic", "topic")
        self.commit(self.write_entry("alpha-change", "fixed", "Fix the second workflow"))
        # Not committed yet: the version the next commit builds as.
        self.write_entry("beta-change", "improved", "Improve a pending workflow")

        catalog = self.read_catalog()

        self.assertEqual(
            [(entry.identifier, str(entry.version)) for entry in catalog.entries.values()],
            [
                ("existing-change", "0.1.1"),
                ("zeta-change", "0.1.2"),
                ("from-topic", "0.1.3"),
                ("alpha-change", "0.1.4"),
                ("beta-change", "0.1.5"),
            ],
        )
        self.assertEqual(str(catalog.newest_written.version), "0.1.1")
        checked = self.run_catalog_check()
        self.assertEqual(checked.returncode, 0, checked.stderr)
        self.assertIn("Validated 5 release-note entries in 5 versions.", checked.stdout)


if __name__ == "__main__":
    unittest.main()
