---
name: standup-notes
description: Generate daily standup notes for Activation and DaaS squads
allowed-tools: mcp__plugin_atlassian_atlassian__getConfluencePage, mcp__plugin_atlassian_atlassian__getConfluencePageDescendants, mcp__plugin_atlassian_atlassian__updateConfluencePage, mcp__plugin_atlassian_atlassian__searchJiraIssuesUsingJql, mcp__plugin_atlassian_atlassian__getJiraIssue, mcp__plugin_atlassian_atlassian__searchConfluenceUsingCql, mcp__plugin_atlassian_atlassian__search, mcp__plugin_atlassian_atlassian__lookupJiraAccountId, mcp__claude_ai_Atlassian__getConfluencePage, mcp__claude_ai_Atlassian__getConfluencePageDescendants, mcp__claude_ai_Atlassian__updateConfluencePage, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__searchConfluenceUsingCql, mcp__claude_ai_Atlassian__search, mcp__claude_ai_Atlassian__lookupJiraAccountId, mcp__claude_ai_Slack__slack_search_public_and_private, mcp__claude_ai_Slack__slack_search_channels, mcp__claude_ai_Slack__slack_read_thread, mcp__claude_ai_Slack__slack_read_channel, mcp__claude_ai_Slack__slack_search_users, mcp__pagerduty__list_incidents, mcp__pagerduty__get_incident, mcp__pagerduty__list_log_entries, mcp__pagerduty__get_user_data, mcp__pagerduty__list_users, mcp__pagerduty__list_oncalls, Bash, Read, Write
user-invocable: true
argument-hint: [activation|daas|both] (default: both)
---

# Daily Standup Notes Generator

Generate daily standup notes for the Activation and DaaS squads by gathering yesterday's activity from GitHub, Slack, Jira, Confluence, and PagerDuty, then updating the appropriate Confluence standup page.

## Constants

- **Jira Cloud ID**: `cb98e3ba-b082-4b0e-a241-0c4ccd00dce8`
- **Activation Parent Page ID**: `5989793812`
- **DaaS Page ID**: `6602752005`
- **Confluence Space Key**: `PROD`

## Squad Configuration

### Activation Squad

Engineers (use @mention format in Confluence):
| Name | Jira Display Name | Slack Search Name | GitHub Username |
|---|---|---|---|
| Mike Brant | Mike Brant | Mike Brant | — |
| Nathan Conroy | Nathan Conroy | Nathan Conroy | — |

Page structure: **Parent page with child pages per sprint**. Each sprint is a child page titled like `Sprint NNN Activation Daily Scrum Notes`. Daily entries are tables within the sprint page, in reverse chronological order (newest at top, below the template section).

### DaaS Squad

Engineers (use full names in Confluence, not initials):
| Name | Jira Display Name | Slack Search Name | GitHub Username |
|---|---|---|---|
| Jonathan Hudson | Jonathan Hudson | Jonathan Hudson | — |
| Sayali Patwardhan | Sayali Patwardhan | Sayali Patwardhan | — |
| Joe Xu | Joe Xu | Joe Xu | — |

Page structure: **Single page with sprint sections as H1 headings**. Sprint headers look like `Sprint NNN (M/D/YYYY - M/D/YYYY)`. Daily entries are tables within each sprint section, in reverse chronological order (newest at top, below the template section).

## Input

The user provides an optional argument: `activation`, `daas`, or `both` (default: `both`).

If no argument is provided, generate notes for both squads.

## Workflow

### Step 0 — Pre-flight Connectivity Check

Before doing anything else, verify connectivity to ALL required services. Run these checks in parallel:

1. **Confluence**: Call `getConfluencePage` for the DaaS page (ID `6602752005`). If this fails, report the error and STOP.
2. **Jira**: Call `searchJiraIssuesUsingJql` with a simple query like `project = CDP AND updated >= -1d ORDER BY updated DESC` (limit 1). If this fails, report the error and STOP.
3. **Slack**: Call `slack_search_channels` with query `data-engineering`. If this fails, report the error and STOP.
4. **PagerDuty**: Call `list_users` (limit 1). If this fails, report the error and STOP.
5. **GitHub**: Run `gh auth status` via Bash. If this fails, report the error and STOP.

