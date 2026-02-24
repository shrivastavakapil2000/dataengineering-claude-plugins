# Contributing to Data Engineering Claude Plugins

## Overview

This guide explains how to create, test, and submit plugins to the Data Engineering Claude Plugins marketplace.

## Plugin Types

### Skills

Custom slash commands that extend Claude Code's capabilities.

**Use cases:**
- Pipeline operations (`/run-pipeline`, `/check-pipeline-status`)
- Data quality checks (`/data-quality`, `/schema-validate`)
- Snowflake operations (`/snow-query`, `/snow-deploy`)

**Structure:**
```
plugins/skills/<name>/
├── manifest.json         # Plugin metadata
├── README.md             # Usage documentation
├── .claude-plugin/
│   └── plugin.json       # Plugin definition
└── skills/<name>/
    ├── SKILL.md           # Main prompt/instructions
    └── [supporting files] # Checklists, templates, etc.
```

### Agents

Specialized agents with focused capabilities and toolsets.

**Use cases:**
- Pipeline debugging agent
- Data quality investigation agent
- ETL migration assistant

**Structure:**
```
plugins/agents/<name>/
├── manifest.json    # Plugin metadata
├── README.md        # Usage documentation
├── prompt.md        # Agent system prompt
└── tools.json       # (optional) Custom tool definitions
```

### MCP Servers

Model Context Protocol servers for external integrations.

**Use cases:**
- Snowflake query interface
- Spark job management
- Data catalog integration
- Pipeline orchestration (Airflow, Step Functions)

**Structure:**
```
plugins/mcp-servers/<name>/
├── manifest.json    # Plugin metadata
├── README.md        # Setup and usage
├── src/             # Server implementation
│   └── index.ts
├── package.json     # Dependencies
└── tsconfig.json    # TypeScript config
```

### Hooks

Event-driven automation triggered by Claude Code lifecycle events.

**Use cases:**
- Pre-commit SQL linting
- Auto-format Spark/Scala code
- Validate schema changes before commit

**Structure:**
```
plugins/hooks/<name>/
├── manifest.json    # Plugin metadata
├── README.md        # Documentation
└── hook.sh          # Hook script
```

## Creating a Plugin

### 1. Start from a Template

```bash
# Clone the repo
git clone git@github.com:shrivastavakapil2000/dataengineering-claude-plugins.git
cd dataengineering-claude-plugins

# Create a branch
git checkout -b feature/add-my-plugin

# Copy the appropriate template
cp -r templates/skill/ plugins/skills/my-plugin/
```

### 2. Edit the Manifest

Update `manifest.json` with your plugin details:

```json
{
  "$schema": "../../schemas/manifest.schema.json",
  "name": "my-plugin",
  "displayName": "My Plugin",
  "version": "1.0.0",
  "category": "skills",
  "description": "Brief description (max 200 chars)",
  "author": "your-name",
  "tags": ["data-engineering", "related-topic"],
  "dependencies": {
    "tools": ["snow", "aws"]
  }
}
```

### 3. Write the Prompt/Implementation

For skills, create a `SKILL.md` with YAML frontmatter:

```markdown
---
name: my-skill
description: What this skill does
allowed-tools: Bash(snow:*), Read, Grep, Glob, Write, Edit
user-invocable: true
---

# My Skill

## Instructions
[Step-by-step instructions for Claude]
```

### 4. Document Your Plugin

Create a comprehensive `README.md`:

- What the plugin does
- Prerequisites and dependencies
- Installation instructions
- Usage examples
- Configuration options
- Troubleshooting

### 5. Test Locally

```bash
# Test with the --plugin-dir flag
claude --plugin-dir ./plugins/skills/my-plugin

# Or copy to your Claude config
cp -r plugins/skills/my-plugin ~/.claude/skills/
```

### 6. Validate

```bash
# Run validation
npm run validate
```

### 7. Submit a PR

```bash
git add plugins/skills/my-plugin/
git commit -m "feat: Add my-plugin skill"
git push -u origin feature/add-my-plugin
gh pr create --title "Add my-plugin skill" --body "Description of the plugin"
```

## Guidelines

### Naming Conventions

- Plugin names: lowercase with hyphens (`pipeline-debugger`, `snow-query`)
- No spaces or special characters
- Descriptive but concise

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

### Security Requirements

1. **No hardcoded secrets** - Use environment variables or AWS Secrets Manager
2. **Least privilege** - Request only necessary permissions
3. **Input validation** - Sanitize user inputs
4. **Safe commands** - Avoid destructive operations without confirmation
5. **Snowflake safety** - Always confirm before running on live/prod connections

### Documentation Standards

- Clear, concise descriptions
- Working examples
- Prerequisites listed
- Troubleshooting section for common issues

### Code Quality

- Follow existing patterns in the repository
- Include error handling
- Test edge cases
- Comment complex logic

## Review Process

1. **Automated checks** - CI validates schemas and runs linters
2. **Peer review** - At least one team member reviews
3. **Security review** - Plugins with elevated permissions require security review
4. **Testing** - Reviewer tests the plugin locally

## Updating Existing Plugins

1. Increment the version in `manifest.json`
2. Update changelog in README
3. Ensure backward compatibility or document breaking changes
4. Submit PR with clear description of changes

## Getting Help

- Check existing plugins for examples
- Ask in #data-engineering Slack channel
- Open a GitHub issue for bugs or feature requests
