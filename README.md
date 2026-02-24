# Data Engineering Claude Plugins

A curated marketplace of Claude Code plugins for the Resonate Data Engineering team.

Modeled after [shield-claude-plugins](https://github.com/resonate/shield-claude-plugins) from the DevOps/Platform team.

## Overview

This repository serves as a central registry for Claude Code extensions including:

- **Skills** - Custom slash commands (e.g., `/pipeline-status`, `/data-quality`)
- **Agents** - Specialized task agents with custom toolsets
- **MCP Servers** - Model Context Protocol servers for external integrations
- **Hooks** - Lifecycle hooks for Claude Code events

## Quick Start

### Installing a Plugin

1. Browse the [plugins directory](./plugins) or check the [registry](./plugins/registry.json)
2. Install using the plugin manager or copy manually:

```bash
# Using Claude Code plugin manager
/plugin marketplace add shrivastavakapil2000/dataengineering-claude-plugins

# Or test locally with --plugin-dir
claude --plugin-dir ./plugins/skills/<plugin-name>
```

## Plugin Categories

| Category | Directory | Description |
|----------|-----------|-------------|
| Skills | `plugins/skills/` | Slash commands for common workflows |
| Agents | `plugins/agents/` | Specialized agents (pipelines, data quality, etc.) |
| MCP Servers | `plugins/mcp-servers/` | External service integrations |
| Hooks | `plugins/hooks/` | Event-driven automation |

## Creating a Plugin

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed instructions.

Quick start with templates:

```bash
# Copy a template
cp -r templates/skill/ plugins/skills/my-new-skill/

# Edit the manifest
vim plugins/skills/my-new-skill/manifest.json

# Add your implementation
vim plugins/skills/my-new-skill/prompt.md

# Validate
npm run validate
```

## Plugin Structure

Each plugin must include:

```
plugins/<category>/<plugin-name>/
├── manifest.json      # Plugin metadata and configuration
├── README.md          # Documentation
└── [implementation]   # SKILL.md, prompt.md, src/, or hook.sh
```

## Registry

The [registry.json](./plugins/registry.json) file contains metadata for all plugins.

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
