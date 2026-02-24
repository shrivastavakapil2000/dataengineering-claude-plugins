# CLAUDE.md — Data Engineering Claude Plugins

## Project Overview

Plugin marketplace for the Data Engineering team at Resonate. Modeled after [shield-claude-plugins](https://github.com/resonate/shield-claude-plugins) from the DevOps team.

Contains Claude Code plugins (skills, agents, MCP servers, hooks) for data pipeline operations, Snowflake, Spark, ETL workflows, and data quality.

## Best Practices Reference

When creating or reviewing plugins in this repo, **always check [resonate/shield-claude-plugins](https://github.com/resonate/shield-claude-plugins) for best practices**. That repo is maintained by the DevOps/Platform team and serves as the canonical reference for:

- Plugin directory structure and naming conventions
- SKILL.md format (YAML frontmatter, allowed-tools, prompt structure)
- manifest.json fields and validation schemas
- README.md documentation standards
- CI/CD validation workflows
- Security patterns (no hardcoded secrets, least privilege permissions)
- Supporting files organization (checklists, templates within skill directories)

If the shield repo has updated its patterns (new schema fields, improved validation, new template formats), adopt those changes here to stay consistent across Resonate plugin repos.

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
  de-plugins                      # CLI helper (list, install, check, search)
  validate-manifests.js           # Plugin validation script
.github/workflows/validate.yml    # CI pipeline
```

## Adding a Plugin

1. Copy the appropriate template: `cp -r templates/skill/ plugins/skills/my-plugin/`
2. Edit `manifest.json` with your plugin details — include `prerequisites` for any required plugins/MCP servers
3. Write the implementation (SKILL.md, prompt.md, src/, or hook.sh)
4. Add a `README.md`
5. Update `plugins/registry.json` and `.claude-plugin/marketplace.json`
6. Run `npm run validate` to verify
7. Run `./scripts/de-plugins check my-plugin` to test prerequisites
8. Submit a PR

See [CONTRIBUTING.md](./CONTRIBUTING.md) for full details.

## Conventions

- Plugin names: lowercase with hyphens (`pipeline-debugger`, `snow-query`)
- Each plugin must have `manifest.json` and `README.md`
- Manifests validated against JSON schemas on every PR
- No hardcoded secrets — use env vars or AWS Secrets Manager
- Always confirm before running destructive or prod operations
- Declare all prerequisites in `manifest.json` so users can run `de-plugins check` before install
- Follow the same patterns as [shield-claude-plugins](https://github.com/resonate/shield-claude-plugins) for consistency across Resonate

## Workflow Orchestration

### 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
