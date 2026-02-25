# Services API MCP

Interact with Resonate's internal Services API for audience data, configurations, and delivery resets.

## Setup

See [audience-delivery-mcp](https://github.com/resonate/audience-delivery-mcp) for full setup instructions.

### Claude Desktop Config

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "services_api_mcp": {
      "command": "<REPO_PATH>/audience-delivery-mcp/.venv/bin/python",
      "args": ["<REPO_PATH>/audience-delivery-mcp/services_api_mcp.py"],
      "env": {
        "OAUTH_USERNAME": "<YOUR_RESONATE_EMAIL>",
        "OAUTH_PASSWORD": "<YOUR_RTP_PASSWORD>"
      }
    }
  }
}
```

## Tools

| Tool | Description |
|------|-------------|
| `get_audience_by_id` | Get audience from Services API |
| `get_configuration_by_id` | Get decrypted configuration (requires account_id) |
| `reset_delivery` | Reset a single delivery job (train/model/stitch/deliver) |
| `reset_deliveries_batch` | Reset multiple delivery jobs at once |
| `reset_instructions` | Best practices for handling delivery errors |

## Requirements

- VPN access to Resonate internal network
- Resonate SSO credentials
