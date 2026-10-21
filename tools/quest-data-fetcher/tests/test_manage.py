from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from zipfile import ZipFile

from manage import deploy


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        root = Path(self.temporary.name)
        self.addons = root / "AddOns"
        self.addons.mkdir()
        self.installed = self.addons / "LoreCompanion"
        self.installed.mkdir()
        (self.installed / "Core.lua").write_text("old code")
        self.archive = root / "addon.zip"
        with ZipFile(self.archive, "w") as archive:
            for name in ("LoreCompanion.toc", "QuestData.lua", "Core.lua"):
                archive.writestr("LoreCompanion/" + name, "new content")

    def test_successful_replacement(self):
        deploy(self.archive, self.addons)
        self.assertEqual((self.installed / "Core.lua").read_text(), "new content")
        self.assertEqual(list(self.addons.iterdir()), [self.installed])

    def test_first_install(self):
        (self.installed / "Core.lua").unlink()
        self.installed.rmdir()
        deploy(self.archive, self.addons)
        self.assertEqual((self.installed / "Core.lua").read_text(), "new content")

    def test_staging_failure_leaves_installation_untouched(self):
        with patch.object(Path, "write_bytes", side_effect=OSError("Simulated disk failure")):
            with self.assertRaises(OSError):
                deploy(self.archive, self.addons)
        self.assertEqual((self.installed / "Core.lua").read_text(), "old code")
        self.assertEqual(list(self.addons.iterdir()), [self.installed])

    def test_install_failure_restores_previous_folder(self):
        rename = Path.rename

        def fail_install(path, target):
            if path.name == "replacement":
                raise OSError("Simulated install failure")
            return rename(path, target)

        with patch.object(Path, "rename", fail_install):
            with self.assertRaises(OSError):
                deploy(self.archive, self.addons)
        self.assertEqual((self.installed / "Core.lua").read_text(), "old code")
        self.assertEqual(list(self.addons.iterdir()), [self.installed])

    def test_failed_rollback_preserves_backup(self):
        rename = Path.rename

        def fail_install_and_restore(path, target):
            if path.name in ("replacement", "backup"):
                raise OSError("Simulated rename failure")
            return rename(path, target)

        with patch.object(Path, "rename", fail_install_and_restore):
            with self.assertRaises(OSError):
                deploy(self.archive, self.addons)
        backups = list(self.addons.glob(".lore-deploy-*/backup/Core.lua"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "old code")
