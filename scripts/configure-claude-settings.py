#!/usr/bin/env python3
import argparse
import json
import os
import sys
from pathlib import Path


DESIRED_SETTINGS = {
    "model": "opus",
    "env": {
        "ANTHROPIC_DEFAULT_OPUS_MODEL": "bedrock.claude-opus-4-6[200k]",
    },
    "modelOverrides": {
        "claude-opus-4-6": "bedrock.claude-opus-4-6[200k]",
    },
    "sandbox": {
        "enabled": False,
    },
}


def deep_merge(base, overlay):
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            deep_merge(base[key], value)
        else:
            base[key] = value
    return base


def load_settings(path):
    if not path.exists():
        return {}

    try:
        with path.open() as handle:
            return json.load(handle)
    except json.JSONDecodeError as exc:
        print(f"Claude settings are not valid JSON: {path}: {exc}", file=sys.stderr)
        return None


def main():
    parser = argparse.ArgumentParser(
        description="Merge safe dotfiles preferences into Claude Code settings."
    )
    parser.add_argument(
        "--settings",
        default=os.path.expanduser("~/.claude/settings.json"),
        help="Path to Claude Code settings.json",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show the merged settings without writing them",
    )
    args = parser.parse_args()

    settings_path = Path(args.settings).expanduser()
    settings = load_settings(settings_path)
    if settings is None:
        return 1
    if not isinstance(settings, dict):
        print(f"Claude settings root must be a JSON object: {settings_path}", file=sys.stderr)
        return 1

    merged = deep_merge(settings, DESIRED_SETTINGS.copy())

    if args.dry_run:
        print(f"dry-run: merge Claude preferences into {settings_path}")
        print(json.dumps(DESIRED_SETTINGS, indent=2, sort_keys=True))
        return 0

    settings_path.parent.mkdir(parents=True, exist_ok=True)

    if settings_path.is_symlink():
        current = settings_path.resolve()
        settings_path.unlink()
        print(f"replaced symlinked Claude settings with regular file from {current}")

    with settings_path.open("w") as handle:
        json.dump(merged, handle, indent=2, sort_keys=False)
        handle.write("\n")

    print(f"configured Claude settings: {settings_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
