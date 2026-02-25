# TikTok Business MCP

Query TikTok Business API for custom audience data. Access tokens are passed per-request (not via env vars) — retrieve them from the RTP database.

## Setup

See [audience-delivery-mcp](https://github.com/resonate/audience-delivery-mcp) for full setup instructions.

### Claude Desktop Config

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "tiktok_mcp": {
      "command": "<REPO_PATH>/audience-delivery-mcp/.venv/bin/python",
      "args": ["<REPO_PATH>/audience-delivery-mcp/tiktok_mcp.py"]
    }
  }
}
```

No environment variables needed — access tokens and advertiser IDs are passed as parameters to each tool call.

## Tools

| Tool | Description |
|------|-------------|
| `get_custom_audiences` | List custom audiences for an advertiser |
| `get_audience_details` | Get details for specific audiences (1-100 IDs) |
| `get_shared_audiences` | List audiences shared with an advertiser |

## Requirements

- TikTok access token and advertiser ID (retrieve from RTP database using `rtp_mcp`)
