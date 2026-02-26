# Data Engineering Forcing Function

Check data engineering team compliance rules against connected systems (GitHub, Slack, Jira) and generate a self-contained HTML report.

## What It Does

| Step | Action |
|------|--------|
| 1 | Reads rules from `rules.yaml` |
| 2 | Resolves the time range (sprint dates, relative, or explicit) |
| 3 | For each enabled rule, queries source systems to check compliance |
| 4 | Generates `rules-report-YYYY-MM-DD.html` with pass/fail results |

### Current Rules

| Rule | Checks                                                                                                                                                                                                                                                                                                              |
|------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **PR Shared in Slack** | Every PR that was created by a DE team member in the `resonate` GitHub org, which was merged or reviewes are in-progress, needs to be posted in `#data-engineering-only`. You should check threads in slack also, sometimes the CR or PR or change request or pull request words are used and there are links to it |

## Installation

**Option A** — Install from the DE plugins marketplace:
```
/plugin install data-engineering-forcing-function from dataengineering-plugins
```

**Option B** — Add directly from the repo:
```
/plugin install ./plugins/skills/data-engineering-forcing-function
```

## Prerequisites

- **GitHub CLI** (`gh`) authenticated to the `resonate` org
- **Slack plugin** connected to Resonate Slack workspace
- **Atlassian plugin** connected to Resonate Jira (for sprint date lookups)

Check prerequisites:
```
./scripts/de-plugins check data-engineering-forcing-function
```

## Usage

```
/data-engineering-forcing-function this sprint
/data-engineering-forcing-function last sprint
/data-engineering-forcing-function last 2 weeks
/data-engineering-forcing-function last month
/data-engineering-forcing-function 2026-02-01..2026-02-26
```

If no time range is given, defaults to **last 2 weeks**.

## Configuration

Edit `rules.yaml` to:

- **Add/remove team members** — update the `team.members` list with GitHub usernames
- **Enable/disable rules** — set `enabled: true/false` on any rule
- **Add new rules** — append to the `rules:` list (matching check logic must exist in SKILL.md)

## Output

The report is written to `rules-report-YYYY-MM-DD.html` in the current working directory. It is a self-contained HTML file (no external dependencies) that you can open in any browser.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `gh: command not found` | Install GitHub CLI: `brew install gh` then `gh auth login` |
| No PRs found | Verify GitHub usernames in `rules.yaml` match actual GitHub accounts |
| Slack search returns nothing | Ensure the Slack plugin has access to `#data-engineering-only` |
| Sprint lookup fails | Check Jira Cloud ID in `rules.yaml` and that the CDP board has active sprints |
