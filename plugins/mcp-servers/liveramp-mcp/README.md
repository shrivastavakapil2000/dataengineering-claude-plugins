# LiveRamp Activation MCP

Query LiveRamp for segment data and activation status.

## Setup

See [audience-delivery-mcp](https://github.com/resonate/audience-delivery-mcp) for full setup instructions.

### Claude Desktop Config

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "liveramp_mcp": {
      "command": "<REPO_PATH>/audience-delivery-mcp/.venv/bin/python",
      "args": ["<REPO_PATH>/audience-delivery-mcp/liveramp_mcp.py"],
      "env": {
        "LIVERAMP_ACCOUNT_ID": "<YOUR_LIVERAMP_ACCOUNT_ID>",
        "LIVERAMP_SECRET_KEY": "<YOUR_LIVERAMP_SECRET_KEY>"
      }
    }
  }
}
```

## Tools

| Tool | Description |
|------|-------------|
| `list_segments` | List all segments in your account |
| `get_segment` | Get details for a specific segment |
| `get_segment_statuses` | Get status for one or more segments |
| `get_segment_metadata` | Combined segment details + status |

## Requirements

- LiveRamp account ID and secret key
