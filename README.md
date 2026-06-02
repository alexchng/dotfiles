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
- `--force` backs up and replaces `~/.tmux.conf` only
- existing `.zshrc` and `.bashrc` files get a small managed source block
  appended so aliases and environment preferences still load
- an existing real `.gitconfig` gets a managed include block appended so Git
  preferences still load
- an existing real `.tmux.conf` gets a managed `source-file` block appended;
  existing tmux symlinks are left alone unless `--force` is used
- real `~/.claude/settings.json` is edited in place, not symlinked, so managed
  tokens stay out of the repo

`--force` is intentionally scoped to tmux. If `~/.tmux.conf` already exists, it
is moved to `~/.dotfiles-backup/<timestamp>/.tmux.conf` before the dotfiles
symlink is created. Existing `~/.zshrc`, `~/.bashrc`, and `~/.gitconfig` files
are not replaced; bootstrap appends managed blocks if the same settings are not
already present. Other existing files under `home/`, such as
`~/.claude/CLAUDE.md` and Claude command files, are still skipped and left in
place.

The real Claude settings file, `~/.claude/settings.json`, is the exception: it
is not linked from `home/`, so `--force` does not replace it either. Bootstrap
merges safe model preferences into that file in place unless
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

## Logs

`bootstrap.sh` and `doctor.sh` print to the terminal and also write timestamped
logs by default:

```text
~/.dotfiles/logs/bootstrap-YYYYMMDD-HHMMSS.log
~/.dotfiles/logs/doctor-YYYYMMDD-HHMMSS.log
```

Log files include timestamps on each line. Use `--no-log` to print only to the
terminal, or `--log-file PATH` to choose a specific log file:

```sh
~/.dotfiles/scripts/bootstrap.sh --no-log
~/.dotfiles/scripts/bootstrap.sh --log-file /tmp/bootstrap.log
~/.dotfiles/scripts/doctor.sh --log-file /tmp/doctor.log
```

## Git Identity

The default dotfiles Git config includes `~/.config/git/tech.gitconfig`, which
sets your Tech/GovTech identity:

```ini
[user]
	name = Alex Chng
	email = alex_chng@tech.gov.sg
```

Use repo-local Git config when a project needs a different identity.

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

`--force-dotfiles` passes the scoped `--force` behavior through to
`bootstrap.sh`, so it only replaces an existing `~/.tmux.conf`.
