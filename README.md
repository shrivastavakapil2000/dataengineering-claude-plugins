# dataengineering-claude-plugins

Claude Code plugins, MCP servers, custom commands, and configuration for the Data Engineering team.

## What's Here

| Path | Description |
|------|-------------|
| `CLAUDE.md` | Project instructions that Claude Code reads automatically |
| `.claude/settings.json` | Project-level permission and tool settings |
| `.claude/commands/` | Custom slash commands for common workflows |

## Custom Commands

- `/status` — Show repo status, recent commits, and what's in progress
- `/new-mcp-server` — Scaffold a new MCP server with boilerplate

## Getting Started

1. Clone this repo
2. Open it with Claude Code (`claude` in the repo root)
3. Claude will automatically pick up `CLAUDE.md` and `.claude/` settings
4. Use `/status` to see current state

## Adding Content

- **MCP servers** — Use `/new-mcp-server` or manually add under `servers/`
- **Custom commands** — Add `.md` files to `.claude/commands/`
- **Project instructions** — Edit `CLAUDE.md`
