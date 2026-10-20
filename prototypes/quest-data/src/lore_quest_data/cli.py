"""Command-line interface for quest-data generation."""
import argparse
from pathlib import Path
import sys
from . import __version__
from .generate import generate


def main(argv=None):
    parser = argparse.ArgumentParser(description="Generate original Blizzard quest JSON and Lua data.")
    parser.add_argument("--version", action="version", version=__version__)
    parser.add_argument("--map", type=Path, required=True, dest="map_path")
    parser.add_argument("--output", type=Path, default=Path("output"))
    parser.add_argument("--env-file", type=Path, default=Path(".env"))
    parser.add_argument("--region", choices=("eu", "us"), default="eu")
    args = parser.parse_args(argv)
    try:
        generate(args.map_path, args.output, args.region, args.env_file)
        return 0
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        print(f"Generation failed: {error}", file=sys.stderr)
        return 1
    except (EOFError, KeyboardInterrupt):
        print("Cancelled.", file=sys.stderr)
        return 1
