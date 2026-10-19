#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
addons_dir="/Applications/World of Warcraft/_retail_/Interface/AddOns"

if [ ! -d "$addons_dir" ]; then
    echo "AddOns directory not found: $addons_dir" >&2
    exit 1
fi

mkdir -p "$addons_dir/LoreCompanion"
cp -R "$project_dir/LoreCompanion/." "$addons_dir/LoreCompanion/"
echo "Copied Lore Companion to $addons_dir/LoreCompanion"
