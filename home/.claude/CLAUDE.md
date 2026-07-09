# Airlift Craft Environment

Ephemeral container. Tools/state may not persist between sessions.

## Key Facts

- Bash sandbox disabled (no kernel user namespaces). Configured in `~/.claude/settings.json`.
- Runtimes not pre-installed. Use `mise use node`, `mise use python`, etc.
- `glab` available for GitLab. Auth with 1-day token:
  `ssh git@<gitlab-host> personal_access_token <name> api 1`
  then `echo "<token>" | glab auth login --hostname <gitlab-host> --stdin`
- Do not assume tests/linting exist. Check the repo first.

## Proxy

One app at a time. URL: `$CRAFT_URL`.

```
airlift proxy <port>    # expose port
airlift unproxy         # remove
```

## Commands

```
airlift configure claude-code  # Platform AI key
airlift configure git          # git identity + signing
airlift configure gitlab       # GitLab SSH key
airlift credentials load       # reload credentials
airlift mcp register           # register MCP server
airlift changelog              # release notes
```