If ANY check fails:
- Report exactly which service failed and what error was returned
- Do NOT try workarounds or alternative approaches
- Ask the user to fix the connectivity issue and retry
- STOP execution — do not proceed with partial data

If ALL checks pass, report: "All services connected successfully" and proceed.

### Step 1 — Determine Dates

Calculate:
- **Today**: Current date (format for display: "DayOfWeek, Mon DD, YYYY" e.g., "Tuesday, Feb 24, 2026")
- **Yesterday**: The previous business day. If today is Monday, yesterday = Friday. Otherwise, yesterday = today - 1.
- **Yesterday ISO**: YYYY-MM-DD format for API queries

### Step 2 — Gather Activity for Each Engineer

For each engineer in the target squad(s), gather yesterday's activity from all sources. Run data gathering for all engineers in parallel where possible.

#### 2a. Jira Activity

Search for issues the engineer worked on yesterday using `searchJiraIssuesUsingJql`:

```
JQL: (assignee = "<engineer name>" OR reporter = "<engineer name>") AND updated >= "<yesterday ISO>" AND updated < "<today ISO>" ORDER BY updated DESC
```

Also search for issues where the engineer added comments:
```
JQL: issueFunction in commented("by <engineer name> after <yesterday ISO>")
```

If `issueFunction` is not supported, fall back to searching by assignee only.

For each issue found, note:
- Issue key and summary
- Current status
- What changed (status transition, comment, etc.)

**Jira Activity Interpretation Rules:**
- A ticket being "updated" does NOT mean active work — it could be a field change, sprint board move, or automation
- Only count a ticket as real work if the **status changed** (e.g., To Do → In Progress, In Progress → Done)
- Tickets still in **To Do** or **Ready for Next** status with no status transition should NOT appear in "Yesterday" — move them to "Open Standup Questions" instead (e.g., "CDP-XXXXX — updated but no progress, is this blocked?")
- Tickets that moved to **Done/Released** are strong signals of completed work
- When in doubt, do NOT overstate — it's better to say "No updates found" than to fabricate activity

Condense into max 5 bullet points, 12 words max each. Group related items.

#### 2b. GitHub Activity

Use `gh` CLI to find yesterday's activity per engineer:

```bash
# Search for PRs authored or reviewed by the engineer (use their GitHub username if known, otherwise search by name)
gh search prs --author="<github_username>" --updated=">=$YESTERDAY" --org=resonate --limit=10 --json title,url,state,repository 2>/dev/null || true

# Search for commits if username is known
gh search commits --author="<github_username>" --committer-date=">=$YESTERDAY" --org=resonate --limit=10 --json message,repository 2>/dev/null || true
```

If the GitHub username is not known for an engineer, try searching by their full name:
```bash
gh search prs --involves="<full name>" --updated=">=$YESTERDAY" --org=resonate --limit=10 --json title,url,state,repository 2>/dev/null || true
```

If GitHub search returns no results or errors for a specific engineer, note it but continue — do not stop.

Condense into max 5 bullet points, 12 words max each. Group related items.

#### 2c. Slack Activity

Search for messages from the engineer in relevant channels using `slack_search_public_and_private`:

```
Query: "from:<engineer name>" (search for messages from yesterday)
```

Focus on messages in team channels (data-engineering, activation, daas-squad, etc.), not DMs.

If Slack search does not support date filtering or the `from:` prefix, search for the engineer's name and filter results manually by date.

Condense into max 5 bullet points, 12 words max each. Only include substantive work-related messages, not casual chat.

#### 2d. Confluence Activity

Search for pages the engineer edited yesterday using `searchConfluenceUsingCql` or `search`:

```
CQL: contributor = "<engineer name>" AND lastModified >= "<yesterday ISO>"
```

If CQL contributor search is not supported, search by:
```
CQL: space = "PROD" AND lastModified >= "<yesterday ISO>"
```
Then filter by author/contributor in the results.

Note any pages edited — these may indicate documentation work, design docs, or meeting notes.

#### 2e. PagerDuty Activity

Search for PagerDuty incidents involving the engineer yesterday:

1. First, look up the engineer's PagerDuty user using `list_users` or `get_user_data` (search by name or email pattern `<first>.<last>@resonate.com`)
2. Then call `list_incidents` filtered to yesterday's date range and the user's PagerDuty ID:
   - `since`: yesterday start of day (ISO format)
   - `until`: today start of day (ISO format)
