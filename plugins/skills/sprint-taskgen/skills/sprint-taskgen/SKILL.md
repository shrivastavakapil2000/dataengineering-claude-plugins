---
name: sprint-taskgen
description: Generate milestone-prefixed sub-tasks for every story in a Jira sprint
allowed-tools: mcp__plugin_atlassian_atlassian__searchJiraIssuesUsingJql, mcp__plugin_atlassian_atlassian__getJiraIssue, mcp__plugin_atlassian_atlassian__createJiraIssue, mcp__plugin_atlassian_atlassian__getJiraProjectIssueTypesMetadata, mcp__plugin_atlassian_atlassian__getJiraIssueRemoteIssueLinks, mcp__plugin_atlassian_atlassian__searchConfluenceUsingCql, mcp__plugin_atlassian_atlassian__getConfluencePage, mcp__plugin_atlassian_atlassian__search, mcp__claude_ai_Slack__slack_search_public_and_private, mcp__claude_ai_Slack__slack_read_thread, mcp__aws-ccapi__check_environment_variables, mcp__aws-ccapi__get_aws_session_info, mcp__aws-ccapi__list_resources, mcp__aws-ccapi__get_resource, Bash, Read, Grep, Glob
user-invocable: true
argument-hint: <SPRINT-NAME> (e.g., DE Sprint 42)
---

# Sprint Task Generator

Analyze every Story in a Jira sprint and create up to 10 milestone-prefixed sub-tasks per story. Tasks are written as executive summaries from a Data Engineering perspective.

## Constants

- **Jira Cloud ID**: `cb98e3ba-b082-4b0e-a241-0c4ccd00dce8`
- **Sub-Task Issue Type**: `Sub-task`
- **Max Tasks Per Story**: `10`

## Milestone Prefixes

Every sub-task summary MUST start with one of these prefixes. Choose the most appropriate prefix based on the nature of the work:

| Prefix | When to use |
|---|---|
| `planning:` | Research, spike, architecture review, design doc, schema design |
| `coding:` | Implementation — ETL code, SQL, Spark jobs, pipeline config, DAGs, lambdas, data models |
| `testing:` | Unit tests, integration tests, data validation tests, test fixtures, mocking |
| `review:` | Code review, PR review, architecture review with team |
| `release:` | Deployment, CI/CD config, environment setup, infra provisioning, migration scripts |
| `validation:` | Production data validation, monitoring setup, alerting, data quality checks, smoke tests |
| `documentation:` | Runbook, Confluence page, README, inline docs, decision records |

## Input

The user provides a single argument: the **sprint name** (e.g., `DE Sprint 42`, `CDP Sprint 2026-03`).

If no argument is provided, ask the user for the sprint name. Do not proceed without it.

## Workflow

### Step 1 — Find all Stories in the sprint

Search for stories using `searchJiraIssuesUsingJql`:

```
JQL: sprint = "<SPRINT_NAME>" AND issuetype = Story ORDER BY rank ASC
```

Use the Jira Cloud ID above. Request fields: `summary`, `description`, `story_points`, `assignee`, `status`, `subtasks`, `labels`, `components`, `acceptance_criteria`.

If zero stories are returned:
- Try with quotes around the sprint name: `sprint = "<SPRINT_NAME>"`
- If still zero, report to the user and stop

Collect the list of story keys and their summaries. Report to the user how many stories were found before proceeding.

### Step 2 — Process each Story

For each story, perform Steps 3-4. Process stories sequentially (one at a time) so the user can see progress.

### Step 3 — Deep-analyze the story across all systems

For each story, perform a multi-source investigation to understand the full scope of work. Do NOT generate tasks from the Jira summary alone — gather real context first.

#### 3a. Jira — Story context and linked issues

- Read the story's summary, description, acceptance criteria, labels, and components
- Fetch **issue links** using `getJiraIssueRemoteIssueLinks` — check for linked design tickets, bugs, dependencies, or prior work
- Check **comments** on the story for discussion, decisions, or technical notes from the team
- Note the **assignee** — this helps tailor tasks to the person's typical work (pipeline dev, SQL dev, infra, etc.)

#### 3b. Confluence — Design docs and architecture

Search Confluence for related documentation using `searchConfluenceUsingCql` or `search`:

- Search for the story key (e.g., `text ~ "CDP-12345"`)
- Search for key terms from the story summary (e.g., `text ~ "vendor ingestion"`)
- If results are found, read the top 1-2 pages using `getConfluencePage` to extract:
  - Architecture decisions or diagrams
  - Schema definitions or data models
  - Deployment instructions or environment requirements
  - Dependencies on other systems or teams

This tells you if there's a design spec, runbook, or architecture doc that defines the real scope.

#### 3c. GitHub — Repos, PRs, and code context

Extract repository names from the story description (look for `github.com/resonate/<repo>` patterns or repo names in text).

If repos are identified, use `Bash` with `gh` CLI to investigate:

```bash
# Check recent PRs related to the story
gh pr list --repo resonate/<repo> --search "<STORY_KEY>" --state all --limit 5

# Check if there are open PRs already in progress
gh pr list --repo resonate/<repo> --state open --limit 10

# Look at repo structure for relevant files (if repo is cloned locally)
ls ~/workspaces/<repo>/
```

This reveals:
- Whether code work has already started (open PRs)
- What repos are involved and their structure
- Prior related PRs that inform what needs to change

