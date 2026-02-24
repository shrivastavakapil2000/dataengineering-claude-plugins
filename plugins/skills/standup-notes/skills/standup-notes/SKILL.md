---
name: standup-notes
description: Generate daily standup notes for Activation and Append squads
allowed-tools: mcp__plugin_atlassian_atlassian__searchJiraIssuesUsingJql, mcp__plugin_atlassian_atlassian__getJiraIssue, mcp__plugin_atlassian_atlassian__searchConfluenceUsingCql, mcp__plugin_atlassian_atlassian__search, mcp__plugin_atlassian_atlassian__lookupJiraAccountId, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__searchConfluenceUsingCql, mcp__claude_ai_Atlassian__search, mcp__claude_ai_Atlassian__lookupJiraAccountId, mcp__claude_ai_Slack__slack_search_public_and_private, mcp__claude_ai_Slack__slack_search_channels, mcp__claude_ai_Slack__slack_read_thread, mcp__claude_ai_Slack__slack_read_channel, mcp__claude_ai_Slack__slack_search_users, mcp__pagerduty__list_incidents, mcp__pagerduty__get_incident, mcp__pagerduty__list_log_entries, mcp__pagerduty__get_user_data, mcp__pagerduty__list_users, mcp__pagerduty__list_oncalls, Bash, Read, Write
user-invocable: true
argument-hint: [activation|append|both|<engineer name>] (default: both)
---

# Daily Standup Notes Generator

Generate daily standup notes for the Activation and Append squads by gathering yesterday's activity from GitHub, Slack, Jira, Confluence, and PagerDuty, then updating the appropriate Confluence standup page.

## Constants

- **Jira Cloud ID**: `cb98e3ba-b082-4b0e-a241-0c4ccd00dce8`
- **Activation Parent Page ID**: `5989793812`
- **Append Parent Folder ID**: `5472681995` (this is a folder, not a page — use CQL search to find sprint child pages)
- **Confluence Space Key**: `PROD`

## Squad Configuration

### Activation Squad

Engineers (use @mention format in Confluence):
| Name | Jira Display Name | Slack Search Name | GitHub Username |
|---|---|---|---|
| Mike Brant | Mike Brant | Mike Brant | — |
| Nathan Conroy | Nathan Conroy | Nathan Conroy | — |

Page structure: **Parent page with child pages per sprint**. Each sprint is a child page titled like `Sprint NNN Activation Daily Scrum Notes`. Daily entries are tables within the sprint page, in reverse chronological order (newest at top, below the template section).

### Append Squad

Engineers (use @mention format in Confluence):
| Name | Jira Display Name | Slack Search Name | GitHub Username |
|---|---|---|---|
| Jonathan Hudson | Jonathan Hudson | Jonathan Hudson | — |
| Sayali Patwardhan | Sayali Patwardhan | Sayali Patwardhan | — |
| Joe Xu | Joe Xu | Joe Xu | — |

Page structure: **Parent folder with child pages per sprint**. Each sprint is a child page titled like `Sprint NNN Append Daily Scrum Note`. Daily entries are tables within the sprint page, in reverse chronological order (newest at top, below the template section). Because the parent is a Confluence **folder** (not a page), use CQL search to find sprint pages rather than `getConfluencePageDescendants`.

## Input

The user provides an optional argument: `activation`, `append`, `both`, or an **engineer's name** (default: `both`).

If no argument is provided, generate notes for both squads.

### Single-Engineer Mode

If the user provides an engineer's name (e.g., `/standup-notes Jonathan Hudson`):
1. Look up which squad(s) the engineer belongs to from the Squad Configuration tables above
2. Gather activity for **only that engineer** (Steps 2a–2f)
3. Generate and post notes for that engineer in their squad's standup page
4. If the engineer has stories/tickets that span across squads (e.g., an Append engineer working on an Activation ticket), include those cross-squad items in the engineer's update on their home squad page
5. Only update the squad page(s) where the engineer is listed — do not touch other squad pages

## Workflow

### Step 0 — Pre-flight Connectivity Check

Before doing anything else, verify connectivity to ALL required services. Run these checks in parallel:

1. **Confluence**: Call `searchConfluenceUsingCql` with `title ~ "PTO" AND space = "PROD"` to verify Confluence connectivity (needed for PTO checks). If this fails, report the error and STOP.
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