3. Also check `list_log_entries` for the user's activity (acknowledged, resolved, escalated, etc.)

Condense PagerDuty activity into max 5 bullet points, 12 words max each. Include:
- Incidents triggered, acknowledged, or resolved
- Services affected
- Actions taken

If an engineer had no PagerDuty activity yesterday, **leave the Pagerduty section blank** — do not write "No PagerDuty activity yesterday". Engineers will fill in their own PagerDuty notes if applicable.

#### 2f. PTO / OOO Check

Before composing notes, check if any engineer was OOO yesterday:

1. Search Slack for OOO messages: `"<engineer name>" OOO on:<yesterday ISO>`
2. Search for the "Engineering & Product PTO" calendar in Confluence or Google Calendar
3. If an engineer was OOO, set their Yesterday to just "OOO" — do not list any other activity

### Step 3 — Compose Standup Notes

For each engineer, compose notes using this exact template (use **full names**, not initials):

```
<Full Name of Engineer>
Yesterday:
- <bullet 1>
- <bullet 2>
...
Today:
PostScrum:
Pagerduty:
- <bullet 1 — only if there was PagerDuty activity, otherwise leave blank>
...
Open Standup Questions:
- <question about ticket status, blockers, etc. — only if applicable>
```

Rules for bullet points:
- Maximum 5 bullets per section (Yesterday, Pagerduty)
- Maximum 12 words per bullet
- Group related items into single bullets
- Be precise and executive-summary style
- Use action verbs: "Completed CDP-XXXXX...", "Released CDP-XXXXX...", "Resolved incident on..."
- If no activity found in any source, write "No updates found in Jira/Slack/GitHub — please update"
- If engineer was OOO, just write "OOO" for Yesterday
- **Pagerduty**: Leave blank if no activity — do not write "No PagerDuty activity"
- **Open Standup Questions**: Use this section for tickets that were updated but show no real progress (e.g., still in To Do), or for backlog items in "Ready for Next" status that need a plan. Do not put these in Yesterday or PostScrum.

Combine the engineer notes into a "Team Notes:" section header followed by all engineers' notes.

### Step 4 — Update Confluence (Activation Squad)

Skip this step if the user specified `daas` only.

#### 4a. Find the current sprint page

Call `getConfluencePageDescendants` on the Activation parent page (ID `5989793812`) to list all child pages.

Identify the **most recent sprint page** — this is the child page with the highest sprint number. The title follows the pattern `Sprint NNN Activation Daily Scrum Notes` or `Sprint NNN - Activation Daily Scrum Notes`.

#### 4b. Read the current sprint page

Call `getConfluencePage` with the sprint page ID. Read the full body content.

#### 4c. Check if today's date already exists

Search the page content for today's date string (e.g., "Tuesday, Feb 24, 2026" or "Feb 24, 2026" or "2/24/2026"). Check multiple date formats.

If today's date section already exists:
- Report to the user: "Today's section already exists on the Activation standup page. Skipping to avoid duplicates."
- Do NOT overwrite or modify existing content
- STOP processing this squad (continue with DaaS if applicable)

#### 4d. Insert today's section

Read the existing page content carefully to understand the exact HTML/ADF structure being used. The new daily entry MUST match the existing format exactly.

The daily entry should be inserted **after the template section** and **before any previous daily entries** (reverse chronological order — newest at top).

The table structure for Activation follows this pattern (adapt to match the exact format observed in the page):

```
| Tuesday, Feb 24, 2026 |
|---|
| **Team Notes:** |
| @Mike Brant |
| Yesterday: |
| - bullet 1 |
| - bullet 2 |
| Today: |
| Post Scrum: |
| Open Standup Questions: |
| |
| @Nathan Conroy |
| Yesterday: |
| - bullet 1 |
| Today: |
| Post Scrum: |
| Open Standup Questions: |
|---|
| Impediments: None |
```

CRITICAL: Read the existing page content first and replicate the exact same table/HTML/ADF structure. Do not guess the format. Match indentation, tags, and spacing exactly.

Call `updateConfluencePage` with the modified content. Preserve the page title and all existing content.

### Step 5 — Update Confluence (DaaS Squad)

Skip this step if the user specified `activation` only.

#### 5a. Read the DaaS page

Call `getConfluencePage` with page ID `6602752005`. Read the full body content.

