---
name: data-engineering-forcing-function
description: Check DE team compliance rules against connected systems and generate an HTML report
allowed-tools: mcp__claude_ai_Slack__slack_search_public_and_private, mcp__claude_ai_Slack__slack_search_channels, mcp__claude_ai_Slack__slack_read_channel, mcp__plugin_atlassian_atlassian__searchJiraIssuesUsingJql, mcp__plugin_atlassian_atlassian__getJiraIssue, Bash, Read, Write, Grep, Glob
user-invocable: true
argument-hint: <TIME_RANGE> (e.g., "this sprint", "last 2 weeks", "last sprint")
---

# Data Engineering Forcing Function

Validate data engineering team compliance rules by querying connected systems (GitHub, Slack, Jira) and produce an HTML report of findings.

## Constants

- **Jira Cloud ID**: `cb98e3ba-b082-4b0e-a241-0c4ccd00dce8`
- **Rules file**: `plugins/skills/data-engineering-forcing-function/rules.yaml` (relative to repo root)
- **Report output**: `rules-report-<YYYY-MM-DD>.html` in the current working directory

## Input

The user provides a time range. Examples:

| User says | Interpretation |
|---|---|
| `this sprint` | Active Jira sprint start date → today |
| `last sprint` | Most recently closed Jira sprint date range |
| `last 2 weeks` | Today minus 14 days → today |
| `last month` | Today minus 30 days → today |
| `2026-02-01..2026-02-26` | Explicit date range |

If no argument is provided, default to **last 2 weeks**.

## Workflow

### Step 0 — Load configuration

Read the `rules.yaml` file from the plugin directory. Extract:

- `team.members` — list of `{ name, github }` objects
- `team.github_org` — the GitHub org to search
- `slack.channel` — the Slack channel name to check
- `rules` — list of enabled rules to check

If `rules.yaml` is not found, report an error and stop.

Skip any rule where `enabled: false`.

### Step 1 — Resolve time range

Convert the user's input into a concrete `START_DATE` and `END_DATE` (both in `YYYY-MM-DD` format).

**For "this sprint":**

Use `searchJiraIssuesUsingJql` with the Jira Cloud ID and JQL:
```
project = CDP AND sprint in openSprints()
```
Request fields: `sprint`. Extract the active sprint's `startDate` and `endDate`. Use those as the date range.

**For "last sprint":**

Use `searchJiraIssuesUsingJql` with JQL:
```
project = CDP AND sprint in closedSprints() ORDER BY updated DESC
```
Request fields: `sprint`. From the results, find the most recently closed sprint and use its `startDate` and `endDate`.

**For relative ranges** (e.g., "last 2 weeks", "last month"):

Compute dates using bash `date` command:
```bash
date -v-14d +%Y-%m-%d   # macOS: 14 days ago
```

**For explicit ranges** (e.g., "2026-02-01..2026-02-26"):

Parse directly.

Store the resolved `START_DATE` and `END_DATE` for all subsequent steps.

### Step 2 — Execute rule: `pr-shared-in-slack`

This is the check for whether PRs were shared in the team Slack channel.

#### 2a. Collect PRs from GitHub

For **each team member** in `team.members`, run:

```bash
gh search prs --author=<GITHUB_USERNAME> --owner=<GITHUB_ORG> --created=<START_DATE>..<END_DATE> --state=merged --json url,title,author,createdAt,repository,state --limit 100
```

Then also search for open PRs that have review activity (reviews in-progress):

```bash
gh search prs --author=<GITHUB_USERNAME> --owner=<GITHUB_ORG> --created=<START_DATE>..<END_DATE> --state=open --reviewed-by=@all --json url,title,author,createdAt,repository,state --limit 100
```

**Important:** Only include PRs that are:
- **Merged**, OR
- **Open with reviews in-progress** (has at least one review or review request)

Exclude draft PRs with no review activity and closed-without-merge PRs.

Combine all results into a single list. Remove duplicates by URL.

