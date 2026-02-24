# Data Engineering Claude Plugins

A curated marketplace of Claude Code plugins for the Resonate Data Engineering team.

Modeled after [shield-claude-plugins](https://github.com/resonate/shield-claude-plugins) from the DevOps/Platform team.

## Overview

This repository serves as a central registry for Claude Code extensions including:

- **Skills** - Custom slash commands (e.g., `/deploy-cmr`, `/pipeline-status`)
- **Agents** - Specialized task agents with custom toolsets
- **MCP Servers** - Model Context Protocol servers for external integrations
- **Hooks** - Lifecycle hooks for Claude Code events

## Quick Start

### Option 1: Add as a marketplace (recommended)

```bash
# Inside Claude Code, register the marketplace:
/plugin marketplace add shrivastavakapil2000/dataengineering-claude-plugins

# Then install plugins via the plugin manager:
/plugin install deploy-cmr@dataengineering-plugins
```

### Option 2: Use the CLI helper

```bash
# Clone the repo
git clone https://github.com/shrivastavakapil2000/dataengineering-claude-plugins.git
cd dataengineering-claude-plugins

# Check prerequisites for a plugin
./scripts/de-plugins check deploy-cmr

# Install a plugin
./scripts/de-plugins install deploy-cmr
```

### Option 3: Test locally without installing

```bash
claude --plugin-dir ./plugins/skills/deploy-cmr
```

## CLI Helper

The `de-plugins` script provides a full CLI for managing plugins:

```bash
./scripts/de-plugins <command> [options]
```

| Command | Description |
|---------|-------------|
| `list [category]` | List available plugins |
| `search <query>` | Search plugins by name or tag |
| `info <plugin>` | Show detailed plugin info and prerequisites |
| `check [plugin]` | Check if prerequisites are met |
| `install <plugin>` | Install plugin to `~/.claude/` (checks prerequisites first) |
| `uninstall <plugin>` | Remove an installed plugin |
| `validate` | Validate all plugin manifests |

### Prerequisite Checking

Every plugin declares its prerequisites in `manifest.json`. The CLI checks them before install:

```bash
$ ./scripts/de-plugins check deploy-cmr

Checking: deploy-cmr
  OK Plugin/MCP: atlassian
  OK Plugin/MCP: slack
  OK Prerequisite plugin: atlassian — Atlassian plugin (atlassian@claude-plugins-official)
  OK Prerequisite plugin: slack — Slack plugin
  OK Network connectivity
  All prerequisites met!
```

If something is missing:

```bash
  CHECK Prerequisite plugin: atlassian — install with: /plugin install atlassian@claude-plugins-official
  CHECK Prerequisite plugin: slack — Connect Slack via Claude Code settings
  Some prerequisites need attention — see above

Continue with install anyway? [y/N]
```

## Verifying Installation

After installing a plugin, verify it's working correctly:

### 1. Check the plugin is loaded

```bash
# In Claude Code, type / and look for your plugin in the slash command list
/deploy-cmr
```

If the skill appears in autocomplete, it's loaded.

### 2. Check via the plugin manager

```bash
# Open the plugin manager and go to the "Installed" tab
/plugin
```

Your plugin should appear under the `dataengineering-plugins` marketplace with a green status.

### 3. Verify prerequisites are connected

```bash
# Run /mcp to check MCP server connectivity
/mcp
```

For `deploy-cmr`, you should see both `atlassian` and `slack` listed and connected. If either shows as disconnected, re-authenticate:
- **Atlassian**: `/mcp` and reconnect, or `/plugin` > Installed > atlassian > Reconnect
- **Slack**: Reconnect via Claude Code settings

### 4. Dry-run the plugin

Test with a known ticket to confirm end-to-end:

```bash
# For deploy-cmr, use any existing ticket key
/deploy-cmr CDP-118328
```

If everything is wired up correctly, you'll see the CMR being created and a Slack message sent.

### 5. CLI verification (if installed via de-plugins)

```bash
# Confirm files were copied
ls ~/.claude/skills/deploy-cmr/

# Re-run prerequisite check
./scripts/de-plugins check deploy-cmr
```

### Troubleshooting

| Symptom | Fix |
|---------|-----|
| Skill not showing in `/` autocomplete | Restart Claude Code, or check `/plugin` > Errors tab |
| "Tool not found" errors during execution | Run `/mcp` to verify Atlassian and Slack are connected |
| Slack message fails | Verify you have access to `#data-engineering-only` channel |
| CMR creation fails | Verify you have write access to the CMR project in Jira |
| Plugin loads but behaves unexpectedly | Check for newer version: `git pull` and reinstall |

## Plugin Categories

| Category | Directory | Description |
|----------|-----------|-------------|
| Skills | `plugins/skills/` | Slash commands for common workflows |
| Agents | `plugins/agents/` | Specialized agents (pipelines, data quality, etc.) |
| MCP Servers | `plugins/mcp-servers/` | External service integrations |
| Hooks | `plugins/hooks/` | Event-driven automation |

## Available Plugins

| Plugin | Category | Description |
|--------|----------|-------------|
| [deploy-cmr](./plugins/skills/deploy-cmr/) | Skill | Create a CMR ticket and notify Slack for prod deployments |

## Creating a Plugin

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed instructions.

Quick start with templates:

```bash
# Copy a template
cp -r templates/skill/ plugins/skills/my-new-skill/

# Edit the manifest (include prerequisites!)
vim plugins/skills/my-new-skill/manifest.json

# Add your implementation
vim plugins/skills/my-new-skill/skills/my-new-skill/SKILL.md

# Validate
npm run validate
```

## Plugin Structure

Each plugin must include:

```
plugins/<category>/<plugin-name>/
├── manifest.json      # Metadata, dependencies, prerequisites
├── README.md          # Documentation
├── .claude-plugin/
│   └── plugin.json    # Plugin definition
└── [implementation]   # skills/<name>/SKILL.md, prompt.md, src/, or hook.sh
```

### Prerequisites in manifest.json

Declare what users need before the plugin will work:

```json
{
  "dependencies": {
    "mcpServers": ["atlassian", "slack"]
  },
  "prerequisites": {
    "plugins": [
      {
        "name": "atlassian",
        "description": "Atlassian plugin — must be connected to Resonate Jira",
        "installHint": "/plugin install atlassian@claude-plugins-official"
      }
    ],
    "permissions": [
      "Write access to CMR project in Jira"
    ]
  }
}
```

## Validation

All plugins are validated on PR via GitHub Actions:

- JSON schema validation for manifests
- Required files check (manifest.json, README.md)
- Security scanning for hardcoded secrets

Run locally:

```bash
npm install
npm run validate
```

## License

Internal use only - Resonate proprietary.
