#!/usr/bin/env python3
import argparse
import json
import os
import sys
from pathlib import Path


DESIRED_SETTINGS = {
    "model": "bedrock.claude-opus-5-5",
    "env": {
        "CLAUDE_CODE_USE_BEDROCK": "0",
        "CLAUDE_CODE_USE_FOUNDRY": "0",
        "CLAUDE_CODE_USE_MANTLE": "0",
        "CLAUDE_CODE_USE_VERTEX": "0",
        "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1",
        "DISABLE_BUG_COMMAND": "1",
        "DISABLE_ERROR_REPORTING": "1",
        "DISABLE_TELEMETRY": "1",
        "ANTHROPIC_DEFAULT_HAIKU_MODEL": "bedrock.claude-haiku-5-5",
        "ANTHROPIC_DEFAULT_SONNET_MODEL": "bedrock.claude-sonnet-5-5",
        "ANTHROPIC_DEFAULT_OPUS_MODEL": "bedrock.claude-opus-5-5",
        "ANTHROPIC_DEFAULT_MODEL": "bedrock.claude-sonnet-5-5",
    },
    "modelOverrides": {
        "claude-haiku-4-5-20251001": "bedrock.claude-haiku-4-5",
        "claude-sonnet-4-5-20250929": "bedrock.claude-sonnet-4-5",
        "claude-sonnet-4-6": "bedrock.claude-sonnet-4-6",
        "claude-opus-4-5-20251101": "bedrock.claude-opus-4-5",
        "claude-opus-4-6": "bedrock.claude-opus-4-6",
        "claude-opus-4-7": "bedrock.claude-opus-4-7",
        "claude-opus-4-8": "bedrock.claude-opus-4-8",
        "claude-opus-5": "bedrock.claude-opus-5",
        "claude-opus-5-5": "bedrock.claude-opus-5-5",
        "claude-sonnet-5": "bedrock.claude-sonnet-5",
        "claude-sonnet-5-5": "bedrock.claude-sonnet-5-5",
        "claude-haiku-5-5": "bedrock.claude-haiku-5-5",
    },
    "modelPicker": {
        "options": [
            {
                "model": "bedrock.claude-sonnet-5-5",
                "label": "Sonnet 5.5",
                "description": "Sonnet 5.5 · Efficient for routine tasks",
            },
            {
                "model": "bedrock.claude-opus-5-5",
                "label": "Opus 5.5",
                "description": "Opus 5.5 · For complex work · Costs more than Sonnet",
            },
            {
                "model": "bedrock.claude-haiku-5-5",
                "label": "Haiku 5.5",
                "description": "Haiku 5.5 · Fastest for quick answers · Costs less than Sonnet",
            },
            {
                "model": "bedrock.claude-sonnet-4-6",
                "label": "Sonnet 4.6",
                "description": "Sonnet 4.6",
            },
            {
                "model": "bedrock.claude-opus-4-8",
                "label": "Opus 4.8",
                "description": "Opus 4.8",
            },
        ],
        "replaceBuiltInOptions": True,
    },
    "modelSettings": {
        "claude-haiku-5-5": {"effortLevel": "medium", "maxEffortLevel": "high"},
        "claude-opus-5-5": {"effortLevel": "medium", "maxEffortLevel": "high"},
        "claude-sonnet-5-5": {"effortLevel": "medium", "maxEffortLevel": "high"},
    },
    "effortLevel": "medium",
    "autoCompactEnabled": True,
    "autoCompactWindow": 300000,
    "theme": "light",
    "enableAllProjectMcpServers": False,
    # Airlift containers lack kernel user namespaces, so bubblewrap cannot start.
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
