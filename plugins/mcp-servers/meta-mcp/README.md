# Meta/Facebook MCP

Query the Meta/Facebook Graph API for audience metadata, campaigns, ads, and performance insights.

## Setup

See [audience-delivery-mcp](https://github.com/resonate/audience-delivery-mcp) for full setup instructions.

### Claude Desktop Config

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "meta_mcp": {
      "command": "<REPO_PATH>/audience-delivery-mcp/.venv/bin/python",
      "args": ["<REPO_PATH>/audience-delivery-mcp/meta_mcp.py"],
      "env": {
        "FB_ACCESS_TOKEN": "<YOUR_FB_ACCESS_TOKEN>"
      }
    }
  }
}
```

## Tools

| Tool | Description |
|------|-------------|
| `get_audience_metadata` | Get metadata for a single audience |
| `get_audiences_metadata` | Get metadata for multiple audiences |
| `get_audience_available_fields` | Get available fields for an audience object |
| `get_ads_by_audience` | Get all ads using a specific audience |
| `get_ad_details` | Get details about an ad |
| `get_adset_details` | Get details about an ad set |
| `get_campaign_details` | Get details about a campaign |
| `get_adaccount_campaigns` | Get all campaigns for an ad account |
| `get_adaccount_audiences` | Get all custom audiences for an ad account |
| `get_campaign_adsets` | Get all ad sets for a campaign |
| `get_adset_ads` | Get all ads for an ad set |
| `get_insights` | Get performance/insights data for any ad object |

## Requirements

- Facebook access token from Meta Business Manager
