# CLAUDE.md — Data Engineering Claude Plugins

## Project Overview

Plugin marketplace for the Data Engineering team at Resonate. Modeled after [shield-claude-plugins](https://github.com/resonate/shield-claude-plugins) from the DevOps team.

Contains Claude Code plugins (skills, agents, MCP servers, hooks) for data pipeline operations, Snowflake, Spark, ETL workflows, and data quality.

## Repository Structure

```
.claude-plugin/marketplace.json   # Marketplace registration
plugins/
  registry.json                   # Central plugin catalog
  skills/                         # Slash command plugins
  agents/                         # Specialized agent plugins
  mcp-servers/                    # MCP server plugins
  hooks/                          # Event-driven hook plugins
schemas/
  manifest.schema.json            # Validation schema for plugin manifests
  registry.schema.json            # Validation schema for registry
templates/                        # Starter templates for each plugin type
  skill/ | agent/ | mcp-server/ | hook/
scripts/
  validate-manifests.js           # Plugin validation script
.github/workflows/validate.yml    # CI pipeline
```

## Adding a Plugin

1. Copy the appropriate template: `cp -r templates/skill/ plugins/skills/my-plugin/`
2. Edit `manifest.json` with your plugin details
3. Write the implementation (SKILL.md, prompt.md, src/, or hook.sh)
4. Add a `README.md`
5. Update `plugins/registry.json` and `.claude-plugin/marketplace.json`
6. Run `npm run validate` to verify
7. Submit a PR

See [CONTRIBUTING.md](./CONTRIBUTING.md) for full details.

## Conventions

- Plugin names: lowercase with hyphens (`pipeline-debugger`, `snow-query`)
- Each plugin must have `manifest.json` and `README.md`
- Manifests validated against JSON schemas on every PR
- No hardcoded secrets — use env vars or AWS Secrets Manager
- Always confirm before running destructive or prod operations