#### 5b. Check if today's date already exists

Search the page content for today's date string (e.g., "Tuesday, Feb 24, 2026" or "Feb 24, 2026" or "2/24/2026"). Check multiple date formats.

If today's date section already exists:
- Report to the user: "Today's section already exists on the DaaS standup page. Skipping to avoid duplicates."
- Do NOT overwrite or modify existing content
- STOP processing this squad

#### 5c. Find the current sprint section

Locate the **first H1 heading** in the page body — this should be the current/most recent sprint header (since sprints are in reverse chronological order). The header looks like: `Sprint NNN (M/D/YYYY - M/D/YYYY)`.

#### 5d. Insert today's section

Insert the new daily entry **below the current sprint header** (and below the template if one exists) and **above any previous daily entries** in that sprint section.

The table structure for DaaS follows this pattern (adapt to match the exact format observed):

```
| **Team Notes:** Tuesday, Feb 24, 2026 |
|---|
| Jonathan Hudson |
| Yesterday: |
| - bullet 1 |
| - bullet 2 |
| Today: |
| PostScrum: |
| Pagerduty: |
| Open Standup Questions: |
| |
| Sayali Patwardhan |
| Yesterday: |
| - bullet 1 |
| Today: |
| PostScrum: |
| Pagerduty: |
| Open Standup Questions: |
| |
| Joe Xu |
| Yesterday: |
| - bullet 1 |
| Today: |
| PostScrum: |
| Pagerduty: |
| Open Standup Questions: |
|---|
| Impediments: None |
|---|
| |
```

CRITICAL: Read the existing page content first and replicate the exact same table/HTML/ADF structure. Do not guess the format. Match the structure of the most recent existing daily entry exactly.

Call `updateConfluencePage` with the modified content. Preserve the page title and all existing content.

### Step 6 — Report Results

Present a summary to the user:

```
## Standup Notes Generated

### Activation Squad
- Page: [Sprint NNN Activation Daily Scrum Notes](link)
- Date section added: Tuesday, Feb 24, 2026
- Engineers: Mike Brant, Nathan Conroy
- Status: Updated successfully / Skipped (already exists) / Error

### DaaS Squad
- Page: [DaaS Squad - Daily Scrum Notes 2026 Q1 Q2](link)
- Date section added: Tuesday, Feb 24, 2026
- Engineers: Jonathan Hudson, Sayali Patwardhan, Joe Xu
- Status: Updated successfully / Skipped (already exists) / Error

### Data Sources Used
- Jira: X issues found across Y engineers
- GitHub: X PRs/commits found
- Slack: X relevant messages found
- PagerDuty: X incidents found
- Confluence: X page edits found

### Notes
- Items marked "To be filled by engineer" need manual updates
- Review auto-generated "Yesterday" bullets for accuracy before standup
```

## Error Handling

- **Confluence page not found**: Report the error. The sprint page may have changed — ask the user for the correct page URL.
- **Confluence update fails**: Report the error with details. Common causes: page was edited by someone else (version conflict), permission denied, or page is locked.
- **Jira search fails**: Report but continue with other data sources. Note which engineers had no Jira data.
- **GitHub search fails**: Report but continue. Note "GitHub data unavailable" in the affected engineer's bullets.
- **Slack search fails**: Report but continue. Note "Slack data unavailable" in the affected engineer's bullets.
- **PagerDuty lookup fails**: Report but continue. Use "PagerDuty data unavailable — please update" for the Pagerduty section.
- **Engineer not found in a system**: Do NOT try workarounds. Report exactly which engineer could not be found in which system, and ask the user to provide the correct identifier (username, email, or ID).
- **Any connector/tool fails**: Do NOT attempt alternative approaches or workarounds. Report the failure clearly and ask the user to fix the connectivity issue.

## Important Rules

1. **Use connectors only** — never try to work around a failed connector (e.g., don't try web scraping if Confluence API fails)
2. **Ask the user** when encountering any ambiguity or missing data — do not guess or assume
3. **Preserve existing content** — never delete or modify existing standup entries
4. **Match existing format** — always read the page first and match the exact format used
5. **Business days only** — skip weekends when calculating "yesterday"
6. **No secrets** — never include credentials, tokens, or sensitive data in standup notes
7. **Idempotent** — if today's section already exists, do not create a duplicate
