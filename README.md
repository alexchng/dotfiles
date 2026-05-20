# dotfiles

Personal dotfiles for turning a fresh dev box or remote workspace into a familiar
environment quickly.

## Quick Start

Clone this repo somewhere stable, then run the bootstrap script:

```sh
git clone <this-repo-url> ~/.dotfiles
~/.dotfiles/scripts/bootstrap.sh --dry-run
~/.dotfiles/scripts/bootstrap.sh
```

The bootstrap script links files from `home/` into your real home directory. It
is intentionally conservative:

- existing files are skipped by default
- `--dry-run` shows what would happen
- `--force` backs up replaced files under `~/.dotfiles-backup/`

This repo does not install system packages or global tools. It assumes the
remote workspace image already provides tools such as `git`, `tmux`, `mise`, and
`claude`, or that missing tools should simply be skipped.

## Layout

```text
home/                  Files that should exist under $HOME
home/.claude/          Claude Code memory, settings, and personal commands
home/.config/dotfiles/ Shell snippets sourced by .zshrc and .bashrc
scripts/               Bootstrap, health-check, and workspace scripts
scripts/workspaces/    Project-specific workspace bootstrap scripts
```

## Fresh Workspace Recipe

```sh
git clone <this-repo-url> ~/.dotfiles
~/.dotfiles/scripts/bootstrap.sh
~/.dotfiles/scripts/doctor.sh
```

After bootstrapping, start or attach to your default tmux session with:

```sh
t
```

## Claude Code

This repo includes personal Claude Code files in `home/.claude/`:

- `CLAUDE.md` for global memory and working preferences
- `settings.json` for personal Claude Code settings
- `commands/` for custom slash commands

Keep secrets and machine-specific values out of this repo. Use local files such
as project-level `.claude/settings.local.json`, shell environment files, or your
password manager for credentials.

## Airdocs Workspace

The Airdocs bootstrap captures the remote workspace flow:

```sh
~/.dotfiles/scripts/workspaces/airdocs.sh --dry-run
~/.dotfiles/scripts/workspaces/airdocs.sh
```

It links the dotfiles, reloads tmux when a tmux server is running, clones or
reuses the Airdocs repository, applies the SGTS Git identity locally to that
repository, runs `mise trust`, and starts Claude Code from the repo with
`claude-sonnet-4-6`.

Useful options:

```sh
~/.dotfiles/scripts/workspaces/airdocs.sh --dir ~/airdocs
~/.dotfiles/scripts/workspaces/airdocs.sh --skip-claude
~/.dotfiles/scripts/workspaces/airdocs.sh --force-dotfiles
```