For each issue found, call `getJiraIssue` with `expand=changelog` and `fields=["summary", "status", "description", "comment", "worklog", "attachment"]` to get full details. Note:
- Issue key and **actual ticket title** (use verbatim — do not paraphrase or shorten)
- Current status
- What changed (status transition, comment, etc.)
- **Time logged** — if a worklog entry exists for yesterday, include hours in the bullet (e.g., "(2h)")
- **Attachments/comments** — if the engineer added comments or attachments, note what they contain

**Jira Activity Interpretation Rules:**
- A ticket being "updated" does NOT mean active work — it could be a field change, sprint board move, or automation
- Only count a ticket as real work if the **status changed** (e.g., To Do → In Progress, In Progress → Done)
- Tickets still in **To Do** or **Ready for Next** status with no status transition should NOT appear in "Yesterday" — move them to "Open Standup Questions" instead (e.g., "CDP-XXXXX — updated but no progress, is this blocked?")
- Tickets that moved to **Done/Released** are strong signals of completed work
- When in doubt, do NOT overstate — it's better to say "No updates found" than to fabricate activity

**Bullet Accuracy Rules:**
- Always use the **actual Jira ticket title** in the bullet — do not paraphrase, summarize, or reword it
- Include **time logged** when worklog data is available (e.g., "Completed CDP-118382 — How to add consumer in Snowflake external sharing (2h)")
- When a Jira ticket has sparse details (no description, no comments), cross-reference Slack messages and Confluence edits to find additional context about what the engineer actually did
- If no additional context is found anywhere, use the ticket title as-is — do not invent details

Condense into max 5 bullet points, 40 words max each.

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

Condense into max 5 bullet points, 40 words max each. Group related items.

#### 2c. Slack Activity

Search for messages from the engineer in relevant channels using `slack_search_public_and_private`:

```
Query: "from:<engineer name>" (search for messages from yesterday)
```

**IMPORTANT: Only report messages sent in public channels, private channels, or group DMs (mpim). NEVER include personal 1-on-1 DMs.** If the search returns 1-on-1 DM conversations, discard them entirely. Use `channel_types: "public_channel,private_channel,mpim"` when available.

Focus on messages in team channels (data-engineering, activation, append-implementation-team, etc.).

If Slack search does not support date filtering or the `from:` prefix, search for the engineer's name and filter results manually by date.

Condense into max 5 bullet points, 40 words max each. Only include substantive work-related messages, not casual chat.

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

Condense PagerDuty activity into max 5 bullet points, 40 words max each. Include:
- Incidents triggered, acknowledged, or resolved
- Services affected
- Actions taken

If an engineer had no PagerDuty activity yesterday, **leave the Pagerduty section blank** — do not write "No PagerDuty activity yesterday". Engineers will fill in their own PagerDuty notes if applicable.

#### 2f. PTO / OOO Check — MANDATORY (run BEFORE composing notes)

**This step is NOT optional.** You MUST complete all PTO/OOO checks before composing any standup notes. Skipping this step leads to incorrect notes (e.g., listing "No updates found" when someone was actually on PTO).

Run ALL of these searches in parallel:

1. **Broad Slack OOO search**: Search `slack_search_public_and_private` with these queries (all filtered to yesterday's date):
   - `OOO on:<yesterday ISO>`
   - `PTO on:<yesterday ISO>`
   - `out of office on:<yesterday ISO>`
   - `vacation on:<yesterday ISO>`
   Then scan results for any mention of the target engineers by name.

2. **Per-engineer Slack status**: For each engineer, also search:
   - `"<engineer name>" OOO`
   - `"<engineer name>" PTO`
   filtered to the last 7 days (people sometimes announce PTO in advance).

3. **Confluence PTO calendar**: Search for PTO/OOO pages:
   - CQL: `title ~ "PTO" AND type = "page" AND space = "PROD"`
   - CQL: `title ~ "PTO" AND type = "page" AND space = "XM1"`
   Check if any results reference the target engineers for yesterday's date.

4. **Cross-reference with previous standup**: If the most recent standup entry for an engineer already shows "PTO" or "OOO", check if they are still out (multi-day PTO is common).

**Rules:**
- If ANY source confirms an engineer was OOO/PTO yesterday, set their Yesterday to just **"OOO"** — do not list any other activity, even if Jira shows ticket updates (those are likely automations)
- If evidence is ambiguous (e.g., someone says "he is out" without specifying PTO), flag it in Open Standup Questions rather than assuming OOO
- Document which engineers were confirmed OOO and the source (e.g., "Sayali — OOO per Saikrish in #append-implementation-team")

### Step 3 — Compose Standup Notes

**GATE CHECK:** Do NOT proceed with this step until Step 2f (PTO/OOO Check) has completed for ALL engineers. If Step 2f was skipped or failed, go back and run it now. Engineers confirmed OOO must have their Yesterday set to "OOO" only.

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
- Maximum 40 words per bullet
- **Focus on actual work done, not Jira metadata.** Describe WHAT the engineer built, fixed, tested, documented, or investigated — not status transitions, timestamps, or who moved the ticket. Bad: "CDP-118382 moved To Do → Done at 11:52 AM". Good: "CDP-118382 — Documented the process for adding a consumer in Snowflake external sharing (2h)".
- **One work item per bullet** — each distinct ticket, PR, or task gets its own bullet. Do not combine separate work items into a single bullet (e.g., "CDP-118382" and "CDP-117816" must be two separate bullets, not one)
- Group only truly related sub-actions into single bullets (e.g., "Opened PR and flagged for review" is one action)
- **Synthesize across sources** — combine Jira title, ticket description, Slack messages, PR titles, and Confluence edits to describe the actual work. A Jira title alone may not tell the full story; Slack messages often have the richest context about what was done.
- Be precise and executive-summary style
- Use action verbs: "Documented...", "Fixed...", "Built...", "Investigated...", "Tested...", "Released..."
- **Link all ticket keys** — every Jira ticket key (e.g., CDP-118382, CON-798) must be a hyperlink: `[CDP-118382](https://resonate-jira.atlassian.net/browse/CDP-118382)`. Never leave a ticket key as plain text.
- If no activity found in any source, write "No updates found in Jira/Slack/GitHub — please update"
- If engineer was OOO, just write "OOO" for Yesterday
- **Pagerduty**: Leave blank if no activity — do not write "No PagerDuty activity"
- **Open Standup Questions**: Use this section for tickets that were updated but show no real progress (e.g., still in To Do), or for backlog items in "Ready for Next" status that need a plan. Do not put these in Yesterday or PostScrum.

Combine the engineer notes into a "Team Notes:" section header followed by all engineers' notes.

### Step 4 — Display Results

Present the generated standup notes to the user for review. Do NOT update Confluence automatically.

For each squad in scope, display the notes in this format:

```
## Standup Notes — <DayOfWeek>, <Mon DD, YYYY>

### Activation Squad

**Mike Brant**
Yesterday:
- <bullet 1>
- <bullet 2>
Today:
Post Scrum:
Pagerduty:
Open Standup Questions:

**Nathan Conroy**
Yesterday:
- <bullet 1>
Today:
Post Scrum:
Pagerduty:
Open Standup Questions:

---

### Append Squad

**Jonathan Hudson**
Yesterday:
- <bullet 1>
Today:
Post Scrum:
Pagerduty:
Open Standup Questions:

**Sayali Patwardhan**
Yesterday:
- <bullet 1>
Today:
Post Scrum:
Pagerduty:
Open Standup Questions:

**Joe Xu**
Yesterday:
- <bullet 1>
Today:
Post Scrum:
Pagerduty:
Open Standup Questions:

---

### Data Sources Used
- Jira: X issues found across Y engineers
- GitHub: X PRs/commits found
- Slack: X relevant messages found
- PagerDuty: X incidents found
- Confluence: X page edits found

### Notes
- Review auto-generated "Yesterday" bullets for accuracy before standup
- Engineers should fill in Today, Post Scrum, and Pagerduty sections themselves
```

## Error Handling

- **Jira search fails**: Report but continue with other data sources. Note which engineers had no Jira data.
- **GitHub search fails**: Report but continue. Note "GitHub data unavailable" in the affected engineer's bullets.
- **Slack search fails**: Report but continue. Note "Slack data unavailable" in the affected engineer's bullets.
- **PagerDuty lookup fails**: Report but continue. Use "PagerDuty data unavailable — please update" for the Pagerduty section.
- **Engineer not found in a system**: Do NOT try workarounds. Report exactly which engineer could not be found in which system, and ask the user to provide the correct identifier (username, email, or ID).
- **Any connector/tool fails**: Do NOT attempt alternative approaches or workarounds. Report the failure clearly and ask the user to fix the connectivity issue.

## Important Rules

1. **Use connectors only** — never try to work around a failed connector (e.g., don't try web scraping if Confluence API fails)
2. **Ask the user** when encountering any ambiguity or missing data — do not guess or assume
3. **Business days only** — skip weekends when calculating "yesterday"
4. **No secrets** — never include credentials, tokens, or sensitive data in standup notes
5. **Display only** — do not write to Confluence; the user will copy/paste or update manually