Record the total PR count.

If the `gh` command fails (not authenticated, rate limited), report the error and skip this rule — do not fail the entire report.

#### 2b. Search Slack for each PR

For each PR collected in 2a, search Slack for the PR URL in the team channel.

Use `slack_search_public_and_private` with query:
```
<PR_URL>
```

A PR is considered **shared** if:
- The PR URL (e.g., `https://github.com/resonate/repo-name/pull/123`) appears in any search result where the channel matches the configured `slack.channel`

A PR is considered **NOT shared** if:
- No search results are found for the PR URL, OR
- Results exist but none are in the configured Slack channel

**Optimization:** If there are more than 20 PRs, first read the Slack channel history using `slack_read_channel` for the configured channel (with a reasonable message limit), extract all GitHub URLs mentioned, and cross-reference against the PR list. Only use individual `slack_search_public_and_private` calls for PRs not found in the initial channel read.

#### 2c. Record results

For each PR, record:
- `url` — the full GitHub PR URL
- `title` — PR title
- `author` — GitHub username
- `author_name` — display name from `team.members`
- `created_at` — when the PR was created
- `repository` — repo name
- `state` — open/merged/closed
- `shared_in_slack` — true/false
- `slack_message_link` — link to the Slack message if found, otherwise null

Separate into two lists: **compliant** (shared) and **violations** (not shared).

### Step 3 — Generate HTML report

Write an HTML file to `rules-report-<TODAY>.html` in the current working directory, where `<TODAY>` is today's date in `YYYY-MM-DD` format.

