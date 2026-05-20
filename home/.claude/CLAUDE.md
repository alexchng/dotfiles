# Personal Claude Code Preferences

This is global Claude Code memory for Alex's development workspaces. Treat it as
default guidance unless a repository-level `CLAUDE.md` gives more specific
instructions.

## Default Working Style

- Read the repository's existing conventions before proposing broad changes.
- Keep code edits narrowly scoped to the requested behavior.
- Prefer small, reversible changes over sweeping rewrites.
- When changing code, run the smallest useful verification command and report it.
- Do not put secrets, tokens, or machine-specific credentials in committed files.
- In reviews, lead with correctness, security, data loss, behavior regressions,
  and missing-test risks.

## Airlift / Craft Session Setup

Airlift craft containers are ephemeral. Globally installed tools and user
settings may be wiped between sessions, so verify the working environment before
assuming tools are available.

### Bash Sandbox

The craft environment may not support the default Claude Code Bash sandbox
because kernel user namespaces can be disabled. If shell commands fail with
`bwrap: No permissions to create new namespace`, tell the user the Bash sandbox
needs to be disabled for the session and use `/sandbox` to manage it.

### Runtimes

Runtimes such as Node and Python are managed with `mise`.

- Use `mise use node`, `mise use python`, etc. to activate runtimes when needed.
- `mise use <runtime>` affects the current shell only.
- Use `mise exec -- <command>` for servers and long-running processes so the
  correct runtime is available even when the command runs from a new shell.
- Run `mise trust` in a project only after confirming the repo is expected and
  trusted.

### Dependency Installation

When `sfw` is available, prefix dependency install commands with it to block
known malicious packages in real time.

| Instead of | Prefer |
|---|---|
| `npm install` | `sfw npm install` |
| `npm ci` | `sfw npm ci` |
| `pip install` | `sfw pip install` |
| `pip install -r requirements.txt` | `sfw pip install -r requirements.txt` |

If `sfw` is missing and dependency installation is required, ask before
installing it globally. Airlift workspaces may not allow privileged installs, so
do not assume global installation is possible.

## Airlift Proxy

Only one app can be proxied at a time. The craft URL is available via
`$CRAFT_URL`.

```bash
airlift proxy <port>
airlift unproxy
```

To switch apps, unproxy first, then proxy the new port.

Common ports:

- docs or md-viewer: `3000`
- Vite apps: `5173`
- Streamlit apps: `8501`

## Project Discovery

Do not assume every workspace has automated tests, linting, or formatting. Check
the repository first, then run the smallest useful verification command that is
actually available.
