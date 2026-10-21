#!/usr/bin/env python3
"""Build and deploy Lore Companion with generated quest data."""
import argparse
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import sys
import tempfile
from zipfile import ZipFile, ZIP_DEFLATED, BadZipFile

def package(export_dir, addon_dir):
    generated = (export_dir / "QuestData.lua").read_text(encoding="utf-8")
    toc_path = addon_dir / "LoreCompanion.toc"
    toc = toc_path.read_text(encoding="utf-8")
    # Include only files explicitly loaded by the manifest, never repository secrets.
    names = [line.strip() for line in toc.splitlines() if line.strip() and not line.lstrip().startswith("#")]
    sources = {}
    for name in names:
        path = addon_dir / name
        if path.is_symlink() or path.resolve().parent != addon_dir.resolve() or path.suffix != ".lua":
            raise RuntimeError(f"Unsupported manifest entry: {name}")
        sources[name] = path.read_bytes()
    if "QuestData.lua" in sources:
        raise RuntimeError("Manifest already includes QuestData.lua; review the build layout.")
    first = next(i for i, line in enumerate(toc.splitlines()) if line.strip() in names)
    lines = toc.splitlines()
    lines.insert(first, "QuestData.lua")
    destination = export_dir / "LoreCompanion.zip"
    temporary = destination.with_suffix(".zip.tmp")
    try:
        with ZipFile(temporary, "w", ZIP_DEFLATED) as archive:
            archive.writestr("LoreCompanion/LoreCompanion.toc", "\n".join(lines) + "\n")
            archive.writestr("LoreCompanion/QuestData.lua", generated)
            for name, content in sources.items():
                archive.writestr("LoreCompanion/" + name, content)
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)
    print(f"Addon ZIP: {destination}")
    return destination



def deploy(archive_path, addons):
    if not addons.is_dir():
        raise ValueError(f"AddOns directory not found: {addons}")
    if not archive_path.is_file():
        raise ValueError("No built ZIP found. Run uv run manage.py --build first.")
    with ZipFile(archive_path) as archive:
        names = archive.namelist()
        required = {"LoreCompanion/LoreCompanion.toc", "LoreCompanion/QuestData.lua"}
        if not required.issubset(names) or len(names) != len(set(names)):
            raise ValueError("ZIP must contain a manifest and bundled quest data without duplicate entries.")
        for name in names:
            path = PurePosixPath(name)
            if len(path.parts) != 2 or path.parts[0] != "LoreCompanion" or path.name in (".", "..") or "\\" in name:
                raise ValueError("ZIP contains an unsupported addon path.")
        # Stage on the destination filesystem so directory renames stay local.
        staging = Path(tempfile.mkdtemp(prefix=".lore-deploy-", dir=addons))
        replacement = staging / "replacement"
        backup = staging / "backup"
        try:
            replacement.mkdir()
            for name in names:
                target = replacement / PurePosixPath(name).name
                target.write_bytes(archive.read(name))
            destination = Path(addons) / "LoreCompanion"
            if destination.is_symlink():
                raise ValueError("Installed addon folder is a symlink; choose a regular AddOns directory.")
            if destination.exists():
                if not destination.is_dir():
                    raise ValueError("Installed addon path is not a directory.")
                destination.rename(backup)
            try:
                replacement.rename(destination)
            except OSError:
                if backup.exists():
                    backup.rename(destination)
                raise
            if backup.exists():
                shutil.rmtree(backup)
        finally:
            # Never delete the old installation if restoring it also failed.
            if backup.exists():
                print(f"Previous addon preserved at {backup}", file=sys.stderr)
            else:
                shutil.rmtree(staging)
    print(f"Deployed {archive_path}\nto {destination}")


def main():
    root = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", action="store_true", help="Generate quest data and package the addon")
    parser.add_argument("--deploy", action="store_true", help="Install the built ZIP")
    parser.add_argument("--region", choices=("eu", "us"), default="eu")
    parser.add_argument("--addons-dir", type=Path, default=Path(os.environ.get("WOW_ADDONS_DIR", "/Applications/World of Warcraft/_retail_/Interface/AddOns")))
    args = parser.parse_args()
    if not args.build and not args.deploy:
        parser.error("choose --build, --deploy, or both")
    output = root / "output"
    archive = output / "LoreCompanion.zip"
    if args.build:
        archive.unlink(missing_ok=True)
        project = root / "tools/quest-data-fetcher"
        environment = dict(os.environ)
        environment.pop("VIRTUAL_ENV", None)  # uv selects the fetcher project environment.
        subprocess.run(["uv", "run", "--project", str(project), "--locked", "quest-data-fetcher", "--map", str(project / "quest_map.json"),
                        "--env-file", str(project / ".env"), "--output", str(output), "--region", args.region], check=True, env=environment)
        package(output, root / "LoreCompanion")
    if args.deploy:
        deploy(archive, args.addons_dir)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, BadZipFile, subprocess.CalledProcessError) as error:
        print(f"Operation failed: {error}", file=sys.stderr)
        sys.exit(1)