The HTML must be a **self-contained, styled page** (all CSS inline in a `<style>` block — no external dependencies). Use the following structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>DE Rules Checker — <TODAY></title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; color: #333; padding: 2rem; }
    .container { max-width: 1100px; margin: 0 auto; }
    h1 { font-size: 1.8rem; margin-bottom: 0.25rem; }
    .subtitle { color: #666; margin-bottom: 1.5rem; }
    .summary-cards { display: flex; gap: 1rem; margin-bottom: 2rem; }
    .card { flex: 1; padding: 1.25rem; border-radius: 8px; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    .card h3 { font-size: 0.85rem; text-transform: uppercase; color: #888; margin-bottom: 0.5rem; }
    .card .value { font-size: 2rem; font-weight: 700; }
    .card.pass .value { color: #16a34a; }
    .card.fail .value { color: #dc2626; }
    .card.total .value { color: #2563eb; }
    .card.skipped .value { color: #9ca3af; }
    .rule-section { background: #fff; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 1.5rem; overflow: hidden; }
    .rule-header { padding: 1rem 1.25rem; border-bottom: 1px solid #e5e7eb; display: flex; align-items: center; justify-content: space-between; }
    .rule-header h2 { font-size: 1.1rem; }
    .badge { display: inline-block; padding: 0.2rem 0.6rem; border-radius: 999px; font-size: 0.75rem; font-weight: 600; }
    .badge.pass { background: #dcfce7; color: #16a34a; }
    .badge.fail { background: #fee2e2; color: #dc2626; }
    .badge.warning { background: #fef3c7; color: #d97706; }
    .badge.skipped { background: #f3f4f6; color: #9ca3af; }
    .rule-body { padding: 1.25rem; }
    .rule-desc { color: #666; margin-bottom: 1rem; font-size: 0.9rem; }
    table { width: 100%; border-collapse: collapse; font-size: 0.875rem; }
    th { text-align: left; padding: 0.6rem 0.75rem; background: #f9fafb; border-bottom: 2px solid #e5e7eb; font-weight: 600; color: #555; }
    td { padding: 0.6rem 0.75rem; border-bottom: 1px solid #f0f0f0; }
    tr:hover td { background: #f9fafb; }
    a { color: #2563eb; text-decoration: none; }
    a:hover { text-decoration: underline; }
    .status-pass { color: #16a34a; font-weight: 600; }
    .status-fail { color: #dc2626; font-weight: 600; }
    .footer { margin-top: 2rem; text-align: center; color: #aaa; font-size: 0.8rem; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Data Engineering — Rules Compliance Report</h1>
    <p class="subtitle">Period: <START_DATE> to <END_DATE> | Generated: <TIMESTAMP></p>

    <div class="summary-cards">
      <div class="card total"><h3>Total PRs</h3><div class="value">N</div></div>
      <div class="card pass"><h3>Compliant</h3><div class="value">N</div></div>
      <div class="card fail"><h3>Violations</h3><div class="value">N</div></div>
    </div>

    <!-- One section per rule -->
    <div class="rule-section">
      <div class="rule-header">
        <h2>PR Shared in Slack</h2>
        <span class="badge fail">N violations</span>
        <!-- OR <span class="badge pass">All clear</span> if zero violations -->
      </div>
      <div class="rule-body">
        <p class="rule-desc">Every PR by a Data Engineer must be shared in #data-engineering-only.</p>

        <!-- If there are violations, show a table: -->
        <table>
          <thead>
            <tr><th>PR</th><th>Author</th><th>Repo</th><th>Created</th><th>State</th><th>Shared?</th></tr>
          </thead>
          <tbody>
            <!-- One row per PR (violations first, then compliant).
                 Show ALL PRs so the report is a complete picture. -->
            <tr>
              <td><a href="URL">PR title (truncated to 60 chars)</a></td>
              <td>Author Name</td>
              <td>repo-name</td>
              <td>2026-02-20</td>
              <td>merged</td>
              <td class="status-fail">No</td>
            </tr>
          </tbody>
        </table>

        <!-- If zero violations: -->
        <!-- <p>All <strong>N</strong> PRs were shared in Slack. No violations found.</p> -->
      </div>
    </div>

    <div class="footer">Generated by DE Rules Checker plugin</div>
  </div>
</body>
</html>
```

**Important HTML rules:**
- Show **all PRs** in the table (violations AND compliant), with violations sorted to the top
- Use `class="status-fail"` for violations and `class="status-pass"` for compliant rows
- If a rule has zero violations, show the pass badge and a short "All clear" message instead of a table
- If a rule was skipped (e.g., GitHub auth failure), show a `badge skipped` with the reason
- Escape all HTML special characters in PR titles and author names

### Step 4 — Report to user

After writing the HTML file, tell the user:

1. The file path of the generated report
2. A brief summary: total PRs checked, how many violations, which authors had violations
3. Offer to open the file: `open rules-report-<TODAY>.html`

## Adding New Rules

To add a new rule:

1. Add the rule definition to `rules.yaml` under the `rules:` section
2. Add a new "Step 2" section in this SKILL.md for the rule's check logic
3. The HTML report generator (Step 3) automatically includes all rules

Future rule ideas (not yet implemented):
- `pr-has-reviewer` — PRs must have at least one reviewer assigned
- `ticket-has-story-points` — Jira tickets in a sprint must have story points estimated
- `incident-ack-sla` — PagerDuty incidents must be acknowledged within 15 minutes
- `cmr-for-prod-deploy` — Every prod deployment must have a CMR ticket

## Error Handling

- **rules.yaml not found**: Report error, stop
- **gh CLI not authenticated**: Skip GitHub-dependent rules, mark as "skipped" in report with reason
- **Slack search fails**: Skip Slack-dependent rules, mark as "skipped" in report
- **Jira sprint lookup fails**: Fall back to "last 2 weeks" and warn the user
- **No PRs found**: Still generate the report — show "0 PRs found" with a note
- **Individual Slack search fails**: Mark that specific PR as "unknown" rather than failing the whole rule

## Security

- Never include tokens or credentials in the HTML report
- Do not modify any Slack messages, Jira tickets, or GitHub PRs — this skill is read-only
- The HTML report is written locally only — it is not uploaded anywhere
