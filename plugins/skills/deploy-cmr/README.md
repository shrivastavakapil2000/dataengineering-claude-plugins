# Deploy CMR

> Create a Change Management Request ticket and notify Slack for production deployments

## Overview

Automates the production deployment workflow:

1. Reads a Jira work item to extract summary and repository information
2. Creates a CMR (Change Request) ticket in the CMR project
3. Links the CMR to the source work item
4. Sends a notification to `data-engineering-only` Slack channel with `@here`, the ticket link, and repos being deployed

## Prerequisites

- **Atlassian plugin** (`atlassian@claude-plugins-official`) — connected to Resonate Jira
- **Slack plugin** (`slack@claude-plugins-official`) — connected to Resonate Slack workspace
- Write access to the CMR project in Jira
- Permission to post in `data-engineering-only` Slack channel

## Installation

```bash
# Via plugin manager
/plugin marketplace add shrivastavakapil2000/dataengineering-claude-plugins
/plugin install deploy-cmr@dataengineering-plugins

# Or test locally
claude --plugin-dir ./plugins/skills/deploy-cmr
```

## Usage

```
/deploy-cmr CDP-118328
```

That's it. One input — the Jira ticket key you're deploying.

## What It Does

| Step | Action |
|------|--------|
| 1 | Reads the source ticket (summary, description, repos, assignee) |
| 2 | Creates a CMR ticket: `[Deploy] <source summary>` |
| 3 | Links CMR to source ticket (or adds cross-reference comments as fallback) |
| 4 | Shows you a preview of the Slack message for approval |
| 5 | Sends `@here` notification to `data-engineering-only` with ticket links and repo list |

## Example

```
> /deploy-cmr CDP-118328

Created CMR-1305: [Deploy] Clean Room Native App — Final Pre-Production Audit Fixes
  Linked to: CDP-118328
  Repos: resonate-snowflake-native-apps

Slack message preview:
  @here Prod deployment is being done for CDP-118328 — Clean Room Native App — Final Pre-Production Audit Fixes
  CMR: https://resonate-jira.atlassian.net/browse/CMR-1305
  Work Item: https://resonate-jira.atlassian.net/browse/CDP-118328
  Repos: resonate-snowflake-native-apps

Send to #data-engineering-only? [y/n]
```

## Configuration

No configuration needed. The skill uses:

| Setting | Value |
|---------|-------|
| Jira Cloud ID | `cb98e3ba-b082-4b0e-a241-0c4ccd00dce8` |
| CMR Project | `CMR` |
| Issue Type | `Change Request` |
| Slack Channel | `data-engineering-only` |

## Troubleshooting

### CMR creation fails

Verify you have write access to the CMR project. Check with your Jira admin.

### Slack channel not found

The skill searches for `data-engineering-only` in both public and private channels. If the channel name has changed, provide the correct name when prompted.

### Repos not detected

If the source ticket description doesn't contain GitHub URLs or repo names, the CMR will note "TBD" and the Slack message will say "See ticket for details". You can manually add repos before the Slack message is sent.

## Changelog

### 1.0.0
- Initial release
- CMR creation with auto-linking
- Slack @here notification with repo extraction

## Author

Data Engineering Team — Resonate