If no repos are explicitly mentioned, infer from labels/components (e.g., `batch-pipeline` label → `batch-expression-modeling` repo, `snowflake` component → `core-data-pipeline` repo).

#### 3d. Slack — Team discussions and decisions

Search Slack for recent conversations about the story using `slack_search_public_and_private`:

- Search for the story key: `"CDP-12345"`
- Search for key terms from the summary if the key yields no results

If threads are found, read the top 1-2 threads using `slack_read_thread` to extract:
- Technical decisions or blockers discussed by the team
- Dependencies on other teams or external vendors
- Timeline constraints or urgency signals
- Deployment coordination needs

#### 3e. AWS — Infrastructure context (when applicable)

Only investigate AWS if the story mentions AWS services (S3, Lambda, EMR, Snowflake external stages, Glue, etc.):

- First call `check_environment_variables`, then `get_aws_session_info`
- Use `list_resources` or `get_resource` to check the current state of mentioned resources
- This helps determine if infra tasks are needed (new resources, config changes, IAM updates)

Skip this step if the story has no AWS footprint.

#### 3f. Synthesize findings and generate tasks

Combine all gathered context to think as a **Data Engineer** about what work is truly needed. Consider:

- **Data pipeline work**: ETL jobs, Spark transformations, Airflow DAGs, Lambda functions
- **SQL / data model changes**: Schema migrations, new tables, column additions, stored procedures
- **Data ingestion**: New data sources, API integrations, file processing, S3 ingestion
- **Data quality**: Validation rules, anomaly detection, data profiling, reconciliation
- **Infrastructure**: Snowflake config, AWS resources, Terraform/CloudFormation, EMR clusters
- **Configuration**: Feature flags, environment variables, pipeline parameters, scheduling
- **Monitoring**: Grafana dashboards, CloudWatch alarms, PagerDuty rules, log queries
- **Compliance / security**: PII handling, encryption, access controls, audit logging

Generate tasks that reflect the ACTUAL work discovered — not generic boilerplate. If Confluence has a design doc, reference it. If GitHub shows code already started, adjust tasks accordingly. If Slack reveals blockers, include a planning task for that.

Generate up to 10 sub-tasks. Not every story needs all 10 — use only as many as the work requires.

**Task generation rules:**

1. Every task summary MUST begin with a milestone prefix (see table above)
2. Keep summaries as **executive summaries** — one sentence, 10-20 words, no implementation details
3. A typical story should include tasks across multiple milestones (not all `coding:`)
4. Always include at minimum: one `coding:` task, one `testing:` task, and one `validation:` task
5. Include `release:` only if the story involves deployment or infra changes
6. Include `documentation:` only if the story introduces new systems, APIs, or complex logic
7. Include `planning:` only if the story requires research, design decisions, or architecture review
8. Include `review:` for stories with significant code changes
9. Order tasks in logical execution sequence (planning first, validation last)
10. If the story already has existing sub-tasks, SKIP it — report that it already has tasks and move on

**Example tasks for a story "Ingest vendor X data into Snowflake":**

- `planning: Evaluate vendor X data format and define target schema`
- `coding: Build S3 ingestion pipeline for vendor X raw files`
- `coding: Implement Spark transformation to normalize vendor data`
- `coding: Create Snowflake staging and target tables with proper DDL`
- `testing: Write unit tests for transformation logic and edge cases`
- `testing: Run integration test with sample vendor data end-to-end`
- `review: Submit PR and complete code review with team`
- `release: Deploy pipeline to staging and configure scheduling`
- `validation: Verify production data counts and quality post-deployment`
- `documentation: Update data catalog and add runbook for new pipeline`

### Step 4 — Create sub-tasks in Jira

For each generated task, create a sub-task using `createJiraIssue`:

- **cloudId**: Use the Jira Cloud ID constant
- **projectKey**: Extract from the parent story key (e.g., `CDP` from `CDP-12345`)
- **issueTypeName**: `Sub-task`
- **summary**: The milestone-prefixed task summary
- **description**: Leave empty or use a single-sentence expansion only if needed for clarity
- **parentKey**: The parent story key

Do NOT set estimates on sub-tasks — the story already carries the estimate.

After creating all sub-tasks for a story, report:
- Story key and summary
- Number of sub-tasks created
- List of sub-task keys with their summaries

### Step 5 — Final summary

After processing all stories, present a summary table:

```
| Story | Sub-tasks Created | Skipped? |
|-------|-------------------|----------|
| CDP-123 — Ingest vendor X data | 8 | No |
| CDP-124 — Fix pipeline timeout | 5 | No |
| CDP-125 — Update dashboards | 0 | Yes (already has tasks) |
```

Total: X sub-tasks created across Y stories.

## Error Handling

- **Sprint not found**: Ask the user to verify the sprint name. Suggest checking the Jira board for the exact sprint name.
- **Story fetch fails**: Log the error, skip the story, continue with the next one
- **Sub-task creation fails**: Report which task failed, continue creating remaining tasks for the story
- **Permission denied**: Report clearly — user may not have write access to the project
- **Rate limiting**: If Jira returns 429, wait briefly and retry once. If still failing, report and stop.

## Security

- Never include credentials or tokens in any task description
- Do not modify existing story fields (summary, description, status, assignee, estimates)
- Only create new sub-tasks — never delete or modify existing sub-tasks
