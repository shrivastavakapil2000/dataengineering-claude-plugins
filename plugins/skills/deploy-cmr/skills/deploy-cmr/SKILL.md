---
name: deploy-cmr
description: Create a CMR ticket linked to a work item and notify Slack for prod deployment
allowed-tools: mcp__plugin_atlassian_atlassian__getJiraIssue, mcp__plugin_atlassian_atlassian__createJiraIssue, mcp__plugin_atlassian_atlassian__editJiraIssue, mcp__plugin_atlassian_atlassian__addCommentToJiraIssue, mcp__plugin_atlassian_atlassian__getJiraIssueRemoteIssueLinks, mcp__claude_ai_Slack__slack_search_channels, mcp__claude_ai_Slack__slack_send_message, mcp__claude_ai_Slack__slack_send_message_draft, Read, Grep, Glob
user-invocable: true
argument-hint: <TICKET-KEY> (e.g., CDP-118328)
---

# Deploy CMR Skill

Create a Change Management Request (CMR) ticket in Jira following Resonate's CMR template, link it to the source work item, then notify the `data-engineering-only` Slack channel about the prod deployment.

## Constants

- **Jira Cloud ID**: `cb98e3ba-b082-4b0e-a241-0c4ccd00dce8`
- **CMR Project Key**: `CMR`
- **CMR Issue Type**: `Change Request`
- **Issue Link Type**: `Relates` (id `10003`)
- **Slack Channel Name**: `data-engineering-only`

## CMR Template Reference

Resonate's CMR template (https://resonate-jira.atlassian.net/wiki/spaces/EN/pages/4012245264) requires:

- **Summary**: 5-10 words describing the change, ending with `[No-Downtime]` or `[Downtime]`
- **Due Date**: The date the release will occur
- **Description**: Must include Release Manager, affected services/repos, reason, PR links, QA environment, and link to Release Page (if applicable)
- **Linkages**: CMR must be linked to the engineering ticket(s)

## Input

The user provides a single argument: a Jira ticket key (e.g., `CDP-118328`).

If no argument is provided, ask the user for the ticket key. Do not proceed without it.

## Workflow

### Step 1 — Read the source ticket

Fetch the source ticket using `getJiraIssue` with the cloud ID above. Request these fields: `summary`, `description`, `issuetype`, `status`, `assignee`, `issuelinks`, `subtasks`, `fixVersions`, `labels`, `components`.

Extract:
- **Summary**: The ticket's summary field
- **Repositories**: Look for GitHub repository URLs (patterns like `github.com/resonate/<repo-name>`) or repo names mentioned in the description. Also check sub-task descriptions if the main description doesn't contain repos. Collect all unique repo names.
- **Assignee**: Who is assigned to the ticket (this is the Release Manager)
- **PR links**: Look for GitHub PR URLs in the description

If the ticket cannot be found, report the error and stop.

### Step 2 — Create the CMR ticket

Create a new ticket in the CMR project using `createJiraIssue`:

- **projectKey**: `CMR`
- **issueTypeName**: `Change Request`
- **summary**: Follow the Resonate CMR summary format — 5-10 words ending with `[No-Downtime]`. Example: `Deploy <source summary abbreviated> [No-Downtime]`
- **description**: Use this template (in Markdown), following the Resonate CMR template:

```
## Change Request

**Release Manager**: <source ticket assignee, or "Unassigned — please update">
**Due Date**: <today's date in YYYY-MM-DD format>
**Downtime**: No

### Work Item

[<SOURCE_KEY> — <source ticket summary>](https://resonate-jira.atlassian.net/browse/<SOURCE_KEY>)

### Services / Repositories Being Deployed

<bulleted list of repos with GitHub links if found, or "See linked ticket for details" if none extracted>

### Reason for Release

Production deployment for <SOURCE_KEY>. See linked work item for full details.

### QA / Testing

Tested as part of <SOURCE_KEY>. See linked ticket for test details.

### PR Links

<bulleted list of PR URLs if found in the ticket, or "See linked ticket for PR details">

### Release Page

N/A — Simple deployment. See linked work item.
```

- **additional_fields**: Set the due date to today:
```json
{
  "duedate": "<today's date in YYYY-MM-DD format>"
}
```

After creation, note the new CMR ticket key (e.g., `CMR-1305`).

### Step 3 — Link the CMR to the source ticket

Add an issue link between the newly created CMR ticket and the source ticket.

Use `editJiraIssue` on the newly created CMR ticket with:
```json
{
  "issueIdOrKey": "<NEW_CMR_KEY>",
  "fields": {},
  "update": {
    "issuelinks": [
      {
        "add": {
          "type": { "name": "Relates" },
          "outwardIssue": { "key": "<SOURCE_TICKET_KEY>" }
        }
      }
    ]
  }
}
```

If `editJiraIssue` does not support the `update` parameter or the linking fails, fall back to adding a comment on the source ticket:

Use `addCommentToJiraIssue` on `<SOURCE_TICKET_KEY>`:
```
CMR created for prod deployment: [<NEW_CMR_KEY>](https://resonate-jira.atlassian.net/browse/<NEW_CMR_KEY>)
```

And add a comment on the CMR ticket:
```
Linked work item: [<SOURCE_TICKET_KEY>](https://resonate-jira.atlassian.net/browse/<SOURCE_TICKET_KEY>)
```

### Step 4 — Send Slack notification

First, search for the `data-engineering-only` channel using `slack_search_channels` with query `data-engineering-only`. This may be a private channel, so search with `channel_types: "public_channel,private_channel"`.

Then send a message to that channel using `slack_send_message`:

```
<!here> Prod deployment is being done for <SOURCE_TICKET_KEY> — <source ticket summary>

*CMR*: https://resonate-jira.atlassian.net/browse/<NEW_CMR_KEY>
*Work Item*: https://resonate-jira.atlassian.net/browse/<SOURCE_TICKET_KEY>
*Repos*: <comma-separated list of repo names, or "See ticket for details">
```

IMPORTANT: Use `<!here>` (not `@here`) — this is the Slack mrkdwn syntax for @here mentions.

Send the message immediately — no confirmation needed.

### Step 5 — Report results

Summarize what was done:

1. CMR ticket created: link to the CMR
2. Linked to source ticket: confirmed or fell back to comments
3. Slack notification: sent or draft created

## Error Handling

- **Ticket not found**: Report clearly, ask user to verify the ticket key
- **CMR creation fails**: Report the error, do not proceed to Slack notification
- **Slack channel not found**: Try searching with alternative names (`data-engineering`, `dataengineering-only`). If still not found, ask the user for the correct channel name
- **Slack send fails**: Offer to create a draft instead using `slack_send_message_draft`

## Security

- Never include credentials or tokens in any ticket description or Slack message
- Do not modify the source ticket's status or assignee
