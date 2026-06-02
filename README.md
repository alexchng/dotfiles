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
- existing `.zshrc` and `.bashrc` files get a small managed source block
  appended so aliases and environment preferences still load
- an existing real `.tmux.conf` gets a managed `source-file` block appended;
  existing tmux symlinks are left alone unless `--force` is used
- real `~/.claude/settings.json` is edited in place, not symlinked, so managed
  tokens stay out of the repo

`--force` applies to every linked file under `home/`, not just tmux. If a
destination file already exists, it is moved to `~/.dotfiles-backup/<timestamp>/`
before the dotfiles symlink is created. This can replace files such as:

- `~/.tmux.conf`
- `~/.zshrc`
- `~/.bashrc`
- `~/.gitconfig`
- `~/.config/git/ignore`
- `~/.config/dotfiles/shell/env.sh`
- `~/.claude/CLAUDE.md`
- `~/.claude/commands/*.md`

The real Claude settings file, `~/.claude/settings.json`, is the exception: it
is not linked from `home/`, so `--force` does not replace it. Bootstrap merges
safe model preferences into that file in place unless
`--skip-claude-settings` is used.

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
- `settings.example.json` as a non-secret example of desired settings
- `commands/` for custom slash commands

During bootstrap, `scripts/configure-claude-settings.py` merges a small set of
safe model preferences into the real `~/.claude/settings.json`:

- default model: `sonnet`
- Sonnet alias target: `bedrock.claude-sonnet-4-6`
- model override: `claude-sonnet-4-6` to `bedrock.claude-sonnet-4-6`

Keep secrets and machine-specific values out of this repo. The real Claude
settings file may contain managed auth tokens, so it should stay local to the
workspace.

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
