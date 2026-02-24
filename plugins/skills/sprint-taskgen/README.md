# Sprint Task Generator

> Automatically break down every story in a Jira sprint into milestone-prefixed sub-tasks from a Data Engineering perspective.

## Overview

When starting a new sprint, this skill takes a sprint name and:

1. Finds all Stories in the sprint
2. **Deep-analyzes each story** by investigating across multiple systems:
   - **Jira** — story details, linked issues, comments, prior work
   - **Confluence** — design docs, architecture specs, runbooks
   - **GitHub** — linked repos, open PRs, code structure (`gh` CLI)
   - **Slack** — team discussions, decisions, blockers
   - **AWS** — infrastructure context for stories involving AWS resources
3. Creates up to 10 sub-tasks per story with milestone prefixes (`planning:`, `coding:`, `testing:`, `review:`, `release:`, `validation:`, `documentation:`)
4. Skips stories that already have sub-tasks

Tasks are written as executive summaries — concise, actionable, one sentence each. They reflect ACTUAL work discovered from all sources, not generic boilerplate.

## Installation

**Option A** — Install from this repo:

```bash
./scripts/de-plugins install sprint-taskgen
```

**Option B** — Point Claude Code at the plugin directory:

```bash
claude --plugin-dir ./plugins/skills/sprint-taskgen
```

**Option C** — Copy manually:

```bash
cp -r plugins/skills/sprint-taskgen ~/.claude/plugins/sprint-taskgen
```

## Prerequisites

- **Atlassian plugin** — connected to Resonate Jira and Confluence
  ```
  /plugin install atlassian@claude-plugins-official
  ```
- **Slack plugin** — connected to Resonate Slack workspace
- **AWS CCAPI MCP server** — configured with valid AWS credentials (for infra context)
- **GitHub CLI** — `gh auth login` completed (for repo and PR investigation)
- Write access to the target Jira project (permission to create sub-tasks)

## Usage

```
/sprint-taskgen DE Sprint 42
```

### Expected Output

```
Found 6 stories in "DE Sprint 42". Processing...

--- CDP-12345: Ingest vendor X data into Snowflake ---
Created 8 sub-tasks:
  CDP-12350  planning: Evaluate vendor X data format and define target schema
  CDP-12351  coding: Build S3 ingestion pipeline for vendor X raw files
  CDP-12352  coding: Implement Spark transformation to normalize vendor data
  ...

--- CDP-12346: Fix pipeline timeout on daily aggregation ---
Created 5 sub-tasks:
  ...

--- CDP-12347: Update Grafana dashboards ---
Skipped — already has 4 sub-tasks

| Story | Sub-tasks Created | Skipped? |
|-------|-------------------|----------|
| CDP-12345 — Ingest vendor X | 8 | No |
| CDP-12346 — Fix pipeline timeout | 5 | No |
| CDP-12347 — Update dashboards | 0 | Yes |

Total: 13 sub-tasks created across 3 stories.
```

## Milestone Prefixes

| Prefix | Purpose |
|---|---|
| `planning:` | Research, spikes, architecture, schema design |
| `coding:` | Implementation — ETL, SQL, Spark, pipelines, lambdas |
| `testing:` | Unit tests, integration tests, data validation |
| `review:` | Code review, PR review |
| `release:` | Deployment, CI/CD, infra, migrations |
| `validation:` | Prod verification, monitoring, data quality |
| `documentation:` | Runbooks, Confluence, READMEs |

## Configuration

| Constant | Value | Description |
|---|---|---|
| Jira Cloud ID | `cb98e3ba-b082-4b0e-a241-0c4ccd00dce8` | Resonate Jira instance |
| Sub-task Type | `Sub-task` | Jira issue type for created tasks |
| Max Tasks | 10 | Maximum sub-tasks per story |

## Troubleshooting

| Problem | Solution |
|---|---|
| "Sprint not found" | Check the exact sprint name on your Jira board — names are case-sensitive |
| "No stories returned" | Verify stories are assigned to the sprint and have type `Story` |
| "Permission denied" | You need write access to the project to create sub-tasks |
| Sub-task type not found | Your project may use a different name — check project issue types |

## Changelog

- **1.0.0** — Initial release with milestone-prefixed task generation
